import CoreGraphics
import Foundation

/// Complete key name → macOS virtual keycode mapping.
/// Covers modifier keys, navigation keys, function keys, numpad keys, media/NX keys, and Unicode fallback.
public enum KeyMapping {

    // MARK: - Public API

    /// Returns the virtual keycode and whether the key is a modifier for a given key name.
    /// Returns `nil` if the key name is not recognized (and is not a single Unicode character).
    public static func virtualKeycode(for name: String) -> (keycode: UInt16, isModifier: Bool)? {
        return keyMap[name]
    }

    /// Returns `true` if the key name corresponds to a modifier key.
    public static func isModifierKey(_ name: String) -> Bool {
        return keyMap[name]?.isModifier == true
    }

    /// Returns the NX key type constant for media/special keys that require the
    /// `NSEvent.otherEvent(with: .systemDefined, ...)` code path.
    /// Returns `nil` if the key name is not a media/NX key.
    public static func nxKeyType(for name: String) -> UInt32? {
        return nxKeyMap[name]
    }

    /// Returns `true` if the name is a single character not found in the named key map
    /// (i.e., it should be typed via the Unicode/CGEventKeyboardSetUnicodeString path).
    public static func isUnicodeCharacter(_ name: String) -> Bool {
        return name.count == 1 && keyMap[name] == nil && nxKeyMap[name] == nil
    }

    /// Returns the `CGEventFlags` mask for a modifier key name, or `nil` if not a modifier.
    public static func modifierFlag(for name: String) -> CGEventFlags? {
        return modifierFlagMap[name]
    }

    // MARK: - Key Map

    private static let keyMap: [String: (keycode: UInt16, isModifier: Bool)] = [
        // Modifier keys
        "Alt":        (0x3A, true),
        "Option":     (0x3A, true),
        "ROption":    (0x3D, true),
        "Command":    (0x37, true),
        "RCommand":   (0x36, true),
        "Super":      (0x37, true),
        "Windows":    (0x37, true),
        "Meta":       (0x37, true),
        "Control":    (0x3B, true),
        "LControl":   (0x3B, true),
        "RControl":   (0x3E, true),
        "Shift":      (0x38, true),
        "LShift":     (0x38, true),
        "RShift":     (0x3C, true),
        "Function":   (0x3F, true),
        "CapsLock":   (0x39, true),

        // Navigation keys
        "Return":     (0x24, false),
        "Tab":        (0x30, false),
        "Space":      (0x31, false),
        "Backspace":  (0x33, false),
        "Delete":     (0x75, false),
        "Escape":     (0x35, false),
        "UpArrow":    (0x7E, false),
        "DownArrow":  (0x7D, false),
        "LeftArrow":  (0x7B, false),
        "RightArrow": (0x7C, false),
        "Home":       (0x73, false),
        "End":        (0x77, false),
        "PageUp":     (0x74, false),
        "PageDown":   (0x79, false),

        // Function keys F1–F20
        "F1":  (0x7A, false),
        "F2":  (0x78, false),
        "F3":  (0x63, false),
        "F4":  (0x76, false),
        "F5":  (0x60, false),
        "F6":  (0x61, false),
        "F7":  (0x62, false),
        "F8":  (0x64, false),
        "F9":  (0x65, false),
        "F10": (0x6D, false),
        "F11": (0x67, false),
        "F12": (0x6F, false),
        "F13": (0x69, false),
        "F14": (0x6B, false),
        "F15": (0x71, false),
        "F16": (0x6A, false),
        "F17": (0x40, false),
        "F18": (0x4F, false),
        "F19": (0x50, false),
        "F20": (0x5A, false),

        // Numpad keys
        "Numpad0":  (0x52, false),
        "Numpad1":  (0x53, false),
        "Numpad2":  (0x54, false),
        "Numpad3":  (0x55, false),
        "Numpad4":  (0x56, false),
        "Numpad5":  (0x57, false),
        "Numpad6":  (0x58, false),
        "Numpad7":  (0x59, false),
        "Numpad8":  (0x5B, false),
        "Numpad9":  (0x5C, false),
        "Add":      (0x45, false),
        "Subtract": (0x4E, false),
        "Multiply": (0x43, false),
        "Divide":   (0x4B, false),
        "Decimal":  (0x41, false),

        // Other / aliases
        "Help":  (0x72, false),
        "Left":  (0x7B, false),  // Alias for LeftArrow

        // Common single-character keys (a-z, 0-9) mapped to their virtual keycodes
        "a": (0x00, false), "b": (0x0B, false), "c": (0x08, false),
        "d": (0x02, false), "e": (0x0E, false), "f": (0x03, false),
        "g": (0x05, false), "h": (0x04, false), "i": (0x22, false),
        "j": (0x26, false), "k": (0x28, false), "l": (0x25, false),
        "m": (0x2E, false), "n": (0x2D, false), "o": (0x1F, false),
        "p": (0x23, false), "q": (0x0C, false), "r": (0x0F, false),
        "s": (0x01, false), "t": (0x11, false), "u": (0x20, false),
        "v": (0x09, false), "w": (0x0D, false), "x": (0x07, false),
        "y": (0x10, false), "z": (0x06, false),

        "0": (0x1D, false), "1": (0x12, false), "2": (0x13, false),
        "3": (0x14, false), "4": (0x15, false), "5": (0x17, false),
        "6": (0x16, false), "7": (0x1A, false), "8": (0x1C, false),
        "9": (0x19, false),

        // Punctuation / symbol keys (US ANSI layout)
        "-":  (0x1B, false),  // Minus/Hyphen
        "=":  (0x18, false),  // Equals
        "[":  (0x21, false),  // Left Bracket
        "]":  (0x1E, false),  // Right Bracket
        "\\": (0x2A, false),  // Backslash
        ";":  (0x29, false),  // Semicolon
        "'":  (0x27, false),  // Quote
        ",":  (0x2B, false),  // Comma
        ".":  (0x2F, false),  // Period
        "/":  (0x2C, false),  // Slash
        "`":  (0x32, false),  // Grave/Backtick
    ]

