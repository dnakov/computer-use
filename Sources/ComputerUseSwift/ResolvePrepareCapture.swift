import AppKit
import CoreGraphics

public enum ResolvePrepareCapture {

    public static func execute(
        allowedBundleIds: [String],
        hostBundleId: String,
        excludeBundleIds: [String]
    ) async -> ResolvePrepareCaptureResult {
        // 1. Resolve target display
        let allowedSet = Set(allowedBundleIds)
        guard let displayInfo = DisplayResolver.resolveTargetDisplay(
            allowedBundleIds: allowedSet,
            preferredDisplayID: nil,
            autoResolve: true
        ) else {
            return ResolvePrepareCaptureResult(
                screenshot: nil,
                hidden: [],
                activated: nil,
                displayId: Int(CGMainDisplayID())
            )
        }

        // 2. Compute hide candidates and hide them
        let exemptIds = Set(allowedBundleIds + [hostBundleId])
        let candidates = HideCandidates.compute(
            exemptBundleIds: exemptIds,
            displayFrame: displayInfo.displayRect
        )

        var hiddenBundleIds: [String] = []
        for app in candidates {
            app.hide()
            if let bundleId = app.bundleIdentifier {
                hiddenBundleIds.append(bundleId)
            }
        }

        // 3. Activate the frontmost allowed app
        var activated: String? = nil
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            if let bundleId = app.bundleIdentifier,
               allowedSet.contains(bundleId),
               app.isActive || !app.isHidden {
                app.activate()
                activated = bundleId
                break
            }
        }

        // 4. Compute optimal image size
        let (targetW, targetH) = ImageSizing.cuTargetImageSize(
            physW: displayInfo.physicalWidth,
            physH: displayInfo.physicalHeight
        )

        // 5. Capture screenshot
        var screenshot: ScreenshotResult? = nil
        var captureError: String? = nil

        do {
            let result = try await ScreenshotCapture.captureScreenWithExclusion(
                displayId: displayInfo.displayID,
                width: targetW,
                height: targetH,
                excludedBundleIds: excludeBundleIds,
                jpegQuality: 0.75
            )
            screenshot = ScreenshotResult(
                base64: result.dataUrl,
                width: result.width,
                height: result.height,
                displayWidth: displayInfo.boundsWidth,
                displayHeight: displayInfo.boundsHeight,
                displayId: Int(displayInfo.displayID),
                originX: displayInfo.originX,
                originY: displayInfo.originY
            )
        } catch {
            captureError = error.localizedDescription
            screenshot = ScreenshotResult(
                base64: "",
                width: 0,
                height: 0,
                displayWidth: displayInfo.boundsWidth,
                displayHeight: displayInfo.boundsHeight,
                displayId: Int(displayInfo.displayID),
                originX: displayInfo.originX,
                originY: displayInfo.originY,
                captureError: captureError
            )
        }

        return ResolvePrepareCaptureResult(
            screenshot: screenshot,
            hidden: hiddenBundleIds,
            activated: activated,
            displayId: Int(displayInfo.displayID)
        )
    }
}
