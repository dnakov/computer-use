import XCTest
@testable import ComputerUseSwift

final class ErrorTests: XCTestCase {

    // MARK: - ScreenshotError

    func testCaptureFailedNoImage() {
        let error = ScreenshotError.captureFailedNoImage
        XCTAssertEqual(
            error.errorDescription,
            "Screenshot capture returned nil (permission missing or SCContentFilter failure)"
        )
    }

    func testRegionCaptureFailedNoImage() {
        let error = ScreenshotError.regionCaptureFailedNoImage
        XCTAssertEqual(
            error.errorDescription,
            "Region capture returned nil (permission missing or SCContentFilter failure)"
        )
    }

    func testScreenCaptureKitUnavailable() {
        let error = ScreenshotError.screenCaptureKitUnavailable
        XCTAssertEqual(error.errorDescription, "ScreenCaptureKit requires macOS 14.0")
    }

    func testMissingPermission() {
        let error = ScreenshotError.missingPermission
        XCTAssertEqual(error.errorDescription, "Missing screen recording permission")
    }

    func testDisplayUnavailable() {
        let error = ScreenshotError.displayUnavailable
        XCTAssertEqual(error.errorDescription, "CU display unavailable")
    }

    func testCaptureWithExclusionFailed() {
        let detail = "timeout exceeded"
        let error = ScreenshotError.captureWithExclusionFailed(detail)
        XCTAssertEqual(
            error.errorDescription,
            "Failed to capture with app exclusion: timeout exceeded"
        )
    }

    func testRegionCaptureWithExclusionFailed() {
        let detail = "filter error"
        let error = ScreenshotError.regionCaptureWithExclusionFailed(detail)
        XCTAssertEqual(
            error.errorDescription,
            "Failed to capture region with app exclusion: filter error"
        )
    }

    func testJpegConversionFailed() {
        let error = ScreenshotError.jpegConversionFailed
        XCTAssertEqual(error.errorDescription, "Failed to convert screenshot to JPEG")
    }

    func testRegionJpegConversionFailed() {
        let error = ScreenshotError.regionJpegConversionFailed
        XCTAssertEqual(error.errorDescription, "Failed to convert region screenshot to JPEG")
    }

    func testDisplayNotFoundForID() {
        let error = ScreenshotError.displayNotFoundForID(42)
        XCTAssertEqual(error.errorDescription, "Display not found for ID: 42")
    }

    func testDisplayNotFound() {
        let error = ScreenshotError.displayNotFound
        XCTAssertEqual(error.errorDescription, "Display not found for the given ID")
    }

    func testCaptureReturnedNoImage() {
        let error = ScreenshotError.captureReturnedNoImage
        XCTAssertEqual(error.errorDescription, "Screenshot capture returned no image")
    }

    // MARK: - InstalledAppsError

    func testQueryFailedToStart() {
        let error = InstalledAppsError.queryFailedToStart
        XCTAssertEqual(
            error.errorDescription,
            "NSMetadataQuery failed to start (Spotlight may be indexing or disabled)"
        )
    }

    // MARK: - AppError

    func testAppNotFound() {
        let error = AppError.notFound("com.example")
        XCTAssertEqual(
            error.errorDescription,
            "No application found for bundle ID com.example"
        )
    }

    func testAppNotFoundDifferentBundleId() {
        let error = AppError.notFound("com.apple.Safari")
        XCTAssertEqual(
            error.errorDescription,
            "No application found for bundle ID com.apple.Safari"
        )
    }
}
