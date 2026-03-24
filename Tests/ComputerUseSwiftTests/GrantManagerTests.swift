import XCTest
@testable import ComputerUseSwift

final class GrantManagerTests: XCTestCase {

    // MARK: - Test data

    private let installedApps: [InstalledApp] = [
        InstalledApp(bundleId: "com.apple.Safari", displayName: "Safari", path: "/Applications/Safari.app"),
        InstalledApp(bundleId: "com.apple.Terminal", displayName: "Terminal", path: "/Applications/Utilities/Terminal.app"),
        InstalledApp(bundleId: "com.apple.Notes", displayName: "Notes", path: "/Applications/Notes.app"),
        InstalledApp(bundleId: "com.spotify.client", displayName: "Spotify", path: "/Applications/Spotify.app"),
        InstalledApp(bundleId: "com.microsoft.VSCode", displayName: "Visual Studio Code", path: "/Applications/Visual Studio Code.app"),
    ]

    // MARK: - App resolution by bundle ID

    func testResolveBySafariByBundleId() {
        let request = GrantManager.GrantRequest(apps: ["com.apple.Safari"], reason: "test")
        let result = GrantManager.resolve(request: request, installedApps: installedApps)
        XCTAssertEqual(result.granted.count, 1)
        XCTAssertEqual(result.granted.first?.bundleId, "com.apple.Safari")
    }

    func testResolveByBundleIdTerminal() {
        let request = GrantManager.GrantRequest(apps: ["com.apple.Terminal"], reason: "test")
        let result = GrantManager.resolve(request: request, installedApps: installedApps)
        XCTAssertEqual(result.granted.count, 1)
        XCTAssertEqual(result.granted.first?.bundleId, "com.apple.Terminal")
    }

    // MARK: - App resolution by display name (case-insensitive)

    func testResolveByDisplayNameExact() {
        let request = GrantManager.GrantRequest(apps: ["Notes"], reason: "test")
        let result = GrantManager.resolve(request: request, installedApps: installedApps)
        XCTAssertEqual(result.granted.count, 1)
        XCTAssertEqual(result.granted.first?.bundleId, "com.apple.Notes")
    }

    func testResolveByDisplayNameCaseInsensitive() {
        let request = GrantManager.GrantRequest(apps: ["notes"], reason: "test")
        let result = GrantManager.resolve(request: request, installedApps: installedApps)
        XCTAssertEqual(result.granted.count, 1)
        XCTAssertEqual(result.granted.first?.bundleId, "com.apple.Notes")
    }

    func testResolveByDisplayNameUppercase() {
        let request = GrantManager.GrantRequest(apps: ["SAFARI"], reason: "test")
        let result = GrantManager.resolve(request: request, installedApps: installedApps)
        XCTAssertEqual(result.granted.count, 1)
        XCTAssertEqual(result.granted.first?.bundleId, "com.apple.Safari")
    }

    // MARK: - Not installed

    func testResolveUnknownAppIsDenied() {
        let request = GrantManager.GrantRequest(apps: ["com.unknown.app"], reason: "test")
        let result = GrantManager.resolve(request: request, installedApps: installedApps)
        XCTAssertTrue(result.granted.isEmpty)
        XCTAssertEqual(result.denied.count, 1)
        XCTAssertEqual(result.denied.first?.reason, "not_installed")
    }

    // MARK: - Policy-blocked filtering

    func testPolicyBlockedAppIsDenied() {
        let request = GrantManager.GrantRequest(apps: ["Spotify"], reason: "test")
        let result = GrantManager.resolve(request: request, installedApps: installedApps)
        XCTAssertTrue(result.granted.isEmpty)
        XCTAssertEqual(result.policyDenied.count, 1)
        XCTAssertTrue(result.policyDenied.first!.reason.contains("blocked by policy"))
    }

    func testPolicyBlockedByBundleId() {
        let request = GrantManager.GrantRequest(apps: ["com.spotify.client"], reason: "test")
        let result = GrantManager.resolve(request: request, installedApps: installedApps)
        XCTAssertTrue(result.granted.isEmpty)
        XCTAssertEqual(result.policyDenied.count, 1)
    }

    // MARK: - User denied

