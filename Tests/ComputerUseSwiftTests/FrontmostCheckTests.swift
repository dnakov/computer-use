import XCTest
@testable import ComputerUseSwift

final class FrontmostCheckTests: XCTestCase {

    // MARK: - isActionAllowed: mousePosition (always allowed)

    func testMousePositionAllowedAtReadTier() {
        XCTAssertTrue(FrontmostCheck.isActionAllowed(tier: .read, category: .mousePosition))
    }

    func testMousePositionAllowedAtClickTier() {
        XCTAssertTrue(FrontmostCheck.isActionAllowed(tier: .click, category: .mousePosition))
    }

    func testMousePositionAllowedAtFullTier() {
        XCTAssertTrue(FrontmostCheck.isActionAllowed(tier: .full, category: .mousePosition))
    }

    // MARK: - isActionAllowed: mouse (click/full)

    func testMouseNotAllowedAtReadTier() {
        XCTAssertFalse(FrontmostCheck.isActionAllowed(tier: .read, category: .mouse))
    }

    func testMouseAllowedAtClickTier() {
        XCTAssertTrue(FrontmostCheck.isActionAllowed(tier: .click, category: .mouse))
    }

    func testMouseAllowedAtFullTier() {
        XCTAssertTrue(FrontmostCheck.isActionAllowed(tier: .full, category: .mouse))
    }

    // MARK: - isActionAllowed: mouseFull (full only)

    func testMouseFullNotAllowedAtReadTier() {
        XCTAssertFalse(FrontmostCheck.isActionAllowed(tier: .read, category: .mouseFull))
    }

    func testMouseFullNotAllowedAtClickTier() {
        XCTAssertFalse(FrontmostCheck.isActionAllowed(tier: .click, category: .mouseFull))
    }

    func testMouseFullAllowedAtFullTier() {
        XCTAssertTrue(FrontmostCheck.isActionAllowed(tier: .full, category: .mouseFull))
    }

    // MARK: - isActionAllowed: keyboard (full only)

    func testKeyboardNotAllowedAtReadTier() {
        XCTAssertFalse(FrontmostCheck.isActionAllowed(tier: .read, category: .keyboard))
    }

    func testKeyboardNotAllowedAtClickTier() {
        XCTAssertFalse(FrontmostCheck.isActionAllowed(tier: .click, category: .keyboard))
    }

    func testKeyboardAllowedAtFullTier() {
        XCTAssertTrue(FrontmostCheck.isActionAllowed(tier: .full, category: .keyboard))
    }

    // MARK: - Finder bypass

    func testFinderBundleIdMatchesConstant() {
        // Verify the Finder bundle ID used in FrontmostCheck matches BundleIDs.finder
        XCTAssertEqual(BundleIDs.finder, "com.apple.finder")
    }

    // MARK: - ActionCategory raw values

    func testActionCategoryRawValues() {
        XCTAssertEqual(ActionCategory.mousePosition.rawValue, "mousePosition")
        XCTAssertEqual(ActionCategory.mouse.rawValue, "mouse")
        XCTAssertEqual(ActionCategory.mouseFull.rawValue, "mouseFull")
        XCTAssertEqual(ActionCategory.keyboard.rawValue, "keyboard")
    }

    // MARK: - Tier error messages

    func testReadTierBrowserError() {
        let error = FrontmostCheck.tierErrorMessage(
            displayName: "Safari",
            tier: .read,
            category: .mouse,
            bundleId: "com.apple.Safari",
            isHitTest: false
        )
        XCTAssertTrue(error.contains("tier \"read\""))
        XCTAssertTrue(error.contains("ask the user"))
    }

    func testReadTierNonBrowserError() {
        let error = FrontmostCheck.tierErrorMessage(
            displayName: "Webull",
            tier: .read,
            category: .mouse,
            bundleId: "com.webull.WebullDesktop",
            isHitTest: false
        )
        XCTAssertTrue(error.contains("tier \"read\""))
        XCTAssertTrue(error.contains("ask the user"))
    }

    func testClickTierKeyboardError() {
        let error = FrontmostCheck.tierErrorMessage(
            displayName: "Terminal",
            tier: .click,
            category: .keyboard,
            bundleId: "com.apple.Terminal",
            isHitTest: false
        )
        XCTAssertTrue(error.contains("tier \"click\""))
        XCTAssertTrue(error.contains("typing"))
    }

    func testClickTierMouseFullError() {
        let error = FrontmostCheck.tierErrorMessage(
            displayName: "Terminal",
            tier: .click,
            category: .mouseFull,
            bundleId: "com.apple.Terminal",
            isHitTest: false
        )
        XCTAssertTrue(error.contains("tier \"click\""))
        XCTAssertTrue(error.contains("right-click"))
    }

    func testFullTierErrorIsEmpty() {
        let error = FrontmostCheck.tierErrorMessage(
            displayName: "Notes",
            tier: .full,
            category: .keyboard,
            bundleId: "com.apple.Notes",
            isHitTest: false
        )
        XCTAssertTrue(error.isEmpty)
    }

    // MARK: - Hit test error messages

    func testHitTestReadBrowserError() {
        let error = FrontmostCheck.tierErrorMessage(
            displayName: "Safari",
            tier: .read,
            category: .mouse,
            bundleId: "com.apple.Safari",
            isHitTest: true
        )
        XCTAssertTrue(error.contains("would land on"))
        XCTAssertTrue(error.contains("Ask the user"))
    }

    func testHitTestReadNonBrowserError() {
        let error = FrontmostCheck.tierErrorMessage(
            displayName: "Webull",
            tier: .read,
            category: .mouse,
            bundleId: "com.webull.WebullDesktop",
            isHitTest: true
        )
        XCTAssertTrue(error.contains("would land on"))
        XCTAssertTrue(error.contains("Ask the user"))
    }

    func testHitTestClickTierError() {
        let error = FrontmostCheck.tierErrorMessage(
            displayName: "Terminal",
            tier: .click,
            category: .mouseFull,
            bundleId: "com.apple.Terminal",
            isHitTest: true
        )
        XCTAssertTrue(error.contains("would land on"))
        XCTAssertTrue(error.contains("tier \"click\""))
    }
}
