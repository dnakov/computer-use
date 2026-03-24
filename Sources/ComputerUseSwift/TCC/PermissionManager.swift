import Foundation
import ApplicationServices
import CoreGraphics

public enum PermissionManager {

    public static func checkAccessibility() -> Bool {
        AXIsProcessTrustedWithOptions(nil)
    }

    public static func requestAccessibility() -> Bool {
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue(): true] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    public static func checkScreenRecording() -> Bool {
        CGPreflightScreenCaptureAccess()
    }

    public static func requestScreenRecording() -> Bool {
        CGRequestScreenCaptureAccess()
    }
}
