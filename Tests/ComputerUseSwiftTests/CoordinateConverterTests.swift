import XCTest
@testable import ComputerUseSwift

final class CoordinateConverterTests: XCTestCase {

    // MARK: - imagePixelsToScreen

    func testImagePixelToScreenIdentity() {
        // Screenshot size == display size, no origin offset
        let pt = CoordinateConverter.imagePixelsToScreen(
            pixelX: 100, pixelY: 200,
            screenshotWidth: 1920, screenshotHeight: 1080,
            displayWidth: 1920, displayHeight: 1080,
            originX: 0, originY: 0
        )
        XCTAssertEqual(pt.x, 100)
        XCTAssertEqual(pt.y, 200)
    }

    func testImagePixelToScreenWithScaling() {
        // Screenshot is half the display size
        let pt = CoordinateConverter.imagePixelsToScreen(
            pixelX: 100, pixelY: 50,
            screenshotWidth: 960, screenshotHeight: 540,
            displayWidth: 1920, displayHeight: 1080,
            originX: 0, originY: 0
        )
        XCTAssertEqual(pt.x, 200)
        XCTAssertEqual(pt.y, 100)
    }

    func testImagePixelToScreenWithOriginOffset() {
        let pt = CoordinateConverter.imagePixelsToScreen(
            pixelX: 100, pixelY: 200,
            screenshotWidth: 1920, screenshotHeight: 1080,
            displayWidth: 1920, displayHeight: 1080,
            originX: 500, originY: 300
        )
        XCTAssertEqual(pt.x, 600)
        XCTAssertEqual(pt.y, 500)
    }

    func testImagePixelToScreenZeroZero() {
        let pt = CoordinateConverter.imagePixelsToScreen(
            pixelX: 0, pixelY: 0,
            screenshotWidth: 1920, screenshotHeight: 1080,
            displayWidth: 1920, displayHeight: 1080,
            originX: 0, originY: 0
        )
        XCTAssertEqual(pt.x, 0)
        XCTAssertEqual(pt.y, 0)
    }

    func testImagePixelToScreenMaxCoordinates() {
        // Pixel at edge of screenshot
        let pt = CoordinateConverter.imagePixelsToScreen(
            pixelX: 1920, pixelY: 1080,
            screenshotWidth: 1920, screenshotHeight: 1080,
            displayWidth: 1920, displayHeight: 1080,
            originX: 0, originY: 0
        )
        XCTAssertEqual(pt.x, 1920)
        XCTAssertEqual(pt.y, 1080)
    }

    // MARK: - normalizedToScreen

    func testNormalizedToScreenCenter() {
        // 50, 50 should be the center of the display
        let pt = CoordinateConverter.normalizedToScreen(
            normX: 50, normY: 50,
            displayWidth: 1920, displayHeight: 1080,
            originX: 0, originY: 0
        )
        XCTAssertEqual(pt.x, 960)
        XCTAssertEqual(pt.y, 540)
    }

    func testNormalizedToScreenZeroZero() {
        let pt = CoordinateConverter.normalizedToScreen(
            normX: 0, normY: 0,
            displayWidth: 1920, displayHeight: 1080,
            originX: 0, originY: 0
        )
        XCTAssertEqual(pt.x, 0)
        XCTAssertEqual(pt.y, 0)
    }

    func testNormalizedToScreenFullExtent() {
        let pt = CoordinateConverter.normalizedToScreen(
            normX: 100, normY: 100,
            displayWidth: 1920, displayHeight: 1080,
            originX: 0, originY: 0
        )
        XCTAssertEqual(pt.x, 1920)
        XCTAssertEqual(pt.y, 1080)
    }

    func testNormalizedToScreenWithOriginOffset() {
        let pt = CoordinateConverter.normalizedToScreen(
            normX: 50, normY: 50,
            displayWidth: 1920, displayHeight: 1080,
            originX: 100, originY: 200
        )
        XCTAssertEqual(pt.x, 1060)
        XCTAssertEqual(pt.y, 740)
    }

    func testNormalizedToScreenSmallDisplay() {
        let pt = CoordinateConverter.normalizedToScreen(
            normX: 25, normY: 75,
            displayWidth: 800, displayHeight: 600,
            originX: 0, originY: 0
        )
        XCTAssertEqual(pt.x, 200)
        XCTAssertEqual(pt.y, 450)
    }
}
