import Foundation

public struct FindWindowDisplaysResult: Codable {
    public let displayIds: [Int]

    public init(displayIds: [Int]) {
        self.displayIds = displayIds
    }
}
