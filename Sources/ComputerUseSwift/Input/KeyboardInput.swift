import AppKit
import CoreGraphics
import Foundation

/// Keyboard input simulation using CGEvent APIs.
public enum KeyboardInput {

    // MARK: - Public API

    /// Performs a keyboard action on a single key.
    ///
    /// - Parameters:
    ///   - keyName: The key name (see `KeyMapping` for valid names) or a single Unicode character.
    ///   - action: One of "press", "release", or "click". Defaults to "click".
    /// - Returns: A success message string.
    public static func key(name keyName: String, action: String = "click") async throws -> String {
        // Validate action
        guard ["press", "release", "click"].contains(action) else {
            throw InputError.invalidAction(action)
        }

        // Check for NX media key
        if let nxKeyType = KeyMapping.nxKeyType(for: keyName) {
            switch action {
            case "press":
                try postMediaKeyEvent(nxKeyType: nxKeyType, keyDown: true)
            case "release":
                try postMediaKeyEvent(nxKeyType: nxKeyType, keyDown: false)
            default: // click
                try postMediaKeyEvent(nxKeyType: nxKeyType, keyDown: true)
                try postMediaKeyEvent(nxKeyType: nxKeyType, keyDown: false)
            }
            return "Successfully \(action)ed key: \(keyName)"
        }

        // Check for named key
        if let (keycode, isModifier) = KeyMapping.virtualKeycode(for: keyName) {
            let source = try createEventSource()
            let flags = isModifier ? (KeyMapping.modifierFlag(for: keyName) ?? CGEventFlags()) : CGEventFlags()

            switch action {
            case "press":
                try postKeyEvent(source: source, keycode: keycode, keyDown: true, flags: flags, isModifier: isModifier, keyName: keyName)
            case "release":
                try postKeyEvent(source: source, keycode: keycode, keyDown: false, flags: flags, isModifier: isModifier, keyName: keyName)
            default: // click
                try postKeyEvent(source: source, keycode: keycode, keyDown: true, flags: flags, isModifier: isModifier, keyName: keyName)
                try postKeyEvent(source: source, keycode: keycode, keyDown: false, flags: flags, isModifier: isModifier, keyName: keyName)
            }
            return "Successfully \(action)ed key: \(keyName)"
        }

        // Check for single Unicode character
        if KeyMapping.isUnicodeCharacter(keyName) {
            let source = try createEventSource()
            switch action {
            case "press":
                try postUnicodeKeyEvent(source: source, character: keyName, keyDown: true)
            case "release":
                try postUnicodeKeyEvent(source: source, character: keyName, keyDown: false)
            default: // click
                try postUnicodeKeyEvent(source: source, character: keyName, keyDown: true)
                try postUnicodeKeyEvent(source: source, character: keyName, keyDown: false)
            }
            return "Successfully \(action)ed key: \(keyName)"
        }

        throw InputError.invalidKeyName(keyName)
    }

