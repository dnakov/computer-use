import Foundation

public struct WindowIdResult: Codable {
    public let windowId: UInt32?

    public init(windowId: UInt32?) {
        self.windowId = windowId
    }
}
