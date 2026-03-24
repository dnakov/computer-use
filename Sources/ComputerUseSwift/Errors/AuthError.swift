import Foundation

public enum AuthError: LocalizedError {
    case alreadyInProgress
    case invalidURL
    case failedToStart
    case timeout
    case cancelled

    public var errorDescription: String? {
        switch self {
        case .alreadyInProgress:
            return "Authentication already in progress"
        case .invalidURL:
            return "Invalid URL"
        case .failedToStart:
            return "Failed to start authentication session"
        case .timeout:
            return "Authentication timeout"
        case .cancelled:
            return "Authentication cancelled"
        }
    }
}
