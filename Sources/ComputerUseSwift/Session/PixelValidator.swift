import AppKit
import Foundation

public enum PixelValidator {

    private static let patchSize = 9

    /// Check if screen content at the target location changed since last screenshot.
    /// Returns nil if unchanged, error string if changed.
    @available(macOS 14.0, *)
    public static func validate(
        targetX: Double, targetY: Double,
        session: SessionState,
        lastScreenshotBase64: String
    ) async -> String? {
        guard let screenshotDims = session.lastScreenshot else {
            return nil
        }

        // 1. Decode last screenshot from base64
        let base64Data: String
        if lastScreenshotBase64.contains(",") {
            base64Data = String(lastScreenshotBase64.split(separator: ",").last ?? "")
        } else {
            base64Data = lastScreenshotBase64
        }

        guard let imageData = Data(base64Encoded: base64Data),
              let nsImage = NSImage(data: imageData) else {
            return nil
        }

        // 2. Compute target position as percentage of display
        let pctX = targetX / Double(screenshotDims.displayWidth)
        let pctY = targetY / Double(screenshotDims.displayHeight)

        // 3. Compute pixel position in screenshot space
        let imgX = Int(pctX * Double(screenshotDims.width))
        let imgY = Int(pctY * Double(screenshotDims.height))

        // 4. Define 9x9 patch bounds (clamped to image)
        let halfPatch = patchSize / 2
        let cropX = max(0, imgX - halfPatch)
        let cropY = max(0, imgY - halfPatch)
        let cropW = min(patchSize, screenshotDims.width - cropX)
        let cropH = min(patchSize, screenshotDims.height - cropY)

        guard cropW > 0, cropH > 0 else {
            return nil
        }

        let cropRect = CGRect(x: cropX, y: cropY, width: cropW, height: cropH)

        // 5. Crop patch from last screenshot
        guard let oldPatch = cropImage(nsImage, rect: cropRect) else {
            return nil
        }

        // 6. Take fresh screenshot of the same region in screen coordinates
        let screenX = Double(screenshotDims.originX) + pctX * Double(screenshotDims.displayWidth) - Double(halfPatch)
        let screenY = Double(screenshotDims.originY) + pctY * Double(screenshotDims.displayHeight) - Double(halfPatch)
        let sourceRect = CGRect(x: screenX, y: screenY, width: Double(patchSize), height: Double(patchSize))

        guard let freshResult = try? await ScreenshotCapture.captureScreenRegion(
            displayId: UInt32(screenshotDims.displayId),
            sourceRect: sourceRect,
            outputWidth: patchSize,
            outputHeight: patchSize,
            excludedBundleIds: [],
            jpegQuality: 1.0
        ) else {
            return nil
        }

        // 7. Decode fresh patch
        let freshBase64: String
        if freshResult.dataUrl.contains(",") {
            freshBase64 = String(freshResult.dataUrl.split(separator: ",").last ?? "")
        } else {
            freshBase64 = freshResult.dataUrl
        }

        guard let freshData = Data(base64Encoded: freshBase64),
              let freshImage = NSImage(data: freshData),
              let freshPatch = bitmapData(from: freshImage) else {
            return nil
        }

        // 8. Compare raw pixel data
        let oldData = bitmapData(from: oldPatch)
        guard let oldBytes = oldData else {
            return nil
        }

        if oldBytes != freshPatch {
            return "Screen content at the target location changed since the last screenshot. Take a new screenshot before clicking."
        }

        return nil
    }

    // MARK: - Private

    private static func cropImage(_ image: NSImage, rect: CGRect) -> NSImage? {
        guard let cgImage = image.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            return nil
        }

        guard let cropped = cgImage.cropping(to: rect) else {
            return nil
        }

        return NSImage(cgImage: cropped, size: NSSize(width: rect.width, height: rect.height))
    }

    private static func bitmapData(from image: NSImage) -> Data? {
        guard let tiffData = image.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData) else {
            return nil
        }
        return bitmapRep.representation(using: .png, properties: [:])
    }
}
