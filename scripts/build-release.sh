#!/bin/bash
set -euo pipefail

VERSION="${1:-0.1.0}"
if [ -f .env ]; then source .env; fi
IDENTITY="${CODESIGN_IDENTITY:?Set CODESIGN_IDENTITY in .env}"
BUNDLE_PREFIX="${BUNDLE_ID_PREFIX:-com.example}"
RELEASE_DIR=".build/apple/Products/Release"
DIST_DIR=".build/dist/computer-use-${VERSION}"

echo "=== Building computer-use v${VERSION} ==="

echo "Building universal binary (arm64 + x86_64)..."
swift build -c release --arch arm64 --arch x86_64

echo "Building teach-overlay..."
swift build -c release --arch arm64 --arch x86_64 --product teach-overlay

echo "Verifying universal binary..."
lipo -info "$RELEASE_DIR/computer-use"
lipo -info "$RELEASE_DIR/teach-overlay"

echo "Creating TeachOverlay.app bundle..."
APP_DIR="$RELEASE_DIR/TeachOverlay.app/Contents"
mkdir -p "$APP_DIR/MacOS"
cp "$RELEASE_DIR/teach-overlay" "$APP_DIR/MacOS/teach-overlay"
cat > "$APP_DIR/Info.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key><string>teach-overlay</string>
    <key>CFBundleIdentifier</key><string>${BUNDLE_PREFIX}.computer-use.teach-overlay</string>
    <key>CFBundleName</key><string>TeachOverlay</string>
    <key>CFBundleVersion</key><string>${VERSION}</string>
    <key>CFBundleShortVersionString</key><string>${VERSION}</string>
    <key>LSUIElement</key><true/>
    <key>NSHighResolutionCapable</key><true/>
    <key>LSMinimumSystemVersion</key><string>14.0</string>
</dict>
</plist>
EOF

echo "Code signing..."
codesign --force --options runtime --sign "$IDENTITY" \
  --identifier "${BUNDLE_PREFIX}.computer-use.teach-overlay" \
  "$RELEASE_DIR/TeachOverlay.app"

codesign --force --options runtime --sign "$IDENTITY" \
  --identifier "${BUNDLE_PREFIX}.computer-use" \
  "$RELEASE_DIR/computer-use"

echo "Verifying signatures..."
codesign -dvv "$RELEASE_DIR/computer-use" 2>&1 | grep -E "Identifier|Authority"
codesign -dvv "$RELEASE_DIR/TeachOverlay.app" 2>&1 | grep -E "Identifier|Authority"

echo "Creating distribution archive..."
rm -rf "$DIST_DIR"
mkdir -p "$DIST_DIR"
cp "$RELEASE_DIR/computer-use" "$DIST_DIR/"
cp -r "$RELEASE_DIR/TeachOverlay.app" "$DIST_DIR/"

cd .build/dist
tar czf "computer-use-${VERSION}.tar.gz" "computer-use-${VERSION}/"
SHA=$(shasum -a 256 "computer-use-${VERSION}.tar.gz" | cut -d' ' -f1)

echo ""
echo "=== Build complete ==="
echo "Binary:  $RELEASE_DIR/computer-use"
echo "App:     $RELEASE_DIR/TeachOverlay.app"
echo "Archive: .build/dist/computer-use-${VERSION}.tar.gz"
echo "SHA256:  $SHA"
echo ""
echo "Update Formula/computer-use-swift.rb with:"
echo "  sha256 \"$SHA\""
