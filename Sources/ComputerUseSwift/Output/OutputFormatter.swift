import Foundation

public enum OutputFormatter {
    public enum OutputError: LocalizedError {
        case encodingFailed

        public var errorDescription: String? {
            switch self {
            case .encodingFailed:
                return "JSON encode failed"
            }
        }
    }

    private static let compactEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        return encoder
    }()

    private static let prettyEncoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .prettyPrinted]
        return encoder
    }()

    public static func output<T: Encodable>(_ value: T, pretty: Bool = false) throws {
        let encoder = pretty ? prettyEncoder : compactEncoder
        let data = try encoder.encode(value)
        guard let json = String(data: data, encoding: .utf8) else {
            throw OutputError.encodingFailed
        }
        print(json)
    }

    public static func exitWithError(_ message: String) -> Never {
        let errorObj = ["error": message]
        if let data = try? JSONEncoder().encode(errorObj),
           let json = String(data: data, encoding: .utf8) {
            FileHandle.standardError.write(Data(json.utf8))
            FileHandle.standardError.write(Data("\n".utf8))
        } else {
            FileHandle.standardError.write(Data("{\"error\":\"\(message)\"}\n".utf8))
        }
        exit(1)
    }
}
