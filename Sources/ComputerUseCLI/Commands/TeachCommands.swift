import ArgumentParser
import ComputerUseSwift
import Foundation

struct TeachGroup: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "teach",
        abstract: "Teach mode overlay commands",
        subcommands: [ShowStep.self, TeachBatch.self]
    )

    // MARK: - teach show-step (single step, no actions)

    struct ShowStep: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "show-step",
            abstract: "Show a single teach tooltip and wait for Next/Exit"
        )

        @Option(name: .long) var explanation: String
        @Option(name: .long) var nextPreview: String = ""
        @Option(name: .long) var anchorX: Double?
        @Option(name: .long) var anchorY: Double?

        func run() async throws {
            let action = try await launchOneStep(
                explanation: explanation,
                nextPreview: nextPreview,
                anchorX: anchorX,
                anchorY: anchorY
            )
            try OutputFormatter.output(["action": action])
        }
    }

    // MARK: - teach batch (multi-step with actions — matches JS spec teach_batch)

    struct TeachBatch: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "batch",
            abstract: "Execute a teach session: show tooltips, wait for Next, execute actions between steps"
        )

        @Option(name: .long, help: "Session ID for action execution")
        var sessionId: String

        @Option(name: .long, help: "JSON array of steps: [{explanation, next_preview, anchor?, actions?}]")
        var steps: String

        func run() async throws {
            // Parse steps JSON
            guard let data = steps.data(using: .utf8),
                  let parsed = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                OutputFormatter.exitWithError("Invalid steps JSON. Expected array of step objects.")
            }

            // Validate all steps upfront (before showing any UI)
            var teachSteps: [ParsedTeachStep] = []
            for (i, stepDict) in parsed.enumerated() {
                guard let explanation = stepDict["explanation"] as? String else {
                    OutputFormatter.exitWithError("Step \(i): missing 'explanation'")
                }
                let nextPreview = stepDict["next_preview"] as? String ?? ""
                let anchor = stepDict["anchor"] as? [Double]
                let actions = stepDict["actions"] as? [[String: Any]] ?? []

                // Validate actions if present
                for (j, action) in actions.enumerated() {
                    guard let _ = action["action"] as? String else {
                        OutputFormatter.exitWithError("Step \(i), action \(j): missing 'action' field")
                    }
                }

                teachSteps.append(ParsedTeachStep(
                    explanation: explanation,
                    nextPreview: nextPreview,
                    anchorX: anchor?.first,
                    anchorY: anchor?.count == 2 ? anchor![1] : nil,
                    actions: actions
                ))
            }

            guard !teachSteps.isEmpty else {
                OutputFormatter.exitWithError("Steps array is empty")
            }

            // Execute steps sequentially
            var results: [StepOutput] = []
            var stepsCompleted = 0

            for (i, step) in teachSteps.enumerated() {
                // Show tooltip, wait for Next or Exit
                let action = try await launchOneStep(
                    explanation: step.explanation,
                    nextPreview: step.nextPreview,
                    anchorX: step.anchorX,
                    anchorY: step.anchorY
                )

                if action == "exit" {
                    results.append(StepOutput(stepIndex: i, action: "exit", actionResults: nil, error: nil))
                    try OutputFormatter.output(TeachBatchResult(
                        exited: true,
                        stepsCompleted: stepsCompleted,
                        results: results
                    ))
                    return
                }

                // User clicked Next — execute this step's actions
                if !step.actions.isEmpty {
                    do {
                        let batchResult = try await SessionLifecycle.executeBatch(
                            sessionId: sessionId,
                            actions: step.actions
                        )

                        if let failedAt = batchResult.failedAt {
                            results.append(StepOutput(
                                stepIndex: i,
                                action: "next",
                                actionResults: batchResult.completed.count,
                                error: "Action \(failedAt) failed: \(batchResult.error ?? "unknown")"
                            ))
                            try OutputFormatter.output(TeachBatchResult(
                                exited: false,
                                stepsCompleted: stepsCompleted,
                                results: results,
                                stepFailed: i,
                                error: batchResult.error
                            ))
                            return
                        }

                        results.append(StepOutput(
                            stepIndex: i,
                            action: "next",
                            actionResults: batchResult.completed.count,
                            error: nil
                        ))
                    } catch {
                        results.append(StepOutput(
                            stepIndex: i,
                            action: "next",
                            actionResults: 0,
                            error: error.localizedDescription
                        ))
                        try OutputFormatter.output(TeachBatchResult(
                            exited: false,
                            stepsCompleted: stepsCompleted,
                            results: results,
                            stepFailed: i,
                            error: error.localizedDescription
                        ))
                        return
                    }
                } else {
                    results.append(StepOutput(stepIndex: i, action: "next", actionResults: 0, error: nil))
                }

                stepsCompleted += 1
            }

            // All steps completed — take trailing screenshot if any step had actions
            let hadActions = teachSteps.contains { !$0.actions.isEmpty }
            if hadActions {
                _ = try? await SessionLifecycle.executeAction(
                    sessionId: sessionId,
                    action: "screenshot",
                    args: [:]
                )
            }

            try OutputFormatter.output(TeachBatchResult(
                exited: false,
                stepsCompleted: stepsCompleted,
                results: results
            ))
        }
    }
}

