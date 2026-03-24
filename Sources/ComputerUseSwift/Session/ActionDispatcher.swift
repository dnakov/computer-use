import Foundation
import CoreGraphics

/// Central action router matching JS `aSe()` and `kyr()`.
/// Routes each action through pre-checks, coordinate conversion, guards, execution, and state update.
public enum ActionDispatcher {

    // MARK: - Result types

    public struct ActionResult: Codable {
        public let content: [ContentItem]
        public let isError: Bool?
        public let screenshot: ScreenshotDims?
        public let screenshotPath: String?

        public init(content: [ContentItem], isError: Bool? = nil, screenshot: ScreenshotDims? = nil, screenshotPath: String? = nil) {
            self.content = content
            self.isError = isError
            self.screenshot = screenshot
            self.screenshotPath = screenshotPath
        }
    }

    public enum ContentItem: Codable {
        case text(String)
        case image(data: String, mimeType: String)

        private enum CodingKeys: String, CodingKey {
            case type, text, data, mimeType
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            switch self {
            case .text(let text):
                try container.encode("text", forKey: .type)
                try container.encode(text, forKey: .text)
            case .image(let data, let mimeType):
                try container.encode("image", forKey: .type)
                try container.encode(data, forKey: .data)
                try container.encode(mimeType, forKey: .mimeType)
            }
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(String.self, forKey: .type)
            switch type {
            case "image":
                let data = try container.decode(String.self, forKey: .data)
                let mimeType = try container.decode(String.self, forKey: .mimeType)
                self = .image(data: data, mimeType: mimeType)
            default:
                let text = try container.decode(String.self, forKey: .text)
                self = .text(text)
            }
        }
    }

    // MARK: - Action categories

    public enum ActionCategory {
        case mouse
        case mouseFull
        case mousePosition
        case keyboard
        case screenshot
        case none
    }

    // MARK: - Errors

    public enum DispatchError: LocalizedError {
        case unknownAction(String)
        case tccNotGranted(String)
        case sessionLocked(String)
        case missingCoordinate
        case missingText
        case missingDuration
        case missingAppName
        case missingScrollDirection
        case invalidCoordinate
        case invalidScrollDirection(String)
        case invalidDuration
        case invalidRepeatCount
        case mouseAlreadyHeld
        case noLastScreenshot
        case systemComboBlocked(String)
        case frontmostCheckFailed(String)
        case hitTestFailed(String)
        case executorThrew(String)

        public var errorDescription: String? {
            switch self {
            case .unknownAction(let action):
                return "Unknown action: \(action)"
            case .tccNotGranted(let detail):
                return "OS permissions not granted: \(detail)"
            case .sessionLocked(let detail):
                return "Session is locked by another client: \(detail)"
            case .missingCoordinate:
                return "Missing required 'coordinate' parameter"
            case .missingText:
                return "Missing required 'text' parameter"
            case .missingDuration:
                return "Missing required 'duration' parameter"
            case .missingAppName:
                return "Missing required 'app' parameter"
            case .missingScrollDirection:
                return "Missing required 'scroll_direction' parameter"
            case .invalidCoordinate:
                return "Invalid coordinate format — expected [x, y]"
            case .invalidScrollDirection(let dir):
                return "Invalid scroll_direction: \(dir). Valid options: up, down, left, right"
            case .invalidDuration:
                return "Invalid duration — must be 0-100 seconds"
            case .invalidRepeatCount:
                return "Invalid repeat count — must be 1-100"
            case .mouseAlreadyHeld:
                return "Mouse button is already held down"
            case .noLastScreenshot:
                return "No previous screenshot available for coordinate conversion"
            case .systemComboBlocked(let combo):
                return "System key combination blocked: \(combo). Enable systemKeyCombos grant to allow."
            case .frontmostCheckFailed(let detail):
                return detail
            case .hitTestFailed(let detail):
                return detail
            case .executorThrew(let detail):
                return detail
            }
        }
    }

    // MARK: - All known action names

    public static let allActions: Set<String> = [
        "screenshot", "left_click", "double_click", "triple_click",
        "right_click", "middle_click", "type", "key", "scroll",
        "left_click_drag", "mouse_move", "wait", "cursor_position",
        "hold_key", "left_mouse_down", "left_mouse_up", "open_application",
    ]

