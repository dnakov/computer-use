import AppKit
import CoreGraphics

public enum AppManager {
    public static func listRunning() -> [RunningApp] {
        NSWorkspace.shared.runningApplications.compactMap { app in
            guard let bundleId = app.bundleIdentifier,
                  let name = app.localizedName else {
                return nil
            }
            return RunningApp(bundleIdentifier: bundleId, localizedName: name)
        }
    }

    public static func openApp(bundleId: String) async throws {
        guard let url = NSWorkspace.shared.urlForApplication(withBundleIdentifier: bundleId) else {
            throw AppError.notFound(bundleId)
        }

        let config = NSWorkspace.OpenConfiguration()
        config.activates = true

        try await NSWorkspace.shared.openApplication(at: url, configuration: config)
    }

    public static func unhideApps(bundleIds: [String], stagger: Bool = true) {
        for bundleId in bundleIds {
            let apps = NSRunningApplication.runningApplications(withBundleIdentifier: bundleId)
            for app in apps {
                app.unhide()
            }
            if stagger && bundleIds.count > 1 {
                Thread.sleep(forTimeInterval: 0.02)  // 20ms stagger lets window server animate
            }
        }
    }

    /// Capture the current window z-order as an ordered list of bundle IDs (front-to-back).
    /// Uses CGWindowListCopyWindowInfo which returns windows in front-to-back order.
    public static func captureWindowStack() -> [String] {
        guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
            return []
        }

        let runningApps = NSWorkspace.shared.runningApplications
        let pidToBundle: [pid_t: String] = {
            var map = [pid_t: String]()
            for app in runningApps {
                if let bid = app.bundleIdentifier {
                    map[app.processIdentifier] = bid
                }
            }
            return map
        }()

        // Collect unique bundle IDs in z-order (front to back), skipping system layers
        var seen = Set<String>()
        var stack: [String] = []
        for info in windowList {
            guard let layer = info[kCGWindowLayer as String] as? Int, layer == 0,
                  let pid = info[kCGWindowOwnerPID as String] as? pid_t,
                  let bundleId = pidToBundle[pid],
                  !seen.contains(bundleId) else {
                continue
            }
            seen.insert(bundleId)
            stack.append(bundleId)
        }
        return stack
    }

    /// Restore the previously frontmost app after unhiding.
    /// Only activates the single app that was on top — no janky one-by-one shuffling.
    public static func restoreFrontmostApp(from stack: [String]) {
        guard let frontmostBundleId = stack.first else { return }
        let apps = NSRunningApplication.runningApplications(withBundleIdentifier: frontmostBundleId)
        if let app = apps.first(where: { !$0.isHidden }) ?? apps.first {
            app.activate()
        }
    }

    public static func resolveBundleIds(names: [String]) -> [String] {
        let runningApps = NSWorkspace.shared.runningApplications

        return names.map { name in
            // First try matching against running apps by localizedName
            for app in runningApps {
                if app.localizedName == name, let bundleId = app.bundleIdentifier {
                    return bundleId
                }
            }

            // Fallback: use NSWorkspace to find the app path, then get bundle ID
            if let fullPath = NSWorkspace.shared.fullPath(forApplication: name),
               let bundle = Bundle(path: fullPath),
               let bundleId = bundle.bundleIdentifier {
                return bundleId
            }

            return name
        }
    }

    public static func iconDataUrl(path: String) -> String? {
        let icon = NSWorkspace.shared.icon(forFile: path)

        let targetSize = NSSize(width: 32, height: 32)
        let resizedImage = NSImage(size: targetSize)
        resizedImage.lockFocus()
        icon.draw(
            in: NSRect(origin: .zero, size: targetSize),
            from: NSRect(origin: .zero, size: icon.size),
            operation: .copy,
            fraction: 1.0
        )
        resizedImage.unlockFocus()

        guard let tiffData = resizedImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            return nil
        }

        let base64 = pngData.base64EncodedString()
        return "data:image/png;base64,\(base64)"
    }

    public static func findWindowDisplays(bundleIds: [String]) -> FindWindowDisplaysResult {
        let runningApps = NSWorkspace.shared.runningApplications
        var targetPIDs = Set<pid_t>()

        for app in runningApps {
            if let bundleId = app.bundleIdentifier, bundleIds.contains(bundleId) {
                targetPIDs.insert(app.processIdentifier)
            }
        }

        let windowList = CGWindowListCopyWindowInfo(
            .optionOnScreenOnly,
            kCGNullWindowID
        ) as? [[String: Any]] ?? []

        let screens = DisplayResolver.allScreenFrames()
        var displayIds = Set<Int>()

        for windowInfo in windowList {
            guard let pid = windowInfo[kCGWindowOwnerPID as String] as? pid_t,
                  targetPIDs.contains(pid) else {
                continue
            }

            guard let frame = DisplayResolver.frameIfNormal(windowInfo) else {
                continue
            }

            if let displayId = DisplayResolver.displayFor(frame, screens: screens) {
                displayIds.insert(Int(displayId))
            }
        }

        return FindWindowDisplaysResult(displayIds: Array(displayIds))
    }

    public static func previewHideSet(exemptBundleIds: [String]) -> [String] {
        let mainDisplayId = CGMainDisplayID()
        let displayBounds = CGDisplayBounds(mainDisplayId)

        let candidates = HideCandidates.compute(
            exemptBundleIds: Set(exemptBundleIds),
            displayFrame: displayBounds
        )

        return candidates.compactMap { $0.bundleIdentifier }
    }

    public static func prepareDisplay(allowedBundleIds: [String], hostBundleId: String) async -> PrepareDisplayResult {
        guard let displayInfo = DisplayResolver.resolveTargetDisplay(
            allowedBundleIds: Set(allowedBundleIds),
            preferredDisplayID: nil,
            autoResolve: true
        ) else {
            return PrepareDisplayResult(hidden: [], activated: nil)
        }

        let candidates = HideCandidates.compute(
            exemptBundleIds: Set(allowedBundleIds + [hostBundleId]),
            displayFrame: displayInfo.displayRect
        )

        var hiddenBundleIds: [String] = []
        for app in candidates {
            app.hide()
            if let bundleId = app.bundleIdentifier {
                hiddenBundleIds.append(bundleId)
            }
            // Small stagger so macOS can animate each hide
            if candidates.count > 1 {
                Thread.sleep(forTimeInterval: 0.02)
            }
        }

        // Activate the frontmost allowed app
        var activated: String? = nil
        let runningApps = NSWorkspace.shared.runningApplications
        for app in runningApps {
            if let bundleId = app.bundleIdentifier,
               allowedBundleIds.contains(bundleId),
               app.isActive || !app.isHidden {
                app.activate()
                activated = bundleId
                break
            }
        }

        return PrepareDisplayResult(hidden: hiddenBundleIds, activated: activated)
    }
}
