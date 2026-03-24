import AppKit
import WebKit
import Foundation

public struct TeachStep {
    public let explanation: String
    public let nextPreview: String
    public let anchorX: Double?
    public let anchorY: Double?

    public init(explanation: String, nextPreview: String, anchorX: Double? = nil, anchorY: Double? = nil) {
        self.explanation = explanation
        self.nextPreview = nextPreview
        self.anchorX = anchorX
        self.anchorY = anchorY
    }
}

public enum TeachAction: String, Codable {
    case next
    case exit
}

public enum TeachOverlayRunner {
    public struct StepResult: Codable {
        public let stepIndex: Int
        public let action: TeachAction
    }

    public static func run(steps: [TeachStep]) -> [StepResult] {
        let app = NSApplication.shared
        app.setActivationPolicy(.accessory)

        let controller = TeachController(steps: steps)
        controller.setup()

        // Small delay for WKWebView to load
        for _ in 0..<20 {
            RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05))
        }

        controller.showCurrentStep()

        while !controller.isDone {
            RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05))
        }

        controller.teardown()
        return controller.results
    }
}

// MARK: - Controller

private class TeachController: NSObject, WKScriptMessageHandler, WKNavigationDelegate {
    let steps: [TeachStep]
    var results: [TeachOverlayRunner.StepResult] = []
    var currentStep = 0
    var isDone = false

    private var panel: NSPanel?
    private var webView: WKWebView?
    private var htmlFileURL: URL?
    private var webViewReady = false

    init(steps: [TeachStep]) {
        self.steps = steps
        super.init()
    }

