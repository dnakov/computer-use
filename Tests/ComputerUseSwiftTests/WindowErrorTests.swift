import XCTest
@testable import ComputerUseSwift

final class WindowErrorTests: XCTestCase {

    func testWindowNotFound() {
        let error = WindowError.windowNotFound
        XCTAssertEqual(error.errorDescription, "Window not found")
    }

    func testInvalidHandleSize() {
        let error = WindowError.invalidHandleSize(expected: 4, actual: 8)
        XCTAssertEqual(
            error.errorDescription,
            "expected parameter 'windowHandle' to be the size of a window handle (4 bytes), got 8 bytes"
        )
    }

    func testInvalidHandleSizeDifferentValues() {
        let error = WindowError.invalidHandleSize(expected: 8, actual: 2)
        XCTAssertEqual(
            error.errorDescription,
            "expected parameter 'windowHandle' to be the size of a window handle (8 bytes), got 2 bytes"
        )
    }

    func testAxElementCreationFailed() {
        let error = WindowError.axElementCreationFailed
        XCTAssertEqual(error.errorDescription, "Failed to create AXUIElementRef")
    }

    func testSystemWideElementFailed() {
        let error = WindowError.systemWideElementFailed
        XCTAssertEqual(error.errorDescription, "Failed to create system wide element")
    }

    func testFocusedWindowFailed() {
        let error = WindowError.focusedWindowFailed("AX error -25204")
        XCTAssertEqual(
            error.errorDescription,
            "Failed to get focused window: AX error -25204"
        )
    }

    func testFocusedWindowIdFailed() {
        let error = WindowError.focusedWindowIdFailed
        XCTAssertEqual(error.errorDescription, "Failed to get focused window id")
    }

    func testAttributeCopyFailed() {
        let error = WindowError.attributeCopyFailed("kAXErrorCannotComplete")
        XCTAssertEqual(
            error.errorDescription,
            "Failed to copy attribute values: kAXErrorCannotComplete"
        )
    }

    func testWindowHandleFailed() {
        let error = WindowError.windowHandleFailed
        XCTAssertEqual(
            error.errorDescription,
            "Could not get accessibility handle for window"
        )
    }
}
