import XCTest
@testable import ComputerUseSwift

final class ImageSizingTests: XCTestCase {

    // MARK: - nTokensForImg

    func testNTokens_1x1() {
        XCTAssertEqual(ImageSizing.nTokensForImg(width: 1, height: 1, tileSize: 28), 1)
    }

    func testNTokens_28x28() {
        XCTAssertEqual(ImageSizing.nTokensForImg(width: 28, height: 28, tileSize: 28), 1)
    }

    func testNTokens_29x29() {
        // 29 requires 2 tiles per axis: ceil(29/28) = 2
        XCTAssertEqual(ImageSizing.nTokensForImg(width: 29, height: 29, tileSize: 28), 4)
    }

    func testNTokens_56x56() {
        // 56/28 = exactly 2 tiles per axis
        XCTAssertEqual(ImageSizing.nTokensForImg(width: 56, height: 56, tileSize: 28), 4)
    }

    func testNTokens_100x100() {
        // ceil(100/28) = 4 tiles per axis → 4*4 = 16
        XCTAssertEqual(ImageSizing.nTokensForImg(width: 100, height: 100, tileSize: 28), 16)
    }

    func testNTokens_defaultTileSize() {
        // Verify default tileSize parameter is 28
        XCTAssertEqual(ImageSizing.nTokensForImg(width: 28, height: 28), 1)
    }

    // MARK: - cuTargetImageSize passthrough

    func testTargetImageSize_smallPassthrough() {
        // 800x600 → both <= 1568, tokens = ceil(800/28)*ceil(600/28) = 29*22 = 638 < 1569
        let (w, h) = ImageSizing.cuTargetImageSize(physW: 800, physH: 600)
        XCTAssertEqual(w, 800)
        XCTAssertEqual(h, 600)
    }

    func testTargetImageSize_1x1() {
        let (w, h) = ImageSizing.cuTargetImageSize(physW: 1, physH: 1)
        XCTAssertEqual(w, 1)
        XCTAssertEqual(h, 1)
    }

    // MARK: - cuTargetImageSize downscaling

    func testTargetImageSize_2560x1440_downscale() {
        let (w, h) = ImageSizing.cuTargetImageSize(physW: 2560, physH: 1440)
        let tokens = ImageSizing.nTokensForImg(width: w, height: h)
        XCTAssertLessThanOrEqual(tokens, 1568)
        // Aspect ratio should be preserved
        let originalRatio = Double(2560) / Double(1440)
        let resultRatio = Double(w) / Double(h)
        XCTAssertEqual(originalRatio, resultRatio, accuracy: 0.05)
    }

    func testTargetImageSize_4K() {
        let (w, h) = ImageSizing.cuTargetImageSize(physW: 3840, physH: 2160)
        let tokens = ImageSizing.nTokensForImg(width: w, height: h)
        XCTAssertLessThanOrEqual(tokens, 1568)
        let originalRatio = Double(3840) / Double(2160)
        let resultRatio = Double(w) / Double(h)
        XCTAssertEqual(originalRatio, resultRatio, accuracy: 0.05)
    }

    func testTargetImageSize_portrait() {
        // 1440x2560 portrait — should preserve w < h
        let (w, h) = ImageSizing.cuTargetImageSize(physW: 1440, physH: 2560)
        let tokens = ImageSizing.nTokensForImg(width: w, height: h)
        XCTAssertLessThanOrEqual(tokens, 1568)
        XCTAssertLessThan(w, h, "Portrait orientation should be preserved (width < height)")
    }

    func testTargetImageSize_ultrawide() {
        // 5120x1440 ultrawide
        let (w, h) = ImageSizing.cuTargetImageSize(physW: 5120, physH: 1440)
        let tokens = ImageSizing.nTokensForImg(width: w, height: h)
        XCTAssertLessThanOrEqual(tokens, 1568)
        let originalRatio = Double(5120) / Double(1440)
        let resultRatio = Double(w) / Double(h)
        XCTAssertEqual(originalRatio, resultRatio, accuracy: 0.1)
    }

    func testTargetImageSize_boundary1568x1568() {
        // 1568x1568 → tokens = ceil(1568/28)^2 = 56^2 = 3136 > 1568, must downscale
        let (w, h) = ImageSizing.cuTargetImageSize(physW: 1568, physH: 1568)
        let tokens = ImageSizing.nTokensForImg(width: w, height: h)
        XCTAssertLessThanOrEqual(tokens, 1568)
        // Should be smaller than original
        XCTAssertTrue(w < 1568 || h < 1568, "1568x1568 must be downscaled")
    }

    func testTargetImageSize_symmetry() {
        // cuTargetImageSize(W, H) and cuTargetImageSize(H, W) should produce swapped results
        let (w1, h1) = ImageSizing.cuTargetImageSize(physW: 2560, physH: 1440)
        let (w2, h2) = ImageSizing.cuTargetImageSize(physW: 1440, physH: 2560)
        XCTAssertEqual(w1, h2)
        XCTAssertEqual(h1, w2)
    }
}
