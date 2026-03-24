import Foundation

public enum AppCategory: String, Codable {
    case browser
    case terminal
    case trading
}

public enum AppTier: String, Codable {
    case read
    case click
    case full
}

public enum AppClassification {

    // MARK: - Browser bundle IDs

    private static let browserBundleIds: Set<String> = [
        "com.apple.Safari",
        "com.google.Chrome",
        "org.mozilla.firefox",
        "com.microsoft.edgemac",
        "company.thebrowser.Browser",
        "com.brave.Browser",
        "com.operasoftware.Opera",
        "com.vivaldi.Vivaldi",
        "org.torproject.torbrowser",
        "com.duckduckgo.macos.browser",
        "ru.yandex.desktop.yandex-browser",
        "ai.perplexity.mac",
        "com.sigmaos.sigmaos",
        "io.kagi.kagimacOS",
    ]

    // MARK: - Terminal / IDE bundle IDs

    private static let terminalBundleIds: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "dev.warp.Warp-Stable",
        "com.github.wez.wezterm",
        "io.alacritty",
        "net.kovidgoyal.kitty",
        "com.mitchellh.ghostty",
        "com.eugeny.tabby",
        "com.termius-dmg.mac",
        "com.microsoft.VSCode",
        "com.todesktop.230313mzl4w4u92",
        "com.codeium.windsurf",
        "dev.zed.Zed",
        "com.jetbrains.intellij",
        "com.jetbrains.pycharm",
        "com.jetbrains.WebStorm",
        "com.jetbrains.goland",
        "com.jetbrains.CLion",
        "com.jetbrains.rubymine",
        "com.jetbrains.PhpStorm",
        "com.jetbrains.rider",
        "com.jetbrains.datagrip",
        "com.jetbrains.appcode",
        "com.jetbrains.fleet",
        "com.sublimetext.4",
        "org.vim.MacVim",
        "org.gnu.Emacs",
        "com.apple.dt.Xcode",
        "org.eclipse.platform.ide",
        "org.apache.netbeans",
        "com.google.android.studio",
        "com.axosoft.gitkraken",
        "com.microsoft.visual-studio",
    ]

    // MARK: - Trading / Finance bundle IDs

    private static let tradingBundleIds: Set<String> = [
        "com.webull.WebullDesktop",
        "com.tastytrade.tastytrade",
        "com.tradingview.TradingViewDesktop",
        "com.fidelity.FidelityDesktop",
        "com.binance.BinanceDesktop",
        "com.exodus.ExodusDesktop",
        "org.electrum.electrum",
        "com.ledger.live",
        "io.trezor.TrezorSuite",
    ]

    // MARK: - Display name substrings for fallback

    private static let browserNames = [
        "safari", "chrome", "firefox", "edge", "arc", "brave", "opera",
        "vivaldi", "tor browser", "duckduckgo", "yandex", "perplexity",
        "sigmaos", "kagi",
    ]

    private static let terminalNames = [
        "terminal", "iterm", "warp", "wezterm", "alacritty", "kitty",
        "ghostty", "tabby", "termius", "visual studio code", "vscode",
        "cursor", "windsurf", "zed", "intellij", "pycharm", "webstorm",
        "goland", "clion", "rubymine", "phpstorm", "rider", "datagrip",
        "appcode", "fleet", "sublime", "vim", "emacs", "xcode", "eclipse",
        "netbeans", "android studio", "gitkraken", "visual studio",
    ]

    private static let tradingNames = [
        "webull", "tastytrade", "tradingview", "fidelity", "binance",
        "exodus", "electrum", "ledger live", "trezor",
    ]

    // MARK: - Public API

    public static func classify(bundleId: String?, displayName: String?) -> AppCategory? {
        if let bid = bundleId {
            if browserBundleIds.contains(bid) { return .browser }
            if terminalBundleIds.contains(bid) { return .terminal }
            if tradingBundleIds.contains(bid) { return .trading }
        }

        if let name = displayName?.lowercased() {
            if browserNames.contains(where: { name.contains($0) }) { return .browser }
            if terminalNames.contains(where: { name.contains($0) }) { return .terminal }
            if tradingNames.contains(where: { name.contains($0) }) { return .trading }
        }

        return nil
    }

    public static func tier(bundleId: String?, displayName: String?) -> AppTier {
        switch classify(bundleId: bundleId, displayName: displayName) {
        case .browser:
            return .full
        case .trading:
            return .read
        case .terminal:
            return .click
        case nil:
            return .full
        }
    }
}
