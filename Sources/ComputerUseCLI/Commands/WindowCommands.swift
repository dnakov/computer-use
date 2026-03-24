import ArgumentParser
import ComputerUseSwift

private struct WindowIdResult: Encodable {
    let windowId: UInt32?
}

struct WindowGroup: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "window",
        abstract: "Window management commands",
        subcommands: [
            Focus.self,
            GetAbove.self,
            MoveBehind.self,
            GetActiveHandle.self,
            GetFrontmostApp.self,
            GetAppForFile.self,
        ]
    )

    struct Focus: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "focus",
            abstract: "Focus a window by its window ID"
        )

        @Option(name: .long)
        var windowId: UInt32

        func run() async throws {
            do {
                try WindowManager.focusWindow(windowId: windowId)
                try OutputFormatter.output(["success": true])
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct GetAbove: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "get-above",
            abstract: "Get the window above a given window in z-order"
        )

        @Option(name: .long)
        var windowId: UInt32

        func run() async throws {
            do {
                let aboveId = WindowManager.getWindowAbove(windowId: windowId)
                try OutputFormatter.output(WindowIdResult(windowId: aboveId))
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct MoveBehind: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "move-behind",
            abstract: "Move a window behind another in z-order"
        )

        @Option(name: .long)
        var windowId: UInt32

        @Option(name: .long)
        var behindWindowId: UInt32

        func run() async throws {
            do {
                try WindowManager.moveWindowBehind(windowId: windowId, behindWindowId: behindWindowId)
                try OutputFormatter.output(["success": true])
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct GetActiveHandle: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "get-active-handle",
            abstract: "Get the active/focused window handle"
        )

        func run() async throws {
            do {
                let windowId = try WindowManager.getActiveWindowHandle()
                try OutputFormatter.output(WindowIdResult(windowId: windowId))
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct GetFrontmostApp: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "get-frontmost-app",
            abstract: "Get info about the frontmost application"
        )

        func run() async throws {
            do {
                let info = WindowManager.getFrontmostAppInfo()
                if let info = info {
                    try OutputFormatter.output(info)
                } else {
                    print("null")
                }
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct GetAppForFile: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "get-app-for-file",
            abstract: "Get default app info for a file"
        )

        @Option(name: .long)
        var path: String

        func run() async throws {
            do {
                let info = WindowManager.getAppInfoForFile(filePath: path)
                if let info = info {
                    try OutputFormatter.output(info)
                } else {
                    print("null")
                }
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }
}
