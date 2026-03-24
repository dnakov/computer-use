import XCTest
@testable import ComputerUseSwift

final class KeyMappingTests: XCTestCase {

    // MARK: - Modifier Keys

    func testAltMapsToOptionKeycode() {
        let result = KeyMapping.virtualKeycode(for: "Alt")
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.keycode, 0x3A)
        XCTAssertTrue(result?.isModifier == true)
    }

    func testOptionIsAliasForAlt() {
        let alt = KeyMapping.virtualKeycode(for: "Alt")
        let option = KeyMapping.virtualKeycode(for: "Option")
        XCTAssertEqual(alt?.keycode, option?.keycode)
    }

    func testROptionMapsToRightOption() {
        let result = KeyMapping.virtualKeycode(for: "ROption")
        XCTAssertEqual(result?.keycode, 0x3D)
        XCTAssertTrue(result?.isModifier == true)
    }

    func testCommandMapsToCorrectKeycode() {
        let result = KeyMapping.virtualKeycode(for: "Command")
        XCTAssertEqual(result?.keycode, 0x37)
        XCTAssertTrue(result?.isModifier == true)
    }

    func testSuperIsAliasForCommand() {
        let cmd = KeyMapping.virtualKeycode(for: "Command")
        let sup = KeyMapping.virtualKeycode(for: "Super")
        XCTAssertEqual(cmd?.keycode, sup?.keycode)
    }

    func testMetaIsAliasForCommand() {
        let cmd = KeyMapping.virtualKeycode(for: "Command")
        let meta = KeyMapping.virtualKeycode(for: "Meta")
        XCTAssertEqual(cmd?.keycode, meta?.keycode)
    }

    func testWindowsIsAliasForCommand() {
        let cmd = KeyMapping.virtualKeycode(for: "Command")
        let win = KeyMapping.virtualKeycode(for: "Windows")
        XCTAssertEqual(cmd?.keycode, win?.keycode)
    }

    func testControlMapsToCorrectKeycode() {
        let result = KeyMapping.virtualKeycode(for: "Control")
        XCTAssertEqual(result?.keycode, 0x3B)
        XCTAssertTrue(result?.isModifier == true)
    }

    func testLControlIsAliasForControl() {
        let ctrl = KeyMapping.virtualKeycode(for: "Control")
        let lctrl = KeyMapping.virtualKeycode(for: "LControl")
        XCTAssertEqual(ctrl?.keycode, lctrl?.keycode)
    }

    func testRControlMapsToRightControl() {
        let result = KeyMapping.virtualKeycode(for: "RControl")
        XCTAssertEqual(result?.keycode, 0x3E)
        XCTAssertTrue(result?.isModifier == true)
    }

    func testShiftMapsToCorrectKeycode() {
        let result = KeyMapping.virtualKeycode(for: "Shift")
        XCTAssertEqual(result?.keycode, 0x38)
        XCTAssertTrue(result?.isModifier == true)
    }

    func testLShiftIsAliasForShift() {
        let shift = KeyMapping.virtualKeycode(for: "Shift")
        let lshift = KeyMapping.virtualKeycode(for: "LShift")
        XCTAssertEqual(shift?.keycode, lshift?.keycode)
    }

    func testRShiftMapsToRightShift() {
        let result = KeyMapping.virtualKeycode(for: "RShift")
        XCTAssertEqual(result?.keycode, 0x3C)
        XCTAssertTrue(result?.isModifier == true)
    }

    func testFunctionKey() {
        let result = KeyMapping.virtualKeycode(for: "Function")
        XCTAssertEqual(result?.keycode, 0x3F)
        XCTAssertTrue(result?.isModifier == true)
    }

    func testCapsLock() {
        let result = KeyMapping.virtualKeycode(for: "CapsLock")
        XCTAssertEqual(result?.keycode, 0x39)
        XCTAssertTrue(result?.isModifier == true)
    }

    // MARK: - Navigation Keys

    func testReturnKey() {
        let result = KeyMapping.virtualKeycode(for: "Return")
        XCTAssertEqual(result?.keycode, 0x24)
        XCTAssertFalse(result?.isModifier == true)
    }

    func testTabKey() {
        let result = KeyMapping.virtualKeycode(for: "Tab")
        XCTAssertEqual(result?.keycode, 0x30)
    }

    func testSpaceKey() {
        let result = KeyMapping.virtualKeycode(for: "Space")
        XCTAssertEqual(result?.keycode, 0x31)
    }

    func testBackspaceKey() {
        let result = KeyMapping.virtualKeycode(for: "Backspace")
        XCTAssertEqual(result?.keycode, 0x33)
    }

    func testDeleteKey() {
        let result = KeyMapping.virtualKeycode(for: "Delete")
        XCTAssertEqual(result?.keycode, 0x75)
    }

    func testEscapeKey() {
        let result = KeyMapping.virtualKeycode(for: "Escape")
        XCTAssertEqual(result?.keycode, 0x35)
    }

    func testArrowKeys() {
        XCTAssertEqual(KeyMapping.virtualKeycode(for: "UpArrow")?.keycode, 0x7E)
        XCTAssertEqual(KeyMapping.virtualKeycode(for: "DownArrow")?.keycode, 0x7D)
        XCTAssertEqual(KeyMapping.virtualKeycode(for: "LeftArrow")?.keycode, 0x7B)
        XCTAssertEqual(KeyMapping.virtualKeycode(for: "RightArrow")?.keycode, 0x7C)
    }

    func testHomeEndPageKeys() {
        XCTAssertEqual(KeyMapping.virtualKeycode(for: "Home")?.keycode, 0x73)
        XCTAssertEqual(KeyMapping.virtualKeycode(for: "End")?.keycode, 0x77)
        XCTAssertEqual(KeyMapping.virtualKeycode(for: "PageUp")?.keycode, 0x74)
        XCTAssertEqual(KeyMapping.virtualKeycode(for: "PageDown")?.keycode, 0x79)
    }

    // MARK: - Function Keys F1-F20

    func testFunctionKeysF1ThroughF20() {
        let expectedKeycodes: [String: UInt16] = [
            "F1": 0x7A, "F2": 0x78, "F3": 0x63, "F4": 0x76,
            "F5": 0x60, "F6": 0x61, "F7": 0x62, "F8": 0x64,
            "F9": 0x65, "F10": 0x6D, "F11": 0x67, "F12": 0x6F,
            "F13": 0x69, "F14": 0x6B, "F15": 0x71, "F16": 0x6A,
            "F17": 0x40, "F18": 0x4F, "F19": 0x50, "F20": 0x5A,
        ]
        for (name, expected) in expectedKeycodes {
            let result = KeyMapping.virtualKeycode(for: name)
            XCTAssertNotNil(result, "F-key \(name) should have a mapping")
            XCTAssertEqual(result?.keycode, expected, "F-key \(name) has wrong keycode")
            XCTAssertFalse(result?.isModifier == true, "F-key \(name) should not be a modifier")
        }
    }

    // MARK: - Numpad Keys

    func testNumpadDigits() {
        for i in 0...9 {
            let result = KeyMapping.virtualKeycode(for: "Numpad\(i)")
            XCTAssertNotNil(result, "Numpad\(i) should have a mapping")
            XCTAssertFalse(result?.isModifier == true)
        }
    }

    func testNumpadOperators() {
        XCTAssertNotNil(KeyMapping.virtualKeycode(for: "Add"))
        XCTAssertNotNil(KeyMapping.virtualKeycode(for: "Subtract"))
        XCTAssertNotNil(KeyMapping.virtualKeycode(for: "Multiply"))
        XCTAssertNotNil(KeyMapping.virtualKeycode(for: "Divide"))
        XCTAssertNotNil(KeyMapping.virtualKeycode(for: "Decimal"))
    }

    // MARK: - isModifierKey

    func testIsModifierKeyForModifiers() {
        let modifiers = [
            "Alt", "Option", "ROption", "Command", "RCommand",
            "Super", "Windows", "Meta", "Control", "LControl",
            "RControl", "Shift", "LShift", "RShift", "Function", "CapsLock",
        ]
        for name in modifiers {
            XCTAssertTrue(KeyMapping.isModifierKey(name), "\(name) should be a modifier")
        }
    }

    func testIsModifierKeyForNonModifiers() {
        let nonModifiers = ["Return", "Tab", "Space", "F1", "a", "Numpad0"]
        for name in nonModifiers {
            XCTAssertFalse(KeyMapping.isModifierKey(name), "\(name) should not be a modifier")
        }
    }

    // MARK: - Unknown Key

    func testUnknownKeyNameReturnsNil() {
        XCTAssertNil(KeyMapping.virtualKeycode(for: "NonExistentKey"))
        XCTAssertNil(KeyMapping.virtualKeycode(for: ""))
        XCTAssertNil(KeyMapping.virtualKeycode(for: "FooBar"))
    }

    // MARK: - Unicode Character Detection

    func testSingleUnicodeCharacterDetection() {
        // Characters not in the named key map should be detected as Unicode
        XCTAssertTrue(KeyMapping.isUnicodeCharacter("€"))
        XCTAssertTrue(KeyMapping.isUnicodeCharacter("ñ"))
        XCTAssertTrue(KeyMapping.isUnicodeCharacter("中"))
    }

    func testMultiCharacterStringIsNotUnicode() {
        XCTAssertFalse(KeyMapping.isUnicodeCharacter("ab"))
        XCTAssertFalse(KeyMapping.isUnicodeCharacter("Return"))
    }

    func testEmptyStringIsNotUnicode() {
        XCTAssertFalse(KeyMapping.isUnicodeCharacter(""))
    }

    func testNamedSingleCharKeysAreNotUnicode() {
        // "a" is in the key map, so it should not be treated as a Unicode character
        XCTAssertFalse(KeyMapping.isUnicodeCharacter("a"))
        XCTAssertFalse(KeyMapping.isUnicodeCharacter("0"))
    }

    // MARK: - Media Key NX Type Mapping

    func testMediaKeyNXTypes() {
        let mediaKeys = [
            "VolumeUp", "VolumeDown", "VolumeMute",
            "BrightnessUp", "BrightnessDown",
            "MediaPlayPause", "MediaNextTrack", "MediaPrevTrack",
            "MediaFast", "MediaRewind",
            "Eject", "Power",
            "IlluminationUp", "IlluminationDown", "IlluminationToggle",
            "LaunchPanel", "Launchpad",
            "MissionControl", "VidMirror",
            "ContrastUp", "ContrastDown",
        ]
        for name in mediaKeys {
            XCTAssertNotNil(
                KeyMapping.nxKeyType(for: name),
                "Media key \(name) should have an NX type mapping"
            )
        }
    }

    func testNonMediaKeyReturnsNilNXType() {
        XCTAssertNil(KeyMapping.nxKeyType(for: "Return"))
        XCTAssertNil(KeyMapping.nxKeyType(for: "Command"))
        XCTAssertNil(KeyMapping.nxKeyType(for: "a"))
    }

    func testVolumeUpNXType() {
        XCTAssertEqual(KeyMapping.nxKeyType(for: "VolumeUp"), 0)
    }

    func testVolumeDownNXType() {
        XCTAssertEqual(KeyMapping.nxKeyType(for: "VolumeDown"), 1)
    }

    func testVolumeMuteNXType() {
        XCTAssertEqual(KeyMapping.nxKeyType(for: "VolumeMute"), 7)
    }

    func testMediaPlayPauseNXType() {
        XCTAssertEqual(KeyMapping.nxKeyType(for: "MediaPlayPause"), 16)
    }

    // MARK: - Left Alias

    func testLeftIsAliasForLeftArrow() {
        let left = KeyMapping.virtualKeycode(for: "Left")
        let leftArrow = KeyMapping.virtualKeycode(for: "LeftArrow")
        XCTAssertEqual(left?.keycode, leftArrow?.keycode)
    }
}
