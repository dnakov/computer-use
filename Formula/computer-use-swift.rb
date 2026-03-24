class ComputerUseSwift < Formula
  desc "macOS computer use capabilities CLI — screenshots, input simulation, app management"
  homepage "https://github.com/dnakov/computer-use"
  url "https://github.com/dnakov/computer-use/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "TODO_REPLACE_WITH_ACTUAL_SHA256"
  license "MIT"

  depends_on :macos => :sonoma
  depends_on xcode: ["15.0", :build]

  def install
    system "swift", "build",
           "-c", "release",
           "--arch", "arm64",
           "--arch", "x86_64",
           "--disable-sandbox"

    release_dir = ".build/apple/Products/Release"
    bin.install "#{release_dir}/computer-use"

    # Build and install the teach overlay helper app
    system "swift", "build",
           "-c", "release",
           "--arch", "arm64",
           "--arch", "x86_64",
           "--disable-sandbox",
           "--product", "teach-overlay"

    # Create TeachOverlay.app bundle
    app_dir = libexec/"TeachOverlay.app/Contents"
    (app_dir/"MacOS").mkpath
    cp "#{release_dir}/teach-overlay", app_dir/"MacOS/teach-overlay"
    (app_dir/"Info.plist").write <<~PLIST
      <?xml version="1.0" encoding="UTF-8"?>
      <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
      <plist version="1.0">
      <dict>
        <key>CFBundleExecutable</key><string>teach-overlay</string>
        <key>CFBundleIdentifier</key><string>com.computer-use.teach-overlay</string>
        <key>CFBundleName</key><string>TeachOverlay</string>
        <key>CFBundleVersion</key><string>#{version}</string>
        <key>CFBundleShortVersionString</key><string>#{version}</string>
        <key>LSUIElement</key><true/>
        <key>NSHighResolutionCapable</key><true/>
        <key>LSMinimumSystemVersion</key><string>14.0</string>
      </dict>
      </plist>
    PLIST

    # Symlink the app bundle next to the binary so it can find it
    ln_sf libexec/"TeachOverlay.app", bin/"TeachOverlay.app"
  end

  def caveats
    <<~EOS
      computer-use requires macOS permissions to function:
        - Accessibility (for input simulation)
        - Screen Recording (for screenshots)

      Grant these in System Settings → Privacy & Security.

      To verify: computer-use tcc check-accessibility
    EOS
  end

  test do
    output = shell_output("#{bin}/computer-use display list-all")
    assert_match "displayId", output

    output = shell_output("#{bin}/computer-use --version")
    assert_match version.to_s, output
  end
end
