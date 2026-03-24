# computer-use

macOS desktop control from the command line. Screenshots, mouse, keyboard, app management, window management — all as a single native binary.

```
brew install dnakov/tap/computer-use
```

Or build from source:

```
git clone https://github.com/dnakov/computer-use
cd computer-use
swift build -c release --arch arm64 --arch x86_64
# binary at .build/apple/Products/Release/computer-use
```

Requires macOS 14+ (Sonoma). You'll need to grant Accessibility and Screen Recording permissions in System Settings.

## What it does

```bash
# take a screenshot
computer-use screenshot capture-excluding

# move the mouse (animated) and click
computer-use input move-mouse --x 500 --y 300 --relative false
computer-use input mouse-button --button left --action click --count 1

# type text
computer-use input type-text --text "hello world"

# key combo
computer-use input keys --key-names command shift z

# scroll
computer-use input mouse-scroll --amount 5 --axis vertical

# drag
computer-use input drag --start-x 100 --start-y 200 --end-x 400 --end-y 200

# get frontmost app
computer-use window get-frontmost-app

# list displays
computer-use display list-all

# read clipboard
computer-use clipboard read
```

Everything outputs JSON to stdout.

## Sessions

Sessions add safety guards on top of the raw commands — tier enforcement, app hiding, coordinate conversion, clipboard guarding, frontmost app checks.

```bash
# start a session and grant access to Notes
computer-use session start --id s1
computer-use session grant --id s1 --apps Notes --reason "taking notes"

# orchestrated screenshot (hides non-granted apps, filters them from capture)
computer-use session action --id s1 --action screenshot

# orchestrated click (converts image pixels to screen coords, checks tiers)
computer-use session action --id s1 --action left_click --coordinate 500,300

# batch multiple actions
computer-use session batch --id s1 --actions '[
  {"action":"left_click","coordinate":[500,300]},
  {"action":"type","text":"hello"},
  {"action":"key","text":"return"}
]'

# end session (unhides apps, restores clipboard, releases lock)
computer-use session end --id s1
```

Apps are granted at tiers:
- **full** — everything allowed (most apps)
- **click** — left click + scroll only, no typing (terminals, IDEs)
- **read** — screenshots only, no interaction (browsers, trading apps)

## All commands

```
computer-use
├── screenshot     capture-excluding, capture-region
├── display        get-size, list-all, convert-coordinates
├── apps           list-installed, list-running, open, classify,
│                  is-policy-blocked, app-under-point, icon-data-url,
│                  resolve-bundle-ids, prepare-display, preview-hide-set,
│                  unhide, find-window-displays
├── tcc            check-accessibility, request-accessibility,
│                  check-screen-recording, request-screen-recording
├── input          key, keys, type-text, move-mouse, mouse-button,
│                  mouse-scroll, mouse-location, drag, hold-key,
│                  is-system-combo
├── window         focus, get-above, move-behind, get-active-handle,
│                  get-frontmost-app, get-app-for-file
├── system         read-plist, read-cf-pref, is-process-running
├── clipboard      read, write, paste
├── session        start, end, grant, revoke, status, action, batch,
│                  list, lock
├── teach          show-step, batch
├── auth           is-available, start, cancel
├── wait
├── resolve-prepare-capture
└── drain-run-loop
```

## Teach mode

Interactive walkthrough overlay. Shows a native macOS tooltip on screen, waits for the user to click Next, executes actions, repeats.

```bash
computer-use teach show-step \
  --explanation "Click the search field to begin." \
  --next-preview "Next: type a search query."

computer-use teach batch --session-id s1 --steps '[
  {"explanation":"Clicking search.","next_preview":"Next: typing.","actions":[{"action":"left_click","coordinate":[500,60]}]},
  {"explanation":"Done.","next_preview":"Finish.","actions":[]}
]'
```

## How coordinates work

Screenshot images are downscaled for token efficiency (max 1568 tokens at 28px/tile). When you pass pixel coordinates from a screenshot to a click/move command, the session layer converts them to screen points:

```
screenX = pixelX * (displayWidth / screenshotWidth) + originX
```

Take a screenshot first, read coordinates from the image, pass them to actions. The CLI handles the math.

## Building

```bash
swift build                    # debug
swift test                     # 294 tests
scripts/build-release.sh       # universal signed release
```

## License

MIT
