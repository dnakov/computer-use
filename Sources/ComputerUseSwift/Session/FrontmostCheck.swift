import Foundation

/// Action categories for tier-based permission checking.
/// Note: ActionDispatcher.ActionCategory has additional cases (.screenshot, .none);
/// this enum is for the core tier-check logic.
public enum ActionCategory: String {
    case mousePosition    // always allowed
    case mouse           // plain left click, scroll — needs click or full
    case mouseFull       // right-click, middle-click, modifier-click, drag — needs full
    case keyboard        // type, key, hold_key — needs full
}

public enum FrontmostCheck {

    public struct CheckResult {
        public let allowed: Bool
        public let error: String?
        public let frontmostApp: FrontmostAppInfo?
    }

    /// Check if the current action is allowed based on frontmost app tier.
    /// Mutates session for clipboard guard side effects.
    /// Throws if the action is blocked.
    @discardableResult
    public static func check(
        session: inout SessionState,
        gates: SubGates,
        category: ActionDispatcher.ActionCategory
    ) async throws -> CheckResult {
        // Map dispatcher category to core category
        guard let coreCategory = mapCategory(category) else {
            // .screenshot, .none — always allowed, no frontmost check needed
            return CheckResult(allowed: true, error: nil, frontmostApp: nil)
        }

        // 1. If hideBeforeAction: prepare display
        if gates.hideBeforeAction {
            let allowedBundleIds = session.allowedApps.map(\.bundleId)
            let result = await AppManager.prepareDisplay(
                allowedBundleIds: allowedBundleIds,
                hostBundleId: BundleIDs.finder
            )
            for bundleId in result.hidden {
                session.hiddenDuringTurn.insert(bundleId)
            }
        }

        // 2. Get frontmost app
        guard let frontmost = WindowManager.getFrontmostAppInfo() else {
            return CheckResult(allowed: true, error: nil, frontmostApp: nil)
        }

        let bundleId = frontmost.bundleId
        let displayName = frontmost.appName

        // 3. Clipboard guard based on frontmost tier
        if gates.clipboardGuard {
            let allowedMap = Dictionary(
                session.allowedApps.map { ($0.bundleId, $0) },
                uniquingKeysWith: { first, _ in first }
            )
            let isClickTier = allowedMap[bundleId]?.tier == .click
            ClipboardGuard.run(session: &session, isClickTier: isClickTier)
        }

        // 4. Build allowed map: bundleId → GrantedApp
        let allowedMap = Dictionary(
            session.allowedApps.map { ($0.bundleId, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        // 5. If frontmost is in allowed list
        if let grant = allowedMap[bundleId] {
            if isActionAllowed(tier: grant.tier, category: coreCategory) {
                return CheckResult(allowed: true, error: nil, frontmostApp: frontmost)
            }

            // Action not allowed at this tier
            let error = tierErrorMessage(
                displayName: displayName,
                tier: grant.tier,
                category: coreCategory,
                bundleId: bundleId,
                isHitTest: false
            )
            throw ActionDispatcher.DispatchError.executorThrew(error)
        }

        // 6. Finder bypass — always allowed
        if bundleId == BundleIDs.finder {
            return CheckResult(allowed: true, error: nil, frontmostApp: frontmost)
        }

        // 7. Not in allowed list
        let error = "\"\(displayName)\" is not in the allowed applications and is currently in front. Take a fresh screenshot to see the current window layout."
        throw ActionDispatcher.DispatchError.executorThrew(error)
    }

    /// Check if the current action is allowed (non-mutating, non-throwing variant).
    public static func check(
        session: SessionState,
        actionCategory: ActionCategory,
        hostBundleId: String? = nil
    ) -> CheckResult {
        // Get frontmost app
        guard let frontmost = WindowManager.getFrontmostAppInfo() else {
            return CheckResult(allowed: true, error: nil, frontmostApp: nil)
        }

        let bundleId = frontmost.bundleId
        let displayName = frontmost.appName

        // Build allowed map
        let allowedMap = Dictionary(
            session.allowedApps.map { ($0.bundleId, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        // If frontmost is in allowed list
        if let grant = allowedMap[bundleId] {
            if isActionAllowed(tier: grant.tier, category: actionCategory) {
                return CheckResult(allowed: true, error: nil, frontmostApp: frontmost)
            }
            let error = tierErrorMessage(
                displayName: displayName,
                tier: grant.tier,
                category: actionCategory,
                bundleId: bundleId,
                isHitTest: false
            )
            return CheckResult(allowed: false, error: error, frontmostApp: frontmost)
        }

        // Finder bypass
        if bundleId == BundleIDs.finder {
            return CheckResult(allowed: true, error: nil, frontmostApp: frontmost)
        }

        // Host app check
        if let hostId = hostBundleId, bundleId == hostId {
            if actionCategory == .keyboard {
                return CheckResult(
                    allowed: false,
                    error: "\(displayName)'s own window still has keyboard focus. Click on the target application first.",
                    frontmostApp: frontmost
                )
            }
            return CheckResult(allowed: true, error: nil, frontmostApp: frontmost)
        }

        // Not in allowed list
        let error = "\"\(displayName)\" is not in the allowed applications and is currently in front. Take a fresh screenshot to see the current window layout."
        return CheckResult(allowed: false, error: error, frontmostApp: frontmost)
    }

    /// Check if an action category is allowed at a given tier.
    public static func isActionAllowed(tier: AppTier, category: ActionCategory) -> Bool {
        switch category {
        case .mousePosition:
            return true
        case .keyboard, .mouseFull:
            return tier == .full
        case .mouse:
            return tier == .click || tier == .full
        }
    }

    /// Build the appropriate error message for tier restrictions.
    static func tierErrorMessage(
        displayName: String,
        tier: AppTier,
        category: ActionCategory,
        bundleId: String,
        isHitTest: Bool
    ) -> String {
        if isHitTest {
            return hitTestTierError(displayName: displayName, tier: tier, category: category, bundleId: bundleId)
        }

        switch tier {
        case .read:
            let isBrowser = AppClassification.classify(bundleId: bundleId, displayName: displayName) == .browser
            if isBrowser {
                return "\"\(displayName)\" is granted at tier \"read\" — visible in screenshots only, no clicks or typing. Use the Browser Extension MCP for browser interaction (tools named `mcp__Browser_Extension__*`; load via ToolSearch if deferred). Do not attempt to work around this restriction — never use AppleScript, System Events, shell commands, or any other method to send clicks or keystrokes to this app."
            } else {
                return "\"\(displayName)\" is granted at tier \"read\" — visible in screenshots only, no clicks or typing. No interaction is permitted; ask the user to take any actions in this app themselves. Do not attempt to work around this restriction — never use AppleScript, System Events, shell commands, or any other method to send clicks or keystrokes to this app."
            }
        case .click:
            if category == .keyboard {
                return "\"\(displayName)\" is granted at tier \"click\" — typing, key presses, and paste require tier \"full\". The keys would go to this app's text fields or integrated terminal. To type into a different app, click it first to bring it forward. For shell commands, use the Bash tool. Do not attempt to work around this restriction — never use AppleScript, System Events, shell commands, or any other method to send clicks or keystrokes to this app."
            } else {
                // mouseFull
                return "\"\(displayName)\" is granted at tier \"click\" — right-click, middle-click, and clicks with modifier keys require tier \"full\". Right-click opens a context menu with Paste/Cut, and modifier chords fire as keystrokes before the click. Plain left_click is allowed here. Do not attempt to work around this restriction — never use AppleScript, System Events, shell commands, or any other method to send clicks or keystrokes to this app."
            }
        case .full:
            return ""
        }
    }

    private static func hitTestTierError(
        displayName: String,
        tier: AppTier,
        category: ActionCategory,
        bundleId: String
    ) -> String {
        switch tier {
        case .read:
            let isBrowser = AppClassification.classify(bundleId: bundleId, displayName: displayName) == .browser
            if isBrowser {
                return "Click at these coordinates would land on \"\(displayName)\", which is granted at tier \"read\" (screenshots only, no interaction). Use the Browser Extension MCP for browser interaction. Do not attempt to work around this restriction — never use AppleScript, System Events, shell commands, or any other method to send clicks or keystrokes to this app."
            } else {
                return "Click at these coordinates would land on \"\(displayName)\", which is granted at tier \"read\" (screenshots only, no interaction). Ask the user to take any actions in this app themselves. Do not attempt to work around this restriction — never use AppleScript, System Events, shell commands, or any other method to send clicks or keystrokes to this app."
            }
        case .click:
            return "Click at these coordinates would land on \"\(displayName)\", which is granted at tier \"click\" — right-click, middle-click, and clicks with modifier keys require tier \"full\" (they can Paste via the context menu or fire modifier-chord keystrokes). Plain left_click is allowed here. Do not attempt to work around this restriction — never use AppleScript, System Events, shell commands, or any other method to send clicks or keystrokes to this app."
        case .full:
            return ""
        }
    }

    /// Map ActionDispatcher.ActionCategory to core ActionCategory.
    private static func mapCategory(_ category: ActionDispatcher.ActionCategory) -> ActionCategory? {
        switch category {
        case .mouse: return .mouse
        case .mouseFull: return .mouseFull
        case .mousePosition: return .mousePosition
        case .keyboard: return .keyboard
        case .screenshot, .none: return nil
        }
    }
}
