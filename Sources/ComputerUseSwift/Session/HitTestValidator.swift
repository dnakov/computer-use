import Foundation

public enum HitTestValidator {

    public struct ValidationResult {
        public let allowed: Bool
        public let error: String?
        public let bundleId: String?
    }

    /// Validate that clicking at (x, y) would hit an allowed app at the right tier.
    /// Throws if the action is blocked (matches ActionDispatcher call sites).
    @discardableResult
    public static func validate(
        session: SessionState,
        gates: SubGates,
        x: Double, y: Double,
        category: ActionDispatcher.ActionCategory
    ) throws -> ValidationResult {
        // Map dispatcher category to core category
        guard let coreCategory = mapCategory(category) else {
            return ValidationResult(allowed: true, error: nil, bundleId: nil)
        }

        let result = validateCore(x: x, y: y, session: session, actionCategory: coreCategory)
        if !result.allowed, let error = result.error {
            throw ActionDispatcher.DispatchError.executorThrew(error)
        }
        return result
    }

    /// Validate that clicking at (x, y) would hit an allowed app at the right tier.
    /// Non-throwing variant returns the result directly.
    public static func validate(
        x: Double, y: Double,
        session: SessionState,
        actionCategory: ActionCategory
    ) -> ValidationResult {
        return validateCore(x: x, y: y, session: session, actionCategory: actionCategory)
    }

    // MARK: - Core logic

    private static func validateCore(
        x: Double, y: Double,
        session: SessionState,
        actionCategory: ActionCategory
    ) -> ValidationResult {
        // 1. Check what app is under the point
        let bundleId = HitTest.appUnderPoint(x: x, y: y)

        // 2. If no app or Finder → allowed
        guard let bundleId = bundleId, bundleId != BundleIDs.finder else {
            return ValidationResult(allowed: true, error: nil, bundleId: bundleId)
        }

        // 3. Build allowed map
        let allowedMap = Dictionary(
            session.allowedApps.map { ($0.bundleId, $0) },
            uniquingKeysWith: { first, _ in first }
        )

        // 4. If not in allowed list
        guard let grant = allowedMap[bundleId] else {
            let displayName = displayNameForBundle(bundleId, session: session)
            let error = "Click at these coordinates would land on \"\(displayName)\", which is not in the allowed applications. Take a fresh screenshot to see the current window layout."
            return ValidationResult(allowed: false, error: error, bundleId: bundleId)
        }

        // 5. Check tier
        if FrontmostCheck.isActionAllowed(tier: grant.tier, category: actionCategory) {
            return ValidationResult(allowed: true, error: nil, bundleId: bundleId)
        }

        // Action not allowed at this tier — use hit test variant error messages
        let error = FrontmostCheck.tierErrorMessage(
            displayName: grant.displayName,
            tier: grant.tier,
            category: actionCategory,
            bundleId: bundleId,
            isHitTest: true
        )
        return ValidationResult(allowed: false, error: error, bundleId: bundleId)
    }

    /// Resolve a display name for a bundle ID, checking the session's allowed apps first.
    private static func displayNameForBundle(_ bundleId: String, session: SessionState) -> String {
        if let app = session.allowedApps.first(where: { $0.bundleId == bundleId }) {
            return app.displayName
        }
        let running = AppManager.listRunning()
        if let app = running.first(where: { $0.bundleIdentifier == bundleId }) {
            return app.localizedName ?? bundleId
        }
        return bundleId
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
