import Foundation

public enum PolicyBlockedApps {

    // MARK: - Blocked bundle IDs

    private static let blockedBundleIds: Set<String> = [
        // Apple media
        "com.apple.TV",
        "com.apple.Music",
        "com.apple.iBooksX",
        "com.apple.podcasts",
        // Streaming music
        "com.spotify.client",
        "com.amazon.music",
        "com.tidal.desktop",
        "com.deezer.Deezer",
        "com.pandora.desktop",
        // Podcasts
        "au.com.shiftyjelly.pocketcasts",
        // Media servers / players
        "tv.plex.desktop",
        "tv.plex.plexamp",
        "tv.plex.htpc",
        // Video streaming
        "com.amazon.aiv.AIVApp",
        // E-readers
        "net.kovidgoyal.calibre",
        "com.amazon.Kindle",
        "com.kobo.KoboDesktop",
    ]

    // MARK: - Blocked display name substrings

    private static let blockedNames = [
        "netflix", "disney+", "hulu", "prime video", "apple tv",
        "peacock", "paramount+", "tubi", "crunchyroll", "vudu",
        "kindle", "apple books", "kobo", "calibre", "libby", "audible",
        "spotify", "apple music", "youtube music", "tidal", "deezer",
        "pandora",
    ]

    // MARK: - Public API

    public static func isBlocked(bundleId: String?, displayName: String?) -> Bool {
        if let bid = bundleId, blockedBundleIds.contains(bid) {
            return true
        }

        if let name = displayName?.lowercased() {
            if blockedNames.contains(where: { name.contains($0) }) {
                return true
            }
        }

        return false
    }
}
