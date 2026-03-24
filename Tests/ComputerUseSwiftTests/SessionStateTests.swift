import XCTest
@testable import ComputerUseSwift

final class SessionStateTests: XCTestCase {

    private let testSessionId = "test-session-\(UUID().uuidString)"

    override func tearDown() {
        try? SessionState.delete(sessionId: testSessionId)
        super.tearDown()
    }

    // MARK: - Creation

    func testInitSetsSessionId() {
        let state = SessionState(sessionId: testSessionId)
        XCTAssertEqual(state.sessionId, testSessionId)
    }

    func testInitSetsDefaults() {
        let state = SessionState(sessionId: testSessionId)
        XCTAssertTrue(state.allowedApps.isEmpty)
        XCTAssertEqual(state.grantFlags, GrantFlags())
        XCTAssertNil(state.lastScreenshot)
        XCTAssertNil(state.selectedDisplayId)
        XCTAssertTrue(state.hiddenDuringTurn.isEmpty)
        XCTAssertNil(state.clipboardStash)
        XCTAssertFalse(state.mouseHeld)
        XCTAssertFalse(state.mouseDragged)
        XCTAssertNil(state.lockAcquiredAt)
    }

    func testCreatedAtIsSet() {
        let before = Date()
        let state = SessionState(sessionId: testSessionId)
        let after = Date()
        XCTAssertGreaterThanOrEqual(state.createdAt, before)
        XCTAssertLessThanOrEqual(state.createdAt, after)
    }

    // MARK: - Save / Load round-trip

    func testSaveAndLoadRoundTrip() throws {
        var state = SessionState(sessionId: testSessionId)
        state.allowedApps = [
            GrantedApp(
                bundleId: "com.apple.Safari",
                displayName: "Safari",
                grantedAt: Date(timeIntervalSince1970: 1000),
                tier: .read
            ),
        ]
        state.grantFlags = GrantFlags(clipboardRead: true, clipboardWrite: false, systemKeyCombos: true)
        state.lastScreenshot = ScreenshotDims(
            width: 1024, height: 768,
            displayWidth: 2048, displayHeight: 1536,
            displayId: 1, originX: 0, originY: 0
        )
        state.selectedDisplayId = 1
        state.hiddenDuringTurn = ["com.apple.Notes"]
        state.clipboardStash = "stashed text"
        state.mouseHeld = true
        state.mouseDragged = true

        try state.save()
        let loaded = try SessionState.load(sessionId: testSessionId)

        XCTAssertEqual(loaded.sessionId, state.sessionId)
        XCTAssertEqual(loaded.allowedApps.count, 1)
        XCTAssertEqual(loaded.allowedApps.first?.bundleId, "com.apple.Safari")
        XCTAssertEqual(loaded.allowedApps.first?.tier, .read)
        XCTAssertEqual(loaded.grantFlags, state.grantFlags)
        XCTAssertEqual(loaded.lastScreenshot, state.lastScreenshot)
        XCTAssertEqual(loaded.selectedDisplayId, 1)
        XCTAssertEqual(loaded.hiddenDuringTurn, ["com.apple.Notes"])
        XCTAssertEqual(loaded.clipboardStash, "stashed text")
        XCTAssertTrue(loaded.mouseHeld)
        XCTAssertTrue(loaded.mouseDragged)
    }

    func testLoadNonexistentSessionThrows() {
        XCTAssertThrowsError(try SessionState.load(sessionId: "nonexistent-\(UUID().uuidString)"))
    }

    func testDeleteRemovesFile() throws {
        let state = SessionState(sessionId: testSessionId)
        try state.save()
        XCTAssertTrue(SessionState.exists(sessionId: testSessionId))

        try SessionState.delete(sessionId: testSessionId)
        XCTAssertFalse(SessionState.exists(sessionId: testSessionId))
    }

    func testDeleteNonexistentDoesNotThrow() {
        XCTAssertNoThrow(try SessionState.delete(sessionId: "nonexistent-\(UUID().uuidString)"))
    }

    func testExistsReturnsFalseForMissingSession() {
        XCTAssertFalse(SessionState.exists(sessionId: "nonexistent-\(UUID().uuidString)"))
    }

    // MARK: - Mouse state reset

    func testResetMouseState() {
        var state = SessionState(sessionId: testSessionId)
        state.mouseHeld = true
        state.mouseDragged = true
        state.resetMouseState()
        XCTAssertFalse(state.mouseHeld)
        XCTAssertFalse(state.mouseDragged)
    }

    // MARK: - Codable encoding of supporting types

    func testGrantedAppCodableRoundTrip() throws {
        let app = GrantedApp(
            bundleId: "com.apple.Notes",
            displayName: "Notes",
            grantedAt: Date(timeIntervalSince1970: 5000),
            tier: .full
        )
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        let data = try encoder.encode(app)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        let decoded = try decoder.decode(GrantedApp.self, from: data)
        XCTAssertEqual(decoded, app)
    }

    func testGrantFlagsCodableRoundTrip() throws {
        let flags = GrantFlags(clipboardRead: true, clipboardWrite: true, systemKeyCombos: false)
        let data = try JSONEncoder().encode(flags)
        let decoded = try JSONDecoder().decode(GrantFlags.self, from: data)
        XCTAssertEqual(decoded, flags)
    }

    func testGrantFlagsDefaultsAllFalse() {
        let flags = GrantFlags()
        XCTAssertFalse(flags.clipboardRead)
        XCTAssertFalse(flags.clipboardWrite)
        XCTAssertFalse(flags.systemKeyCombos)
    }

    func testScreenshotDimsCodableRoundTrip() throws {
        let dims = ScreenshotDims(
            width: 800, height: 600,
            displayWidth: 1600, displayHeight: 1200,
            displayId: 2, originX: 100, originY: 50
        )
        let data = try JSONEncoder().encode(dims)
        let decoded = try JSONDecoder().decode(ScreenshotDims.self, from: data)
        XCTAssertEqual(decoded, dims)
    }

    func testScreenshotDimsDefaultOriginAndDisplayId() {
        let dims = ScreenshotDims(width: 100, height: 100, displayWidth: 200, displayHeight: 200)
        XCTAssertEqual(dims.displayId, 0)
        XCTAssertEqual(dims.originX, 0)
        XCTAssertEqual(dims.originY, 0)
    }

    func testAppTierRawValues() {
        XCTAssertEqual(AppTier.read.rawValue, "read")
        XCTAssertEqual(AppTier.click.rawValue, "click")
        XCTAssertEqual(AppTier.full.rawValue, "full")
    }
}
