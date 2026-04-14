import CoreGraphics

enum StrokeSmoothing {
    /// Catmull-Rom spline through points, sampled as short segments for drawing.
    static func smooth(_ points: [CGPoint], tension: CGFloat = 0.5) -> [CGPoint] {
        guard points.count >= 2 else { return points }
        if points.count == 2 { return points }

        var result: [CGPoint] = []
        result.reserveCapacity(points.count * 4)

        let first = points[0]
        let second = points[1]
        result.append(first)
        let initialMid = CGPoint(
            x: (first.x + second.x) / 2,
            y: (first.y + second.y) / 2
        )
        result.append(initialMid)

        for i in 1..<(points.count - 1) {
            let p0 = points[i - 1]
            let p1 = points[i]
            let p2 = points[i + 1]
            let mid = CGPoint(
                x: (p1.x + p2.x) / 2,
                y: (p1.y + p2.y) / 2
            )
            let c1 = CGPoint(
                x: p1.x + (p2.x - p0.x) * tension * 0.25,
                y: p1.y + (p2.y - p0.y) * tension * 0.25
            )
            let steps = 8
            for s in 1...steps {
                let t = CGFloat(s) / CGFloat(steps)
                let q0 = quadratic(p1, c1, mid, t)
                result.append(q0)
            }
        }

        result.append(points[points.count - 1])
        return result
    }

    private static func quadratic(_ p0: CGPoint, _ p1: CGPoint, _ p2: CGPoint, _ t: CGFloat) -> CGPoint {
        let u = 1 - t
        let x = u * u * p0.x + 2 * u * t * p1.x + t * t * p2.x
        let y = u * u * p0.y + 2 * u * t * p1.y + t * t * p2.y
        return CGPoint(x: x, y: y)
    }

    /// Constrain rect to square when shift pressed (from drag start).
    static func constrainRect(from start: CGPoint, to end: CGPoint, shiftPressed: Bool) -> CGRect {
        if shiftPressed {
            let dx = end.x - start.x
            let dy = end.y - start.y
            let side = max(abs(dx), abs(dy))
            let sx = dx >= 0 ? side : -side
            let sy = dy >= 0 ? side : -side
            let e = CGPoint(x: start.x + sx, y: start.y + sy)
            return CGRect(
                x: min(start.x, e.x),
                y: min(start.y, e.y),
                width: abs(e.x - start.x),
                height: abs(e.y - start.y)
            )
        }
        return CGRect(
            x: min(start.x, end.x),
            y: min(start.y, end.y),
            width: abs(end.x - start.x),
            height: abs(end.y - start.y)
        )
    }
}
