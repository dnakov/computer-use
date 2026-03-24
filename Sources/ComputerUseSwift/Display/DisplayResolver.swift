import AppKit
import CoreGraphics

public enum DisplayResolver {

    /// Extracts the window frame from a CGWindowList info dictionary,
    /// but only for "normal" windows (layer 0, non-zero alpha).
    public static func frameIfNormal(_ windowInfo: [String: Any]) -> CGRect? {
        guard let layer = windowInfo[kCGWindowLayer as String] as? Int, layer == 0 else {
            return nil
        }
        guard let alpha = windowInfo[kCGWindowAlpha as String] as? Double, alpha > 0 else {
            return nil
        }
        guard let boundsValue = windowInfo[kCGWindowBounds as String],
              let boundsDict = boundsValue as? [String: Any] as CFDictionary?,
              let rect = CGRect(dictionaryRepresentation: boundsDict) else {
            return nil
        }
        return rect
    }

    /// Given a window frame, determines which display it belongs to
    /// by checking intersection against each display's bounds.
    public static func displayFor(_ rect: CGRect, screens: [(displayID: UInt32, frame: CGRect)]) -> UInt32? {
        for screen in screens {
            if rect.intersects(screen.frame) {
                return screen.displayID
            }
        }
        return nil
    }

    /// Returns all screen frames as (displayID, frame) tuples from NSScreen.screens.
    public static func allScreenFrames() -> [(displayID: UInt32, frame: CGRect)] {
        var result: [(displayID: UInt32, frame: CGRect)] = []
        for screen in NSScreen.screens {
            guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                continue
            }
            let displayID = screenNumber.uint32Value
            let frame = CGDisplayBounds(displayID)
            result.append((displayID: displayID, frame: frame))
        }
        return result
    }

    /// Resolves the target display for computer use operations.
    ///
    /// When autoResolve is false, returns display info for the preferred display ID.
    /// When autoResolve is true, finds the display with the most windows from allowed apps.
    public static func resolveTargetDisplay(
        allowedBundleIds: Set<String>,
        preferredDisplayID: UInt32?,
        autoResolve: Bool
    ) -> CUDisplayInfo? {
        if !autoResolve {
            return DisplayManager.cuDisplayInfo(forDisplayID: preferredDisplayID)
        }

        // Build set of relevant PIDs from running apps matching allowedBundleIds
        let ownPID = ProcessInfo.processInfo.processIdentifier
        let finderAllowed = allowedBundleIds.contains(BundleIDs.finder)
        var relevantPIDs = Set<pid_t>()

        for app in NSWorkspace.shared.runningApplications {
            guard let bundleID = app.bundleIdentifier else { continue }
            guard allowedBundleIds.contains(bundleID) else { continue }
            // Skip Finder unless explicitly allowed
            if bundleID == BundleIDs.finder && !finderAllowed { continue }
            if app.processIdentifier == ownPID { continue }
            relevantPIDs.insert(app.processIdentifier)
        }

        // Get window list
        guard let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] else {
            return DisplayManager.cuDisplayInfo(forDisplayID: preferredDisplayID)
        }

        // Get all screen frames
        let screens = allScreenFrames()

        // Count which displays have relevant windows
        var displayHits: [UInt32: Int] = [:]

        for windowInfo in windowList {
            guard let pid = windowInfo[kCGWindowOwnerPID as String] as? pid_t else { continue }
            guard relevantPIDs.contains(pid) else { continue }
            guard let frame = frameIfNormal(windowInfo) else { continue }
            if let displayID = displayFor(frame, screens: screens) {
                displayHits[displayID, default: 0] += 1
            }
        }

        // Return display with the most hits, or fall back to preferred/main
        if let bestDisplay = displayHits.max(by: { $0.value < $1.value }) {
            return DisplayManager.cuDisplayInfo(forDisplayID: bestDisplay.key)
        }

        return DisplayManager.cuDisplayInfo(forDisplayID: preferredDisplayID)
    }
}
