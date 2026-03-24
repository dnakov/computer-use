import Foundation

public enum ScreenshotFilter {

    /// Build list of bundle IDs to exclude from screenshots.
    /// Excludes all running apps NOT in the allowed list, plus the host app.
    public static func buildExcludeList(
        session: SessionState,
        hostBundleId: String? = nil
    ) -> [String] {
        return buildExcludeList(allowedApps: session.allowedApps, hostBundleId: hostBundleId)
    }

    /// Build list of bundle IDs to exclude from screenshots (from allowed apps list directly).
    public static func buildExcludeList(
        allowedApps: [GrantedApp],
        hostBundleId: String? = nil
    ) -> [String] {
        let allowed = Set(allowedApps.map { $0.bundleId })
        let running = AppManager.listRunning()

        var excluded = running.compactMap { app -> String? in
            guard let bundleId = app.bundleIdentifier,
                  !allowed.contains(bundleId) else {
                return nil
            }
            return bundleId
        }

        if let hostId = hostBundleId, !excluded.contains(hostId) {
            excluded.append(hostId)
        }

        return excluded
    }
}