    // MARK: - NX Media Key Map

    // NX_KEYTYPE constants from IOKit/hidsystem/ev_keymap.h
    private static let nxKeyMap: [String: UInt32] = [
        "BrightnessDown":      3,   // NX_KEYTYPE_BRIGHTNESS_DOWN
        "BrightnessUp":        2,   // NX_KEYTYPE_BRIGHTNESS_UP
        "ContrastUp":          11,  // NX_KEYTYPE_CONTRAST_UP
        "ContrastDown":        12,  // NX_KEYTYPE_CONTRAST_DOWN
        "Eject":               14,  // NX_KEYTYPE_EJECT
        "IlluminationDown":    22,  // NX_KEYTYPE_ILLUMINATION_DOWN
        "IlluminationUp":      21,  // NX_KEYTYPE_ILLUMINATION_UP
        "IlluminationToggle":  23,  // NX_KEYTYPE_ILLUMINATION_TOGGLE
        "LaunchPanel":         19,  // NX_KEYTYPE_LAUNCH_PANEL
        "Launchpad":           131, // NX_KEYTYPE_LAUNCHPAD  (0x83)
        "MediaFast":           17,  // NX_KEYTYPE_FAST
        "MediaNextTrack":      17,  // NX_KEYTYPE_NEXT  (same as FAST in some mappings)
        "MediaPlayPause":      16,  // NX_KEYTYPE_PLAY
        "MediaPrevTrack":      18,  // NX_KEYTYPE_PREVIOUS
        "MediaRewind":         20,  // NX_KEYTYPE_REWIND
        "MissionControl":      130, // NX_KEYTYPE_MISSION_CONTROL  (0x82)
        "Power":               6,   // NX_KEYTYPE_POWER
        "VidMirror":           15,  // NX_KEYTYPE_VIDMIRROR
        "VolumeDown":          1,   // NX_KEYTYPE_SOUND_DOWN
        "VolumeMute":          7,   // NX_KEYTYPE_MUTE
        "VolumeUp":            0,   // NX_KEYTYPE_SOUND_UP
    ]

    // MARK: - Modifier Flag Map

    private static let modifierFlagMap: [String: CGEventFlags] = [
        "Alt":       .maskAlternate,
        "Option":    .maskAlternate,
        "ROption":   .maskAlternate,
        "Command":   .maskCommand,
        "RCommand":  .maskCommand,
        "Super":     .maskCommand,
        "Windows":   .maskCommand,
        "Meta":      .maskCommand,
        "Control":   .maskControl,
        "LControl":  .maskControl,
        "RControl":  .maskControl,
        "Shift":     .maskShift,
        "LShift":    .maskShift,
        "RShift":    .maskShift,
        "Function":  .maskSecondaryFn,
        "CapsLock":  .maskAlphaShift,
    ]
}
