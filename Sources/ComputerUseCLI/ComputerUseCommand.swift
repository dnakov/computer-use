import ArgumentParser

@main
struct ComputerUse: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "computer-use",
        abstract: "macOS computer use capabilities",
        version: "0.2.1",
        subcommands: [
            ScreenshotGroup.self,
            DisplayGroup.self,
            AppsGroup.self,
            TCCGroup.self,
            ResolvePrepareCaptureCommand.self,
            DrainRunLoopCommand.self,
            InputGroup.self,
            WindowGroup.self,
            SystemGroup.self,
            AuthGroup.self,
            ClipboardGroup.self,
            WaitCommand.self,
            SessionGroup.self,
            TeachGroup.self,
        ]
    )
}
