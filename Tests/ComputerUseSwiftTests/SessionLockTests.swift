import XCTest
@testable import ComputerUseSwift

final class SessionLockTests: XCTestCase {

    private let sessionA = "lock-test-session-a"
    private let sessionB = "lock-test-session-b"

    override func setUp() {
        super.setUp()
        SessionLock.forceRelease()
    }

    override func tearDown() {
        SessionLock.forceRelease()
        super.tearDown()
    }

    // MARK: - Acquire / Release cycle

    func testAcquireReturnsNilOnSuccess() {
        let error = SessionLock.acquire(sessionId: sessionA)
        XCTAssertNil(error)
    }

    func testReleaseReturnsTrueWhenHeld() {
        _ = SessionLock.acquire(sessionId: sessionA)
        let released = SessionLock.release(sessionId: sessionA)
        XCTAssertTrue(released)
    }

    func testCheckReturnsLockInfoAfterAcquire() {
        _ = SessionLock.acquire(sessionId: sessionA)
        let info = SessionLock.check()
        XCTAssertNotNil(info)
        XCTAssertEqual(info?.sessionId, sessionA)
        XCTAssertEqual(info?.pid, ProcessInfo.processInfo.processIdentifier)
    }

    func testCheckReturnsNilAfterRelease() {
        _ = SessionLock.acquire(sessionId: sessionA)
        SessionLock.release(sessionId: sessionA)
        let info = SessionLock.check()
        XCTAssertNil(info)
    }

    func testCheckReturnsNilWhenNoLockExists() {
        let info = SessionLock.check()
        XCTAssertNil(info)
    }

    // MARK: - Double-acquire same session

    func testDoubleAcquireSameSessionSucceeds() {
        let first = SessionLock.acquire(sessionId: sessionA)
        XCTAssertNil(first)

        let second = SessionLock.acquire(sessionId: sessionA)
        XCTAssertNil(second, "Re-acquiring with the same session ID should succeed")
    }

    // MARK: - Acquire by different session fails

    func testAcquireByDifferentSessionFails() {
        let first = SessionLock.acquire(sessionId: sessionA)
        XCTAssertNil(first)

        let second = SessionLock.acquire(sessionId: sessionB)
        XCTAssertNotNil(second, "Acquiring with a different session ID should return an error")
        XCTAssertTrue(second!.contains("Another session"))
    }

    // MARK: - Release wrong session

    func testReleaseWrongSessionReturnsFalse() {
        _ = SessionLock.acquire(sessionId: sessionA)
        let released = SessionLock.release(sessionId: sessionB)
        XCTAssertFalse(released)

        // Original lock should still be held
        let info = SessionLock.check()
        XCTAssertEqual(info?.sessionId, sessionA)
    }

    func testReleaseWithNoLockReturnsFalse() {
        let released = SessionLock.release(sessionId: sessionA)
        XCTAssertFalse(released)
    }

    // MARK: - Force release

    func testForceReleaseClearsAnyLock() {
        _ = SessionLock.acquire(sessionId: sessionA)
        SessionLock.forceRelease()
        XCTAssertNil(SessionLock.check())

        // Another session can now acquire
        let error = SessionLock.acquire(sessionId: sessionB)
        XCTAssertNil(error)
    }

    // MARK: - LockInfo encoding

    func testLockInfoCodableRoundTrip() throws {
        let info = SessionLock.LockInfo(
            sessionId: "test",
            acquiredAt: Date(timeIntervalSince1970: 1000),
            pid: 12345
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        let data = try encoder.encode(info)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let decoded = try decoder.decode(SessionLock.LockInfo.self, from: data)
        XCTAssertEqual(decoded.sessionId, info.sessionId)
        XCTAssertEqual(decoded.pid, info.pid)
    }
}
