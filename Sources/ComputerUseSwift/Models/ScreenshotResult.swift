import Foundation

public struct ScreenshotResult: Codable {
    public let base64: String
    public let width: Int
    public let height: Int
    public let displayWidth: Int
    public let displayHeight: Int
    public let displayId: Int
    public let originX: Int
    public let originY: Int
    public let captureError: String?

    public init(
        base64: String,
        width: Int,
        height: Int,
        displayWidth: Int,
        displayHeight: Int,
        displayId: Int,
        originX: Int,
        originY: Int,
        captureError: String? = nil
    ) {
        self.base64 = base64
        self.width = width
        self.height = height
        self.displayWidth = displayWidth
        self.displayHeight = displayHeight
        self.displayId = displayId
        self.originX = originX
        self.originY = originY
        self.captureError = captureError
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(base64, forKey: .base64)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(displayWidth, forKey: .displayWidth)
        try container.encode(displayHeight, forKey: .displayHeight)
        try container.encode(displayId, forKey: .displayId)
        try container.encode(originX, forKey: .originX)
        try container.encode(originY, forKey: .originY)
        if let captureError = captureError {
            try container.encode(captureError, forKey: .captureError)
        } else {
            try container.encodeNil(forKey: .captureError)
        }
    }
}
