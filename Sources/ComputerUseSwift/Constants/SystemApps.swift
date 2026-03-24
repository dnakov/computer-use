import Foundation

public enum SystemApps {
    public static let defocusSystemApps: Set<String> = [
        "Window Server",
        "SystemUIServer",
        "Dock",
        "Spotlight",
        "Control Center",
        "com.apple.screencaptureui",
        "Screenshot",
        "screencaptureui",
    ]

    public static let hitTestSkipBundleIds: Set<String> = [
        "com.apple.screencaptureui",
    ]
}
