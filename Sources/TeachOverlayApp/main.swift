import AppKit
import WebKit

// This is a minimal app bundle for the teach mode overlay.
// It's launched by the `computer-use teach` CLI command.
// Communication: steps are passed via command-line JSON args,
// results are printed to stdout as JSON.

// Parse input from argv: JSON array of steps
// Usage: TeachOverlayApp '{"steps":[{"explanation":"...","nextPreview":"...","anchorX":null,"anchorY":null}]}'

struct StepInput: Codable {
    let explanation: String
    let nextPreview: String
    let anchorX: Double?
    let anchorY: Double?
}

struct Input: Codable {
    let steps: [StepInput]
}

struct StepResult: Codable {
    let stepIndex: Int
    let action: String // "next" or "exit"
}

struct Output: Codable {
    let results: [StepResult]
    let completed: Bool
    let stepsCompleted: Int
}

// Read input
guard CommandLine.arguments.count > 1,
      let data = CommandLine.arguments[1].data(using: .utf8),
      let input = try? JSONDecoder().decode(Input.self, from: data) else {
    let err = #"{"error":"Usage: TeachOverlayApp '<json>'"}"#
    FileHandle.standardError.write(Data(err.utf8))
    exit(1)
}

// Set up NSApplication
let app = NSApplication.shared
app.setActivationPolicy(.accessory)

let delegate = AppDelegate(steps: input.steps)
app.delegate = delegate
app.run()

// Output results
let completed = delegate.results.count == input.steps.count && delegate.results.last?.action == "next"
let output = Output(
    results: delegate.results,
    completed: completed,
    stepsCompleted: delegate.results.count
)
if let json = try? JSONEncoder().encode(output),
   let str = String(data: json, encoding: .utf8) {
    print(str)
}

// MARK: - AppDelegate

class AppDelegate: NSObject, NSApplicationDelegate, WKScriptMessageHandler {
    let steps: [StepInput]
    var results: [StepResult] = []
    var currentStep = 0
    var panel: NSPanel!
    var webView: WKWebView!
    var htmlURL: URL?

    init(steps: [StepInput]) {
        self.steps = steps
        super.init()
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Write HTML to temp
        let tmp = FileManager.default.temporaryDirectory
        let url = tmp.appendingPathComponent("cu-teach-\(ProcessInfo.processInfo.processIdentifier).html")
        try? Self.html.write(to: url, atomically: true, encoding: .utf8)
        htmlURL = url

        // WKWebView
        let config = WKWebViewConfiguration()
        let uc = WKUserContentController()
        uc.add(self, name: "cuTeach")
        config.userContentController = uc

        let size = NSSize(width: 440, height: 340)
        webView = WKWebView(frame: NSRect(origin: .zero, size: size), configuration: config)
        webView.setValue(false, forKey: "drawsBackground")

        // Panel — native macOS popover-style with vibrancy
        panel = NSPanel(
            contentRect: NSRect(origin: .zero, size: size),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.level = .floating
        panel.hasShadow = true
        panel.isMovableByWindowBackground = true
        panel.isReleasedWhenClosed = false

        // Vibrancy background
        let vibrancy = NSVisualEffectView(frame: NSRect(origin: .zero, size: size))
        vibrancy.material = .popover
        vibrancy.blendingMode = .behindWindow
        vibrancy.state = .active
        vibrancy.wantsLayer = true
        vibrancy.layer?.cornerRadius = 12
        vibrancy.layer?.masksToBounds = true

        webView.frame = vibrancy.bounds
        webView.autoresizingMask = [.width, .height]
        vibrancy.addSubview(webView)
        panel.contentView = vibrancy

        webView.loadFileURL(url, allowingReadAccessTo: tmp)

        // Wait for load, then show first step
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.showStep()
        }
    }

