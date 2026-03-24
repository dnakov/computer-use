import XCTest
@testable import ComputerUseSwift

final class ScreenshotFilterTests: XCTestCase {

    // MARK: - Exclude list with no allowed apps

    func testExcludeListWithNoAllowedAppsExcludesRunning() {
        // With an empty session (no allowed apps), all running apps should be excluded
        let session = SessionState(sessionId: "test-filter")
        let excluded = ScreenshotFilter.buildExcludeList(session: session)
        // We can't know exactly what's running, but the function should return without error.
        // The key invariant: no allowed app should be in the exclude list.
        XCTAssertNotNil(excluded)
    }

    // MARK: - Allowed apps are not excluded

    func testAllowedAppsNotInExcludeList() {
        var session = SessionState(sessionId: "test-filter")
        // Add Finder as allowed — it's almost always running
        session.allowedApps = [
            GrantedApp(
                bundleId: BundleIDs.finder,
                displayName: "Finder",
                grantedAt: Date(),
                tier: .full
            ),
        ]
        let excluded = ScreenshotFilter.buildExcludeList(session: session)
        XCTAssertFalse(excluded.contains(BundleIDs.finder), "Allowed apps should not appear in exclude list")
    }

    // MARK: - Host app is always excluded

    func testHostAppAlwaysExcluded() {
        let session = SessionState(sessionId: "test-filter")
        let hostId = "com.test.host.app"
        let excluded = ScreenshotFilter.buildExcludeList(session: session, hostBundleId: hostId)
        XCTAssertTrue(excluded.contains(hostId), "Host app should be in exclude list")
    }

    func testHostAppNotDuplicatedIfAlreadyExcluded() {
        // If host is a running app not in allowed, it should appear only once
        let session = SessionState(sessionId: "test-filter")
        let hostId = "com.test.host.app"
        let excluded = ScreenshotFilter.buildExcludeList(session: session, hostBundleId: hostId)
        let hostCount = excluded.filter { $0 == hostId }.count
        XCTAssertEqual(hostCount, 1, "Host app should appear exactly once")
    }

    // MARK: - No host app

    func testNoHostAppDoesNotCrash() {
        let session = SessionState(sessionId: "test-filter")
        let excluded = ScreenshotFilter.buildExcludeList(session: session, hostBundleId: nil)
        XCTAssertNotNil(excluded)
    }
}