    func testUserDeniedAppIsDenied() {
        let request = GrantManager.GrantRequest(apps: ["Notes"], reason: "test")
        let result = GrantManager.resolve(
            request: request,
            installedApps: installedApps,
            userDeniedBundleIds: ["com.apple.Notes"]
        )
        XCTAssertTrue(result.granted.isEmpty)
        XCTAssertEqual(result.denied.count, 1)
        XCTAssertEqual(result.denied.first?.reason, "user_denied")
    }

    // MARK: - Tier assignment

    func testSafariAssignedReadTier() {
        let request = GrantManager.GrantRequest(apps: ["Safari"], reason: "test")
        let result = GrantManager.resolve(request: request, installedApps: installedApps)
        XCTAssertEqual(result.granted.first?.tier, .read)
    }

    func testTerminalAssignedClickTier() {
        let request = GrantManager.GrantRequest(apps: ["Terminal"], reason: "test")
        let result = GrantManager.resolve(request: request, installedApps: installedApps)
        XCTAssertEqual(result.granted.first?.tier, .click)
    }

    func testVSCodeAssignedClickTier() {
        let request = GrantManager.GrantRequest(apps: ["Visual Studio Code"], reason: "test")
        let result = GrantManager.resolve(request: request, installedApps: installedApps)
        XCTAssertEqual(result.granted.first?.tier, .click)
    }

    func testNotesAssignedFullTier() {
        let request = GrantManager.GrantRequest(apps: ["Notes"], reason: "test")
        let result = GrantManager.resolve(request: request, installedApps: installedApps)
        XCTAssertEqual(result.granted.first?.tier, .full)
    }

    // MARK: - Merge

    func testMergeAddsNewApps() {
        let existing = [
            GrantedApp(bundleId: "com.apple.Notes", displayName: "Notes", grantedAt: Date(), tier: .full),
        ]
        let newResult = GrantManager.GrantResult(
            granted: [
                GrantedApp(bundleId: "com.apple.Safari", displayName: "Safari", grantedAt: Date(), tier: .read),
            ],
            denied: [],
            policyDenied: [],
            tierGuidance: nil
        )

        let merged = GrantManager.merge(
            existing: existing,
            existingFlags: GrantFlags(),
            result: newResult,
            requestedFlags: GrantFlags()
        )

        XCTAssertEqual(merged.apps.count, 2)
        XCTAssertEqual(merged.apps[0].bundleId, "com.apple.Notes")
        XCTAssertEqual(merged.apps[1].bundleId, "com.apple.Safari")
    }

    func testMergePreservesExistingApps() {
        let existing = [
            GrantedApp(bundleId: "com.apple.Notes", displayName: "Notes", grantedAt: Date(), tier: .full),
        ]
        let newResult = GrantManager.GrantResult(
            granted: [
                GrantedApp(bundleId: "com.apple.Notes", displayName: "Notes", grantedAt: Date(), tier: .full),
            ],
            denied: [],
            policyDenied: [],
            tierGuidance: nil
        )

        let merged = GrantManager.merge(
            existing: existing,
            existingFlags: GrantFlags(),
            result: newResult,
            requestedFlags: GrantFlags()
        )

        XCTAssertEqual(merged.apps.count, 1, "Duplicate apps should not be added")
    }

    func testMergeFlagsOnceTrue() {
        let merged = GrantManager.merge(
            existing: [],
            existingFlags: GrantFlags(clipboardRead: true, clipboardWrite: false, systemKeyCombos: false),
            result: GrantManager.GrantResult(granted: [], denied: [], policyDenied: [], tierGuidance: nil),
            requestedFlags: GrantFlags(clipboardRead: false, clipboardWrite: true, systemKeyCombos: false)
        )

        XCTAssertTrue(merged.flags.clipboardRead, "Existing true should stay true")
        XCTAssertTrue(merged.flags.clipboardWrite, "Requested true should become true")
        XCTAssertFalse(merged.flags.systemKeyCombos, "Both false should stay false")
    }

    // MARK: - Prune (TTL)

