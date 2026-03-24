import XCTest
@testable import ComputerUseSwift

final class AppClassificationTests: XCTestCase {

    // MARK: - classify() by bundle ID

    func testSafariClassifiedAsBrowser() {
        let result = AppClassification.classify(bundleId: "com.apple.Safari", displayName: nil)
        XCTAssertEqual(result, .browser)
    }

    func testChromeClassifiedAsBrowser() {
        let result = AppClassification.classify(bundleId: "com.google.Chrome", displayName: nil)
        XCTAssertEqual(result, .browser)
    }

    func testTerminalClassifiedAsTerminal() {
        let result = AppClassification.classify(bundleId: "com.apple.Terminal", displayName: nil)
        XCTAssertEqual(result, .terminal)
    }

    func testVSCodeClassifiedAsTerminal() {
        let result = AppClassification.classify(bundleId: "com.microsoft.VSCode", displayName: nil)
        XCTAssertEqual(result, .terminal)
    }

    func testJetBrainsIntelliJClassifiedAsTerminal() {
        let result = AppClassification.classify(bundleId: "com.jetbrains.intellij", displayName: nil)
        XCTAssertEqual(result, .terminal)
    }

    func testJetBrainsPyCharmClassifiedAsTerminal() {
        let result = AppClassification.classify(bundleId: "com.jetbrains.pycharm", displayName: nil)
        XCTAssertEqual(result, .terminal)
    }

    func testJetBrainsWebStormClassifiedAsTerminal() {
        let result = AppClassification.classify(bundleId: "com.jetbrains.WebStorm", displayName: nil)
        XCTAssertEqual(result, .terminal)
    }

    func testWebullClassifiedAsTrading() {
        let result = AppClassification.classify(bundleId: "com.webull.WebullDesktop", displayName: nil)
        XCTAssertEqual(result, .trading)
    }

    func testNotesReturnsNil() {
        let result = AppClassification.classify(bundleId: "com.apple.Notes", displayName: "Notes")
        XCTAssertNil(result)
    }

    func testUnknownAppReturnsNil() {
        let result = AppClassification.classify(bundleId: "com.unknown.app", displayName: "Unknown App")
        XCTAssertNil(result)
    }

    // MARK: - classify() by display name fallback

    func testFirefoxDisplayNameFallbackClassifiedAsBrowser() {
        let result = AppClassification.classify(bundleId: nil, displayName: "Firefox")
        XCTAssertEqual(result, .browser)
    }

    func testTerminalDisplayNameFallbackClassifiedAsTerminal() {
        let result = AppClassification.classify(bundleId: nil, displayName: "Terminal")
        XCTAssertEqual(result, .terminal)
    }

    func testWebullDisplayNameFallbackClassifiedAsTrading() {
        let result = AppClassification.classify(bundleId: nil, displayName: "Webull")
        XCTAssertEqual(result, .trading)
    }

    func testNilBundleIdAndNilDisplayNameReturnsNil() {
        let result = AppClassification.classify(bundleId: nil, displayName: nil)
        XCTAssertNil(result)
    }

    // MARK: - tier()

    func testBrowserTierIsFull() {
        let tier = AppClassification.tier(bundleId: "com.apple.Safari", displayName: nil)
        XCTAssertEqual(tier, .full)
    }

    func testTradingTierIsRead() {
        let tier = AppClassification.tier(bundleId: "com.webull.WebullDesktop", displayName: nil)
        XCTAssertEqual(tier, .read)
    }

    func testTerminalTierIsClick() {
        let tier = AppClassification.tier(bundleId: "com.apple.Terminal", displayName: nil)
        XCTAssertEqual(tier, .click)
    }

    func testVSCodeTierIsClick() {
        let tier = AppClassification.tier(bundleId: "com.microsoft.VSCode", displayName: nil)
        XCTAssertEqual(tier, .click)
    }

    func testUnknownAppTierIsFull() {
        let tier = AppClassification.tier(bundleId: "com.apple.Notes", displayName: "Notes")
        XCTAssertEqual(tier, .full)
    }

    func testNilBundleIdTierIsFull() {
        let tier = AppClassification.tier(bundleId: nil, displayName: nil)
        XCTAssertEqual(tier, .full)
    }

    // MARK: - PolicyBlockedApps

    func testSpotifyIsBlocked() {
        XCTAssertTrue(PolicyBlockedApps.isBlocked(bundleId: "com.spotify.client", displayName: nil))
    }

    func testNetflixBlockedByDisplayName() {
        XCTAssertTrue(PolicyBlockedApps.isBlocked(bundleId: nil, displayName: "Netflix"))
    }

    func testNotesIsNotBlocked() {
        XCTAssertFalse(PolicyBlockedApps.isBlocked(bundleId: "com.apple.Notes", displayName: "Notes"))
    }

    func testSafariIsNotBlocked() {
        XCTAssertFalse(PolicyBlockedApps.isBlocked(bundleId: "com.apple.Safari", displayName: "Safari"))
    }

    func testNilBundleIdAndNilDisplayNameNotBlocked() {
        XCTAssertFalse(PolicyBlockedApps.isBlocked(bundleId: nil, displayName: nil))
    }

    func testAppleTVIsBlocked() {
        XCTAssertTrue(PolicyBlockedApps.isBlocked(bundleId: "com.apple.TV", displayName: nil))
    }

    func testKindleIsBlocked() {
        XCTAssertTrue(PolicyBlockedApps.isBlocked(bundleId: "com.amazon.Kindle", displayName: nil))
    }
}
