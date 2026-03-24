import AppKit
import CoreGraphics
import Foundation

/// Mouse input simulation using CGEvent APIs.
public enum MouseInput {

    // MARK: - Public API

    /// Moves the mouse cursor to a position, with optional animation.
    ///
    /// - Parameters:
    ///   - x: X coordinate.
    ///   - y: Y coordinate.
    ///   - isRelative: If `false`, moves to absolute position. If `true`, moves relative to current position.
    ///   - animate: If `true`, animates the movement with cubic ease-out. Defaults to `true`.
    /// - Returns: A success message string.
    public static func moveMouse(x: Int32, y: Int32, isRelative: Bool, animate: Bool = true) async throws -> String {
        let source = try createEventSource()
        let current = CGEvent(source: nil)?.location ?? .zero

        let targetPoint: CGPoint
        if isRelative {
            targetPoint = CGPoint(x: current.x + CGFloat(x), y: current.y + CGFloat(y))
        } else {
            targetPoint = CGPoint(x: CGFloat(x), y: CGFloat(y))
        }

        if animate {
            try await moveMouseAnimated(fromX: current.x, fromY: current.y, toX: targetPoint.x, toY: targetPoint.y, eventType: .mouseMoved, source: source)
        } else {
            CGWarpMouseCursorPosition(targetPoint)
        }

        // Post a final mouseMoved event so apps see the movement
        if let event = CGEvent(
            mouseEventSource: source,
            mouseType: .mouseMoved,
            mouseCursorPosition: targetPoint,
            mouseButton: .left
        ) {
            event.post(tap: .cghidEventTap)
        }

        // Match JS spec: 50ms delay after move
        try await Task.sleep(nanoseconds: 50_000_000)

        let mode = isRelative ? "relative" : "absolute"
        return "Successfully moved mouse to \(mode) position: (\(x), \(y))"
    }

    /// Animates the mouse cursor from one position to another using cubic ease-out.
    ///
    /// - Parameters:
    ///   - fromX: Starting X coordinate.
    ///   - fromY: Starting Y coordinate.
    ///   - toX: Ending X coordinate.
    ///   - toY: Ending Y coordinate.
    ///   - eventType: The CGEventType to post during animation (e.g., `.mouseMoved` or `.leftMouseDragged`).
    ///   - source: The CGEventSource to use.
    public static func moveMouseAnimated(
        fromX: CGFloat, fromY: CGFloat,
        toX: CGFloat, toY: CGFloat,
        eventType: CGEventType = .mouseMoved,
        source: CGEventSource? = nil
    ) async throws {
        let eventSource = try source ?? createEventSource()
        let fps: Double = 60
        let frameDuration: UInt64 = UInt64(1_000_000_000 / fps) // ~16.67ms in nanoseconds
        let distance = hypot(toX - fromX, toY - fromY)
        let duration = min(distance / 2000.0, 0.5)
        let totalFrames = Int(floor(duration * fps))

        // Skip animation for short distances (< ~60px, i.e. duration < 0.03s)
        if totalFrames < 2 {
            CGWarpMouseCursorPosition(CGPoint(x: toX, y: toY))
            return
        }

        for frame in 1...totalFrames {
            let t = Double(frame) / Double(totalFrames)
            let eased = 1.0 - pow(1.0 - t, 3.0) // cubic ease-out
            let x = fromX + (toX - fromX) * CGFloat(eased)
            let y = fromY + (toY - fromY) * CGFloat(eased)
            let point = CGPoint(x: x, y: y)

            CGWarpMouseCursorPosition(point)

            if let event = CGEvent(
                mouseEventSource: eventSource,
                mouseType: eventType,
                mouseCursorPosition: point,
                mouseButton: .left
            ) {
                event.post(tap: .cghidEventTap)
            }

            if frame < totalFrames {
                try await Task.sleep(nanoseconds: frameDuration)
            }
        }
    }