    func showStep() {
        guard currentStep < steps.count else {
            quit()
            return
        }

        let step = steps[currentStep]
        let js = """
        showStep({
            explanation: "\(step.explanation.jsEscaped)",
            nextPreview: "\(step.nextPreview.jsEscaped)"
        });
        """

        webView.evaluateJavaScript(js) { _, _ in
            // Resize panel to fit tooltip
            self.webView.evaluateJavaScript("getTooltipSize()") { result, _ in
                if let dict = result as? [String: Double],
                   let w = dict["width"], let h = dict["height"] {
                    let panelW = CGFloat(w) + 8
                    let panelH = CGFloat(h) + 8
                    self.positionPanel(width: panelW, height: panelH, step: step)
                }
                self.panel.orderFrontRegardless()
                NSApp.activate(ignoringOtherApps: true)
            }
        }
    }

    func positionPanel(width: CGFloat, height: CGFloat, step: StepInput) {
        guard let screen = NSScreen.main else { return }
        let screenH = screen.frame.height

        let x: CGFloat
        let y: CGFloat

        if let ax = step.anchorX, let ay = step.anchorY {
            // Anchor is in top-left origin coords (like screenshot coords)
            // Convert to AppKit bottom-left origin
            let appKitAnchorY = screenH - CGFloat(ay)

            // Try to place tooltip below the anchor
            let belowY = appKitAnchorY - height - 16  // 16px gap
            let aboveY = appKitAnchorY + 16

            // Prefer below, fall back to above if it would go off-screen
            if belowY >= screen.frame.minY + 10 {
                y = belowY
            } else {
                y = aboveY
            }

            // Center horizontally on anchor
            x = CGFloat(ax) - width / 2
        } else {
            x = screen.frame.midX - width / 2
            y = screen.frame.midY - height / 2
        }

        let cx = max(screen.frame.minX + 10, min(screen.frame.maxX - width - 10, x))
        let cy = max(screen.frame.minY + 10, min(screen.frame.maxY - height - 10, y))

        panel.setFrame(NSRect(x: cx, y: cy, width: width, height: height), display: true, animate: true)
    }

    func quit() {
        panel.orderOut(nil)
        if let url = htmlURL { try? FileManager.default.removeItem(at: url) }

        // Print results before exiting (NSApp.terminate calls exit())
        let completed = results.count == steps.count && results.last?.action == "next"
        let output = Output(results: results, completed: completed, stepsCompleted: results.count)
        if let json = try? JSONEncoder().encode(output),
           let str = String(data: json, encoding: .utf8) {
            print(str)
            fflush(stdout)
        }

        NSApp.terminate(nil)
    }

    // MARK: WKScriptMessageHandler

    func userContentController(_ uc: WKUserContentController, didReceive message: WKScriptMessage) {
        guard let body = message.body as? String else { return }
        if body == "next" {
            results.append(StepResult(stepIndex: currentStep, action: "next"))
            currentStep += 1
            showStep()
        } else if body == "exit" {
            results.append(StepResult(stepIndex: currentStep, action: "exit"))
            quit()
        }
    }

    // MARK: HTML

