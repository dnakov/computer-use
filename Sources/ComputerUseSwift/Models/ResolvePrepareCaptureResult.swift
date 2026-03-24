import Foundation

public struct ResolvePrepareCaptureResult: Codable {
    public let screenshot: ScreenshotResult?
    public let hidden: [String]
    public let activated: String?
    public let displayId: Int

    public init(
        screenshot: ScreenshotResult?,
        hidden: [String],
        activated: String?,
        displayId: Int
    ) {
        self.screenshot = screenshot
        self.hidden = hidden
        self.activated = activated
        self.displayId = displayId
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let screenshot = screenshot {
            try container.encode(screenshot, forKey: .screenshot)
        } else {
            try container.encodeNil(forKey: .screenshot)
        }
        try container.encode(hidden, forKey: .hidden)
        if let activated = activated {
            try container.encode(activated, forKey: .activated)
        } else {
            try container.encodeNil(forKey: .activated)
        }
        try container.encode(displayId, forKey: .displayId)
    }
}
