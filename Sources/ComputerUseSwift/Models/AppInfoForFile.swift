import Foundation

public struct AppInfoForFile: Codable {
    public let appName: String
    public let appIconBase64: String

    public init(appName: String, appIconBase64: String) {
        self.appName = appName
        self.appIconBase64 = appIconBase64
    }
}
