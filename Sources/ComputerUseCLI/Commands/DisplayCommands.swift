import ArgumentParser
import ComputerUseSwift

struct DisplayGroup: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "display",
        abstract: "Display management commands",
        subcommands: [GetSize.self, ListAll.self, ConvertCoordinates.self]
    )

    struct GetSize: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "get-size",
            abstract: "Get display size and metadata"
        )

        @Option(name: .long)
        var displayId: UInt32?

        func run() async throws {
            do {
                guard let info = DisplayManager.cuDisplayInfo(forDisplayID: displayId) else {
                    OutputFormatter.exitWithError("CU display unavailable")
                }
                try OutputFormatter.output(info.toDisplayInfo())
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct ListAll: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "list-all",
            abstract: "List all connected displays"
        )

        func run() async throws {
            do {
                let displays = DisplayManager.listAllDisplays()
                try OutputFormatter.output(displays)
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct ConvertCoordinates: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "convert-coordinates",
            abstract: "Convert image pixel coordinates to screen points"
        )

        @Option(name: .long, help: "Pixel X coordinate in the screenshot")
        var pixelX: Double

        @Option(name: .long, help: "Pixel Y coordinate in the screenshot")
        var pixelY: Double

        @Option(name: .long, help: "Screenshot width in pixels")
        var screenshotWidth: Int

        @Option(name: .long, help: "Screenshot height in pixels")
        var screenshotHeight: Int

        @Option(name: .long, help: "Display width in points")
        var displayWidth: Int

        @Option(name: .long, help: "Display height in points")
        var displayHeight: Int

        @Option(name: .long, help: "Display origin X offset")
        var originX: Int = 0

        @Option(name: .long, help: "Display origin Y offset")
        var originY: Int = 0

        func run() async throws {
            let point = CoordinateConverter.imagePixelsToScreen(
                pixelX: pixelX, pixelY: pixelY,
                screenshotWidth: screenshotWidth, screenshotHeight: screenshotHeight,
                displayWidth: displayWidth, displayHeight: displayHeight,
                originX: originX, originY: originY
            )
            do {
                try OutputFormatter.output(point)
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }
}
