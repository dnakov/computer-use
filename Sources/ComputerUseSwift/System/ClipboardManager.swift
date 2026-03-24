import AppKit

public enum ClipboardManager {
    public static func read() -> String {
        NSPasteboard.general.string(forType: .string) ?? ""
    }

    public static func write(_ text: String) {
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(text, forType: .string)
    }
}
