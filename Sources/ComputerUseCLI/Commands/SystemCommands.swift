import ArgumentParser
import ComputerUseSwift

struct SystemGroup: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "system",
        abstract: "System query commands",
        subcommands: [
            ReadPlist.self,
            ReadCfPref.self,
            IsProcessRunning.self,
        ]
    )

    struct ReadPlist: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "read-plist",
            abstract: "Read a value from a plist file"
        )

        @Option(name: .long)
        var file: String

        @Option(name: .long)
        var key: String

        func run() async throws {
            do {
                let value = try SystemQueries.readPlistValue(filePath: file, key: key)
                if let value = value {
                    try OutputFormatter.output(value)
                } else {
                    print("null")
                }
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct ReadCfPref: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "read-cf-pref",
            abstract: "Read a value from CFPreferences"
        )

        @Option(name: .long)
        var key: String

        func run() async throws {
            do {
                let value = SystemQueries.readCfPrefValue(key: key)
                if let value = value {
                    try OutputFormatter.output(value)
                } else {
                    print("null")
                }
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct IsProcessRunning: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "is-process-running",
            abstract: "Check if a process is running"
        )

        @Option(name: .long)
        var processId: String

        @MainActor
        func run() async throws {
            do {
                let running = SystemQueries.isProcessRunning(processId: processId)
                try OutputFormatter.output(["running": running])
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }
}
