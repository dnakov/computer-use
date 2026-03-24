import Foundation

public struct InstalledApp {
    public let bundleId: String
    public let displayName: String
    public let path: String

    public init(bundleId: String, displayName: String, path: String) {
        self.bundleId = bundleId
        self.displayName = displayName
        self.path = path
    }
}

public struct InstalledAppJson: Codable {
    public let bundleId: String
    public let displayName: String
    public let path: String

    public init(from app: InstalledApp) {
        self.bundleId = app.bundleId
        self.displayName = app.displayName
        self.path = app.path
    }
}