    /// Executes a key combination. Presses all keys in order, then releases in reverse.
    ///
    /// - Parameter keyNames: Array of key names to press simultaneously.
    /// - Returns: A success message string.
    public static func keys(names keyNames: [String]) async throws -> String {
        guard !keyNames.isEmpty else {
            throw InputError.noKeysProvided
        }

        // Validate all key names first
        for name in keyNames {
            if KeyMapping.virtualKeycode(for: name) == nil
                && KeyMapping.nxKeyType(for: name) == nil
                && !KeyMapping.isUnicodeCharacter(name)
            {
                throw InputError.invalidKeyName(name)
            }
        }

        // Separate modifiers from regular keys
        var modifiers: [String] = []
        var regularKeys: [String] = []
        for name in keyNames {
            if KeyMapping.isModifierKey(name) {
                modifiers.append(name)
            } else {
                regularKeys.append(name)
            }
        }

        let source = try createEventSource()

        // Build cumulative modifier flags
        var currentFlags = CGEventFlags()

        // Press modifiers first (in order)
        for mod in modifiers {
            if let (keycode, _) = KeyMapping.virtualKeycode(for: mod) {
                if let flag = KeyMapping.modifierFlag(for: mod) {
                    currentFlags.insert(flag)
                }
                do {
                    try postKeyEvent(source: source, keycode: keycode, keyDown: true, flags: currentFlags, isModifier: true, keyName: mod)
                } catch {
                    throw InputError.modifierPressFailed(error.localizedDescription)
                }
            }
        }

        // Press regular keys (in order)
        for key in regularKeys {
            if let (keycode, _) = KeyMapping.virtualKeycode(for: key) {
                do {
                    try postKeyEvent(source: source, keycode: keycode, keyDown: true, flags: currentFlags, isModifier: false, keyName: key)
                } catch {
                    throw InputError.keyPressFailed(error.localizedDescription)
                }
            } else if KeyMapping.isUnicodeCharacter(key) {
                try postUnicodeKeyEvent(source: source, character: key, keyDown: true)
            }
        }

        // Release regular keys (reversed)
        for key in regularKeys.reversed() {
            if let (keycode, _) = KeyMapping.virtualKeycode(for: key) {
                do {
                    try postKeyEvent(source: source, keycode: keycode, keyDown: false, flags: currentFlags, isModifier: false, keyName: key)
                } catch {
                    throw InputError.keyReleaseFailed(error.localizedDescription)
                }
            } else if KeyMapping.isUnicodeCharacter(key) {
                try postUnicodeKeyEvent(source: source, character: key, keyDown: false)
            }
        }

        // Release modifiers (reversed)
        for mod in modifiers.reversed() {
            if let (keycode, _) = KeyMapping.virtualKeycode(for: mod) {
                if let flag = KeyMapping.modifierFlag(for: mod) {
                    currentFlags.remove(flag)
                }
                do {
                    try postKeyEvent(source: source, keycode: keycode, keyDown: false, flags: currentFlags, isModifier: true, keyName: mod)
                } catch {
                    throw InputError.modifierReleaseFailed(error.localizedDescription)
                }
            }
        }

        return "Successfully executed key combination: \(keyNames)"
    }

    /// Holds one or more keys for a specified duration, then releases them.
    ///
    /// Modifiers are pressed first, then regular keys. Release is in reverse order.
    ///
    /// - Parameters:
    ///   - keyNames: Array of key names to hold simultaneously.
    ///   - durationMs: How long to hold the keys, in milliseconds.
    /// - Returns: A success message string.
    public static func holdKey(keyNames: [String], durationMs: Int) async throws -> String {
        guard !keyNames.isEmpty else {
            throw InputError.noKeysProvided
        }

        // Validate all key names first
        for name in keyNames {
            if KeyMapping.virtualKeycode(for: name) == nil
                && KeyMapping.nxKeyType(for: name) == nil
                && !KeyMapping.isUnicodeCharacter(name)
            {
                throw InputError.invalidKeyName(name)
            }
        }

        // Separate modifiers from regular keys
        var modifiers: [String] = []
        var regularKeys: [String] = []
        for name in keyNames {
            if KeyMapping.isModifierKey(name) {
                modifiers.append(name)
            } else {
                regularKeys.append(name)
            }
        }

        let source = try createEventSource()

        // Build cumulative modifier flags
        var currentFlags = CGEventFlags()

        // Press modifiers first (in order)
        for mod in modifiers {
            if let (keycode, _) = KeyMapping.virtualKeycode(for: mod) {
                if let flag = KeyMapping.modifierFlag(for: mod) {
                    currentFlags.insert(flag)
                }
                try postKeyEvent(source: source, keycode: keycode, keyDown: true, flags: currentFlags, isModifier: true, keyName: mod)
            }
        }

        // Press regular keys (in order)
        for key in regularKeys {
            if let (keycode, _) = KeyMapping.virtualKeycode(for: key) {
                try postKeyEvent(source: source, keycode: keycode, keyDown: true, flags: currentFlags, isModifier: false, keyName: key)
            } else if KeyMapping.isUnicodeCharacter(key) {
                try postUnicodeKeyEvent(source: source, character: key, keyDown: true)
            }
        }

        // Hold for the specified duration
        try await Task.sleep(nanoseconds: UInt64(durationMs) * 1_000_000)

        // Release regular keys (reversed)
        for key in regularKeys.reversed() {
            if let (keycode, _) = KeyMapping.virtualKeycode(for: key) {
                try postKeyEvent(source: source, keycode: keycode, keyDown: false, flags: currentFlags, isModifier: false, keyName: key)
            } else if KeyMapping.isUnicodeCharacter(key) {
                try postUnicodeKeyEvent(source: source, character: key, keyDown: false)
            }
        }

        // Release modifiers (reversed)
        for mod in modifiers.reversed() {
            if let (keycode, _) = KeyMapping.virtualKeycode(for: mod) {
                if let flag = KeyMapping.modifierFlag(for: mod) {
                    currentFlags.remove(flag)
                }
                try postKeyEvent(source: source, keycode: keycode, keyDown: false, flags: currentFlags, isModifier: true, keyName: mod)
            }
        }

        return "Successfully held keys for \(durationMs)ms"
    }

