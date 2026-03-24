import ArgumentParser
import ComputerUseSwift

struct ClipboardGroup: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "clipboard",
        abstract: "Clipboard commands",
        subcommands: [Read.self, Write.self, Paste.self]
    )

    struct Read: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "read",
            abstract: "Read text from the clipboard"
        )

        func run() async throws {
            let text = ClipboardManager.read()
            try OutputFormatter.output(["text": text])
        }
    }

    struct Write: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "write",
            abstract: "Write text to the clipboard"
        )

        @Option(name: .long)
        var text: String

        func run() async throws {
            ClipboardManager.write(text)
            try OutputFormatter.output(["success": true])
        }
    }

    struct Paste: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "paste",
            abstract: "Paste text by temporarily writing to clipboard and pressing Cmd+V"
        )

        @Option(name: .long)
        var text: String

        func run() async throws {
            do {
                // Stash current clipboard
                let stash = ClipboardManager.read()

                // Write new text to clipboard
                ClipboardManager.write(text)

                // Press Cmd+V
                _ = try await KeyboardInput.keys(names: ["command", "v"])

                // Wait 100ms for paste to complete
                try await Task.sleep(nanoseconds: 100_000_000)

                // Restore stashed clipboard
                ClipboardManager.write(stash)

                try OutputFormatter.output(["success": true])
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }
}
