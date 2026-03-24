import Foundation

public enum AppError: LocalizedError {
    case notFound(String)

    public var errorDescription: String? {
        switch self {
        case .notFound(let bundleId):
            return "No application found for bundle ID \(bundleId)"
        }
    }
}
