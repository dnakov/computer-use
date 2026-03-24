import ArgumentParser
import ComputerUseSwift

struct TCCGroup: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "tcc",
        abstract: "TCC permission checks",
        subcommands: [
            CheckAccessibility.self,
            RequestAccessibility.self,
            CheckScreenRecording.self,
            RequestScreenRecording.self,
        ]
    )

    struct CheckAccessibility: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "check-accessibility",
            abstract: "Check if accessibility permission is granted"
        )

        func run() async throws {
            do {
                let granted = PermissionManager.checkAccessibility()
                try OutputFormatter.output(["granted": granted])
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct RequestAccessibility: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "request-accessibility",
            abstract: "Request accessibility permission"
        )

        func run() async throws {
            do {
                let granted = PermissionManager.requestAccessibility()
                try OutputFormatter.output(["granted": granted])
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct CheckScreenRecording: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "check-screen-recording",
            abstract: "Check if screen recording permission is granted"
        )

        func run() async throws {
            do {
                let granted = PermissionManager.checkScreenRecording()
                try OutputFormatter.output(["granted": granted])
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct RequestScreenRecording: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "request-screen-recording",
            abstract: "Request screen recording permission"
        )

        func run() async throws {
            do {
                let granted = PermissionManager.requestScreenRecording()
                try OutputFormatter.output(["granted": granted])
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }
}
