import Foundation

public enum ClipboardGuard {

    /// Run clipboard guard based on frontmost app tier.
    /// - If entering click-tier: stash clipboard contents, clear clipboard
    /// - If leaving click-tier: restore stashed clipboard
    public static func run(
        session: inout SessionState,
        isClickTier: Bool
    ) {
        if !isClickTier {
            // Restore clipboard if we had stashed it
            if let stash = session.clipboardStash {
                ClipboardManager.write(stash)
                session.clipboardStash = nil
            }
            return
        }

        // Entering click-tier territory: stash clipboard and clear it
        if session.clipboardStash == nil {
            let current = ClipboardManager.read()
            session.clipboardStash = current
        }
        ClipboardManager.write("")
    }

    /// Clipboard guard variant called from ActionDispatcher click paths.
    /// Determines click-tier based on hit-testing the target coordinates.
    public static func `guard`(
        session: inout SessionState,
        x: Double, y: Double
    ) {
        let bundleId = HitTest.appUnderPoint(x: x, y: y)
        let isClickTier: Bool
        if let bundleId = bundleId,
           let grant = session.allowedApps.first(where: { $0.bundleId == bundleId }) {
            isClickTier = grant.tier == .click
        } else {
            isClickTier = false
        }
        run(session: &session, isClickTier: isClickTier)
    }

    /// Check if write_clipboard is allowed given the current frontmost app.
    /// Returns (allowed, error) — if not allowed, error contains the reason.
    public static func canWriteClipboard(session: SessionState) -> (allowed: Bool, error: String?) {
        guard let frontmost = WindowManager.getFrontmostAppInfo() else {
            return (allowed: true, error: nil)
        }

        let allowedMap = Dictionary(
            session.allowedApps.map { ($0.bundleId, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        guard let grant = allowedMap[frontmost.bundleId] else {
            return (allowed: true, error: nil)
        }

        if grant.tier == .click {
            let error = "\"\(frontmost.appName)\" is a tier-\"click\" app and currently frontmost. write_clipboard is blocked because the next action would clear the clipboard anyway — a UI Paste button in this app cannot be used to inject text. Bring a tier-\"full\" app forward before writing to the clipboard. Do not attempt to work around this restriction — never use AppleScript, System Events, shell commands, or any other method to send clicks or keystrokes to this app."
            return (allowed: false, error: error)
        }

        return (allowed: true, error: nil)
    }
}
