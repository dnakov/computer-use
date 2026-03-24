import Foundation
import CoreGraphics
import AppKit
import ScreenCaptureKit

/// Screenshot capture pipeline using ScreenCaptureKit.
public enum ScreenshotCapture {

    /// Captures the full display, excluding applications with the specified bundle IDs.
    @available(macOS 14.0, *)
    public static func captureScreenWithExclusion(
        displayId: UInt32,
        width: Int,
        height: Int,
        excludedBundleIds: [String],
        jpegQuality: CGFloat
    ) async throws -> (dataUrl: String, width: Int, height: Int) {
        // 1. Get shareable content
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

        // 2. Check screen recording permission
        guard CGPreflightScreenCaptureAccess() else {
            throw ScreenshotError.missingPermission
        }

        // 3. Find target display
        guard let display = content.displays.first(where: { $0.displayID == displayId }) else {
            throw ScreenshotError.displayNotFoundForID(displayId)
        }

        // 4. Build exclusion filter
        let excludedApps = content.applications.filter { app in
            excludedBundleIds.contains(app.bundleIdentifier)
        }
        let filter = SCContentFilter(display: display, excludingApplications: excludedApps, exceptingWindows: [])

        // 5. Configure capture
        let config = SCStreamConfiguration()
        config.width = width
        config.height = height
        config.scalesToFit = true
        config.capturesAudio = false
        config.showsCursor = true

        // 6. Capture image
        let cgImage: CGImage
        do {
            cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        } catch {
            throw ScreenshotError.captureWithExclusionFailed(error.localizedDescription)
        }

        // 7. Convert to JPEG
        let jpegData = try convertToJPEG(cgImage: cgImage, quality: jpegQuality, isRegion: false)

        // 8. Encode to base64 data URL
        let base64 = jpegData.base64EncodedString()
        let dataUrl = "data:image/jpeg;base64,\(base64)"

        return (dataUrl: dataUrl, width: width, height: height)
    }

    /// Captures a specific rectangular region of the display.
    @available(macOS 14.0, *)
    public static func captureScreenRegion(
        displayId: UInt32,
        sourceRect: CGRect,
        outputWidth: Int,
        outputHeight: Int,
        excludedBundleIds: [String],
        jpegQuality: CGFloat
    ) async throws -> (dataUrl: String, width: Int, height: Int) {
        // 1. Get shareable content
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)

        // 2. Check screen recording permission
        guard CGPreflightScreenCaptureAccess() else {
            throw ScreenshotError.missingPermission
        }

        // 3. Find target display
        guard let display = content.displays.first(where: { $0.displayID == displayId }) else {
            throw ScreenshotError.displayNotFoundForID(displayId)
        }

        // 4. Build exclusion filter
        let excludedApps = content.applications.filter { app in
            excludedBundleIds.contains(app.bundleIdentifier)
        }
        let filter = SCContentFilter(display: display, excludingApplications: excludedApps, exceptingWindows: [])

        // 5. Configure capture with source rect
        let config = SCStreamConfiguration()
        config.width = outputWidth
        config.height = outputHeight
        config.sourceRect = sourceRect
        config.scalesToFit = true
        config.capturesAudio = false
        config.showsCursor = true

        // 6. Capture image
        let cgImage: CGImage
        do {
            cgImage = try await SCScreenshotManager.captureImage(contentFilter: filter, configuration: config)
        } catch {
            throw ScreenshotError.regionCaptureWithExclusionFailed(error.localizedDescription)
        }

        // 7. Convert to JPEG
        let jpegData = try convertToJPEG(cgImage: cgImage, quality: jpegQuality, isRegion: true)

        // 8. Encode to base64 data URL
        let base64 = jpegData.base64EncodedString()
        let dataUrl = "data:image/jpeg;base64,\(base64)"

        return (dataUrl: dataUrl, width: outputWidth, height: outputHeight)
    }

    // MARK: - Private Helpers

    private static func convertToJPEG(cgImage: CGImage, quality: CGFloat, isRegion: Bool) throws -> Data {
        let nsImage = NSImage(cgImage: cgImage, size: NSSize(width: cgImage.width, height: cgImage.height))
        guard let tiffData = nsImage.tiffRepresentation,
              let bitmapRep = NSBitmapImageRep(data: tiffData),
              let jpegData = bitmapRep.representation(using: .jpeg, properties: [.compressionFactor: quality]) else {
            if isRegion {
                throw ScreenshotError.regionJpegConversionFailed
            } else {
                throw ScreenshotError.jpegConversionFailed
            }
        }
        return jpegData
    }
}