    func testPruneRemovesExpiredGrants() {
        let now = Date()
        let apps = [
            GrantedApp(bundleId: "com.old", displayName: "Old", grantedAt: now.addingTimeInterval(-2000), tier: .full),
            GrantedApp(bundleId: "com.fresh", displayName: "Fresh", grantedAt: now.addingTimeInterval(-100), tier: .full),
        ]

        let pruned = GrantManager.prune(apps: apps, now: now, ttl: 1800)
        XCTAssertEqual(pruned.count, 1)
        XCTAssertEqual(pruned.first?.bundleId, "com.fresh")
    }

    func testPruneKeepsAllFreshGrants() {
        let now = Date()
        let apps = [
            GrantedApp(bundleId: "com.a", displayName: "A", grantedAt: now.addingTimeInterval(-100), tier: .full),
            GrantedApp(bundleId: "com.b", displayName: "B", grantedAt: now.addingTimeInterval(-200), tier: .read),
        ]

        let pruned = GrantManager.prune(apps: apps, now: now, ttl: 1800)
        XCTAssertEqual(pruned.count, 2)
    }

    func testPruneRemovesAllExpired() {
        let now = Date()
        let apps = [
            GrantedApp(bundleId: "com.old1", displayName: "Old1", grantedAt: now.addingTimeInterval(-3600), tier: .full),
            GrantedApp(bundleId: "com.old2", displayName: "Old2", grantedAt: now.addingTimeInterval(-7200), tier: .read),
        ]

        let pruned = GrantManager.prune(apps: apps, now: now, ttl: 1800)
        XCTAssertTrue(pruned.isEmpty)
    }

    // MARK: - Tier guidance messages

    func testTierGuidanceForReadBrowser() {
        let apps = [
            GrantedApp(bundleId: "com.apple.Safari", displayName: "Safari", grantedAt: Date(), tier: .read),
        ]
        let guidance = GrantManager.tierGuidance(for: apps)
        XCTAssertNotNil(guidance)
        XCTAssertTrue(guidance!.contains("Safari"))
        XCTAssertTrue(guidance!.contains("tier \"read\""))
        XCTAssertTrue(guidance!.contains("Browser Extension MCP"))
    }

    func testTierGuidanceForReadNonBrowser() {
        let apps = [
            GrantedApp(bundleId: "com.webull.WebullDesktop", displayName: "Webull", grantedAt: Date(), tier: .read),
        ]
        let guidance = GrantManager.tierGuidance(for: apps)
        XCTAssertNotNil(guidance)
        XCTAssertTrue(guidance!.contains("Webull"))
        XCTAssertTrue(guidance!.contains("Ask the user"))
    }

    func testTierGuidanceForClickTier() {
        let apps = [
            GrantedApp(bundleId: "com.apple.Terminal", displayName: "Terminal", grantedAt: Date(), tier: .click),
        ]
        let guidance = GrantManager.tierGuidance(for: apps)
        XCTAssertNotNil(guidance)
        XCTAssertTrue(guidance!.contains("Terminal"))
        XCTAssertTrue(guidance!.contains("tier \"click\""))
        XCTAssertTrue(guidance!.contains("NO typing"))
    }

    func testTierGuidanceNilForFullOnly() {
        let apps = [
            GrantedApp(bundleId: "com.apple.Notes", displayName: "Notes", grantedAt: Date(), tier: .full),
        ]
        let guidance = GrantManager.tierGuidance(for: apps)
        XCTAssertNil(guidance, "Full tier apps should not produce guidance")
    }

    func testTierGuidanceNilForEmptyApps() {
        let guidance = GrantManager.tierGuidance(for: [])
        XCTAssertNil(guidance)
    }

    func testMultipleAppsGuidance() {
        let apps = [
            GrantedApp(bundleId: "com.apple.Safari", displayName: "Safari", grantedAt: Date(), tier: .read),
            GrantedApp(bundleId: "com.apple.Terminal", displayName: "Terminal", grantedAt: Date(), tier: .click),
            GrantedApp(bundleId: "com.apple.Notes", displayName: "Notes", grantedAt: Date(), tier: .full),
        ]
        let guidance = GrantManager.tierGuidance(for: apps)
        XCTAssertNotNil(guidance)
        XCTAssertTrue(guidance!.contains("Safari"))
        XCTAssertTrue(guidance!.contains("Terminal"))
        XCTAssertFalse(guidance!.contains("Notes"), "Full tier should not appear in guidance")
    }
}
