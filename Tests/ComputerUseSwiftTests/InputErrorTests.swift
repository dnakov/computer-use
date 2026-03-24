import XCTest
@testable import ComputerUseSwift

final class InputErrorTests: XCTestCase {

    func testInvalidKeyName() {
        let error = InputError.invalidKeyName("foo")
        XCTAssertEqual(
            error.errorDescription,
            "Invalid key name: foo. Please use a valid key name."
        )
    }

    func testInvalidKeyNameDifferentValue() {
        let error = InputError.invalidKeyName("XYZ123")
        XCTAssertEqual(
            error.errorDescription,
            "Invalid key name: XYZ123. Please use a valid key name."
        )
    }

    func testInvalidAction() {
        let error = InputError.invalidAction("baz")
        XCTAssertEqual(
            error.errorDescription,
            "Invalid action: baz. Valid options are: press, release, click"
        )
    }

    func testInvalidActionDifferentValue() {
        let error = InputError.invalidAction("hold")
        XCTAssertEqual(
            error.errorDescription,
            "Invalid action: hold. Valid options are: press, release, click"
        )
    }

    func testInvalidButton() {
        let error = InputError.invalidButton("x")
        XCTAssertEqual(
            error.errorDescription,
            "Invalid button name: x. Valid options are: left, right, middle, scrollUp, scrollDown, scrollLeft, scrollRight"
        )
    }

    func testInvalidButtonDifferentValue() {
        let error = InputError.invalidButton("extra")
        XCTAssertEqual(
            error.errorDescription,
            "Invalid button name: extra. Valid options are: left, right, middle, scrollUp, scrollDown, scrollLeft, scrollRight"
        )
    }

    func testInvalidAxis() {
        let error = InputError.invalidAxis("z")
        XCTAssertEqual(
            error.errorDescription,
            "Invalid axis: z. Valid options are: horizontal, vertical"
        )
    }

    func testInvalidAxisDifferentValue() {
        let error = InputError.invalidAxis("diagonal")
        XCTAssertEqual(
            error.errorDescription,
            "Invalid axis: diagonal. Valid options are: horizontal, vertical"
        )
    }

    func testNoKeysProvided() {
        let error = InputError.noKeysProvided
        XCTAssertEqual(error.errorDescription, "No keys provided")
    }

    func testEmptyText() {
        let error = InputError.emptyText
        XCTAssertEqual(error.errorDescription, "The text to enter was empty")
    }

    func testEventCreationFailed() {
        let error = InputError.eventCreationFailed("CGEvent returned nil")
        XCTAssertEqual(
            error.errorDescription,
            "Error performing key action: CGEvent returned nil"
        )
    }

    func testKeyActionFailed() {
        let error = InputError.keyActionFailed("post failed")
        XCTAssertEqual(
            error.errorDescription,
            "Error performing key action: post failed"
        )
    }

    func testMouseMoveFailed() {
        let error = InputError.mouseMoveFailed("event creation failed")
        XCTAssertEqual(
            error.errorDescription,
            "Error moving mouse: event creation failed"
        )
    }

    func testButtonActionFailed() {
        let error = InputError.buttonActionFailed("CGEvent nil", 3)
        XCTAssertEqual(
            error.errorDescription,
            "Error performing button action on attempt 3: CGEvent nil"
        )
    }

    func testScrollFailed() {
        let error = InputError.scrollFailed("scroll event creation failed")
        XCTAssertEqual(
            error.errorDescription,
            "Error performing scroll action: scroll event creation failed"
        )
    }

    func testMouseLocationFailed() {
        let error = InputError.mouseLocationFailed("unable to read")
        XCTAssertEqual(
            error.errorDescription,
            "Error getting mouse location: unable to read"
        )
    }
}
