import Foundation

/// Pure functions for computing token-optimized image dimensions.
public enum ImageSizing {

    /// Computes the token count for an image of given dimensions.
    ///
    /// Uses ceiling division to count tiles along each axis.
    public static func nTokensForImg(
        width: Int,
        height: Int,
        tileSize: Int = ImageConstants.tileSize
    ) -> Int {
        let tilesW = ((width - 1) / tileSize) + 1
        let tilesH = ((height - 1) / tileSize) + 1
        return tilesW * tilesH
    }

    /// Computes optimal output dimensions for a screenshot to minimize token usage
    /// while preserving enough detail.
    ///
    /// - If both dimensions fit within 1568px and token count is acceptable, returns original size.
    /// - Otherwise, uses binary search to find the largest width that keeps tokens <= 1568.
    /// - Maintains aspect ratio throughout.
    public static func cuTargetImageSize(physW: Int, physH: Int) -> (Int, Int) {
        // Step 1: If both dimensions <= maxTokenCount, check token count
        if physW <= ImageConstants.maxTokenCount && physH <= ImageConstants.maxTokenCount {
            let tokens = nTokensForImg(width: physW, height: physH)
            if tokens < ImageConstants.maxTokenCount + 1 {
                return (physW, physH)
            }
        }

        // Step 2: Normalize so that physW >= physH (long side is width)
        if physW < physH {
            let (w, h) = cuTargetImageSize(physW: physH, physH: physW)
            return (h, w)
        }

        // Step 3: Binary search for optimal width
        let ratio = Double(physW) / Double(physH)
        var lo = 1
        var hi = physW

        while lo + 1 < hi {
            let mid = (lo + hi) / 2
            var scaledH = Int((Double(mid) / ratio).rounded())
            if scaledH < 1 { scaledH = 1 }

            let tokens = nTokensForImg(width: mid, height: scaledH)
            if tokens > ImageConstants.maxTokenCount {
                hi = mid
            } else {
                lo = mid
            }
        }

        // Step 4: Use lo as the final width
        var finalH = Int((Double(lo) / ratio).rounded())
        if finalH < 1 { finalH = 1 }
        return (lo, finalH)
    }
}
