import AppKit
import CoreGraphics

public enum HideCandidates {
    public static func compute(exemptBundleIds: Set<String>, displayFrame: CGRect) -> [NSRunningApplication] {
        let windowList = CGWindowListCopyWindowInfo(
            [.optionOnScreenOnly, .optionOnScreenAboveWindow],
            kCGNullWindowID
        ) as? [[String: Any]] ?? []

        let fullExempt = exemptBundleIds.union(SystemApps.defocusSystemApps)

        var candidatePIDs = Set<pid_t>()

        for windowInfo in windowList {
            guard let boundsValue = windowInfo[kCGWindowBounds as String],
                  let boundsDict = boundsValue as? [String: Any] as CFDictionary?,
                  let bounds = CGRect(dictionaryRepresentation: boundsDict) else {
                continue
            }

            guard let layer = windowInfo[kCGWindowLayer as String] as? Int, layer == 0 else {
                continue
            }

            guard let alpha = windowInfo[kCGWindowAlpha as String] as? Double, alpha > 0.0 else {
                continue
            }

            if bounds.intersects(displayFrame) {
                if let pid = windowInfo[kCGWindowOwnerPID as String] as? pid_t {
                    candidatePIDs.insert(pid)
                }
            }
        }

        let runningApps = NSWorkspace.shared.runningApplications
        var result: [NSRunningApplication] = []

        for app in runningApps {
            let bundleId = app.bundleIdentifier
            let name = app.localizedName

            let isExemptByBundleId = bundleId != nil && fullExempt.contains(bundleId!)
            let isExemptByName = name != nil && fullExempt.contains(name!)

            if !isExemptByBundleId && !isExemptByName && candidatePIDs.contains(app.processIdentifier) {
                result.append(app)
            }
        }

        return result
    }
}
