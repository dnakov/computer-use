import AppKit
import CoreGraphics
import ApplicationServices

@_silgen_name("_AXUIElementGetWindow")
func _AXUIElementGetWindow(_ element: AXUIElement, _ windowID: UnsafeMutablePointer<CGWindowID>) -> AXError

public enum WindowManager {

    // MARK: - focusWindow

    public static func focusWindow(windowId: UInt32) throws {
        let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] ?? []

        var ownerPID: pid_t?
        for info in windowList {
            guard let wid = info[kCGWindowNumber as String] as? UInt32,
                  wid == windowId,
                  let pid = info[kCGWindowOwnerPID as String] as? pid_t else {
                continue
            }
            ownerPID = pid
            break
        }

        guard let pid = ownerPID else {
            throw WindowError.windowNotFound
        }

        let appElement = AXUIElementCreateApplication(pid)

        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)
        guard result == .success, let windows = windowsRef as? [AXUIElement] else {
            throw WindowError.attributeCopyFailed("kAXWindowsAttribute")
        }

        for window in windows {
            var windowIDOut: CGWindowID = 0
            let err = _AXUIElementGetWindow(window, &windowIDOut)
            if err == .success && windowIDOut == windowId {
                AXUIElementPerformAction(window, kAXRaiseAction as CFString)
                break
            }
        }

        // Also activate the owning application
        if let app = NSRunningApplication(processIdentifier: pid) {
            app.activate()
        }
    }

    // MARK: - getWindowAbove

    public static func getWindowAbove(windowId: UInt32) -> UInt32? {
        let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] ?? []

        var previousWindowId: UInt32?
        for info in windowList {
            guard let wid = info[kCGWindowNumber as String] as? UInt32 else {
                continue
            }
            if wid == windowId {
                return previousWindowId
            }
            previousWindowId = wid
        }

        return nil
    }

    // MARK: - moveWindowBehind

    public static func moveWindowBehind(windowId: UInt32, behindWindowId: UInt32) throws {
        let windowList = CGWindowListCopyWindowInfo(.optionOnScreenOnly, kCGNullWindowID) as? [[String: Any]] ?? []

        // Find the PID for the window we want to move
        var ownerPID: pid_t?
        for info in windowList {
            guard let wid = info[kCGWindowNumber as String] as? UInt32,
                  wid == windowId,
                  let pid = info[kCGWindowOwnerPID as String] as? pid_t else {
                continue
            }
            ownerPID = pid
            break
        }

        guard let pid = ownerPID else {
            throw WindowError.windowNotFound
        }

        let appElement = AXUIElementCreateApplication(pid)

        var windowsRef: CFTypeRef?
        let result = AXUIElementCopyAttributeValue(appElement, kAXWindowsAttribute as CFString, &windowsRef)
        guard result == .success, let windows = windowsRef as? [AXUIElement] else {
            throw WindowError.attributeCopyFailed("kAXWindowsAttribute")
        }

        // Find the AX element for our window and reorder
        var targetWindow: AXUIElement?
        var reorderedWindows: [AXUIElement] = []

        for window in windows {
            var windowIDOut: CGWindowID = 0
            let err = _AXUIElementGetWindow(window, &windowIDOut)
            if err == .success && windowIDOut == windowId {
                targetWindow = window
            } else {
                reorderedWindows.append(window)
            }
        }

        guard let target = targetWindow else {
            throw WindowError.windowNotFound
        }

        // Insert the target window after the behindWindowId position
        var inserted = false
        var finalWindows: [AXUIElement] = []
        for window in reorderedWindows {
            finalWindows.append(window)
            var windowIDOut: CGWindowID = 0
            let err = _AXUIElementGetWindow(window, &windowIDOut)
            if err == .success && windowIDOut == behindWindowId {
                finalWindows.append(target)
                inserted = true
            }
        }

        if !inserted {
            // If behindWindowId not found, append at end
            finalWindows.append(target)
        }

        AXUIElementSetAttributeValue(
            appElement,
            kAXWindowsAttribute as CFString,
            finalWindows as CFTypeRef
        )
    }

    // MARK: - getActiveWindowHandle

    public static func getActiveWindowHandle() throws -> UInt32? {
        let systemWide = AXUIElementCreateSystemWide()

        var focusedAppRef: CFTypeRef?
        let appResult = AXUIElementCopyAttributeValue(
            systemWide,
            kAXFocusedApplicationAttribute as CFString,
            &focusedAppRef
        )
        guard appResult == .success else {
            throw WindowError.focusedWindowFailed("no focused application")
        }

        let focusedApp = focusedAppRef as! AXUIElement

        var focusedWindowRef: CFTypeRef?
        let windowResult = AXUIElementCopyAttributeValue(
            focusedApp,
            kAXFocusedWindowAttribute as CFString,
            &focusedWindowRef
        )
        guard windowResult == .success else {
            throw WindowError.focusedWindowFailed("no focused window")
        }

        let focusedWindow = focusedWindowRef as! AXUIElement

        var windowId: CGWindowID = 0
        let err = _AXUIElementGetWindow(focusedWindow, &windowId)
        guard err == .success else {
            throw WindowError.focusedWindowIdFailed
        }

        return windowId
    }

    // MARK: - getFrontmostAppInfo

    public static func getFrontmostAppInfo() -> FrontmostAppInfo? {
        guard let app = NSWorkspace.shared.frontmostApplication,
              let name = app.localizedName,
              let bundleId = app.bundleIdentifier,
              let bundleURL = app.bundleURL else {
            return nil
        }

        let iconBase64 = AppManager.iconDataUrl(path: bundleURL.path) ?? ""

        return FrontmostAppInfo(
            appName: name,
            bundleId: bundleId,
            appIconBase64: iconBase64
        )
    }

    // MARK: - getAppInfoForFile

    public static func getAppInfoForFile(filePath: String) -> AppInfoForFile? {
        let url = URL(fileURLWithPath: filePath)
        let ext = url.pathExtension

        guard !ext.isEmpty else {
            return nil
        }

        guard let uti = UTTypeCreatePreferredIdentifierForTag(
            kUTTagClassFilenameExtension,
            ext as CFString,
            nil
        )?.takeRetainedValue() else {
            return nil
        }

        guard let appURL = LSCopyDefaultApplicationURLForContentType(
            uti,
            .all,
            nil
        )?.takeRetainedValue() else {
            return nil
        }

        let appPath = (appURL as URL).path
        guard let bundle = Bundle(path: appPath),
              let appName = bundle.infoDictionary?["CFBundleName"] as? String
                ?? bundle.infoDictionary?["CFBundleDisplayName"] as? String
                ?? (appPath as NSString).lastPathComponent.components(separatedBy: ".").first else {
            return nil
        }

        let iconBase64 = AppManager.iconDataUrl(path: appPath) ?? ""

        return AppInfoForFile(
            appName: appName,
            appIconBase64: iconBase64
        )
    }
}
