import Foundation

public enum SessionLock {

    public struct LockInfo: Codable {
        public let sessionId: String
        public let acquiredAt: Date
        public let pid: Int32

        public init(sessionId: String, acquiredAt: Date, pid: Int32) {
            self.sessionId = sessionId
            self.acquiredAt = acquiredAt
            self.pid = pid
        }
    }

    private static let lockPath: URL = {
        FileManager.default.homeDirectoryForCurrentUser
            .appendingPathComponent(".computer-use/lock.json")
    }()

    private static func ensureDirectoryExists() throws {
        let dir = lockPath.deletingLastPathComponent()
        try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    /// Check who holds the lock. Returns nil if no lock or lock is stale.
    public static func check() -> LockInfo? {
        guard let data = try? Data(contentsOf: lockPath) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        guard let info = try? decoder.decode(LockInfo.self, from: data) else {
            return nil
        }
        // Stale lock detection: if the PID is no longer alive, auto-release
        if !isProcessAlive(pid: info.pid) {
            try? FileManager.default.removeItem(at: lockPath)
            return nil
        }
        return info
    }

    /// Acquire lock for a session. Returns nil on success, error string if held by another.
    public static func acquire(sessionId: String) -> String? {
        if let existing = check() {
            if existing.sessionId == sessionId {
                return nil // Already held by us
            }
            return "Another session is currently using the computer."
        }

        let info = LockInfo(
            sessionId: sessionId,
            acquiredAt: Date(),
            pid: ProcessInfo.processInfo.processIdentifier
        )

        do {
            try ensureDirectoryExists()
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .millisecondsSince1970
            let data = try encoder.encode(info)
            try data.write(to: lockPath, options: .atomic)
            return nil
        } catch {
            return "Failed to acquire lock: \(error.localizedDescription)"
        }
    }

    /// Release lock if held by this session. Returns true if released.
    @discardableResult
    public static func release(sessionId: String) -> Bool {
        guard let existing = check(), existing.sessionId == sessionId else {
            return false
        }
        try? FileManager.default.removeItem(at: lockPath)
        return true
    }

    /// Force release the lock regardless of holder.
    public static func forceRelease() {
        try? FileManager.default.removeItem(at: lockPath)
    }

    /// Check if a process is still alive using kill(pid, 0).
    private static func isProcessAlive(pid: Int32) -> Bool {
        kill(pid, 0) == 0
    }
}
