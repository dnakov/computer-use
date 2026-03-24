import ArgumentParser
import ComputerUseSwift
import CoreGraphics
import Foundation

struct ScreenshotGroup: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "screenshot",
        abstract: "Screenshot capture commands",
        subcommands: [CaptureExcluding.self, CaptureRegion.self]
    )

    struct CaptureExcluding: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "capture-excluding",
            abstract: "Capture the full display, excluding specified apps"
        )

        @Option(name: .long, parsing: .upToNextOption)
        var excludeBundleIds: [String] = []

        @Option(name: .long)
        var jpegQuality: Double = 0.75

        @Option(name: .long)
        var displayId: UInt32?

        func run() async throws {
            do {
                guard let displayInfo = DisplayManager.cuDisplayInfo(forDisplayID: displayId) else {
                    OutputFormatter.exitWithError("CU display unavailable")
                }

                let (targetW, targetH) = ImageSizing.cuTargetImageSize(
                    physW: displayInfo.physicalWidth,
                    physH: displayInfo.physicalHeight
                )

                let result = try await ScreenshotCapture.captureScreenWithExclusion(
                    displayId: displayInfo.displayID,
                    width: targetW,
                    height: targetH,
                    excludedBundleIds: excludeBundleIds,
                    jpegQuality: CGFloat(jpegQuality)
                )

                // Save to temp file
                let base64 = result.dataUrl.replacingOccurrences(of: "data:image/jpeg;base64,", with: "")
                let screenshotDir = FileManager.default.temporaryDirectory.appendingPathComponent("computer-use-screenshots")
                try? FileManager.default.createDirectory(at: screenshotDir, withIntermediateDirectories: true)
                let filename = "screenshot-\(Int(Date().timeIntervalSince1970)).jpg"
                let filePath = screenshotDir.appendingPathComponent(filename)
                if let imageData = Data(base64Encoded: base64) {
                    try imageData.write(to: filePath)
                }

                struct ScreenshotOutput: Codable {
                    let path: String
                    let width: Int
                    let height: Int
                    let displayWidth: Int
                    let displayHeight: Int
                    let displayId: Int
                    let originX: Int
                    let originY: Int
                }
                let dims = ScreenshotDims(
                    width: result.width,
                    height: result.height,
                    displayWidth: displayInfo.boundsWidth,
                    displayHeight: displayInfo.boundsHeight,
                    displayId: Int(displayInfo.displayID),
                    originX: displayInfo.originX,
                    originY: displayInfo.originY
                )
                LastScreenshot.save(dims)

                try OutputFormatter.output(ScreenshotOutput(
                    path: filePath.path,
                    width: result.width,
                    height: result.height,
                    displayWidth: displayInfo.boundsWidth,
                    displayHeight: displayInfo.boundsHeight,
                    displayId: Int(displayInfo.displayID),
                    originX: displayInfo.originX,
                    originY: displayInfo.originY
                ))
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct CaptureRegion: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "capture-region",
            abstract: "Capture a specific region of the display"
        )

        @Option(name: .long, parsing: .upToNextOption)
        var excludeBundleIds: [String] = []

        @Option(name: .long)
        var regionX: Double

        @Option(name: .long)
        var regionY: Double

        @Option(name: .long)
        var regionW: Double

        @Option(name: .long)
        var regionH: Double

        @Option(name: .long)
        var outputWidth: Int

        @Option(name: .long)
        var outputHeight: Int

        @Option(name: .long)
        var jpegQuality: Double = 0.75

        @Option(name: .long)
        var displayId: UInt32?

        func run() async throws {
            do {
                guard let displayInfo = DisplayManager.cuDisplayInfo(forDisplayID: displayId) else {
                    OutputFormatter.exitWithError("CU display unavailable")
                }

                let sourceRect = CGRect(x: regionX, y: regionY, width: regionW, height: regionH)

                let result = try await ScreenshotCapture.captureScreenRegion(
                    displayId: displayInfo.displayID,
                    sourceRect: sourceRect,
                    outputWidth: outputWidth,
                    outputHeight: outputHeight,
                    excludedBundleIds: excludeBundleIds,
                    jpegQuality: CGFloat(jpegQuality)
                )

                let screenshotResult = ScreenshotResult(
                    base64: result.dataUrl,
                    width: result.width,
                    height: result.height,
                    displayWidth: displayInfo.boundsWidth,
                    displayHeight: displayInfo.boundsHeight,
                    displayId: Int(displayInfo.displayID),
                    originX: displayInfo.originX,
                    originY: displayInfo.originY
                )
                try OutputFormatter.output(screenshotResult)
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }
}
