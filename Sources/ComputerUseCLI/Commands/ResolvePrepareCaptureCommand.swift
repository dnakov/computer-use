import ArgumentParser
import ComputerUseSwift

struct ResolvePrepareCaptureCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "resolve-prepare-capture",
        abstract: "Resolve target display, prepare it, and capture a screenshot"
    )

    @Option(name: .long, parsing: .upToNextOption)
    var allowedBundleIds: [String]

    @Option(name: .long)
    var hostBundleId: String

    @Option(name: .long, parsing: .upToNextOption)
    var excludeBundleIds: [String]

    func run() async throws {
        do {
            let result = await ResolvePrepareCapture.execute(
                allowedBundleIds: allowedBundleIds,
                hostBundleId: hostBundleId,
                excludeBundleIds: excludeBundleIds
            )
            try OutputFormatter.output(result)
        } catch {
            OutputFormatter.exitWithError(error.localizedDescription)
        }
    }
}
