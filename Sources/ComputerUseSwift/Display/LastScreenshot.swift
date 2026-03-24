import Foundation

/// Persists the last screenshot dimensions to a temp file so that
/// direct CLI commands (input move-mouse, drag, etc.) can auto-convert
/// screenshot pixel coordinates to screen points without a session.
public enum LastScreenshot {
    private static let filePath: URL = {
        FileManager.default.temporaryDirectory
            .appendingPathComponent("computer-use-last-screenshot.json")
    }()

    public static func save(_ dims: ScreenshotDims) {
        guard let data = try? JSONEncoder().encode(dims) else { return }
        try? data.write(to: filePath)
    }

    public static func load() -> ScreenshotDims? {
        guard let data = try? Data(contentsOf: filePath) else { return nil }
        return try? JSONDecoder().decode(ScreenshotDims.self, from: data)
    }
}
