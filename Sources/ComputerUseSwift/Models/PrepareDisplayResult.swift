import Foundation

public struct PrepareDisplayResult: Codable {
    public let hidden: [String]
    public let activated: String?

    public init(hidden: [String], activated: String?) {
        self.hidden = hidden
        self.activated = activated
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(hidden, forKey: .hidden)
        if let activated = activated {
            try container.encode(activated, forKey: .activated)
        } else {
            try container.encodeNil(forKey: .activated)
        }
    }
}
