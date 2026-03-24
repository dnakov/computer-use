import Foundation

public enum InstalledAppsError: LocalizedError, Hashable, Equatable {
    case queryFailedToStart

    public var errorDescription: String? {
        switch self {
        case .queryFailedToStart:
            return "NSMetadataQuery failed to start (Spotlight may be indexing or disabled)"
        }
    }
}
