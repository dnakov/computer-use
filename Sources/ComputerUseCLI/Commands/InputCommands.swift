import ArgumentParser
import ComputerUseSwift

struct InputGroup: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "input",
        abstract: "Input simulation commands",
        subcommands: [
            Key.self,
            Keys.self,
            TypeText.self,
            MoveMouse.self,
            MouseButton.self,
            MouseScroll.self,
            MouseLocationCmd.self,
            Drag.self,
            HoldKey.self,
            IsSystemCombo.self,
        ]
    )

    struct Key: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "key",
            abstract: "Press, release, or click a single key"
        )

        @Option(name: .long)
        var keyName: String

        @Option(name: .long)
        var action: String = "click"

        func run() async throws {
            do {
                let result = try await KeyboardInput.key(name: keyName, action: action)
                try OutputFormatter.output(["result": result])
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct Keys: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "keys",
            abstract: "Execute a key combination (multiple simultaneous keys)"
        )

        @Option(name: .long, parsing: .upToNextOption)
        var keyNames: [String]

        func run() async throws {
            do {
                let result = try await KeyboardInput.keys(names: keyNames)
                try OutputFormatter.output(["result": result])
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct TypeText: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "type-text",
            abstract: "Type a text string"
        )

        @Option(name: .long)
        var text: String

        func run() async throws {
            do {
                let result = try await KeyboardInput.typeText(text)
                try OutputFormatter.output(["result": result])
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct MoveMouse: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "move-mouse",
            abstract: "Move mouse cursor to coordinates"
        )

        @Option(name: .long)
        var x: Int32

        @Option(name: .long)
        var y: Int32

        @Option(name: .long)
        var relative: Bool

        @Flag(name: .long, help: "Disable animation")
        var noAnimate: Bool = false

        func run() async throws {
            do {
                let result = try await MouseInput.moveMouse(x: x, y: y, isRelative: relative, animate: !noAnimate)
                try OutputFormatter.output(["result": result])
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct MouseButton: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "mouse-button",
            abstract: "Perform a mouse button action"
        )

        @Option(name: .long)
        var button: String

        @Option(name: .long)
        var action: String

        @Option(name: .long)
        var count: Int32 = 1

        func run() async throws {
            do {
                let result = try await MouseInput.mouseButton(button: button, action: action, count: count)
                try OutputFormatter.output(["result": result])
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct MouseScroll: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "mouse-scroll",
            abstract: "Scroll the mouse wheel"
        )

        @Option(name: .long)
        var amount: Int32

        @Option(name: .long)
        var axis: String

        func run() async throws {
            do {
                let result = try await MouseInput.mouseScroll(amount: amount, axis: axis)
                try OutputFormatter.output(["result": result])
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct MouseLocationCmd: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "mouse-location",
            abstract: "Get current mouse cursor position"
        )

        func run() async throws {
            do {
                let location = try await MouseInput.mouseLocation()
                try OutputFormatter.output(location)
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct Drag: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "drag",
            abstract: "Drag from one position to another"
        )

        @Option(name: .long, help: "Starting X coordinate (defaults to current cursor X)")
        var startX: Int32?

        @Option(name: .long, help: "Starting Y coordinate (defaults to current cursor Y)")
        var startY: Int32?

        @Option(name: .long)
        var endX: Int32

        @Option(name: .long)
        var endY: Int32

        func run() async throws {
            do {
                let sx: Int32
                let sy: Int32
                if let startX = startX, let startY = startY {
                    sx = startX
                    sy = startY
                } else {
                    let location = try await MouseInput.mouseLocation()
                    sx = Int32(location.x)
                    sy = Int32(location.y)
                }
                let result = try await MouseInput.drag(startX: sx, startY: sy, endX: endX, endY: endY)
                try OutputFormatter.output(["result": result])
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct HoldKey: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "hold-key",
            abstract: "Hold keys for a duration then release"
        )

        @Option(name: .long, help: "Keys to hold, joined with + (e.g. shift+down)")
        var keys: String

        @Option(name: .long, help: "Duration in seconds (0-100)")
        var duration: Double

        func run() async throws {
            do {
                let keyNames = keys.split(separator: "+").map(String.init)
                let durationMs = Int(duration * 1000)
                let result = try await KeyboardInput.holdKey(keyNames: keyNames, durationMs: durationMs)
                try OutputFormatter.output(["result": result])
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct IsSystemCombo: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "is-system-combo",
            abstract: "Check if a key combination is a blocked system combo"
        )

        @Option(name: .long, help: "Keys to check, joined with + (e.g. meta+q)")
        var keys: String

        func run() async throws {
            let keyNames = keys.split(separator: "+").map(String.init)
            let result = SystemKeyCombos.isSystemCombo(keyNames)
            try OutputFormatter.output(["isSystemCombo": result])
        }
    }
}
