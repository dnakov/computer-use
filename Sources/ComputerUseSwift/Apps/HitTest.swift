import AppKit
import CoreGraphics

public enum HitTest {
    public static func appUnderPoint(x: Double, y: Double) -> String? {
        let point = CGPoint(x: x, y: y)

        let windowList = CGWindowListCopyWindowInfo(
            .optionOnScreenOnly,
            kCGNullWindowID
        ) as? [[String: Any]] ?? []

        let runningApps = NSWorkspace.shared.runningApplications
        let pidToBundleId: [pid_t: String] = {
            var map = [pid_t: String]()
            for app in runningApps {
                if let bundleId = app.bundleIdentifier {
                    map[app.processIdentifier] = bundleId
                }
            }
            return map
        }()

        for windowInfo in windowList {
            guard let layer = windowInfo[kCGWindowLayer as String] as? Int, layer == 0 else {
                continue
            }

            guard let boundsValue = windowInfo[kCGWindowBounds as String],
                  let boundsDict = boundsValue as? [String: Any] as CFDictionary?,
                  let bounds = CGRect(dictionaryRepresentation: boundsDict) else {
                continue
            }

            guard bounds.contains(point) else {
                continue
            }

            guard let pid = windowInfo[kCGWindowOwnerPID as String] as? pid_t else {
                continue
            }

            if let bundleId = pidToBundleId[pid] {
                if SystemApps.hitTestSkipBundleIds.contains(bundleId) {
                    continue
                }
                return bundleId
            }
        }

        return nil
    }
}