    /// Performs a drag operation from one position to another with animated movement.
    ///
    /// - Parameters:
    ///   - startX: Starting X coordinate.
    ///   - startY: Starting Y coordinate.
    ///   - endX: Ending X coordinate.
    ///   - endY: Ending Y coordinate.
    /// - Returns: A success message string.
    public static func drag(
        startX: Int32, startY: Int32,
        endX: Int32, endY: Int32
    ) async throws -> String {
        let source = try createEventSource()
        let startPoint = CGPoint(x: CGFloat(startX), y: CGFloat(startY))
        let endPoint = CGPoint(x: CGFloat(endX), y: CGFloat(endY))

        // 1. Warp to start position
        CGWarpMouseCursorPosition(startPoint)

        // 2. Post mouseDown at start
        guard let downEvent = CGEvent(
            mouseEventSource: source,
            mouseType: .leftMouseDown,
            mouseCursorPosition: startPoint,
            mouseButton: .left
        ) else {
            throw InputError.buttonActionFailed("failed creating mouseDown event for drag", 1)
        }
        downEvent.post(tap: .cghidEventTap)

        // 3. Animate from start to end using leftMouseDragged events
        try await moveMouseAnimated(
            fromX: CGFloat(startX), fromY: CGFloat(startY),
            toX: CGFloat(endX), toY: CGFloat(endY),
            eventType: .leftMouseDragged,
            source: source
        )

        // 4. Post mouseUp at end
        guard let upEvent = CGEvent(
            mouseEventSource: source,
            mouseType: .leftMouseUp,
            mouseCursorPosition: endPoint,
            mouseButton: .left
        ) else {
            throw InputError.buttonActionFailed("failed creating mouseUp event for drag", 1)
        }
        upEvent.post(tap: .cghidEventTap)

        return "Successfully dragged from (\(startX), \(startY)) to (\(endX), \(endY))"
    }

    /// Performs a mouse button action.
    ///
    /// - Parameters:
    ///   - button: One of "left", "right", "middle", "scrollUp", "scrollDown", "scrollLeft", "scrollRight".
    ///   - action: One of "press", "release", "click".
    ///   - count: Click count for multi-click (default 1).
    /// - Returns: A success message string.
    public static func mouseButton(button: String, action: String, count: Int32 = 1) async throws -> String {
        let validButtons = ["left", "right", "middle", "scrollUp", "scrollDown", "scrollLeft", "scrollRight"]
        guard validButtons.contains(button) else {
            throw InputError.invalidButton(button)
        }
        guard ["press", "release", "click"].contains(action) else {
            throw InputError.invalidAction(action)
        }

        // Handle scroll buttons
        let scrollButtons = ["scrollUp", "scrollDown", "scrollLeft", "scrollRight"]
        if scrollButtons.contains(button) {
            if action == "release" {
                // No-op on release for scroll buttons
                return "Successfully released mouse button \(button) \(count) times"
            }
            // Map scroll button to scroll action
            let (amount, axis): (Int32, String) = {
                switch button {
                case "scrollUp":    return (-1, "vertical")
                case "scrollDown":  return (1, "vertical")
                case "scrollLeft":  return (-1, "horizontal")
                case "scrollRight": return (1, "horizontal")
                default:            return (0, "vertical")
                }
            }()
            let clickCount = action == "click" ? count : 1
            for i in 0..<clickCount {
                do {
                    _ = try await mouseScroll(amount: amount, axis: axis)
                } catch {
                    throw InputError.buttonActionFailed(error.localizedDescription, Int(i + 1))
                }
            }
            return "Successfully \(action)ed mouse button \(button) \(count) times"
        }

        // Regular mouse buttons
        let source = try createEventSource()
        let currentPos = CGEvent(source: nil)?.location ?? .zero

        let (downType, upType, cgButton) = try mouseEventTypes(for: button)

        switch action {
        case "press":
            try postMouseEvent(source: source, type: downType, position: currentPos, button: cgButton, clickCount: count, attempt: 1)
        case "release":
            try postMouseEvent(source: source, type: upType, position: currentPos, button: cgButton, clickCount: count, attempt: 1)
        case "click":
            let interval = NSEvent.doubleClickInterval
            for i in 1...count {
                try postMouseEvent(source: source, type: downType, position: currentPos, button: cgButton, clickCount: i, attempt: Int(i))
                if count > 1 {
                    try await Task.sleep(nanoseconds: UInt64(interval * 0.5 * 1_000_000_000))
                }
                try postMouseEvent(source: source, type: upType, position: currentPos, button: cgButton, clickCount: i, attempt: Int(i))
                if i < count && count > 1 {
                    try await Task.sleep(nanoseconds: UInt64(interval * 0.5 * 1_000_000_000))
                }
            }
        default:
            break
        }

        return "Successfully \(action)ed mouse button \(button) \(count) times"
    }

