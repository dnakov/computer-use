import ArgumentParser
import Foundation

struct DrainRunLoopCommand: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "drain-run-loop",
        abstract: "Synchronously drain the main run loop"
    )

    func run() throws {
        RunLoop.main.run(mode: .default, before: .distantPast)
    }
}
