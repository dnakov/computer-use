import AppKit
import Foundation

public enum SystemQueries {
    public static func readPlistValue(filePath: String, key: String) throws -> PlistValue? {
        let url = URL(fileURLWithPath: filePath)
        let data = try Data(contentsOf: url)
        let plist = try PropertyListSerialization.propertyList(
            from: data, options: [], format: nil
        )

        guard let dict = plist as? [String: Any] else {
            throw SystemQueryError.plistRootNotDictionary
        }

        guard let value = dict[key] else {
            return nil
        }

        return convertToPlistValue(value)
    }

    public static func readCfPrefValue(key: String) -> PlistValue? {
        guard let value = CFPreferencesCopyAppValue(
            key as CFString, kCFPreferencesCurrentApplication
        ) else {
            return nil
        }

        let typeId = CFGetTypeID(value)

        if typeId == CFStringGetTypeID() {
            return .string(value as! String)
        } else if typeId == CFBooleanGetTypeID() {
            return .bool(CFBooleanGetValue((value as! CFBoolean)))
        } else if typeId == CFNumberGetTypeID() {
            let cfNumber = value as! CFNumber
            if CFNumberIsFloatType(cfNumber) {
                var doubleValue: Double = 0
                CFNumberGetValue(cfNumber, .doubleType, &doubleValue)
                return .float(doubleValue)
            } else {
                var intValue: Int = 0
                CFNumberGetValue(cfNumber, .longType, &intValue)
                return .integer(intValue)
            }
        }

        return nil
    }

    @MainActor
    public static func isProcessRunning(processId: String) -> Bool {
        let apps = NSWorkspace.shared.runningApplications
        return apps.contains { app in
            app.bundleIdentifier == processId || app.localizedName == processId
        }
    }

    private static func convertToPlistValue(_ value: Any) -> PlistValue? {
        switch value {
        case let boolVal as Bool:
            return .bool(boolVal)
        case let intVal as Int:
            return .integer(intVal)
        case let doubleVal as Double:
            return .float(doubleVal)
        case let stringVal as String:
            return .string(stringVal)
        default:
            return nil
        }
    }
}

public enum SystemQueryError: LocalizedError {
    case plistRootNotDictionary

    public var errorDescription: String? {
        switch self {
        case .plistRootNotDictionary:
            return "Plist root is not a dictionary"
        }
    }
}
