import AppKit
import SwiftUI

struct TextAnnotation: Identifiable {
    var id: UUID
    var position: CGPoint
    var text: String
    var fontSize: CGFloat
    var color: Color
    /// Metin kutusu arkası (varsayılan beyaz).
    var backgroundColor: Color

    /// Hazır taslak kimliği (`TextStyleTemplate.rawValue`); manuel renk ile sıfırlanır.
    var styleTemplateId: String?
    var fontDesign: TextFontDesign
    var fontWeightKind: TextFontWeightKind
    var isItalic: Bool
    /// İki renk arasında yatay gradient (yalnızca tuval önizlemesi; PNG’de ortalama renk).
    var usesForegroundGradient: Bool
    var gradientEndColor: Color
    /// Tuval düzleminde metin kutusu etrafında (merkez = `position`).
    var rotationRadians: CGFloat = 0

    init(
        id: UUID = UUID(),
        position: CGPoint,
        text: String,
        fontSize: CGFloat = 18,
        color: Color = .black,
        backgroundColor: Color = .white,
        styleTemplateId: String? = nil,
        fontDesign: TextFontDesign = .default,
        fontWeightKind: TextFontWeightKind = .regular,
        isItalic: Bool = false,
        usesForegroundGradient: Bool = false,
        gradientEndColor: Color = .black,
        rotationRadians: CGFloat = 0
    ) {
        self.id = id
        self.position = position
        self.text = text
        self.fontSize = fontSize
        self.color = color
        self.backgroundColor = backgroundColor
        self.styleTemplateId = styleTemplateId
        self.fontDesign = fontDesign
        self.fontWeightKind = fontWeightKind
        self.isItalic = isItalic
        self.usesForegroundGradient = usesForegroundGradient
        self.gradientEndColor = gradientEndColor
        self.rotationRadians = rotationRadians
    }
}

struct Stroke: Identifiable {
    var id: UUID
    var points: [CGPoint]
    var color: Color
    var width: CGFloat
    var tool: DrawingTool
    /// Highlighter / blend
    var opacity: CGFloat
    /// Pixel eraser mask segments (simplified: strokes that clear alpha in region)
    var isEraserMask: Bool

    init(
        id: UUID = UUID(),
        points: [CGPoint],
        color: Color,
        width: CGFloat,
        tool: DrawingTool,
        opacity: CGFloat = 1,
        isEraserMask: Bool = false
    ) {
        self.id = id
        self.points = points
        self.color = color
        self.width = width
        self.tool = tool
        self.opacity = opacity
        self.isEraserMask = isEraserMask
    }

    func distanceToPoint(_ p: CGPoint) -> CGFloat {
        guard points.count >= 2 else {
            if let first = points.first {
                return hypot(p.x - first.x, p.y - first.y)
            }
            return .infinity
        }
        var best: CGFloat = .infinity
        for i in 0..<(points.count - 1) {
            let a = points[i]
            let b = points[i + 1]
            best = min(best, distancePointToSegment(p, a, b))
        }
        return best
    }

    /// Yüzen panel konumu için sınırlayıcı kutu.
    var boundingRect: CGRect {
        guard let p0 = points.first else { return .zero }
        var minX = p0.x, maxX = p0.x, minY = p0.y, maxY = p0.y
        for p in points {
            minX = min(minX, p.x)
            maxX = max(maxX, p.x)
            minY = min(minY, p.y)
            maxY = max(maxY, p.y)
        }
        return CGRect(
            x: minX,
            y: minY,
            width: max(1, maxX - minX),
            height: max(1, maxY - minY)
        )
    }
}

private func distancePointToSegment(_ p: CGPoint, _ a: CGPoint, _ b: CGPoint) -> CGFloat {
    let ab = CGPoint(x: b.x - a.x, y: b.y - a.y)
    let ap = CGPoint(x: p.x - a.x, y: p.y - a.y)
    let abLenSq = ab.x * ab.x + ab.y * ab.y
    if abLenSq < 1e-10 {
        return hypot(ap.x, ap.y)
    }
    var t = (ap.x * ab.x + ap.y * ab.y) / abLenSq
    t = max(0, min(1, t))
    let proj = CGPoint(x: a.x + t * ab.x, y: a.y + t * ab.y)
    return hypot(p.x - proj.x, p.y - proj.y)
}