// MARK: - Models

private struct ParsedTeachStep {
    let explanation: String
    let nextPreview: String
    let anchorX: Double?
    let anchorY: Double?
    let actions: [[String: Any]]
}

private struct StepOutput: Codable {
    let stepIndex: Int
    let action: String
    let actionResults: Int?
    let error: String?
}

private struct TeachBatchResult: Codable {
    let exited: Bool
    let stepsCompleted: Int
    let results: [StepOutput]
    var stepFailed: Int? = nil
    var error: String? = nil
}

// MARK: - Overlay launcher (one step at a time)

private func launchOneStep(
    explanation: String,
    nextPreview: String,
    anchorX: Double?,
    anchorY: Double?
) async throws -> String {
    struct StepInput: Codable {
        let explanation: String
        let nextPreview: String
        let anchorX: Double?
        let anchorY: Double?
    }
    struct Input: Codable {
        let steps: [StepInput]
    }
    struct OverlayResult: Codable {
        let results: [ResultItem]?
        let completed: Bool?
        let stepsCompleted: Int?
    }
    struct ResultItem: Codable {
        let stepIndex: Int
        let action: String
    }

    let input = Input(steps: [StepInput(
        explanation: explanation,
        nextPreview: nextPreview,
        anchorX: anchorX,
        anchorY: anchorY
    )])
    let jsonData = try JSONEncoder().encode(input)
    let jsonStr = String(data: jsonData, encoding: .utf8)!

    // Find teach-overlay binary
    let selfPath = ProcessInfo.processInfo.arguments[0]
    let resolvedSelf = URL(fileURLWithPath: selfPath).resolvingSymlinksInPath()
    let candidates = [
        // App bundle next to computer-use binary
        resolvedSelf.deletingLastPathComponent()
            .appendingPathComponent("TeachOverlay.app/Contents/MacOS/teach-overlay").path,
        // Plain binary next to computer-use binary (debug builds, symlinked installs)
        resolvedSelf.deletingLastPathComponent()
            .appendingPathComponent("teach-overlay").path,
        // Fallback: check common build paths relative to source
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent().deletingLastPathComponent()
            .appendingPathComponent(".build/debug/teach-overlay").path,
    ]
    guard let teachBinary = candidates.first(where: { FileManager.default.fileExists(atPath: $0) }) else {
        throw NSError(domain: "TeachOverlay", code: 1,
                      userInfo: [NSLocalizedDescriptionKey: "teach-overlay binary not found"])
    }

    let process = Process()
    process.executableURL = URL(fileURLWithPath: teachBinary)
    process.arguments = [jsonStr]
    let stdout = Pipe()
    process.standardOutput = stdout

    try process.run()
    process.waitUntilExit()

    let outputData = stdout.fileHandleForReading.readDataToEndOfFile()
    let outputStr = String(data: outputData, encoding: .utf8) ?? ""

    // Parse result to get action
    if let resultData = outputStr.data(using: .utf8),
       let result = try? JSONDecoder().decode(OverlayResult.self, from: resultData),
       let first = result.results?.first {
        return first.action
    }

    return "exit" // default if parsing fails
}