    static let html = """
    <!DOCTYPE html><html><head><meta charset="UTF-8">
    <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    html, body {
      width: 100%; height: 100%; overflow: hidden;
      background: transparent;
      user-select: none; -webkit-user-select: none;
      -webkit-font-smoothing: antialiased;
      font-family: -apple-system, BlinkMacSystemFont, "SF Pro Text", "Helvetica Neue", sans-serif;
    }
    .tooltip {
      padding: 16px 18px 14px;
      opacity: 0; transform: scale(0.96);
      transition: opacity 200ms ease-out, transform 200ms ease-out;
    }
    .tooltip.visible { opacity: 1; transform: scale(1); }
    .step { display: flex; flex-direction: column; gap: 8px; }
    .explanation {
      font-size: 13px; line-height: 1.45;
      color: var(--text);
      white-space: pre-wrap; word-wrap: break-word;
    }
    .next-preview {
      font-size: 11.5px; line-height: 1.35;
      color: var(--text-secondary);
      border-top: 0.5px solid var(--separator);
      margin-top: 4px; padding-top: 6px;
    }
    .next-preview:empty { display: none; }
    .buttons {
      display: flex; justify-content: flex-end;
      gap: 6px; margin-top: 6px;
    }
    .btn {
      height: 24px; padding: 0 12px;
      border-radius: 6px; font-size: 12px;
      font-family: inherit; font-weight: 400;
      cursor: pointer; border: none;
      line-height: 24px;
    }
    .btn-secondary {
      background: var(--btn-bg);
      border: 0.5px solid var(--btn-border);
      color: var(--text);
    }
    .btn-secondary:hover { background: var(--btn-hover); }
    .btn-primary {
      background: var(--accent);
      color: #fff;
    }
    .btn-primary:hover { opacity: 0.9; }
    .btn:disabled { opacity: 0.4; cursor: default; }
    .working { display: none; align-items: center; gap: 8px; }
    .tooltip.is-working .step { display: none; }
    .tooltip.is-working .working { display: flex; }
    .spinner {
      width: 14px; height: 14px;
      animation: spin 0.8s linear infinite;
      color: var(--text-secondary);
    }
    @keyframes spin { to { transform: rotate(360deg); } }
    .working-label { flex: 1; font-size: 12px; color: var(--text-secondary); }

    :root {
      --text: #1d1d1f;
      --text-secondary: #86868b;
      --separator: rgba(0,0,0,0.12);
      --btn-bg: rgba(0,0,0,0.04);
      --btn-border: rgba(0,0,0,0.15);
      --btn-hover: rgba(0,0,0,0.08);
      --accent: #007AFF;
    }
    @media (prefers-color-scheme: dark) {
      :root {
        --text: #f5f5f7;
        --text-secondary: #86868b;
        --separator: rgba(255,255,255,0.12);
        --btn-bg: rgba(255,255,255,0.08);
        --btn-border: rgba(255,255,255,0.18);
        --btn-hover: rgba(255,255,255,0.12);
        --accent: #0A84FF;
      }
    }
    </style></head><body>
    <div class="tooltip" id="tt">
      <div class="step">
        <div class="explanation" id="exp"></div>
        <div class="next-preview" id="np"></div>
        <div class="buttons">
          <button class="btn btn-secondary" id="eb">Exit</button>
          <button class="btn btn-primary" id="nb">Next</button>
        </div>
      </div>
      <div class="working">
        <svg class="spinner" viewBox="0 0 256 256" fill="currentColor"><path d="M236,128a108,108,0,0,1-216,0c0-42.52,24.73-81.34,63-98.9A12,12,0,1,1,93,50.91C63.24,64.57,44,94.83,44,128a84,84,0,0,0,168,0c0-33.17-19.24-63.43-49-77.09A12,12,0,1,1,173,29.1C211.27,46.66,236,85.48,236,128Z"/></svg>
        <span class="working-label">Working...</span>
        <button class="btn btn-secondary" id="ebw">Exit</button>
      </div>
    </div>
    <script>
    var tt=document.getElementById("tt"),exp=document.getElementById("exp"),
        np=document.getElementById("np"),nb=document.getElementById("nb"),
        eb=document.getElementById("eb"),ebw=document.getElementById("ebw");
    function showStep(d){
      tt.classList.remove("is-working");
      nb.disabled=false;
      // Replace literal \\n with real newlines
      var text = (d.explanation||"").replace(/\\\\n/g,"\\n");
      exp.textContent = text;
      np.textContent = d.nextPreview||"";
      tt.classList.add("visible");
    }
    function showWorking(){tt.classList.add("is-working")}
    function getTooltipSize(){var r=tt.getBoundingClientRect();return{width:r.width,height:r.height}}
    nb.addEventListener("click",function(){nb.disabled=true;
      window.webkit.messageHandlers.cuTeach.postMessage("next");
      setTimeout(function(){nb.disabled=false},2000)});
    function ex(){eb.disabled=ebw.disabled=true;window.webkit.messageHandlers.cuTeach.postMessage("exit")}
    eb.addEventListener("click",ex);ebw.addEventListener("click",ex);
    </script></body></html>
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