struct ShapeStroke: Identifiable {
    var id: UUID
    var rect: CGRect
    var kind: DrawingTool
    var color: Color
    var lineWidth: CGFloat
    var opacity: CGFloat
    /// Çizgi / ok araçları: gerçek uçlar. Yalnızca `rect` üzerinden güncelleme bazı durumlarda işaret kaybına yol açabildiği için çizim ve isabet burayı kullanır.
    var lineFrom: CGPoint?
    var lineTo: CGPoint?
    /// Kapalı şekiller: `rect` merkezinde döndürme (çizgi / ok için kullanılmaz).
    var rotationRadians: CGFloat = 0

    init(
        id: UUID = UUID(),
        rect: CGRect,
        kind: DrawingTool,
        color: Color,
        lineWidth: CGFloat,
        opacity: CGFloat = 1,
        lineFrom: CGPoint? = nil,
        lineTo: CGPoint? = nil
    ) {
        self.id = id
        self.kind = kind
        self.color = color
        self.lineWidth = lineWidth
        self.opacity = opacity

        if kind.isLineSegmentTool {
            let fromRect = LineArrowTool.endpoints(from: rect)
            let a = lineFrom ?? fromRect.0
            let b = lineTo ?? fromRect.1
            self.lineFrom = a
            self.lineTo = b
            self.rect = LineArrowTool.storageRect(start: a, end: b)
            self.rotationRadians = 0
        } else {
            self.rect = rect
            self.lineFrom = nil
            self.lineTo = nil
        }
    }

    /// Çizgi ve ok: önce açık uçlar, yoksa `rect` vektörü.
    func lineSegmentEndpoints() -> (CGPoint, CGPoint)? {
        guard kind.isLineSegmentTool else { return nil }
        if let a = lineFrom, let b = lineTo {
            return (a, b)
        }
        return LineArrowTool.endpoints(from: rect)
    }

    /// Tıklama / çift tıklama ile seçim: kontura olan mesafe (küçük = isabet).
    func hitDistance(to point: CGPoint) -> CGFloat {
        let r = rect.standardized

        switch kind {
        case .shapeLine, .shapeArrow, .shapeArrowStart, .shapeArrowDouble:
            guard let (a, b) = lineSegmentEndpoints() else { return .infinity }
            guard hypot(b.x - a.x, b.y - a.y) > 0.3 else { return .infinity }
            return distancePointToSegment(point, a, b)

        case .shapeRect, .shapeRoundedRect, .shapeTriangle, .shapeEllipse, .shapeDiamond, .shapeHexagon:
            let c = CGPoint(x: r.midX, y: r.midY)
            let sample = AnnotationGeometryMath.rotatePoint(point, around: c, by: -rotationRadians)
            switch kind {
            case .shapeRect:
                return distanceToAxisRectBorder(point: sample, rect: r)
            case .shapeRoundedRect:
                let cr = min(min(r.width, r.height) * 0.22, 22)
                return distanceToRoundedRectBorder(point: sample, rect: r, cornerRadius: cr)
            case .shapeTriangle:
                let pts = triangleVertices(in: r)
                return minDistanceToPolygonEdges(point: sample, vertices: pts)
            case .shapeEllipse:
                return distanceToEllipseBorder(point: sample, rect: r)
            case .shapeDiamond:
                let pts = diamondVertices(in: r)
                return minDistanceToPolygonEdges(point: sample, vertices: pts)
            case .shapeHexagon:
                let pts = hexagonVertices(in: r)
                return minDistanceToPolygonEdges(point: sample, vertices: pts)
            default:
                return .infinity
            }

        case .pen, .pencil, .highlighter, .eraserStroke, .eraserPixel, .text, .select, .laser, .spotlight:
            return .infinity
        }
    }

    func isHit(by point: CGPoint) -> Bool {
        hitDistance(to: point) <= max(16, lineWidth * 2.5 + 10)
    }

    /// Seçim çerçevesi (kesik çizgi) için sınırlayıcı dikdörtgen.
    var selectionHighlightRect: CGRect {
        switch kind {
        case .shapeLine, .shapeArrow, .shapeArrowStart, .shapeArrowDouble:
            guard let (a, b) = lineSegmentEndpoints() else { return rect.standardized }
            let r = CGRect(
                x: min(a.x, b.x),
                y: min(a.y, b.y),
                width: max(1, abs(b.x - a.x)),
                height: max(1, abs(b.y - a.y))
            )
            return r.insetBy(dx: -14, dy: -14)
        default:
            let r0 = rect.standardized
            let pad = r0.insetBy(dx: -8, dy: -8)
            guard abs(rotationRadians) > 1e-5 else { return pad }
            let c = CGPoint(x: r0.midX, y: r0.midY)
            return AnnotationGeometryMath.axisAlignedBounds(ofRotatedRect: pad, angle: rotationRadians, center: c)
        }
    }
}

