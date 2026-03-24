import ArgumentParser
import ComputerUseSwift

struct AppsGroup: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "apps",
        abstract: "App management commands",
        subcommands: [
            ListInstalled.self,
            ListRunning.self,
            IconDataUrl.self,
            ResolveBundleIds.self,
            Open.self,
            PrepareDisplay.self,
            PreviewHideSet.self,
            Unhide.self,
            AppUnderPoint.self,
            FindWindowDisplays.self,
            Classify.self,
            IsPolicyBlocked.self,
        ]
    )

    struct ListInstalled: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "list-installed",
            abstract: "List all installed applications"
        )

        func run() async throws {
            do {
                let apps = try await InstalledAppsCache.shared.list()
                let jsonApps = apps.map { InstalledAppJson(from: $0) }
                try OutputFormatter.output(jsonApps)
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct ListRunning: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "list-running",
            abstract: "List all running applications"
        )

        func run() async throws {
            do {
                let apps = AppManager.listRunning()
                try OutputFormatter.output(apps)
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct IconDataUrl: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "icon-data-url",
            abstract: "Get app icon as a data URL"
        )

        @Option(name: .long)
        var path: String

        func run() async throws {
            do {
                let dataUrl = AppManager.iconDataUrl(path: path)
                try OutputFormatter.output(["dataUrl": dataUrl])
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct ResolveBundleIds: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "resolve-bundle-ids",
            abstract: "Resolve application names to bundle IDs"
        )

        @Option(name: .long, parsing: .upToNextOption)
        var names: [String]

        func run() async throws {
            do {
                let bundleIds = AppManager.resolveBundleIds(names: names)
                try OutputFormatter.output(bundleIds)
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct Open: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "open",
            abstract: "Open an application by bundle ID"
        )

        @Option(name: .long)
        var bundleId: String

        func run() async throws {
            do {
                try await AppManager.openApp(bundleId: bundleId)
                try OutputFormatter.output(["success": true])
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct PrepareDisplay: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "prepare-display",
            abstract: "Prepare display by hiding non-relevant apps"
        )

        @Option(name: .long, parsing: .upToNextOption)
        var allowedBundleIds: [String]

        @Option(name: .long)
        var hostBundleId: String

        func run() async throws {
            do {
                let result = await AppManager.prepareDisplay(
                    allowedBundleIds: allowedBundleIds,
                    hostBundleId: hostBundleId
                )
                try OutputFormatter.output(result)
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct PreviewHideSet: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "preview-hide-set",
            abstract: "Preview which apps would be hidden"
        )

        @Option(name: .long, parsing: .upToNextOption)
        var exemptBundleIds: [String]

        func run() async throws {
            do {
                let bundleIds = AppManager.previewHideSet(exemptBundleIds: exemptBundleIds)
                try OutputFormatter.output(bundleIds)
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct Unhide: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "unhide",
            abstract: "Unhide previously hidden applications"
        )

        @Option(name: .long, parsing: .upToNextOption)
        var bundleIds: [String]

        func run() async throws {
            do {
                AppManager.unhideApps(bundleIds: bundleIds)
                try OutputFormatter.output(["success": true])
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct AppUnderPoint: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "app-under-point",
            abstract: "Find which app is under a screen coordinate"
        )

        @Option(name: .long)
        var x: Double

        @Option(name: .long)
        var y: Double

        func run() async throws {
            do {
                let bundleId = HitTest.appUnderPoint(x: x, y: y)
                try OutputFormatter.output(["bundleId": bundleId])
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct Classify: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "classify",
            abstract: "Classify an app by category and tier"
        )

        @Option(name: .long)
        var bundleId: String?

        @Option(name: .long)
        var displayName: String?

        func run() async throws {
            do {
                let category = AppClassification.classify(bundleId: bundleId, displayName: displayName)
                let tier = AppClassification.tier(bundleId: bundleId, displayName: displayName)
                let result = ClassifyResult(category: category?.rawValue, tier: tier.rawValue)
                try OutputFormatter.output(result)
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    private struct ClassifyResult: Encodable {
        let category: String?
        let tier: String
    }

    struct IsPolicyBlocked: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "is-policy-blocked",
            abstract: "Check if an app is policy-blocked"
        )

        @Option(name: .long)
        var bundleId: String?

        @Option(name: .long)
        var displayName: String?

        func run() async throws {
            do {
                let blocked = PolicyBlockedApps.isBlocked(bundleId: bundleId, displayName: displayName)
                try OutputFormatter.output(["blocked": blocked])
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }

    struct FindWindowDisplays: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "find-window-displays",
            abstract: "Find displays with windows from specified apps"
        )

        @Option(name: .long, parsing: .upToNextOption)
        var bundleIds: [String]

        func run() async throws {
            do {
                let result = AppManager.findWindowDisplays(bundleIds: bundleIds)
                try OutputFormatter.output(result)
            } catch {
                OutputFormatter.exitWithError(error.localizedDescription)
            }
        }
    }
}
