import CoreGraphics
import SwiftUI

enum DrawingPathRenderer {
    static func path(from points: [CGPoint]) -> Path {
        var path = Path()
        guard let first = points.first else { return path }
        path.move(to: first)
        if points.count == 1 {
            path.addLine(to: first)
            return path
        }
        for p in points.dropFirst() {
            path.addLine(to: p)
        }
        return path
    }

    static func drawStroke(
        _ stroke: Stroke,
        in context: inout GraphicsContext,
        lineWidthScale: CGFloat = 1
    ) {
        let pts = stroke.points
        guard pts.count >= 1 else { return }
        let w = stroke.width * lineWidthScale
        let linePath = path(from: pts)
        let color = stroke.color.opacity(stroke.opacity)

        switch stroke.tool {
        case .pen, .pencil, .highlighter:
            context.stroke(
                linePath,
                with: .color(color),
                style: StrokeStyle(
                    lineWidth: w,
                    lineCap: .round,
                    lineJoin: .round
                )
            )
        case .eraserPixel:
            context.blendMode = .destinationOut
            context.stroke(
                linePath,
                with: .color(.white),
                style: StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round)
            )
            context.blendMode = .normal
        default:
            context.stroke(
                linePath,
                with: .color(color),
                style: StrokeStyle(lineWidth: w, lineCap: .round, lineJoin: .round)
            )
        }
    }

    static func drawShape(_ shape: ShapeStroke, in context: inout GraphicsContext) {
        let r = shape.rect.standardized
        let color = shape.color.opacity(shape.opacity)
        var path = Path()

        switch shape.kind {
        case .shapeLine, .shapeArrow, .shapeArrowStart, .shapeArrowDouble:
            guard let (start, end) = shape.lineSegmentEndpoints() else { return }
            guard hypot(end.x - start.x, end.y - start.y) > 0.5 else { return }
            path.move(to: start)
            path.addLine(to: end)
            context.stroke(
                path,
                with: .color(color),
                style: StrokeStyle(lineWidth: shape.lineWidth, lineCap: .round, lineJoin: .round)
            )
            switch shape.kind {
            case .shapeArrow:
                LineArrowTool.drawStrokedHead(
                    in: &context,
                    color: color,
                    lineWidth: shape.lineWidth,
                    tip: end,
                    start: start,
                    end: end,
                    tipAtEnd: true
                )
            case .shapeArrowStart:
                LineArrowTool.drawStrokedHead(
                    in: &context,
                    color: color,
                    lineWidth: shape.lineWidth,
                    tip: start,
                    start: start,
                    end: end,
                    tipAtEnd: false
                )
            case .shapeArrowDouble:
                LineArrowTool.drawStrokedHead(
                    in: &context,
                    color: color,
                    lineWidth: shape.lineWidth,
                    tip: end,
                    start: start,
                    end: end,
                    tipAtEnd: true
                )
                LineArrowTool.drawStrokedHead(
                    in: &context,
                    color: color,
                    lineWidth: shape.lineWidth,
                    tip: start,
                    start: start,
                    end: end,
                    tipAtEnd: false
                )
            default:
                break
            }
        case .shapeRect:
            guard r.width > 1, r.height > 1 else { return }
            path = Path()
            path.addRoundedRect(in: r, cornerSize: CGSize(width: 4, height: 4))
            path = rotatedPath(path, rect: r, radians: shape.rotationRadians)
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: shape.lineWidth))
        case .shapeRoundedRect:
            guard r.width > 1, r.height > 1 else { return }
            path = Path()
            let cr = min(min(r.width, r.height) * 0.22, 22)
            path.addRoundedRect(in: r, cornerSize: CGSize(width: cr, height: cr))
            path = rotatedPath(path, rect: r, radians: shape.rotationRadians)
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: shape.lineWidth))
        case .shapeTriangle:
            guard r.width > 1, r.height > 1 else { return }
            path = Path()
            path.move(to: CGPoint(x: r.midX, y: r.minY))
            path.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
            path.addLine(to: CGPoint(x: r.minX, y: r.maxY))
            path.closeSubpath()
            path = rotatedPath(path, rect: r, radians: shape.rotationRadians)
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: shape.lineWidth, lineJoin: .round))
        case .shapeEllipse:
            guard r.width > 1, r.height > 1 else { return }
            path = Path()
            path.addEllipse(in: r)
            path = rotatedPath(path, rect: r, radians: shape.rotationRadians)
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: shape.lineWidth))
        case .shapeDiamond:
            guard r.width > 1, r.height > 1 else { return }
            path = Path()
            path.move(to: CGPoint(x: r.midX, y: r.minY))
            path.addLine(to: CGPoint(x: r.maxX, y: r.midY))
            path.addLine(to: CGPoint(x: r.midX, y: r.maxY))
            path.addLine(to: CGPoint(x: r.minX, y: r.midY))
            path.closeSubpath()
            path = rotatedPath(path, rect: r, radians: shape.rotationRadians)
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: shape.lineWidth, lineJoin: .round))
        case .shapeHexagon:
            guard r.width > 1, r.height > 1 else { return }
            path = Path()
            let cx = r.midX
            let cy = r.midY
            let rad = min(r.width, r.height) / 2
            for i in 0 ..< 6 {
                let a = -CGFloat.pi / 2 + CGFloat(i) * CGFloat.pi / 3
                let px = cx + rad * cos(a)
                let py = cy + rad * sin(a)
                if i == 0 {
                    path.move(to: CGPoint(x: px, y: py))
                } else {
                    path.addLine(to: CGPoint(x: px, y: py))
                }
            }
            path.closeSubpath()
            path = rotatedPath(path, rect: r, radians: shape.rotationRadians)
            context.stroke(path, with: .color(color), style: StrokeStyle(lineWidth: shape.lineWidth, lineJoin: .round))
        case .pen, .pencil, .highlighter, .eraserStroke, .eraserPixel, .text, .select, .laser, .spotlight:
            break
        }
    }

    static func drawSelectionHighlight(for shape: ShapeStroke, in context: inout GraphicsContext) {
        switch shape.kind {
        case .shapeLine, .shapeArrow, .shapeArrowStart, .shapeArrowDouble:
            let r = shape.selectionHighlightRect
            guard r.width > 0, r.height > 0 else { return }
            let p = Path(roundedRect: r, cornerSize: CGSize(width: 6, height: 6))
            context.stroke(
                p,
                with: .color(Color.cyan.opacity(0.9)),
                style: StrokeStyle(lineWidth: 1.75, dash: [7, 5])
            )
        default:
            let r0 = shape.rect.standardized
            let pad = r0.insetBy(dx: -8, dy: -8)
            guard pad.width > 0, pad.height > 0 else { return }
            var p = Path(roundedRect: pad, cornerSize: CGSize(width: 6, height: 6))
            p = rotatedPath(p, rect: r0, radians: shape.rotationRadians)
            context.stroke(
                p,
                with: .color(Color.cyan.opacity(0.9)),
                style: StrokeStyle(lineWidth: 1.75, dash: [7, 5])
            )
        }
    }

    private static func rotatedPath(_ path: Path, rect r: CGRect, radians: CGFloat) -> Path {
        guard abs(radians) > 1e-6 else { return path }
        let rs = r.standardized
        let c = CGPoint(x: rs.midX, y: rs.midY)
        let t = CGAffineTransform(translationX: c.x, y: c.y)
            .concatenating(CGAffineTransform(rotationAngle: radians))
            .concatenating(CGAffineTransform(translationX: -c.x, y: -c.y))
        return path.applying(t)
    }

    static func drawSketchStrokeSelectionHighlight(for stroke: Stroke, in context: inout GraphicsContext) {
        let r = stroke.boundingRect.insetBy(dx: -14, dy: -14)
        guard r.width > 0, r.height > 0 else { return }
        let p = Path(roundedRect: r, cornerSize: CGSize(width: 6, height: 6))
        context.stroke(
            p,
            with: .color(Color.cyan.opacity(0.9)),
            style: StrokeStyle(lineWidth: 1.75, dash: [7, 5])
        )
    }
}
