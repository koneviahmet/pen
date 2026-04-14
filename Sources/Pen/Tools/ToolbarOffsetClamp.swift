import CoreGraphics

/// Araç çubuğu / kalem sürükleme ofseti için ortak sınırlar (`MainOverlayView` GeometryReader boyutu).
enum ToolbarOffsetClamp {
    static let tapVsDragThreshold: CGFloat = 14

    static func clamp(_ o: CGSize, containerSize: CGSize) -> CGSize {
        guard containerSize.width > 80, containerSize.height > 80 else { return o }
        let m: CGFloat = 28
        let minX = -containerSize.width + m + 72
        let maxX = containerSize.width - m - 40
        let minY = -containerSize.height + m + 80
        let maxY = containerSize.height - m - 40
        return CGSize(
            width: min(maxX, max(minX, o.width)),
            height: min(maxY, max(minY, o.height))
        )
    }
}