    // MARK: - Dispatch (top-level handler matching kyr)

    /// Dispatch a single action with full session enforcement.
    public static func dispatch(
        action: String,
        args: [String: Any],
        session: inout SessionState,
        gates: SubGates
    ) async throws -> ActionResult {
        // 1. TCC permission check
        guard PermissionManager.checkAccessibility() else {
            throw DispatchError.tccNotGranted("Accessibility permission required")
        }
        guard PermissionManager.checkScreenRecording() else {
            throw DispatchError.tccNotGranted("Screen recording permission required")
        }

        // 2. Session lock check
        if let existing = SessionLock.check() {
            if existing.sessionId != session.sessionId {
                throw DispatchError.sessionLocked("Another session is currently using the computer.")
            }
        } else {
            // No lock held — acquire it for this session
            if let lockError = SessionLock.acquire(sessionId: session.sessionId) {
                throw DispatchError.sessionLocked(lockError)
            }
            session.resetMouseState()
        }

        // 3. Route to action handler
        do {
            return try await route(action: action, args: args, session: &session, gates: gates)
        } catch let error as DispatchError {
            throw error
        } catch {
            throw DispatchError.executorThrew(error.localizedDescription)
        }
    }

    // MARK: - Action router (matching aSe)

    static func route(
        action: String,
        args: [String: Any],
        session: inout SessionState,
        gates: SubGates
    ) async throws -> ActionResult {
        switch action {
        case "screenshot":
            return try await screenshotHandler(session: &session, gates: gates)
        case "left_click":
            return try await clickHandler(args: args, session: &session, gates: gates, button: "left", count: 1)
        case "double_click":
            return try await clickHandler(args: args, session: &session, gates: gates, button: "left", count: 2)
        case "triple_click":
            return try await clickHandler(args: args, session: &session, gates: gates, button: "left", count: 3)
        case "right_click":
            return try await clickHandler(args: args, session: &session, gates: gates, button: "right", count: 1)
        case "middle_click":
            return try await clickHandler(args: args, session: &session, gates: gates, button: "middle", count: 1)
        case "type":
            return try await typeHandler(args: args, session: &session, gates: gates)
        case "key":
            return try await keyHandler(args: args, session: &session, gates: gates)
        case "scroll":
            return try await scrollHandler(args: args, session: &session, gates: gates)
        case "left_click_drag":
            return try await dragHandler(args: args, session: &session, gates: gates)
        case "mouse_move":
            return try await mouseMoveHandler(args: args, session: &session, gates: gates)
        case "wait":
            return try await waitHandler(args: args)
        case "cursor_position":
            return try await cursorPositionHandler(session: &session)
        case "hold_key":
            return try await holdKeyHandler(args: args, session: &session, gates: gates)
        case "left_mouse_down":
            return try await mouseDownHandler(session: &session, gates: gates)
        case "left_mouse_up":
            return try await mouseUpHandler(session: &session, gates: gates)
        case "open_application":
            return try await openAppHandler(args: args, session: &session)
        default:
            throw DispatchError.unknownAction(action)
        }
    }

    // MARK: - Screenshot handler

