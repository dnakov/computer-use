import AppKit

public actor InstalledAppsCache {
    public static let shared = InstalledAppsCache()

    private var cached: [InstalledApp]?
    private var cachedAt: Date?
    private var inFlight: Task<[InstalledApp], Error>?
    private let cacheTTL: TimeInterval = 300

    private init() {}

    public func list() async throws -> [InstalledApp] {
        if let cached = cached, let cachedAt = cachedAt,
           Date().timeIntervalSince(cachedAt) < cacheTTL {
            return cached
        }

        if let inFlight = inFlight {
            return try await inFlight.value
        }

        let task = Task<[InstalledApp], Error> {
            try await InstalledAppsCache.performSpotlightQuery()
        }
        inFlight = task

        do {
            let result = try await task.value
            cached = result
            cachedAt = Date()
            inFlight = nil
            return result
        } catch {
            inFlight = nil
            throw error
        }
    }

    private static func performSpotlightQuery() async throws -> [InstalledApp] {
        try await withCheckedThrowingContinuation { continuation in
            DispatchQueue.main.async {
                let query = NSMetadataQuery()
                query.predicate = NSPredicate(
                    format: "kMDItemContentType == %@",
                    BundleIDs.applicationBundleUTI
                )

                var observer: NSObjectProtocol?
                observer = NotificationCenter.default.addObserver(
                    forName: .NSMetadataQueryDidFinishGathering,
                    object: query,
                    queue: nil
                ) { _ in
                    query.stop()
                    if let observer = observer {
                        NotificationCenter.default.removeObserver(observer)
                    }

                    var apps: [InstalledApp] = []
                    for i in 0..<query.resultCount {
                        guard let item = query.result(at: i) as? NSMetadataItem else { continue }

                        guard let bundleId = item.value(forAttribute: kMDItemCFBundleIdentifier as String) as? String else {
                            continue
                        }

                        guard let path = item.value(forAttribute: NSMetadataItemPathKey) as? String else {
                            continue
                        }

                        let displayName = (path as NSString).lastPathComponent
                            .replacingOccurrences(of: ".app", with: "")

                        if InstalledAppsCache.isBackgroundOrAgent(atPath: path) {
                            continue
                        }

                        apps.append(InstalledApp(
                            bundleId: bundleId,
                            displayName: displayName,
                            path: path
                        ))
                    }

                    continuation.resume(returning: apps)
                }

                if !query.start() {
                    if let observer = observer {
                        NotificationCenter.default.removeObserver(observer)
                    }
                    continuation.resume(throwing: InstalledAppsError.queryFailedToStart)
                }
            }
        }
    }

    private static func isBackgroundOrAgent(atPath path: String) -> Bool {
        let infoPlistPath = (path as NSString).appendingPathComponent("Contents/Info.plist")
        guard let plist = NSDictionary(contentsOfFile: infoPlistPath) else {
            return false
        }
        if let bgOnly = plist["LSBackgroundOnly"] as? Bool, bgOnly {
            return true
        }
        return false
    }
}
