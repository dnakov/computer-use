import Foundation

/// Sequential batch action executor matching JS `Iyr()`.
/// Executes a sequence of actions in one call, stopping on first error.
public enum BatchExecutor {

    public struct BatchResult: Codable {
        public let completed: [ActionDispatcher.ActionResult]
        public let failedAt: Int?
        public let error: String?

        public init(
            completed: [ActionDispatcher.ActionResult],
            failedAt: Int? = nil,
            error: String? = nil
        ) {
            self.completed = completed
            self.failedAt = failedAt
            self.error = error
        }
    }

    /// Allowed action names within a batch.
    public static let allowedBatchActions: Set<String> = [
        "key", "type", "mouse_move", "left_click", "left_click_drag",
        "right_click", "middle_click", "double_click", "triple_click",
        "scroll", "hold_key", "screenshot", "cursor_position",
        "left_mouse_down", "left_mouse_up", "wait",
    ]

    /// Execute actions sequentially. Stops on first error.
    ///
    /// Logic (matching JS spec):
    /// 1. Validate all actions have valid `action` field from allowed set
    /// 2. `prepareForAction()` once at start (if hideBeforeAction gate)
    /// 3. Execute each action via `ActionDispatcher.dispatch()` with:
    ///    - `hideBeforeAction: false` (already done)
    ///    - `pixelValidation: false`
    ///    - `autoTargetDisplay: false`
    /// 4. 10ms delay between actions
    /// 5. If any action errors, stop and return partial results
    /// 6. Return `BatchResult(completed: results, failedAt: nil, error: nil)`
    public static func execute(
        actions: [[String: Any]],
        session: inout SessionState,
        gates: SubGates
    ) async throws -> BatchResult {
        // 1. Validate all actions
        for (index, actionDict) in actions.enumerated() {
            guard let actionName = actionDict["action"] as? String else {
                return BatchResult(
                    completed: [],
                    failedAt: index,
                    error: "Action at index \(index) missing 'action' field"
                )
            }
            guard allowedBatchActions.contains(actionName) else {
                return BatchResult(
                    completed: [],
                    failedAt: index,
                    error: "Action '\(actionName)' at index \(index) is not allowed in batch. Allowed: \(allowedBatchActions.sorted().joined(separator: ", "))"
                )
            }
        }

        // 2. Prepare display once at start (if hideBeforeAction gate)
        if gates.hideBeforeAction {
            // Capture window z-order before hiding
            if session.windowStackBeforeHide.isEmpty {
                session.windowStackBeforeHide = AppManager.captureWindowStack()
            }

            let allowedBundleIds = session.allowedApps.map(\.bundleId)
            let result = await AppManager.prepareDisplay(
                allowedBundleIds: allowedBundleIds,
                hostBundleId: BundleIDs.finder
            )
            for bundleId in result.hidden {
                session.hiddenDuringTurn.insert(bundleId)
            }
        }

        // Sub-action gates: override certain gates for batch sub-actions
        var subGates = gates
        subGates.hideBeforeAction = false
        subGates.pixelValidation = false
        subGates.autoTargetDisplay = false

        // 3. Execute each action sequentially
        var completed: [ActionDispatcher.ActionResult] = []

        for (index, actionDict) in actions.enumerated() {
            let actionName = actionDict["action"] as! String
            var args = actionDict
            args.removeValue(forKey: "action")

            // 10ms delay between actions (not before the first)
            if index > 0 {
                try await Task.sleep(nanoseconds: 10_000_000)
            }

            do {
                let result = try await ActionDispatcher.dispatch(
                    action: actionName,
                    args: args,
                    session: &session,
                    gates: subGates
                )

                // Check if result is an error
                if result.isError == true {
                    completed.append(result)
                    let errorText = result.content.compactMap { item -> String? in
                        if case .text(let t) = item { return t }
                        return nil
                    }.joined()
                    return BatchResult(
                        completed: completed,
                        failedAt: index,
                        error: errorText
                    )
                }

                completed.append(result)
            } catch {
                return BatchResult(
                    completed: completed,
                    failedAt: index,
                    error: error.localizedDescription
                )
            }
        }

        // 6. All actions succeeded
        return BatchResult(completed: completed, failedAt: nil, error: nil)
    }
}
