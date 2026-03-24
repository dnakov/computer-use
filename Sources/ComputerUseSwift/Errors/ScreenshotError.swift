import Foundation

public enum ScreenshotError: LocalizedError {
    case captureFailedNoImage
    case regionCaptureFailedNoImage
    case screenCaptureKitUnavailable
    case missingPermission
    case displayUnavailable
    case captureWithExclusionFailed(String)
    case regionCaptureWithExclusionFailed(String)
    case jpegConversionFailed
    case regionJpegConversionFailed
    case displayNotFoundForID(UInt32)
    case displayNotFound
    case captureReturnedNoImage

    public var errorDescription: String? {
        switch self {
        case .captureFailedNoImage:
            return "Screenshot capture returned nil (permission missing or SCContentFilter failure)"
        case .regionCaptureFailedNoImage:
            return "Region capture returned nil (permission missing or SCContentFilter failure)"
        case .screenCaptureKitUnavailable:
            return "ScreenCaptureKit requires macOS 14.0"
        case .missingPermission:
            return "Missing screen recording permission"
        case .displayUnavailable:
            return "CU display unavailable"
        case .captureWithExclusionFailed(let detail):
            return "Failed to capture with app exclusion: \(detail)"
        case .regionCaptureWithExclusionFailed(let detail):
            return "Failed to capture region with app exclusion: \(detail)"
        case .jpegConversionFailed:
            return "Failed to convert screenshot to JPEG"
        case .regionJpegConversionFailed:
            return "Failed to convert region screenshot to JPEG"
        case .displayNotFoundForID(let id):
            return "Display not found for ID: \(id)"
        case .displayNotFound:
            return "Display not found for the given ID"
        case .captureReturnedNoImage:
            return "Screenshot capture returned no image"
        }
    }
}