    /// Scrolls the mouse wheel.
    ///
    /// - Parameters:
    ///   - amount: Scroll amount (positive = down/right, negative = up/left).
    ///   - axis: One of "vertical" or "horizontal".
    /// - Returns: A success message string.
    public static func mouseScroll(amount: Int32, axis: String) async throws -> String {
        guard ["vertical", "horizontal"].contains(axis) else {
            throw InputError.invalidAxis(axis)
        }

        let source = try createEventSource()

        let wheel1: Int32 = axis == "vertical" ? amount : 0
        let wheel2: Int32 = axis == "horizontal" ? amount : 0

        guard let event = CGEvent(
            scrollWheelEvent2Source: source,
            units: .pixel,
            wheelCount: 2,
            wheel1: wheel1,
            wheel2: wheel2,
            wheel3: 0
        ) else {
            throw InputError.scrollFailed("failed creating event to scroll")
        }

        event.post(tap: .cghidEventTap)
        return "Successfully scrolled \(amount) with axis \(axis)"
    }

    /// Gets the current mouse cursor position.
    ///
    /// - Returns: A `MouseLocation` with x and y coordinates.
    public static func mouseLocation() async throws -> MouseLocation {
        let location = NSEvent.mouseLocation
        // Convert from AppKit coordinates (bottom-left origin) to screen coordinates (top-left origin)
        guard let screenHeight = NSScreen.main?.frame.height else {
            throw InputError.mouseLocationFailed("could not determine screen height")
        }
        let x = Int(location.x)
        let y = Int(screenHeight - location.y)
        return MouseLocation(x: x, y: y)
    }

    // MARK: - Private Helpers

    private static func createEventSource() throws -> CGEventSource {
        guard let source = CGEventSource(stateID: .hidSystemState) else {
            throw InputError.eventCreationFailed("failed creating event source")
        }
        return source
    }

    private static func mouseEventTypes(for button: String) throws -> (down: CGEventType, up: CGEventType, button: CGMouseButton) {
        switch button {
        case "left":
            return (.leftMouseDown, .leftMouseUp, .left)
        case "right":
            return (.rightMouseDown, .rightMouseUp, .right)
        case "middle":
            return (.otherMouseDown, .otherMouseUp, .center)
        default:
            throw InputError.invalidButton(button)
        }
    }

    private static func postMouseEvent(
        source: CGEventSource,
        type: CGEventType,
        position: CGPoint,
        button: CGMouseButton,
        clickCount: Int32,
        attempt: Int
    ) throws {
        guard let event = CGEvent(
            mouseEventSource: source,
            mouseType: type,
            mouseCursorPosition: position,
            mouseButton: button
        ) else {
            throw InputError.buttonActionFailed("failed creating event to enter mouse button", attempt)
        }

        if clickCount > 1 {
            event.setIntegerValueField(.mouseEventClickState, value: Int64(clickCount))
        }

        event.post(tap: .cghidEventTap)
    }
}
