import XCTest
@testable import ComputerUseSwift

final class AuthErrorTests: XCTestCase {

    func testAlreadyInProgress() {
        let error = AuthError.alreadyInProgress
        XCTAssertEqual(error.errorDescription, "Authentication already in progress")
    }

    func testInvalidURL() {
        let error = AuthError.invalidURL
        XCTAssertEqual(error.errorDescription, "Invalid URL")
    }

    func testFailedToStart() {
        let error = AuthError.failedToStart
        XCTAssertEqual(
            error.errorDescription,
            "Failed to start authentication session"
        )
    }

    func testTimeout() {
        let error = AuthError.timeout
        XCTAssertEqual(error.errorDescription, "Authentication timeout")
    }

    func testCancelled() {
        let error = AuthError.cancelled
        XCTAssertEqual(error.errorDescription, "Authentication cancelled")
    }
}
