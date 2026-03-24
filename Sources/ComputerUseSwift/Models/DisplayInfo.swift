import Foundation

public struct DisplayInfo: Codable {
    public let displayId: Int
    public let width: Int
    public let height: Int
    public let scaleFactor: Double
    public let originX: Int
    public let originY: Int
    public let isPrimary: Bool?

    public init(
        displayId: Int,
        width: Int,
        height: Int,
        scaleFactor: Double,
        originX: Int,
        originY: Int,
        isPrimary: Bool? = nil
    ) {
        self.displayId = displayId
        self.width = width
        self.height = height
        self.scaleFactor = scaleFactor
        self.originX = originX
        self.originY = originY
        self.isPrimary = isPrimary
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(displayId, forKey: .displayId)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(scaleFactor, forKey: .scaleFactor)
        try container.encode(originX, forKey: .originX)
        try container.encode(originY, forKey: .originY)
        if let isPrimary = isPrimary {
            try container.encode(isPrimary, forKey: .isPrimary)
        } else {
            try container.encodeNil(forKey: .isPrimary)
        }
    }
}
