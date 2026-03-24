import Foundation

public enum GrantManager {

    // MARK: - Types

    public struct GrantRequest {
        public let apps: [String]
        public let reason: String
        public let clipboardRead: Bool
        public let clipboardWrite: Bool
        public let systemKeyCombos: Bool

        public init(
            apps: [String],
            reason: String,
            clipboardRead: Bool = false,
            clipboardWrite: Bool = false,
            systemKeyCombos: Bool = false
        ) {
            self.apps = apps
            self.reason = reason
            self.clipboardRead = clipboardRead
            self.clipboardWrite = clipboardWrite
            self.systemKeyCombos = systemKeyCombos
        }
    }

    public struct GrantResult: Codable {
        public let granted: [GrantedApp]
        public let denied: [DeniedApp]
        public let policyDenied: [DeniedApp]
        public let tierGuidance: String?

        public init(
            granted: [GrantedApp],
            denied: [DeniedApp],
            policyDenied: [DeniedApp],
            tierGuidance: String?
        ) {
            self.granted = granted
            self.denied = denied
            self.policyDenied = policyDenied
            self.tierGuidance = tierGuidance
        }
    }

    public struct DeniedApp: Codable {
        public let name: String
        public let reason: String

        public init(name: String, reason: String) {
            self.name = name
            self.reason = reason
        }
    }

    // MARK: - Bundle ID pattern

    /// Matches strings that look like reverse-DNS bundle IDs.
    private static let bundleIdPattern = try! NSRegularExpression(
        pattern: #"^[A-Za-z0-9][\w.\-]*\.[A-Za-z0-9][\w.\-]*$"#
    )

    private static func looksLikeBundleId(_ name: String) -> Bool {
        let range = NSRange(name.startIndex..., in: name)
        return bundleIdPattern.firstMatch(in: name, range: range) != nil
    }

    // MARK: - App resolution

    /// Resolve a single requested name against the installed apps list.
    /// Returns the matched InstalledApp or nil.
    private static func resolveApp(
        name: String,
        installedApps: [InstalledApp]
    ) -> InstalledApp? {
        if looksLikeBundleId(name) {
            // Try exact bundle ID match
            if let match = installedApps.first(where: { $0.bundleId == name }) {
                return match
            }
        }
        // Case-insensitive display name match
        let lower = name.lowercased()
        return installedApps.first(where: { $0.displayName.lowercased() == lower })
    }

    // MARK: - Public API

    /// Resolve app names to bundle IDs, check policy, assign tiers.
    public static func resolve(
        request: GrantRequest,
        installedApps: [InstalledApp],
        userDeniedBundleIds: Set<String> = []
    ) -> GrantResult {
        var granted: [GrantedApp] = []
        var denied: [DeniedApp] = []
        var policyDenied: [DeniedApp] = []
        let now = Date()

        for name in request.apps {
            guard let resolved = resolveApp(name: name, installedApps: installedApps) else {
                denied.append(DeniedApp(name: name, reason: "not_installed"))
                continue
            }

            // Check policy block
            if PolicyBlockedApps.isBlocked(bundleId: resolved.bundleId, displayName: resolved.displayName) {
                policyDenied.append(DeniedApp(
                    name: resolved.displayName,
                    reason: "\(resolved.displayName) is blocked by policy for computer use. Requests for this app are automatically denied regardless of what the user has approved. There is no Settings override."
                ))
                continue
            }

            // Check user deny list
            if userDeniedBundleIds.contains(resolved.bundleId) {
                denied.append(DeniedApp(
                    name: resolved.displayName,
                    reason: "user_denied"
                ))
                continue
            }

            // Assign tier
            let tier = AppClassification.tier(
                bundleId: resolved.bundleId,
                displayName: resolved.displayName
            )

            granted.append(GrantedApp(
                bundleId: resolved.bundleId,
                displayName: resolved.displayName,
                grantedAt: now,
                tier: tier
            ))
        }

        let guidance = tierGuidance(for: granted)

        return GrantResult(
            granted: granted,
            denied: denied,
            policyDenied: policyDenied,
            tierGuidance: guidance
        )
    }

    /// Merge new grants into existing session state.
    /// Matches JS spec's AUe() function.
    public static func merge(
        existing: [GrantedApp],
        existingFlags: GrantFlags,
        result: GrantResult,
        requestedFlags: GrantFlags
    ) -> (apps: [GrantedApp], flags: GrantFlags) {
        let existingIds = Set(existing.map { $0.bundleId })
        let newApps = result.granted.filter { !existingIds.contains($0.bundleId) }
        let apps = existing + newApps

        // Merge flags: once true, stays true
        let flags = GrantFlags(
            clipboardRead: existingFlags.clipboardRead || requestedFlags.clipboardRead,
            clipboardWrite: existingFlags.clipboardWrite || requestedFlags.clipboardWrite,
            systemKeyCombos: existingFlags.systemKeyCombos || requestedFlags.systemKeyCombos
        )

        return (apps: apps, flags: flags)
    }

    /// Prune expired grants. Matches JS spec's WQe().
    public static func prune(
        apps: [GrantedApp],
        now: Date = Date(),
        ttl: TimeInterval = 1800 // 30 minutes
    ) -> [GrantedApp] {
        let hasExpired = apps.contains { now.timeIntervalSince($0.grantedAt) >= ttl }
        guard hasExpired else { return apps }
        return apps.filter { now.timeIntervalSince($0.grantedAt) < ttl }
    }

    // MARK: - Tier guidance

    private static let workaroundSuffix =
        " Do not attempt to work around this restriction — never use AppleScript, System Events, shell commands, or any other method to send clicks or keystrokes to this app."

    /// Generate tier guidance message for restricted apps.
    public static func tierGuidance(for apps: [GrantedApp]) -> String? {
        var messages: [String] = []

        let readApps = apps.filter { $0.tier == .read }
        let clickApps = apps.filter { $0.tier == .click }

        for app in readApps {
            messages.append(
                "\"\(app.displayName)\" is granted at tier \"read\" — visible in screenshots only. Ask the user to take any actions."
                + workaroundSuffix
            )
        }

        for app in clickApps {
            messages.append(
                "\"\(app.displayName)\" is granted at tier \"click\" — visible + plain left-click only; NO typing, key presses, right-click, modifier-clicks, or drag-drop."
                + workaroundSuffix
            )
        }

        return messages.isEmpty ? nil : messages.joined(separator: "\n")
    }
}