// MARK: - Dönüşüm / sınırlayıcı kutu

enum AnnotationGeometryMath {
    static func rotatePoint(_ p: CGPoint, around c: CGPoint, by angle: CGFloat) -> CGPoint {
        let cosa = cos(angle)
        let sina = sin(angle)
        let dx = p.x - c.x
        let dy = p.y - c.y
        return CGPoint(x: c.x + dx * cosa - dy * sina, y: c.y + dx * sina + dy * cosa)
    }

    static func axisAlignedBounds(ofRotatedRect r: CGRect, angle: CGFloat, center c: CGPoint) -> CGRect {
        let corners = [
            CGPoint(x: r.minX, y: r.minY),
            CGPoint(x: r.maxX, y: r.minY),
            CGPoint(x: r.maxX, y: r.maxY),
            CGPoint(x: r.minX, y: r.maxY),
        ]
        let rp = corners.map { rotatePoint($0, around: c, by: angle) }
        let xs = rp.map(\.x)
        let ys = rp.map(\.y)
        guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max() else {
            return r
        }
        return CGRect(x: minX, y: minY, width: max(1, maxX - minX), height: max(1, maxY - minY))
    }

    static func shortestAngleDelta(from a: CGFloat, to b: CGFloat) -> CGFloat {
        var d = b - a
        while d > .pi { d -= 2 * .pi }
        while d < -.pi { d += 2 * .pi }
        return d
    }
}

// MARK: - Şekil isabet geometrisi

private func triangleVertices(in r: CGRect) -> [CGPoint] {
    [
        CGPoint(x: r.midX, y: r.minY),
        CGPoint(x: r.maxX, y: r.maxY),
        CGPoint(x: r.minX, y: r.maxY),
    ]
}

private func diamondVertices(in r: CGRect) -> [CGPoint] {
    [
        CGPoint(x: r.midX, y: r.minY),
        CGPoint(x: r.maxX, y: r.midY),
        CGPoint(x: r.midX, y: r.maxY),
        CGPoint(x: r.minX, y: r.midY),
    ]
}

private func hexagonVertices(in r: CGRect) -> [CGPoint] {
    let cx = r.midX
    let cy = r.midY
    let rad = min(r.width, r.height) / 2
    return (0 ..< 6).map { i in
        let a = -CGFloat.pi / 2 + CGFloat(i) * CGFloat.pi / 3
        return CGPoint(x: cx + rad * cos(a), y: cy + rad * sin(a))
    }
}

private func minDistanceToPolygonEdges(point: CGPoint, vertices: [CGPoint]) -> CGFloat {
    guard vertices.count >= 2 else { return .infinity }
    var best: CGFloat = .infinity
    for i in 0 ..< vertices.count {
        let a = vertices[i]
        let b = vertices[(i + 1) % vertices.count]
        best = min(best, distancePointToSegment(point, a, b))
    }
    return best
}

private func distanceToAxisRectBorder(point: CGPoint, rect r: CGRect) -> CGFloat {
    guard r.width >= 1, r.height >= 1 else { return .infinity }
    if r.contains(point) {
        return min(
            min(point.x - r.minX, r.maxX - point.x),
            min(point.y - r.minY, r.maxY - point.y)
        )
    }
    let dx = max(max(r.minX - point.x, point.x - r.maxX), 0)
    let dy = max(max(r.minY - point.y, point.y - r.maxY), 0)
    return hypot(dx, dy)
}

private func distanceToRoundedRectBorder(point: CGPoint, rect r: CGRect, cornerRadius: CGFloat) -> CGFloat {
    distanceToAxisRectBorder(point: point, rect: r)
}

private func distanceToEllipseBorder(point: CGPoint, rect r: CGRect) -> CGFloat {
    guard r.width > 1, r.height > 1 else { return .infinity }
    let cx = r.midX
    let cy = r.midY
    let rx = max(r.width / 2, 0.5)
    let ry = max(r.height / 2, 0.5)
    let vx = (point.x - cx) / rx
    let vy = (point.y - cy) / ry
    let distCenter = hypot(vx, vy)
    if distCenter < 1e-8 {
        return min(rx, ry)
    }
    let edge = CGPoint(x: cx + vx / distCenter * rx, y: cy + vy / distCenter * ry)
    return hypot(point.x - edge.x, point.y - edge.y)
}