    /// Types a text string using fast text entry, falling back to character-by-character.
    ///
    /// - Parameter text: The text to type.
    /// - Returns: A success message string.
    public static func typeText(_ text: String) async throws -> String {
        guard !text.isEmpty else {
            throw InputError.emptyText
        }

        let source = try createEventSource()

        // Try fast text entry first: single CGEvent with the full Unicode string
        let fastSuccess = postUnicodeString(source: source, text: text, keyDown: true)
            && postUnicodeString(source: source, text: text, keyDown: false)

        if !fastSuccess {
            // Fall back to character-by-character
            for char in text {
                let charStr = String(char)
                do {
                    try postUnicodeKeyEvent(source: source, character: charStr, keyDown: true)
                    try postUnicodeKeyEvent(source: source, character: charStr, keyDown: false)
                } catch {
                    throw InputError.keyActionFailed("Error typing text: \(error.localizedDescription)")
                }
            }
        }

        return "Successfully typed text: \(text)"
    }

    // MARK: - Private Helpers

    private static func createEventSource() throws -> CGEventSource {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            throw InputError.eventCreationFailed("failed creating event source")
        }
        return source
    }

    private static func postKeyEvent(
        source: CGEventSource,
        keycode: UInt16,
        keyDown: Bool,
        flags: CGEventFlags,
        isModifier: Bool,
        keyName: String
    ) throws {
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: keycode, keyDown: keyDown) else {
            let action = keyDown ? "press" : "release"
            if isModifier {
                throw keyDown
                    ? InputError.modifierPressFailed("failed creating event to \(action) the key")
                    : InputError.modifierReleaseFailed("failed creating event to \(action) the key")
            } else {
                throw keyDown
                    ? InputError.keyPressFailed("failed creating event to \(action) the key")
                    : InputError.keyReleaseFailed("failed creating event to \(action) the key")
            }
        }
        if flags != CGEventFlags() {
            event.flags = flags
        }
        event.post(tap: .cghidEventTap)
    }

    private static func postUnicodeKeyEvent(
        source: CGEventSource,
        character: String,
        keyDown: Bool
    ) throws {
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: keyDown) else {
            throw InputError.eventCreationFailed("failed creating event to enter the text")
        }
        let utf16 = Array(character.utf16)
        event.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
        event.post(tap: .cghidEventTap)
    }

    /// Attempts to post a full Unicode string on a single event. Returns `false` if event creation fails.
    private static func postUnicodeString(source: CGEventSource, text: String, keyDown: Bool) -> Bool {
        guard let event = CGEvent(keyboardEventSource: source, virtualKey: 0, keyDown: keyDown) else {
            return false
        }
        let utf16 = Array(text.utf16)
        event.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
        event.post(tap: .cghidEventTap)
        return true
    }

    /// Posts a media/NX system-defined key event via NSEvent.
    private static func postMediaKeyEvent(nxKeyType: UInt32, keyDown: Bool) throws {
        // data1 encodes: (keyType << 16) | (keyDown ? 0x0A00 : 0x0B00)
        let flags: Int = keyDown ? 0x0A00 : 0x0B00
        let data1 = Int((nxKeyType << 16)) | flags

        guard let event = NSEvent.otherEvent(
            with: .systemDefined,
            location: .zero,
            modifierFlags: NSEvent.ModifierFlags(rawValue: UInt(keyDown ? 0xa00 : 0xb00)),
            timestamp: 0,
            windowNumber: 0,
            context: nil,
            subtype: 8, // NX_SUBTYPE_AUX_CONTROL_BUTTONS
            data1: data1,
            data2: -1
        ) else {
            throw InputError.eventCreationFailed("failed creating event to \(keyDown ? "press" : "release") special key")
        }

        guard let cgEvent = event.cgEvent else {
            throw InputError.eventCreationFailed("failed converting NSEvent to CGEvent for special key")
        }
        cgEvent.post(tap: .cghidEventTap)
    }
}
