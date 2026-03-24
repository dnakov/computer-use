import Foundation

public enum SessionLifecycle {

    // MARK: - Start session

    /// Start a new session: create state, acquire lock.
    public static func start(sessionId: String) throws -> SessionState {
        // Acquire lock
        if let error = SessionLock.acquire(sessionId: sessionId) {
            throw SessionError.lockFailed(error)
        }

        // Create fresh state
        var state = SessionState(sessionId: sessionId)
        state.lockAcquiredAt = Date()
        state.resetMouseState()

        // Persist
        try state.save()

        return state
    }

    // MARK: - End session

    /// End a session: unhide apps, restore clipboard, release mouse, release lock, delete state.
    public static func end(sessionId: String) throws {
        let state: SessionState
        do {
            state = try SessionState.load(sessionId: sessionId)
        } catch {
            // State file might not exist; still release lock
            SessionLock.release(sessionId: sessionId)
            return
        }

        // 1. Auto-unhide all at once, then restore the frontmost app
        if !state.hiddenDuringTurn.isEmpty {
            AppManager.unhideApps(bundleIds: Array(state.hiddenDuringTurn))

            // Restore whichever app was frontmost before we hid everything
            if !state.windowStackBeforeHide.isEmpty {
                Thread.sleep(forTimeInterval: 0.1)
                AppManager.restoreFrontmostApp(from: state.windowStackBeforeHide)
            }
        }

        // 2. Clipboard restore
        if let stash = state.clipboardStash {
            ClipboardManager.write(stash)
        }

        // 3. Release held mouse button
        if state.mouseHeld {
            Task {
                _ = try? await MouseInput.mouseButton(button: "left", action: "release")
            }
        }

        // 4. Release lock
        SessionLock.release(sessionId: sessionId)

        // 5. Delete state file
        try? SessionState.delete(sessionId: sessionId)
    }

    // MARK: - Grant access

    /// Grant access to apps for a session.
    public static func grantAccess(
        sessionId: String,
        request: GrantManager.GrantRequest,
        installedApps: [InstalledApp],
        userDeniedBundleIds: Set<String> = []
    ) throws -> GrantManager.GrantResult {
        var state = try SessionState.load(sessionId: sessionId)

        let result = GrantManager.resolve(
            request: request,
            installedApps: installedApps,
            userDeniedBundleIds: userDeniedBundleIds
        )

        // Merge grants into session
        let requestedFlags = GrantFlags(
            clipboardRead: request.clipboardRead,
            clipboardWrite: request.clipboardWrite,
            systemKeyCombos: request.systemKeyCombos
        )
        let merged = GrantManager.merge(
            existing: state.allowedApps,
            existingFlags: state.grantFlags,
            result: result,
            requestedFlags: requestedFlags
        )

        state.allowedApps = merged.apps
        state.grantFlags = merged.flags
        try state.save()

        return result
    }

    // MARK: - Execute action

    /// Execute a single action within a session with full orchestration.
    public static func executeAction(
        sessionId: String,
        action: String,
        args: [String: Any],
        gates: SubGates = SubGates()
    ) async throws -> ActionDispatcher.ActionResult {
        var state = try SessionState.load(sessionId: sessionId)

        let result = try await ActionDispatcher.dispatch(
            action: action,
            args: args,
            session: &state,
            gates: gates
        )

        try state.save()
        return result
    }

    // MARK: - Execute batch

    /// Execute a batch of actions within a session with full orchestration.
    public static func executeBatch(
        sessionId: String,
        actions: [[String: Any]],
        gates: SubGates = SubGates()
    ) async throws -> BatchExecutor.BatchResult {
        var state = try SessionState.load(sessionId: sessionId)

        let result = try await BatchExecutor.execute(
            actions: actions,
            session: &state,
            gates: gates
        )

        try state.save()
        return result
    }
}

// MARK: - Session errors

public enum SessionError: Error, LocalizedError {
    case lockFailed(String)
    case notFound(String)
    case notImplemented(String)

    public var errorDescription: String? {
        switch self {
        case .lockFailed(let msg): return msg
        case .notFound(let id): return "Session not found: \(id)"
        case .notImplemented(let msg): return msg
        }
    }
}