    func setup() {
        // Write HTML to temp file
        let tmpDir = FileManager.default.temporaryDirectory
        let htmlURL = tmpDir.appendingPathComponent("cu-teach-\(ProcessInfo.processInfo.processIdentifier).html")
        try? Self.overlayHTML.write(to: htmlURL, atomically: true, encoding: .utf8)
        self.htmlFileURL = htmlURL

        // Create WKWebView
        let config = WKWebViewConfiguration()
        let uc = WKUserContentController()
        uc.add(self, name: "cuTeach")
        config.userContentController = uc

        let panelSize = NSSize(width: 400, height: 300)
        let wv = WKWebView(frame: NSRect(origin: .zero, size: panelSize), configuration: config)
        wv.navigationDelegate = self
        wv.setValue(false, forKey: "drawsBackground")
        self.webView = wv

        // Create tooltip-sized floating panel
        let p = NSPanel(
            contentRect: NSRect(origin: .zero, size: panelSize),
            styleMask: [.borderless, .nonactivatingPanel, .hudWindow],
            backing: .buffered,
            defer: false
        )
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.level = .floating
        p.isMovableByWindowBackground = false
        p.contentView = wv
        p.isReleasedWhenClosed = false
        self.panel = p

        // Load HTML
        wv.loadFileURL(htmlURL, allowingReadAccessTo: tmpDir)
    }

    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        webViewReady = true
    }

    func showCurrentStep() {
        guard currentStep < steps.count else {
            isDone = true
            return
        }

        // Wait for webview to be ready
        while !webViewReady {
            RunLoop.main.run(mode: .default, before: Date(timeIntervalSinceNow: 0.05))
        }

        let step = steps[currentStep]

        let anchorJS: String
        if let ax = step.anchorX, let ay = step.anchorY {
            anchorJS = "{x: \(ax), y: \(ay)}"
        } else {
            anchorJS = "null"
        }

        let js = """
        showStep({
            explanation: "\(step.explanation.jsEscaped)",
            nextPreview: "\(step.nextPreview.jsEscaped)",
            anchor: \(anchorJS)
        });
        """

        webView?.evaluateJavaScript(js) { [weak self] _, _ in
            guard let self = self else { return }
            // After JS runs, get the tooltip size and position the panel
            self.webView?.evaluateJavaScript("getTooltipRect()") { result, _ in
                if let dict = result as? [String: Double],
                   let x = dict["x"], let y = dict["y"],
                   let w = dict["width"], let h = dict["height"] {
                    self.positionPanel(tooltipX: x, tooltipY: y, tooltipW: w, tooltipH: h, step: step)
                } else {
                    // Fallback: center on screen
                    self.positionPanelCentered()
                }
                self.panel?.orderFrontRegardless()
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    private func positionPanel(tooltipX: Double, tooltipY: Double, tooltipW: Double, tooltipH: Double, step: TeachStep) {
        guard let screen = NSScreen.main else { return }
        let padding: CGFloat = 20
        let panelW = CGFloat(tooltipW) + padding * 2
        let panelH = CGFloat(tooltipH) + padding * 2

        let screenX: CGFloat
        let screenY: CGFloat

        if let ax = step.anchorX, let ay = step.anchorY {
            // Position below anchor, convert top-left to AppKit bottom-left
            screenX = CGFloat(ax) - panelW / 2
            screenY = screen.frame.height - CGFloat(ay) - panelH - 16
        } else {
            // Center
            screenX = screen.frame.midX - panelW / 2
            screenY = screen.frame.midY - panelH / 2
        }

        let clampedX = max(screen.frame.minX + 10, min(screen.frame.maxX - panelW - 10, screenX))
        let clampedY = max(screen.frame.minY + 10, min(screen.frame.maxY - panelH - 10, screenY))

        panel?.setFrame(NSRect(x: clampedX, y: clampedY, width: panelW, height: panelH), display: true)

        // Tell the webview where the panel is so it can position the tooltip within
        let js = "positionInPanel(\(padding), \(padding), \(tooltipW), \(tooltipH));"
        webView?.evaluateJavaScript(js, completionHandler: nil)
    }

    private func positionPanelCentered() {
        guard let screen = NSScreen.main else { return }
        let w: CGFloat = 440
        let h: CGFloat = 340
        let x = screen.frame.midX - w / 2
        let y = screen.frame.midY - h / 2
        panel?.setFrame(NSRect(x: x, y: y, width: w, height: h), display: true)
    }

    func teardown() {
        panel?.orderOut(nil)
        panel = nil
        webView = nil
        if let url = htmlFileURL {
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - WKScriptMessageHandler

    func userContentController(_ controller: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? String else { return }
        if body == "next" {
            results.append(TeachOverlayRunner.StepResult(stepIndex: currentStep, action: .next))
            currentStep += 1
            if currentStep < steps.count {
                showCurrentStep()
            } else {
                isDone = true
            }
        } else if body == "exit" {
            results.append(TeachOverlayRunner.StepResult(stepIndex: currentStep, action: .exit))
            isDone = true
        }
    }

    // MARK: - HTML

    static let overlayHTML = """
    <!DOCTYPE html>
    <html>
    <head>
    <meta charset="UTF-8">
    <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body {
        width: 100%; height: 100%; overflow: hidden;
        background: transparent;
        user-select: none; -webkit-user-select: none;
        -webkit-font-smoothing: antialiased;
        font-family: -apple-system, BlinkMacSystemFont, sans-serif;
    }
    .tooltip {
        position: absolute;
        min-width: 280px; max-width: 400px;
        border-radius: 16px;
        padding: 18px 20px;
        box-shadow: 0 10px 40px rgba(0,0,0,0.25);
        background: linear-gradient(to bottom, #fff, rgba(245,245,250,0.98));
        opacity: 0; transform: scale(0.94);
        transition: opacity 250ms ease-out, transform 250ms ease-out;
    }
    .tooltip.visible { opacity: 1; transform: scale(1); }
    .tooltip::before {
        content: ""; position: absolute; inset: 0; border-radius: 17px;
        pointer-events: none; border: 0.5px solid rgba(0,0,0,0.15);
    }
    @media (prefers-color-scheme: dark) {
        .tooltip { background: linear-gradient(to bottom, rgba(64,63,62,0.98), rgba(41,37,35,1)); }
        .tooltip::before { border-color: rgba(255,255,255,0.15); }
        .explanation { color: #f5f4ef !important; }
        .next-preview { color: #b8b5a9 !important; border-top-color: rgba(255,255,255,0.1) !important; }
        .btn-secondary { border-color: rgba(255,255,255,0.15) !important; color: #e5e5e2 !important; }
        .btn-secondary:hover { background: rgba(255,255,255,0.06) !important; }
        .working-label, .spinner { color: #b8b5a9 !important; }
    }
    .step { display: flex; flex-direction: column; gap: 10px; }
    .logo { width: 18px; height: 18px; }
    .explanation { font-size: 14px; line-height: 1.5; color: #29261b; white-space: pre-wrap; }
    .next-preview {
        font-size: 12px; line-height: 1.4; color: #656358;
        border-top: 0.5px solid rgba(0,0,0,0.1);
        margin-top: 2px; padding-top: 8px;
    }
    .next-preview:empty { display: none; }
    .buttons { display: flex; justify-content: flex-end; gap: 8px; margin-top: 4px; }
    .btn {
        height: 32px; padding: 0 16px; border-radius: 8px;
        font-size: 13px; font-family: inherit; font-weight: 500;
        cursor: pointer; border: none;
    }
    .btn-secondary {
        background: transparent; border: 0.5px solid rgba(0,0,0,0.15); color: #3d3929;
    }
    .btn-secondary:hover { background: rgba(0,0,0,0.05); }
    .btn-primary { background: #D97757; color: #fff; }
    .btn-primary:hover { background: #c86a4a; }
    .btn:disabled { opacity: 0.5; cursor: default; }
    .working { display: none; align-items: center; gap: 10px; }
    .tooltip.is-working .step { display: none; }
    .tooltip.is-working .working { display: flex; }
    .spinner {
        width: 18px; height: 18px; animation: spin 0.8s linear infinite;
        color: #656358;
    }
    @keyframes spin { to { transform: rotate(360deg); } }
    .working-label { flex: 1; font-size: 14px; color: #656358; }
    </style>
    </head>
    <body>
    <div class="tooltip" id="tooltip" style="left:10px;top:10px;">
      <div class="step">
        <svg class="logo" viewBox="0 0 248 248" fill="none"><circle cx="124" cy="124" r="110" fill="#D97757"/></svg>
        <div class="explanation" id="explanation"></div>
        <div class="next-preview" id="next-preview"></div>
        <div class="buttons">
          <button class="btn btn-secondary" id="exit-btn">Exit</button>
          <button class="btn btn-primary" id="next-btn">Next</button>
        </div>
      </div>
      <div class="working">
        <svg class="spinner" viewBox="0 0 256 256" fill="currentColor"><path d="M236,128a108,108,0,0,1-216,0c0-42.52,24.73-81.34,63-98.9A12,12,0,1,1,93,50.91C63.24,64.57,44,94.83,44,128a84,84,0,0,0,168,0c0-33.17-19.24-63.43-49-77.09A12,12,0,1,1,173,29.1C211.27,46.66,236,85.48,236,128Z"/></svg>
        <span class="working-label">Working...</span>
        <button class="btn btn-secondary" id="exit-btn-w">Exit</button>
      </div>
    </div>
    <script>
    var tt=document.getElementById("tooltip"), exp=document.getElementById("explanation"),
        np=document.getElementById("next-preview"), nb=document.getElementById("next-btn"),
        eb=document.getElementById("exit-btn"), ebw=document.getElementById("exit-btn-w");

    function showStep(d) {
        tt.classList.remove("is-working");
        nb.disabled = false;
        exp.textContent = d.explanation || "";
        np.textContent = d.nextPreview || "";
        tt.style.left = "10px"; tt.style.top = "10px";
        tt.classList.add("visible");
    }
    function showWorking() { tt.classList.add("is-working"); }
    function hideTooltip() { tt.classList.remove("visible"); }
    function getTooltipRect() {
        var r = tt.getBoundingClientRect();
        return {x: r.x, y: r.y, width: r.width, height: r.height};
    }
    function positionInPanel(x, y, w, h) {
        tt.style.left = x + "px"; tt.style.top = y + "px";
    }

    nb.addEventListener("click", function() {
        nb.disabled = true;
        window.webkit.messageHandlers.cuTeach.postMessage("next");
        setTimeout(function(){ nb.disabled = false; }, 2000);
    });
    function ex() {
        eb.disabled = ebw.disabled = true;
        window.webkit.messageHandlers.cuTeach.postMessage("exit");
    }
    eb.addEventListener("click", ex);
    ebw.addEventListener("click", ex);
    </script>
    </body>
    </html>
    """
}

private extension String {
    var jsEscaped: String {
        self.replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")
            .replacingOccurrences(of: "\r", with: "\\r")
    }
}
