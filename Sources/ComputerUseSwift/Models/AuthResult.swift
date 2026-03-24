import Foundation

public struct AuthResult: Codable {
    public let callbackUrl: String?
    public let error: String?

    public init(callbackUrl: String?, error: String?) {
        self.callbackUrl = callbackUrl
        self.error = error
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        if let callbackUrl = callbackUrl {
            try container.encode(callbackUrl, forKey: .callbackUrl)
        } else {
            try container.encodeNil(forKey: .callbackUrl)
        }
        if let error = error {
            try container.encode(error, forKey: .error)
        } else {
            try container.encodeNil(forKey: .error)
        }
    }
}
