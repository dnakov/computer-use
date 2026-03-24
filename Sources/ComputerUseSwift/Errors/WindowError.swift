import Foundation

public enum WindowError: LocalizedError {
    case windowNotFound
    case invalidHandleSize(expected: Int, actual: Int)
    case axElementCreationFailed
    case systemWideElementFailed
    case focusedWindowFailed(String)
    case focusedWindowIdFailed
    case attributeCopyFailed(String)
    case windowHandleFailed

    public var errorDescription: String? {
        switch self {
        case .windowNotFound:
            return "Window not found"
        case .invalidHandleSize(let expected, let actual):
            return "expected parameter 'windowHandle' to be the size of a window handle (\(expected) bytes), got \(actual) bytes"
        case .axElementCreationFailed:
            return "Failed to create AXUIElementRef"
        case .systemWideElementFailed:
            return "Failed to create system wide element"
        case .focusedWindowFailed(let detail):
            return "Failed to get focused window: \(detail)"
        case .focusedWindowIdFailed:
            return "Failed to get focused window id"
        case .attributeCopyFailed(let detail):
            return "Failed to copy attribute values: \(detail)"
        case .windowHandleFailed:
            return "Could not get accessibility handle for window"
        }
    }
}
