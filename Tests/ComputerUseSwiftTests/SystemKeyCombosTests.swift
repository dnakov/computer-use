import XCTest
@testable import ComputerUseSwift

final class SystemKeyCombosTests: XCTestCase {

    // MARK: - Blocked combos

    func testMetaQIsSystemCombo() {
        XCTAssertTrue(SystemKeyCombos.isSystemCombo(["meta", "q"]))
    }

    func testAltMetaEscapeIsSystemCombo() {
        XCTAssertTrue(SystemKeyCombos.isSystemCombo(["alt", "meta", "escape"]))
    }

    func testMetaTabIsSystemCombo() {
        XCTAssertTrue(SystemKeyCombos.isSystemCombo(["meta", "tab"]))
    }

    func testCtrlMetaQIsSystemCombo() {
        XCTAssertTrue(SystemKeyCombos.isSystemCombo(["ctrl", "meta", "q"]))
    }

    func testMetaSpaceIsSystemCombo() {
        XCTAssertTrue(SystemKeyCombos.isSystemCombo(["meta", "space"]))
    }

    func testShiftMetaQIsSystemCombo() {
        XCTAssertTrue(SystemKeyCombos.isSystemCombo(["shift", "meta", "q"]))
    }

    // MARK: - Non-blocked combos

    func testMetaCIsNotSystemCombo() {
        XCTAssertFalse(SystemKeyCombos.isSystemCombo(["meta", "c"]))
    }

    func testShiftAIsNotSystemCombo() {
        XCTAssertFalse(SystemKeyCombos.isSystemCombo(["shift", "a"]))
    }

    func testEmptyArrayIsNotSystemCombo() {
        XCTAssertFalse(SystemKeyCombos.isSystemCombo([]))
    }

    func testSingleKeyIsNotSystemCombo() {
        XCTAssertFalse(SystemKeyCombos.isSystemCombo(["q"]))
    }

    // MARK: - Normalization

    func testCommandQNormalizesToMetaQ() {
        XCTAssertTrue(SystemKeyCombos.isSystemCombo(["command", "q"]))
    }

    func testCmdQNormalizesToMetaQ() {
        XCTAssertTrue(SystemKeyCombos.isSystemCombo(["cmd", "q"]))
    }

    func testSuperQNormalizesToMetaQ() {
        XCTAssertTrue(SystemKeyCombos.isSystemCombo(["super", "q"]))
    }

    func testWindowsQNormalizesToMetaQ() {
        XCTAssertTrue(SystemKeyCombos.isSystemCombo(["windows", "q"]))
    }

    func testControlNormalizesToCtrl() {
        XCTAssertTrue(SystemKeyCombos.isSystemCombo(["control", "meta", "q"]))
    }

    func testOptionNormalizesToAlt() {
        XCTAssertTrue(SystemKeyCombos.isSystemCombo(["option", "meta", "escape"]))
    }

    func testCaseInsensitiveNormalization() {
        XCTAssertTrue(SystemKeyCombos.isSystemCombo(["Meta", "Q"]))
        XCTAssertTrue(SystemKeyCombos.isSystemCombo(["META", "Q"]))
        XCTAssertTrue(SystemKeyCombos.isSystemCombo(["Command", "Q"]))
    }
}
