import ArgumentParser
import ComputerUseSwift
import Foundation

struct SessionGroup: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "session",
        abstract: "Session management commands",
        subcommands: [
            Start.self,
            End.self,
            Grant.self,
            Status.self,
            Revoke.self,
            Action.self,
            Batch.self,
            List.self,
            Lock.self,
        ]
    )

    // MARK: - Start

    struct Start: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "start",
            abstract: "Start a new session, creating state and acquiring lock"
        )

        @Option(name: .long, help: "Session identifier")
        var id: String

        func run() async throws {
            do {
                let state = try SessionLifecycle.start(sessionId: id)
                let result = StartResult(
                    sessionId: state.sessionId,
                    status: "started",
                    createdAt: state.createdAt.timeIntervalSince1970 * 1000
                )
                try OutputFormatter.output(result)
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    private struct StartResult: Encodable {
        let sessionId: String
        let status: String
        let createdAt: Double
    }

    // MARK: - End

    struct End: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "end",
            abstract: "End a session: unhide apps, restore clipboard, release lock"
        )

        @Option(name: .long, help: "Session identifier")
        var id: String

        func run() async throws {
            do {
                try SessionLifecycle.end(sessionId: id)
                let result = EndResult(sessionId: id, status: "ended")
                try OutputFormatter.output(result)
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    private struct EndResult: Encodable {
        let sessionId: String
        let status: String
    }

    // MARK: - Grant

    struct Grant: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "grant",
            abstract: "Grant access to applications for a session"
        )

        @Option(name: .long, help: "Session identifier")
        var id: String

        @Option(name: .long, parsing: .upToNextOption, help: "Application names or bundle IDs")
        var apps: [String]

        @Option(name: .long, help: "Reason for access")
        var reason: String

        @Flag(name: .long, help: "Request clipboard read permission")
        var clipboardRead: Bool = false

        @Flag(name: .long, help: "Request clipboard write permission")
        var clipboardWrite: Bool = false

        @Flag(name: .long, help: "Request system key combos permission")
        var systemKeyCombos: Bool = false

        @Option(name: .long, parsing: .upToNextOption, help: "User-denied bundle IDs")
        var userDenied: [String] = []

        func run() async throws {
            do {
                let installedApps = try await InstalledAppsCache.shared.list()

                let request = GrantManager.GrantRequest(
                    apps: apps,
                    reason: reason,
                    clipboardRead: clipboardRead,
                    clipboardWrite: clipboardWrite,
                    systemKeyCombos: systemKeyCombos
                )

                let result = try SessionLifecycle.grantAccess(
                    sessionId: id,
                    request: request,
                    installedApps: installedApps,
                    userDeniedBundleIds: Set(userDenied)
                )

                try OutputFormatter.output(result)
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    // MARK: - Status

    struct Status: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "status",
            abstract: "Show full session state"
        )

        @Option(name: .long, help: "Session identifier")
        var id: String

        func run() async throws {
            do {
                let state = try SessionState.load(sessionId: id)
                try OutputFormatter.output(state, pretty: true)
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    // MARK: - Revoke

    struct Revoke: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "revoke",
            abstract: "Revoke a grant from a session"
        )

        @Option(name: .long, help: "Session identifier")
        var id: String

        @Option(name: .long, help: "Bundle ID to revoke")
        var bundleId: String

        func run() async throws {
            do {
                var state = try SessionState.load(sessionId: id)
                let before = state.allowedApps.count
                state.allowedApps.removeAll { $0.bundleId == bundleId }
                let removed = before != state.allowedApps.count
                try state.save()
                let result = RevokeResult(
                    sessionId: id,
                    bundleId: bundleId,
                    revoked: removed
                )
                try OutputFormatter.output(result)
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    private struct RevokeResult: Encodable {
        let sessionId: String
        let bundleId: String
        let revoked: Bool
    }

    // MARK: - Action

    struct Action: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "action",
            abstract: "Execute a single action within a session"
        )

        @Option(name: .long, help: "Session identifier")
        var id: String

        @Option(name: .long, help: "Action name (e.g. left_click, screenshot, type, key, scroll)")
        var action: String

        @Option(name: .long, help: "Coordinates as x,y")
        var coordinate: String?

        @Option(name: .long, help: "Text for type/key actions")
        var text: String?

        @Option(name: .long, help: "Scroll direction (up/down/left/right)")
        var scrollDirection: String?

        @Option(name: .long, help: "Scroll amount (0-100)")
        var scrollAmount: Int?

        @Option(name: .long, help: "Duration in seconds (for wait/hold_key)")
        var duration: Double?

        @Option(name: .long, help: "Repeat count for key action")
        var repeatCount: Int?

        @Option(name: .long, help: "Start coordinate as x,y (for drag)")
        var startCoordinate: String?

        func run() async throws {
            do {
                var args: [String: Any] = [:]

                if let coord = coordinate {
                    let parts = coord.split(separator: ",").compactMap { Double($0) }
                    guard parts.count == 2 else {
                        OutputFormatter.exitWithError("Invalid coordinate format. Use x,y")
                    }
                    args["coordinate"] = [parts[0], parts[1]]
                }

                if let startCoord = startCoordinate {
                    let parts = startCoord.split(separator: ",").compactMap { Double($0) }
                    guard parts.count == 2 else {
                        OutputFormatter.exitWithError("Invalid start_coordinate format. Use x,y")
                    }
                    args["start_coordinate"] = [parts[0], parts[1]]
                }

                if let text = text { args["text"] = text }
                if let dir = scrollDirection { args["scroll_direction"] = dir }
                if let amt = scrollAmount { args["scroll_amount"] = amt }
                if let dur = duration { args["duration"] = dur }
                if let rep = repeatCount { args["repeat"] = rep }

                let result = try await SessionLifecycle.executeAction(
                    sessionId: id,
                    action: action,
                    args: args
                )
                try OutputFormatter.output(result)
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    // MARK: - Batch

    struct Batch: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "batch",
            abstract: "Execute a batch of actions within a session"
        )

        @Option(name: .long, help: "Session identifier")
        var id: String

        @Option(name: .long, help: "JSON array of actions")
        var actions: String

        func run() async throws {
            do {
                guard let data = actions.data(using: .utf8),
                      let parsed = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                    OutputFormatter.exitWithError("Invalid actions JSON. Expected array of action objects.")
                }

                let result = try await SessionLifecycle.executeBatch(
                    sessionId: id,
                    actions: parsed
                )
                try OutputFormatter.output(result)
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    // MARK: - List

    struct List: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "list",
            abstract: "List all active sessions"
        )

        func run() async throws {
            do {
                let sessionsDir = FileManager.default.homeDirectoryForCurrentUser
                    .appendingPathComponent(".computer-use/sessions")

                guard FileManager.default.fileExists(atPath: sessionsDir.path) else {
                    try OutputFormatter.output(SessionListResult(sessions: []))
                    return
                }

                let files = try FileManager.default.contentsOfDirectory(
                    at: sessionsDir,
                    includingPropertiesForKeys: nil
                ).filter { $0.pathExtension == "json" }

                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .millisecondsSince1970

                var sessions: [SessionSummary] = []
                for file in files {
                    if let data = try? Data(contentsOf: file),
                       let state = try? decoder.decode(SessionState.self, from: data) {
                        sessions.append(SessionSummary(
                            sessionId: state.sessionId,
                            createdAt: state.createdAt.timeIntervalSince1970 * 1000,
                            appCount: state.allowedApps.count,
                            mouseHeld: state.mouseHeld
                        ))
                    }
                }

                try OutputFormatter.output(SessionListResult(sessions: sessions))
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    private struct SessionListResult: Encodable {
        let sessions: [SessionSummary]
    }

    private struct SessionSummary: Encodable {
        let sessionId: String
        let createdAt: Double
        let appCount: Int
        let mouseHeld: Bool
    }

    // MARK: - Lock

    struct Lock: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "lock",
            abstract: "Check current lock status"
        )

        func run() async throws {
            do {
                if let info = SessionLock.check() {
                    let result = LockResult(
                        held: true,
                        sessionId: info.sessionId,
                        acquiredAt: info.acquiredAt.timeIntervalSince1970 * 1000,
                        pid: info.pid
                    )
                    try OutputFormatter.output(result)
                } else {
                    try OutputFormatter.output(LockResult(
                        held: false,
                        sessionId: nil,
                        acquiredAt: nil,
                        pid: nil
                    ))
                }
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    private struct LockResult: Encodable {
        let held: Bool
        let sessionId: String?
        let acquiredAt: Double?
        let pid: Int32?
    }
}
