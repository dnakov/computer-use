import Foundation

public enum CoordinateConverter {
    public struct ScreenPoint: Codable {
        public let x: Int
        public let y: Int
    }

    /// Convert image pixel coordinates to screen points.
    /// Uses the screenshot dimensions to compute the scaling ratio.
    public static func imagePixelsToScreen(
        pixelX: Double, pixelY: Double,
        screenshotWidth: Int, screenshotHeight: Int,
        displayWidth: Int, displayHeight: Int,
        originX: Int, originY: Int
    ) -> ScreenPoint {
        let x = Int((pixelX * Double(displayWidth) / Double(screenshotWidth)).rounded()) + originX
        let y = Int((pixelY * Double(displayHeight) / Double(screenshotHeight)).rounded()) + originY
        return ScreenPoint(x: x, y: y)
    }

    /// Convert normalized 0-100 coordinates to screen points.
    public static func normalizedToScreen(
        normX: Double, normY: Double,
        displayWidth: Int, displayHeight: Int,
        originX: Int, originY: Int
    ) -> ScreenPoint {
        let x = Int((normX / 100.0 * Double(displayWidth)).rounded()) + originX
        let y = Int((normY / 100.0 * Double(displayHeight)).rounded()) + originY
        return ScreenPoint(x: x, y: y)
    }
}
