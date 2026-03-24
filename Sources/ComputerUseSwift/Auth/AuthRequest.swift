import Foundation
import AuthenticationServices

// MARK: - Presentation Context Provider

class AuthPresentationContextProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        if let window = NSApp?.keyWindow {
            return window
        }
        // For CLI or headless contexts, create a minimal window as anchor
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 1, height: 1),
            styleMask: [],
            backing: .buffered,
            defer: false
        )
        return window
    }
}

// MARK: - AuthRequest

public class AuthRequest {
    private var session: ASWebAuthenticationSession?
    private let contextProvider = AuthPresentationContextProvider()

    public init() {}

    /// Check if ASWebAuthenticationSession is available (always true on macOS 14+).
    public static func isAvailable() -> Bool {
        return true
    }

    /// Start an authentication session.
    ///
    /// - Parameters:
    ///   - url: The authorization URL to open.
    ///   - callbackUrlScheme: The URL scheme for the callback.
    /// - Returns: An `AuthResult` with either a callback URL or an error message.
    public func start(url: String, callbackUrlScheme: String) async throws -> AuthResult {
        guard session == nil else {
            throw AuthError.alreadyInProgress
        }

        guard let authURL = URL(string: url) else {
            throw AuthError.invalidURL
        }

        return try await withCheckedThrowingContinuation { continuation in
            let webAuthSession = ASWebAuthenticationSession(
                url: authURL,
                callbackURLScheme: callbackUrlScheme
            ) { callbackURL, error in
                if let callbackURL = callbackURL {
                    continuation.resume(returning: AuthResult(
                        callbackUrl: callbackURL.absoluteString,
                        error: nil
                    ))
                } else if let error = error {
                    let nsError = error as NSError
                    if nsError.domain == ASWebAuthenticationSessionErrorDomain {
                        switch ASWebAuthenticationSessionError.Code(rawValue: nsError.code) {
                        case .canceledLogin:
                            continuation.resume(returning: AuthResult(
                                callbackUrl: nil,
                                error: AuthError.cancelled.errorDescription
                            ))
                        default:
                            continuation.resume(returning: AuthResult(
                                callbackUrl: nil,
                                error: error.localizedDescription
                            ))
                        }
                    } else {
                        continuation.resume(returning: AuthResult(
                            callbackUrl: nil,
                            error: error.localizedDescription
                        ))
                    }
                } else {
                    continuation.resume(returning: AuthResult(
                        callbackUrl: nil,
                        error: AuthError.failedToStart.errorDescription
                    ))
                }
            }

            webAuthSession.presentationContextProvider = self.contextProvider
            self.session = webAuthSession

            if !webAuthSession.start() {
                self.session = nil
                continuation.resume(throwing: AuthError.failedToStart)
            }
        }
    }

    /// Cancel the active authentication session.
    public func cancel() {
        session?.cancel()
        session = nil
    }
}
