import CoreGraphics
import SwiftUI

/// Çizgi ve ok araçları: önizleme, kayıt ve çizim aynı geometriyi kullanır (`ShapeStroke.rect` = `origin` + işaretli `size` vektörü).
enum LineArrowTool {
    private static let flare = CGFloat.pi / 6
    static let minCommitLength: CGFloat = 2

    static func headLength(lineWidth: CGFloat) -> CGFloat {
        max(lineWidth * 3, 10)
    }

    /// Shift: yatay, dikey veya 45°; vektör uzunluğu korunur.
    static func constrainedEnd(from start: CGPoint, to rawEnd: CGPoint, shiftPressed: Bool) -> CGPoint {
        guard shiftPressed else { return rawEnd }
        var dx = rawEnd.x - start.x
        var dy = rawEnd.y - start.y
        let dist = hypot(dx, dy)
        if dist < 1 { return rawEnd }
        let eps: CGFloat = 0.5
        if abs(dx) < eps { dx = 0 }
        if abs(dy) < eps { dy = 0 }
        let angle: CGFloat
        if dx == 0 && dy == 0 {
            return rawEnd
        } else if dx == 0 {
            angle = dy > 0 ? .pi / 2 : -.pi / 2
        } else if dy == 0 {
            angle = dx > 0 ? 0 : .pi
        } else {
            angle = atan2(dy, dx)
        }
        let step = CGFloat.pi / 4
        let snapped = (angle / step).rounded() * step
        return CGPoint(x: start.x + cos(snapped) * dist, y: start.y + sin(snapped) * dist)
    }

    /// `ShapeStroke` ile uyumlu depolama: `width` / `height` işaretlidir (Swift `CGRect.width` mutlak değer döndürmez burada `size` kullanılır).
    static func storageRect(start: CGPoint, end: CGPoint) -> CGRect {
        CGRect(x: start.x, y: start.y, width: end.x - start.x, height: end.y - start.y)
    }

    static func endpoints(from rect: CGRect) -> (CGPoint, CGPoint) {
        let start = CGPoint(x: rect.origin.x, y: rect.origin.y)
        let end = CGPoint(x: rect.origin.x + rect.size.width, y: rect.origin.y + rect.size.height)
        return (start, end)
    }

    /// Gövde yönü: `start` → `end` (`atan2`).
    private static func lineAngle(start: CGPoint, end: CGPoint) -> CGFloat {
        atan2(end.y - start.y, end.x - start.x)
    }

    /// Ok kanat uçları; `tipAtEnd`: uç `end` noktasında (gövde uca girer). `false`: uç `start` noktasında (gövde uca doğru açılır).
    static func arrowWingPoints(tip: CGPoint, start: CGPoint, end: CGPoint, lineWidth: CGFloat, tipAtEnd: Bool) -> (CGPoint, CGPoint) {
        let head = headLength(lineWidth: lineWidth)
        let θ = lineAngle(start: start, end: end)
        if tipAtEnd {
            let back = θ + .pi
            let a1 = back - flare
            let a2 = back + flare
            return (
                CGPoint(x: tip.x + head * cos(a1), y: tip.y + head * sin(a1)),
                CGPoint(x: tip.x + head * cos(a2), y: tip.y + head * sin(a2))
            )
        }
        let a1 = θ - flare
        let a2 = θ + flare
        return (
            CGPoint(x: tip.x + head * cos(a1), y: tip.y + head * sin(a1)),
            CGPoint(x: tip.x + head * cos(a2), y: tip.y + head * sin(a2))
        )
    }

    static func drawStrokedHead(
        in context: inout GraphicsContext,
        color: Color,
        lineWidth: CGFloat,
        tip: CGPoint,
        start: CGPoint,
        end: CGPoint,
        tipAtEnd: Bool
    ) {
        let (left, right) = arrowWingPoints(tip: tip, start: start, end: end, lineWidth: lineWidth, tipAtEnd: tipAtEnd)
        var headPath = Path()
        headPath.move(to: left)
        headPath.addLine(to: tip)
        headPath.addLine(to: right)
        context.stroke(
            headPath,
            with: .color(color),
            style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round)
        )
    }

    static func drawStrokedHeadCG(
        ctx: CGContext,
        tip: CGPoint,
        start: CGPoint,
        end: CGPoint,
        lineWidth: CGFloat,
        tipAtEnd: Bool
    ) {
        let (left, right) = arrowWingPoints(tip: tip, start: start, end: end, lineWidth: lineWidth, tipAtEnd: tipAtEnd)
        ctx.move(to: left)
        ctx.addLine(to: tip)
        ctx.addLine(to: right)
        ctx.strokePath()
    }
}
