import AppKit
import CoreGraphics

public enum DisplayLabels {

    public struct LabeledDisplay: Codable {
        public let displayId: Int
        public let label: String
        public let width: Int
        public let height: Int
        public let isPrimary: Bool
    }

    /// Generate labeled display list with deduplicated names.
    /// Uses `NSScreen.screens` and `NSScreen.localizedName` for display names.
    /// Deduplicates by appending " (1)", " (2)" if multiple screens share the same name.
    public static func generate() -> [LabeledDisplay] {
        let mainID = CGMainDisplayID()
        var entries: [(displayId: UInt32, name: String, width: Int, height: Int, isPrimary: Bool)] = []

        for screen in NSScreen.screens {
            guard let screenNumber = screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? NSNumber else {
                continue
            }
            let displayID = screenNumber.uint32Value
            let bounds = CGDisplayBounds(displayID)
            let name = screen.localizedName
            entries.append((
                displayId: displayID,
                name: name,
                width: Int(bounds.size.width),
                height: Int(bounds.size.height),
                isPrimary: displayID == mainID
            ))
        }

        // Count occurrences of each name for deduplication
        var nameCounts: [String: Int] = [:]
        for entry in entries {
            nameCounts[entry.name, default: 0] += 1
        }

        // Track per-name index for suffix assignment
        var nameIndex: [String: Int] = [:]
        var results: [LabeledDisplay] = []

        for entry in entries {
            let label: String
            if nameCounts[entry.name, default: 0] > 1 {
                let idx = nameIndex[entry.name, default: 0] + 1
                nameIndex[entry.name] = idx
                label = "\(entry.name) (\(idx))"
            } else {
                label = entry.name
            }

            results.append(LabeledDisplay(
                displayId: Int(entry.displayId),
                label: label,
                width: entry.width,
                height: entry.height,
                isPrimary: entry.isPrimary
            ))
        }

        return results
    }

    /// Generate multi-display context message for screenshot results.
    ///
    /// Returns a string like:
    /// "This screenshot was taken on Built-in Retina Display. Other attached monitors: LG UltraFine."
    ///
    /// Returns `nil` if there is only one display attached.
    public static func contextMessage(
        capturedDisplayId: Int,
        previousDisplayId: Int?
    ) -> String? {
        let displays = generate()

        guard displays.count > 1 else {
            return nil
        }

        let captured = displays.first { $0.displayId == capturedDisplayId }
        let capturedLabel = captured?.label ?? "Unknown Display"

        let others = displays
            .filter { $0.displayId != capturedDisplayId }
            .map { $0.label }

        var message = "This screenshot was taken on \(capturedLabel)."

        if !others.isEmpty {
            message += " Other attached monitors: \(others.joined(separator: ", "))."
        }

        return message
    }
}
