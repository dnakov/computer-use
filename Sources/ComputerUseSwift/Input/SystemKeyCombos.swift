import Foundation

/// Detection of dangerous system key combinations that should be blocked by default.
public enum SystemKeyCombos {

    /// macOS blocked combos — these can quit apps, lock screen, force-quit, etc.
    private static let blockedCombos: Set<Set<String>> = [
        Set(["meta", "q"]),              // Quit
        Set(["shift", "meta", "q"]),     // Quit all
        Set(["alt", "meta", "escape"]),  // Force Quit
        Set(["meta", "tab"]),            // App Switcher
        Set(["meta", "space"]),          // Spotlight
        Set(["ctrl", "meta", "q"]),      // Lock Screen
    ]

    /// Normalizes a modifier/key name to a canonical form.
    private static func normalize(_ key: String) -> String {
        switch key.lowercased() {
        case "meta", "super", "command", "cmd", "windows", "win":
            return "meta"
        case "ctrl", "control", "lctrl", "rctrl", "lcontrol", "rcontrol":
            return "ctrl"
        case "shift", "lshift", "rshift":
            return "shift"
        case "alt", "option", "roption":
            return "alt"
        default:
            return key.lowercased()
        }
    }

    /// Returns `true` if the given key combination is a blocked system combo.
    ///
    /// - Parameter keys: Array of key names (e.g., `["meta", "q"]`).
    /// - Returns: Whether this is a system key combo.
    public static func isSystemCombo(_ keys: [String]) -> Bool {
        let normalized = Set(keys.map { normalize($0) })
        return blockedCombos.contains(normalized)
    }
}
