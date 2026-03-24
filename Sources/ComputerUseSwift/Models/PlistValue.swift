import Foundation

public enum PlistValue: Codable {
    case string(String)
    case bool(Bool)
    case integer(Int)
    case float(Double)

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .string(let v): try container.encode(v)
        case .bool(let v): try container.encode(v)
        case .integer(let v): try container.encode(v)
        case .float(let v): try container.encode(v)
        }
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let v = try? container.decode(Bool.self) {
            self = .bool(v)
        } else if let v = try? container.decode(Int.self) {
            self = .integer(v)
        } else if let v = try? container.decode(Double.self) {
            self = .float(v)
        } else if let v = try? container.decode(String.self) {
            self = .string(v)
        } else {
            throw DecodingError.typeMismatch(
                PlistValue.self,
                DecodingError.Context(
                    codingPath: decoder.codingPath,
                    debugDescription: "Expected a string, bool, integer, or float value"
                )
            )
        }
    }
}
