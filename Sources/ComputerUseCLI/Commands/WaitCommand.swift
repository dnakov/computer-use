import ArgumentParser
import ComputerUseSwift

struct WaitCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(commandName: "wait")

    @Option(name: .long)
    var duration: Double

    func run() async throws {
        guard duration >= 0 && duration <= 100 else {
            OutputFormatter.exitWithError("Duration must be 0-100 seconds")
        }
        try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        try OutputFormatter.output(["waited": duration])
    }
}
