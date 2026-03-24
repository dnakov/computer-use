import Foundation

public enum InputError: LocalizedError {
    case invalidKeyName(String)
    case invalidAction(String)
    case invalidButton(String)
    case invalidAxis(String)
    case noKeysProvided
    case emptyText
    case eventCreationFailed(String)
    case keyActionFailed(String)
    case modifierPressFailed(String)
    case modifierReleaseFailed(String)
    case keyPressFailed(String)
    case keyReleaseFailed(String)
    case channelFailed(String)
    case mouseMoveFailed(String)
    case buttonActionFailed(String, Int)
    case scrollFailed(String)
    case mouseLocationFailed(String)

    public var errorDescription: String? {
        switch self {
        case .invalidKeyName(let name):
            return "Invalid key name: \(name). Please use a valid key name."
        case .invalidAction(let action):
            return "Invalid action: \(action). Valid options are: press, release, click"
        case .invalidButton(let button):
            return "Invalid button name: \(button). Valid options are: left, right, middle, scrollUp, scrollDown, scrollLeft, scrollRight"
        case .invalidAxis(let axis):
            return "Invalid axis: \(axis). Valid options are: horizontal, vertical"
        case .noKeysProvided:
            return "No keys provided"
        case .emptyText:
            return "The text to enter was empty"
        case .eventCreationFailed(let detail):
            return "Error performing key action: \(detail)"
        case .keyActionFailed(let detail):
            return "Error performing key action: \(detail)"
        case .modifierPressFailed(let detail):
            return "Error pressing modifier key: \(detail)"
        case .modifierReleaseFailed(let detail):
            return "Error releasing modifier key: \(detail)"
        case .keyPressFailed(let detail):
            return "Error pressing key: \(detail)"
        case .keyReleaseFailed(let detail):
            return "Error releasing key: \(detail)"
        case .channelFailed(let operation):
            return "Failed to receive result from \(operation) operation"
        case .mouseMoveFailed(let detail):
            return "Error moving mouse: \(detail)"
        case .buttonActionFailed(let detail, let attempt):
            return "Error performing button action on attempt \(attempt): \(detail)"
        case .scrollFailed(let detail):
            return "Error performing scroll action: \(detail)"
        case .mouseLocationFailed(let detail):
            return "Error getting mouse location: \(detail)"
        }
    }
}
