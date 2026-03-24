import Foundation

public struct FrontmostAppInfo: Codable {
    public let appName: String
    public let bundleId: String
    public let appIconBase64: String

    public init(appName: String, bundleId: String, appIconBase64: String) {
        self.appName = appName
        self.bundleId = bundleId
        self.appIconBase64 = appIconBase64
    }
}
