import XCTest
@testable import ComputerUseSwift

final class ConstantsTests: XCTestCase {

    // MARK: - SystemApps.defocusSystemApps

    func testDefocusSystemAppsCount() {
        XCTAssertEqual(SystemApps.defocusSystemApps.count, 8)
    }

    func testDefocusSystemAppsContainsAllEntries() {
        let expected: Set<String> = [
            "Window Server",
            "SystemUIServer",
            "Dock",
            "Spotlight",
            "Control Center",
            "com.apple.screencaptureui",
            "Screenshot",
            "screencaptureui",
        ]
        XCTAssertEqual(SystemApps.defocusSystemApps, expected)
    }

    func testDefocusSystemAppsContainsWindowServer() {
        XCTAssertTrue(SystemApps.defocusSystemApps.contains("Window Server"))
    }

    func testDefocusSystemAppsContainsSystemUIServer() {
        XCTAssertTrue(SystemApps.defocusSystemApps.contains("SystemUIServer"))
    }

    func testDefocusSystemAppsContainsDock() {
        XCTAssertTrue(SystemApps.defocusSystemApps.contains("Dock"))
    }

    func testDefocusSystemAppsContainsSpotlight() {
        XCTAssertTrue(SystemApps.defocusSystemApps.contains("Spotlight"))
    }

    func testDefocusSystemAppsContainsControlCenter() {
        XCTAssertTrue(SystemApps.defocusSystemApps.contains("Control Center"))
    }

    func testDefocusSystemAppsContainsScreencaptureUIBundleId() {
        XCTAssertTrue(SystemApps.defocusSystemApps.contains("com.apple.screencaptureui"))
    }

    func testDefocusSystemAppsContainsScreenshot() {
        XCTAssertTrue(SystemApps.defocusSystemApps.contains("Screenshot"))
    }

    func testDefocusSystemAppsContainsScreencaptureui() {
        XCTAssertTrue(SystemApps.defocusSystemApps.contains("screencaptureui"))
    }

    // MARK: - SystemApps.hitTestSkipBundleIds

    func testHitTestSkipBundleIdsCount() {
        XCTAssertEqual(SystemApps.hitTestSkipBundleIds.count, 1)
    }

    func testHitTestSkipBundleIdsContainsScreencaptureUI() {
        XCTAssertTrue(SystemApps.hitTestSkipBundleIds.contains("com.apple.screencaptureui"))
    }

    // MARK: - ImageConstants

    func testTileSize() {
        XCTAssertEqual(ImageConstants.tileSize, 28)
    }

    func testMaxTokenCount() {
        XCTAssertEqual(ImageConstants.maxTokenCount, 1568)
    }

    // MARK: - BundleIDs

    func testFinderBundleId() {
        XCTAssertEqual(BundleIDs.finder, "com.apple.finder")
    }

    func testApplicationBundleUTI() {
        XCTAssertEqual(BundleIDs.applicationBundleUTI, "com.apple.application-bundle")
    }

    func testScreencaptureUIBundleId() {
        XCTAssertEqual(BundleIDs.screencaptureUI, "com.apple.screencaptureui")
    }
}
