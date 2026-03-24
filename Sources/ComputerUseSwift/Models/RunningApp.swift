import Foundation

public struct RunningApp: Codable {
    public let bundleIdentifier: String?
    public let localizedName: String?

    public init(bundleIdentifier: String?, localizedName: String?) {
        self.bundleIdentifier = bundleIdentifier
        self.localizedName = localizedName
    }
}