    private static func screenshotHandler(
        session: inout SessionState,
        gates: SubGates
    ) async throws -> ActionResult {
        // Prepare display (hide non-allowed apps)
        if gates.hideBeforeAction {
            // Capture window z-order before hiding so we can restore later
            if session.windowStackBeforeHide.isEmpty {
                session.windowStackBeforeHide = AppManager.captureWindowStack()
            }

            let allowedBundleIds = session.allowedApps.map(\.bundleId)
            let result = await AppManager.prepareDisplay(
                allowedBundleIds: allowedBundleIds,
                hostBundleId: BundleIDs.finder
            )
            for bundleId in result.hidden {
                session.hiddenDuringTurn.insert(bundleId)
            }
        }

        // Build exclude list
        let excludeList = gates.screenshotFilter
            ? ScreenshotFilter.buildExcludeList(session: session)
            : []

        // Determine display
        let displayId = session.selectedDisplayId ?? Int(CGMainDisplayID())
        guard let displayInfo = DisplayManager.cuDisplayInfo(forDisplayID: UInt32(displayId)) else {
            throw DispatchError.executorThrew("CU display unavailable")
        }
        let displayWidth = displayInfo.boundsWidth   // points
        let displayHeight = displayInfo.boundsHeight  // points
        let physW = displayInfo.physicalWidth          // physical pixels (points * scale)
        let physH = displayInfo.physicalHeight

        // Compute capture dimensions from physical pixels (matching JS spec)
        let (captureW, captureH) = ImageSizing.cuTargetImageSize(
            physW: physW,
            physH: physH
        )

        // Capture
        if #available(macOS 14.0, *) {
            let result = try await ScreenshotCapture.captureScreenWithExclusion(
                displayId: UInt32(displayId),
                width: captureW,
                height: captureH,
                excludedBundleIds: excludeList,
                jpegQuality: 0.75
            )

            // Save image to temp file instead of returning base64 inline
            let base64 = result.dataUrl.replacingOccurrences(
                of: "data:image/jpeg;base64,", with: ""
            )

            let dims = ScreenshotDims(
                width: result.width,
                height: result.height,
                displayWidth: displayWidth,
                displayHeight: displayHeight,
                displayId: displayId,
                originX: displayInfo.originX,
                originY: displayInfo.originY
            )
            session.lastScreenshot = dims

            // Write to file
            let screenshotDir = FileManager.default.temporaryDirectory.appendingPathComponent("computer-use-screenshots")
            try? FileManager.default.createDirectory(at: screenshotDir, withIntermediateDirectories: true)
            let filename = "screenshot-\(session.sessionId)-\(Int(Date().timeIntervalSince1970)).jpg"
            let filePath = screenshotDir.appendingPathComponent(filename)

            if let imageData = Data(base64Encoded: base64) {
                try imageData.write(to: filePath)
            }

            return ActionResult(
                content: [.text("Screenshot saved to \(filePath.path)")],
                screenshot: dims,
                screenshotPath: filePath.path
            )
        } else {
            throw DispatchError.executorThrew("Screenshot requires macOS 14.0 or later")
        }
    }

    // MARK: - Click handler

    private static func clickHandler(
        args: [String: Any],
        session: inout SessionState,
        gates: SubGates,
        button: String,
        count: Int
    ) async throws -> ActionResult {
        // Release held mouse if any
        if session.mouseHeld {
            _ = try await MouseInput.mouseButton(button: "left", action: "release")
            session.resetMouseState()
        }

        // Parse coordinate
        let (rawX, rawY) = try parseCoordinate(args)

        // Parse optional modifier keys
        let modifierKeys = parseModifierKeys(args)

        // Check system shortcut restriction
        if !modifierKeys.isEmpty && !session.grantFlags.systemKeyCombos {
            if SystemKeyCombos.isSystemCombo(modifierKeys) {
                throw DispatchError.systemComboBlocked(modifierKeys.joined(separator: "+"))
            }
        }

        // Determine action category
        let category: ActionCategory = (button != "left" || !modifierKeys.isEmpty)
            ? .mouseFull : .mouse

        // Frontmost app check
        try await checkFrontmost(session: &session, category: category, gates: gates)

        // Convert coordinates
        let screenPoint = try convertCoordinates(rawX: rawX, rawY: rawY, session: session)

        // Pixel-level hit test
        try checkHitTest(
            session: session, gates: gates,
            x: Double(screenPoint.x),
            y: Double(screenPoint.y),
            category: category
        )

        // Clipboard guard
        if gates.clipboardGuard {
            runClipboardGuardForPoint(
                x: Double(screenPoint.x),
                y: Double(screenPoint.y),
                session: &session
            )
        }

        // Move mouse to position (with animation if gate enabled)
        _ = try await MouseInput.moveMouse(
            x: Int32(screenPoint.x),
            y: Int32(screenPoint.y),
            isRelative: false,
            animate: gates.mouseAnimation
        )

        // Execute click
        if !modifierKeys.isEmpty {
            for key in modifierKeys {
                _ = try await KeyboardInput.key(name: key, action: "press")
            }
            _ = try await MouseInput.mouseButton(button: button, action: "click", count: Int32(count))
            for key in modifierKeys.reversed() {
                _ = try await KeyboardInput.key(name: key, action: "release")
            }
        } else {
            _ = try await MouseInput.mouseButton(button: button, action: "click", count: Int32(count))
        }

        return textResult("Clicked.")
    }

    // MARK: - Type handler

    private static func typeHandler(
        args: [String: Any],
        session: inout SessionState,
        gates: SubGates
    ) async throws -> ActionResult {
        guard let text = args["text"] as? String, !text.isEmpty else {
            throw DispatchError.missingText
        }

        // Frontmost app check for keyboard
        try await checkFrontmost(session: &session, category: .keyboard, gates: gates)

        // If text contains newline, clipboardWrite granted, and gate enabled -> clipboard fast path
        if text.contains("\n") && session.grantFlags.clipboardWrite && gates.clipboardPasteMultiline {
            ClipboardManager.write(text)
            _ = try await KeyboardInput.keys(names: ["meta", "v"])
            let count = text.unicodeScalars.count
            return textResult("Typed \(count) grapheme(s).")
        }

        // Character-by-character typing
        var graphemeCount = 0
        for char in text {
            let charStr = String(char)
            switch charStr {
            case "\n", "\r":
                _ = try await KeyboardInput.key(name: "return")
            case "\t":
                _ = try await KeyboardInput.key(name: "tab")
            default:
                _ = try await KeyboardInput.typeText(charStr)
            }
            graphemeCount += 1
            // 8ms delay between graphemes
            try await Task.sleep(nanoseconds: 8_000_000)
        }

        return textResult("Typed \(graphemeCount) grapheme(s).")
    }

    // MARK: - Key handler

    private static func keyHandler(
        args: [String: Any],
        session: inout SessionState,
        gates: SubGates
    ) async throws -> ActionResult {
        guard let text = args["text"] as? String, !text.isEmpty else {
            throw DispatchError.missingText
        }

        let repeatCount = (args["repeat"] as? Int) ?? 1
        guard repeatCount >= 1 && repeatCount <= 100 else {
            throw DispatchError.invalidRepeatCount
        }

        // Parse key combo
        let keys = text.split(separator: "+").map { String($0).trimmingCharacters(in: .whitespaces) }

        // Check system shortcut restriction
        if !session.grantFlags.systemKeyCombos && SystemKeyCombos.isSystemCombo(keys) {
            throw DispatchError.systemComboBlocked(text)
        }

        // Frontmost app check for keyboard
        try await checkFrontmost(session: &session, category: .keyboard, gates: gates)

        // Execute key combo
        for _ in 0..<repeatCount {
            if keys.count == 1 {
                _ = try await KeyboardInput.key(name: keys[0])
            } else {
                _ = try await KeyboardInput.keys(names: keys)
            }
        }

        return textResult("Key pressed.")
    }

    // MARK: - Scroll handler

    private static func scrollHandler(
        args: [String: Any],
        session: inout SessionState,
        gates: SubGates
    ) async throws -> ActionResult {
        let (rawX, rawY) = try parseCoordinate(args)

        guard let direction = args["scroll_direction"] as? String else {
            throw DispatchError.missingScrollDirection
        }
        let amount = (args["scroll_amount"] as? Int) ?? 3

        guard ["up", "down", "left", "right"].contains(direction) else {
            throw DispatchError.invalidScrollDirection(direction)
        }

        // Frontmost app check for mouse
        try await checkFrontmost(session: &session, category: .mouse, gates: gates)

        // Convert coordinates
        let screenPoint = try convertCoordinates(rawX: rawX, rawY: rawY, session: session)

        // Hit test
        let hitCategory: ActionCategory = session.mouseHeld ? .mouseFull : .mouse
        try checkHitTest(
            session: session, gates: gates,
            x: Double(screenPoint.x),
            y: Double(screenPoint.y),
            category: hitCategory
        )

        // Move to position
        _ = try await MouseInput.moveMouse(
            x: Int32(screenPoint.x),
            y: Int32(screenPoint.y),
            isRelative: false,
            animate: gates.mouseAnimation
        )

        // Execute scroll
        let (scrollAmount, axis): (Int32, String) = {
            switch direction {
            case "up":    return (-Int32(amount), "vertical")
            case "down":  return (Int32(amount), "vertical")
            case "left":  return (-Int32(amount), "horizontal")
            case "right": return (Int32(amount), "horizontal")
            default:      return (0, "vertical")
            }
        }()

        _ = try await MouseInput.mouseScroll(amount: scrollAmount, axis: axis)

        // If mouse is held, mark as dragged
        if session.mouseHeld {
            session.mouseDragged = true
        }

        return textResult("Scrolled \(direction) by \(amount).")
    }

    // MARK: - Drag handler

    private static func dragHandler(
        args: [String: Any],
        session: inout SessionState,
        gates: SubGates
    ) async throws -> ActionResult {
        // Release held mouse if any
        if session.mouseHeld {
            _ = try await MouseInput.mouseButton(button: "left", action: "release")
            session.resetMouseState()
        }

        // Parse end coordinate
        let (endRawX, endRawY) = try parseCoordinate(args)

        // Parse optional start coordinate
        let (startRawX, startRawY): (Double, Double)
        if let startCoord = args["start_coordinate"] as? [Any],
           startCoord.count == 2,
           let sx = asDouble(startCoord[0]),
           let sy = asDouble(startCoord[1]) {
            startRawX = sx
            startRawY = sy
        } else {
            // Use current cursor position as start
            let loc = try await MouseInput.mouseLocation()
            startRawX = Double(loc.x)
            startRawY = Double(loc.y)
        }

        // Frontmost check for mouse
        try await checkFrontmost(session: &session, category: .mouse, gates: gates)

        // Convert coordinates
        let startPoint = try convertCoordinates(rawX: startRawX, rawY: startRawY, session: session)
        let endPoint = try convertCoordinates(rawX: endRawX, rawY: endRawY, session: session)

        // Hit test on start point (mouse category)
        try checkHitTest(
            session: session, gates: gates,
            x: Double(startPoint.x),
            y: Double(startPoint.y),
            category: .mouse
        )

        // Hit test on end point (mouse_full category)
        try checkHitTest(
            session: session, gates: gates,
            x: Double(endPoint.x),
            y: Double(endPoint.y),
            category: .mouseFull
        )

        // Execute drag
        _ = try await MouseInput.drag(
            startX: Int32(startPoint.x),
            startY: Int32(startPoint.y),
            endX: Int32(endPoint.x),
            endY: Int32(endPoint.y)
        )

        return textResult("Dragged.")
    }

    // MARK: - Mouse move handler

    private static func mouseMoveHandler(
        args: [String: Any],
        session: inout SessionState,
        gates: SubGates
    ) async throws -> ActionResult {
        let (rawX, rawY) = try parseCoordinate(args)

        // Frontmost check: "mouse" if held, else "mousePosition"
        let category: ActionCategory = session.mouseHeld ? .mouse : .mousePosition
        try await checkFrontmost(session: &session, category: category, gates: gates)

        // Convert coordinates
        let screenPoint = try convertCoordinates(rawX: rawX, rawY: rawY, session: session)

        // If mouse held: pixel hit test on destination
        if session.mouseHeld {
            try checkHitTest(
                session: session, gates: gates,
                x: Double(screenPoint.x),
                y: Double(screenPoint.y),
                category: .mouseFull
            )
        }

        // Execute move
        _ = try await MouseInput.moveMouse(
            x: Int32(screenPoint.x),
            y: Int32(screenPoint.y),
            isRelative: false,
            animate: gates.mouseAnimation
        )

        // If mouse held, mark as dragged
        if session.mouseHeld {
            session.mouseDragged = true
        }

        return textResult("Moved mouse.")
    }

    // MARK: - Wait handler

    private static func waitHandler(args: [String: Any]) async throws -> ActionResult {
        guard let duration = asDouble(args["duration"]) else {
            throw DispatchError.missingDuration
        }
        guard duration >= 0 && duration <= 100 else {
            throw DispatchError.invalidDuration
        }

        try await Task.sleep(nanoseconds: UInt64(duration * 1_000_000_000))
        return textResult("Waited \(duration)s.")
    }

    // MARK: - Cursor position handler

    private static func cursorPositionHandler(
        session: inout SessionState
    ) async throws -> ActionResult {
        let location = try await MouseInput.mouseLocation()

        if let lastScreenshot = session.lastScreenshot {
            // Convert logical screen coords to screenshot image pixel coords
            let imgX = Double(location.x - lastScreenshot.originX) *
                Double(lastScreenshot.width) / Double(lastScreenshot.displayWidth)
            let imgY = Double(location.y - lastScreenshot.originY) *
                Double(lastScreenshot.height) / Double(lastScreenshot.displayHeight)

            return textResult(
                "{\"x\": \(Int(imgX.rounded())), \"y\": \(Int(imgY.rounded())), \"coordinateSpace\": \"image_pixels\"}"
            )
        } else {
            return textResult(
                "{\"x\": \(location.x), \"y\": \(location.y), \"coordinateSpace\": \"logical_points\", \"note\": \"take a screenshot first\"}"
            )
        }
    }

    // MARK: - Hold key handler

    private static func holdKeyHandler(
        args: [String: Any],
        session: inout SessionState,
        gates: SubGates
    ) async throws -> ActionResult {
        guard let text = args["text"] as? String, !text.isEmpty else {
            throw DispatchError.missingText
        }
        guard let duration = asDouble(args["duration"]) else {
            throw DispatchError.missingDuration
        }
        guard duration >= 0 && duration <= 100 else {
            throw DispatchError.invalidDuration
        }

        let keys = text.split(separator: "+").map { String($0).trimmingCharacters(in: .whitespaces) }

        // Check system shortcut restriction
        if !session.grantFlags.systemKeyCombos && SystemKeyCombos.isSystemCombo(keys) {
            throw DispatchError.systemComboBlocked(text)
        }

        // Frontmost app check for keyboard
        try await checkFrontmost(session: &session, category: .keyboard, gates: gates)

        // Execute hold
        _ = try await KeyboardInput.holdKey(keyNames: keys, durationMs: Int(duration * 1000))

        return textResult("Held key for \(duration)s.")
    }

    // MARK: - Mouse down handler

    private static func mouseDownHandler(
        session: inout SessionState,
        gates: SubGates
    ) async throws -> ActionResult {
        guard !session.mouseHeld else {
            throw DispatchError.mouseAlreadyHeld
        }

        // Frontmost app check for mouse
        try await checkFrontmost(session: &session, category: .mouse, gates: gates)

        // Hit test at current cursor position
        let location = try await MouseInput.mouseLocation()
        try checkHitTest(
            session: session, gates: gates,
            x: Double(location.x),
            y: Double(location.y),
            category: .mouse
        )

        // Execute mouse down
        _ = try await MouseInput.mouseButton(button: "left", action: "press")
        session.mouseHeld = true
        session.mouseDragged = false

        return textResult("Mouse button pressed.")
    }

    // MARK: - Mouse up handler

    private static func mouseUpHandler(
        session: inout SessionState,
        gates: SubGates
    ) async throws -> ActionResult {
        // Frontmost app check for mouse
        try await checkFrontmost(session: &session, category: .mouse, gates: gates)

        // Hit test — if was dragged, use mouse_full category
        let location = try await MouseInput.mouseLocation()
        let hitCategory: ActionCategory = session.mouseDragged ? .mouseFull : .mouse
        try checkHitTest(
            session: session, gates: gates,
            x: Double(location.x),
            y: Double(location.y),
            category: hitCategory
        )

        // Execute mouse up
        _ = try await MouseInput.mouseButton(button: "left", action: "release")
        session.mouseHeld = false
        session.mouseDragged = false

        return textResult("Mouse button released.")
    }

    // MARK: - Open application handler

    private static func openAppHandler(
        args: [String: Any],
        session: inout SessionState
    ) async throws -> ActionResult {
        guard let appName = args["app"] as? String, !appName.isEmpty else {
            throw DispatchError.missingAppName
        }

        // Match against allowed apps (by bundle ID or display name)
        guard let matchedApp = session.allowedApps.first(where: {
            $0.bundleId.lowercased() == appName.lowercased() ||
            $0.displayName.lowercased() == appName.lowercased()
        }) else {
            let allowedNames = session.allowedApps.map(\.displayName).joined(separator: ", ")
            return errorResult(
                "Application '\(appName)' is not in the allowed applications. Allowed: \(allowedNames)"
            )
        }

        try await AppManager.openApp(bundleId: matchedApp.bundleId)

        return textResult("Opened \(matchedApp.displayName).")
    }

    // MARK: - Guard wrappers

    /// Wrapper around FrontmostCheck.check (throwing overload with gates).
    private static func checkFrontmost(
        session: inout SessionState,
        category: ActionCategory,
        gates: SubGates
    ) async throws {
        try await FrontmostCheck.check(
            session: &session,
            gates: gates,
            category: category
        )
    }

    /// Wrapper around HitTestValidator.validate (throwing overload with gates).
    private static func checkHitTest(
        session: SessionState,
        gates: SubGates,
        x: Double, y: Double,
        category: ActionCategory
    ) throws {
        try HitTestValidator.validate(
            session: session,
            gates: gates,
            x: x, y: y,
            category: category
        )
    }

    /// Run clipboard guard based on the app under the target point.
    private static func runClipboardGuardForPoint(
        x: Double, y: Double,
        session: inout SessionState
    ) {
        let bundleId = HitTest.appUnderPoint(x: x, y: y)
        let isClickTier: Bool
        if let bid = bundleId,
           let grant = session.allowedApps.first(where: { $0.bundleId == bid }) {
            isClickTier = grant.tier == .click
        } else {
            isClickTier = false
        }
        ClipboardGuard.run(session: &session, isClickTier: isClickTier)
    }

    // MARK: - Coordinate parsing helpers

    private static func parseCoordinate(_ args: [String: Any]) throws -> (Double, Double) {
        guard let coord = args["coordinate"] as? [Any], coord.count == 2 else {
            throw DispatchError.missingCoordinate
        }

        guard let x = asDouble(coord[0]), let y = asDouble(coord[1]) else {
            throw DispatchError.invalidCoordinate
        }

        return (x, y)
    }

    private static func parseModifierKeys(_ args: [String: Any]) -> [String] {
        if let text = args["text"] as? String, !text.isEmpty {
            return text.split(separator: "+").map { String($0).trimmingCharacters(in: .whitespaces) }
        }
        return []
    }

    private static func convertCoordinates(
        rawX: Double, rawY: Double,
        session: SessionState
    ) throws -> CoordinateConverter.ScreenPoint {
        guard let lastScreenshot = session.lastScreenshot else {
            throw DispatchError.noLastScreenshot
        }

        return CoordinateConverter.imagePixelsToScreen(
            pixelX: rawX, pixelY: rawY,
            screenshotWidth: lastScreenshot.width,
            screenshotHeight: lastScreenshot.height,
            displayWidth: lastScreenshot.displayWidth,
            displayHeight: lastScreenshot.displayHeight,
            originX: lastScreenshot.originX,
            originY: lastScreenshot.originY
        )
    }

    /// Safely convert Any to Double.
    private static func asDouble(_ value: Any?) -> Double? {
        if let d = value as? Double { return d }
        if let i = value as? Int { return Double(i) }
        if let f = value as? Float { return Double(f) }
        return nil
    }

    // MARK: - Result helpers

    static func textResult(_ text: String) -> ActionResult {
        ActionResult(content: [.text(text)])
    }

    static func errorResult(_ text: String) -> ActionResult {
        ActionResult(content: [.text(text)], isError: true)
    }
}

// MARK: - SubGates (matching JS lH())

public struct SubGates: Codable {
    public var pixelValidation: Bool
    public var clipboardPasteMultiline: Bool
    public var screenshotFilter: Bool
    public var mouseAnimation: Bool
    public var hideBeforeAction: Bool
    public var autoTargetDisplay: Bool
    public var clipboardGuard: Bool

    public init(
        pixelValidation: Bool = false,
        clipboardPasteMultiline: Bool = true,
        screenshotFilter: Bool = true,
        mouseAnimation: Bool = true,
        hideBeforeAction: Bool = true,
        autoTargetDisplay: Bool = true,
        clipboardGuard: Bool = true
    ) {
        self.pixelValidation = pixelValidation
        self.clipboardPasteMultiline = clipboardPasteMultiline
        self.screenshotFilter = screenshotFilter
        self.mouseAnimation = mouseAnimation
        self.hideBeforeAction = hideBeforeAction
        self.autoTargetDisplay = autoTargetDisplay
        self.clipboardGuard = clipboardGuard
    }
}
