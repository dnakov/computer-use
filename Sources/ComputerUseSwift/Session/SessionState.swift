import Foundation

public struct SessionState: Codable {
    public var sessionId: String
    public var allowedApps: [GrantedApp]
    public var grantFlags: GrantFlags
    public var lastScreenshot: ScreenshotDims?
    public var selectedDisplayId: Int?
    public var hiddenDuringTurn: Set<String>
    public var windowStackBeforeHide: [String]  // bundle IDs in front-to-back order
    public var clipboardStash: String?
    public var mouseHeld: Bool
    public var mouseDragged: Bool
    public var lockAcquiredAt: Date?
    public var createdAt: Date

    public init(sessionId: String) {
        self.sessionId = sessionId
        self.allowedApps = []
        self.grantFlags = GrantFlags()
        self.lastScreenshot = nil
        self.selectedDisplayId = nil
        self.hiddenDuringTurn = []
        self.windowStackBeforeHide = []
        self.clipboardStash = nil
        self.mouseHeld = false
        self.mouseDragged = false
        self.lockAcquiredAt = nil
        self.createdAt = Date()
    }

    // MARK: - Persistence

    private static let sessionsDirectory: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".computer-use/sessions")
    }()

    private static func ensureDirectoryExists() throws {
        try FileManager.default.createDirectory(
            at: sessionsDirectory,
            withIntermediateDirectories: true
        )
    }

    private static func filePath(for sessionId: String) -> URL {
        sessionsDirectory.appendingPathComponent("\(sessionId).json")
    }

    public static func load(sessionId: String) throws -> SessionState {
        let path = filePath(for: sessionId)
        let data = try Data(contentsOf: path)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return try decoder.decode(SessionState.self, from: data)
    }

    public func save() throws {
        try Self.ensureDirectoryExists()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(self)

        // Atomic write: write to temp file then rename
        let target = Self.filePath(for: sessionId)
        let tempURL = target.deletingLastPathComponent()
            .appendingPathComponent(".\(sessionId).\(UUID().uuidString).tmp")
        try data.write(to: tempURL, options: .atomic)
        _ = try? FileManager.default.removeItem(at: target)
        try FileManager.default.moveItem(at: tempURL, to: target)
    }

    public static func delete(sessionId: String) throws {
        let path = filePath(for: sessionId)
        if FileManager.default.fileExists(atPath: path.path) {
            try FileManager.default.removeItem(at: path)
        }
    }

    public static func exists(sessionId: String) -> Bool {
        FileManager.default.fileExists(atPath: filePath(for: sessionId).path)
    }

    // MARK: - Mouse state reset

    public mutating func resetMouseState() {
        mouseHeld = false
        mouseDragged = false
    }
}

// MARK: - Supporting types

public struct GrantedApp: Codable, Equatable {
    public let bundleId: String
    public let displayName: String
    public let grantedAt: Date
    public var tier: AppTier

    public init(bundleId: String, displayName: String, grantedAt: Date, tier: AppTier) {
        self.bundleId = bundleId
        self.displayName = displayName
        self.grantedAt = grantedAt
        self.tier = tier
    }
}

public struct GrantFlags: Codable, Equatable {
    public var clipboardRead: Bool
    public var clipboardWrite: Bool
    public var systemKeyCombos: Bool

    public init(
        clipboardRead: Bool = false,
        clipboardWrite: Bool = false,
        systemKeyCombos: Bool = false
    ) {
        self.clipboardRead = clipboardRead
        self.clipboardWrite = clipboardWrite
        self.systemKeyCombos = systemKeyCombos
    }
}

public struct ScreenshotDims: Codable, Equatable {
    public let width: Int
    public let height: Int
    public let displayWidth: Int
    public let displayHeight: Int
    public let displayId: Int
    public let originX: Int
    public let originY: Int

    public init(
        width: Int, height: Int,
        displayWidth: Int, displayHeight: Int,
        displayId: Int = 0,
        originX: Int = 0, originY: Int = 0
    ) {
        self.width = width
        self.height = height
        self.displayWidth = displayWidth
        self.displayHeight = displayHeight
        self.displayId = displayId
        self.originX = originX
        self.originY = originY
    }
}
