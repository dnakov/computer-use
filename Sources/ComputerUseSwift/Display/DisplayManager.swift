import AppKit
import CoreGraphics

public enum DisplayManager {

    /// Finds the NSScreen matching a given CGDirectDisplayID.
    public static func findScreen(for displayID: UInt32) -> NSScreen? {
        for screen in NSScreen.screens {
            if let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber,
               screenNumber.uint32Value == displayID {
                return screen
            }
        }
        return nil
    }

    /// Returns display info for a given display ID, falling back to the main display.
    public static func cuDisplayInfo(forDisplayID displayID: UInt32?) -> CUDisplayInfo? {
        let mainID = CGMainDisplayID()
        let targetID = displayID ?? mainID

        var screen = findScreen(for: targetID)
        var resolvedID = targetID

        // If requested display not found, fall back to main
        if screen == nil && targetID != mainID {
            screen = findScreen(for: mainID)
            resolvedID = mainID
        }

        guard let screen = screen else {
            return nil
        }

        let bounds = CGDisplayBounds(resolvedID)
        let boundsW = Int(CGFloat(bounds.size.width))
        let boundsH = Int(CGFloat(bounds.size.height))
        let scale = screen.backingScaleFactor
        let physW = Int(Double(boundsW) * Double(scale))
        let physH = Int(Double(boundsH) * Double(scale))
        let originX = Int(bounds.origin.x)
        let originY = Int(bounds.origin.y)

        return CUDisplayInfo(
            displayID: resolvedID,
            boundsWidth: boundsW,
            boundsHeight: boundsH,
            displayRect: bounds,
            physicalWidth: physW,
            physicalHeight: physH,
            scaleFactor: Double(scale),
            originX: originX,
            originY: originY
        )
    }

    /// Lists all connected displays.
    public static func listAllDisplays() -> [DisplayInfo] {
        let mainID = CGMainDisplayID()
        var results: [DisplayInfo] = []

        for screen in NSScreen.screens {
            guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                continue
            }
            let displayID = screenNumber.uint32Value
            let bounds = CGDisplayBounds(displayID)
            let width = Int(bounds.size.width)
            let height = Int(bounds.size.height)
            let scale = screen.backingScaleFactor
            let isPrimary = displayID == mainID

            results.append(DisplayInfo(
                displayId: Int(displayID),
                width: width,
                height: height,
                scaleFactor: Double(scale),
                originX: Int(bounds.origin.x),
                originY: Int(bounds.origin.y),
                isPrimary: isPrimary
            ))
        }

        return results
    }

    /// Gets the size/metadata of a display. If displayId is nil, uses the main display.
    public static func getDisplaySize(displayId: UInt32?) -> DisplayInfo? {
        guard let info = cuDisplayInfo(forDisplayID: displayId) else {
            return nil
        }
        return info.toDisplayInfo()
    }
}
