import ArgumentParser
import ComputerUseSwift

struct AuthGroup: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "auth",
        abstract: "Web authentication commands",
        subcommands: [
            IsAvailable.self,
            Start.self,
            Cancel.self,
        ]
    )

    struct IsAvailable: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "is-available",
            abstract: "Check if web authentication is available"
        )

        func run() async throws {
            do {
                let available = AuthRequest.isAvailable()
                try OutputFormatter.output(["available": available])
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct Start: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "start",
            abstract: "Start a web authentication session"
        )

        @Option(name: .long)
        var url: String

        @Option(name: .long)
        var callbackScheme: String

        func run() async throws {
            do {
                let authRequest = AuthRequest()
                let result = try await authRequest.start(url: url, callbackUrlScheme: callbackScheme)
                try OutputFormatter.output(result)
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct Cancel: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "cancel",
            abstract: "Cancel the active authentication session"
        )

        func run() async throws {
            // Note: cancel is a no-op from CLI since each invocation is a separate process.
            // Included for API completeness.
            try OutputFormatter.output(["success": true])
        }
    }
}
