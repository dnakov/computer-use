import Foundation
import CoreGraphics

public struct CUDisplayInfo {
    public var displayID: UInt32
    public var boundsWidth: Int
    public var boundsHeight: Int
    public var displayRect: CGRect
    public var physicalWidth: Int
    public var physicalHeight: Int
    public var scaleFactor: Double
    public var originX: Int
    public var originY: Int

    public init(
        displayID: UInt32,
        boundsWidth: Int,
        boundsHeight: Int,
        displayRect: CGRect,
        physicalWidth: Int,
        physicalHeight: Int,
        scaleFactor: Double,
        originX: Int,
        originY: Int
    ) {
        self.displayID = displayID
        self.boundsWidth = boundsWidth
        self.boundsHeight = boundsHeight
        self.displayRect = displayRect
        self.physicalWidth = physicalWidth
        self.physicalHeight = physicalHeight
        self.scaleFactor = scaleFactor
        self.originX = originX
        self.originY = originY
    }

    public func toDisplayInfo(isPrimary: Bool? = nil) -> DisplayInfo {
        DisplayInfo(
            displayId: Int(displayID),
            width: boundsWidth,
            height: boundsHeight,
            scaleFactor: scaleFactor,
            originX: originX,
            originY: originY,
            isPrimary: isPrimary
        )
    }
}
