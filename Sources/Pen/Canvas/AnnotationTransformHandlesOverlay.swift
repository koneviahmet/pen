import SwiftUI

/// Seçim çerçevesi: mavi kontur, köşe kareleri (ölçek), üstte dönüş tutamağı.
struct AnnotationTransformHandlesOverlay: View {
    @ObservedObject var document: DrawingDocument
    var editor: AnnotationEditTarget
    var canvasCoordinateSpaceName: String

    private static let accent = Color(red: 0.15, green: 0.42, blue: 0.95)
    private static let handleSize: CGFloat = 8
    private static let handleHit: CGFloat = 16
    private static let minResizeSide: CGFloat = 6
    private static let rotateStem: CGFloat = 22
    private static let rotateKnobR: CGFloat = 5

    @State private var resizeSession: ResizeSession?
    @State private var rotateSession: RotateSession?

    private struct ResizeSession {
        var pivot: CGPoint
        var startBounds: CGRect
        var lineHint: CGPoint?
        var sketchPointsStart: [CGPoint]?
        var textStartFontSize: CGFloat?
        var undoStarted = false
    }

    private struct RotateSession {
        var fingerStartAngle: CGFloat
        var pivot: CGPoint
        var baseShapeRotation: CGFloat
        var baseSketchPoints: [CGPoint]?
        var baseLineA: CGPoint?
        var baseLineB: CGPoint?
        var undoStarted = false
    }

    private var cornerResizeEnabled: Bool {
        switch editor {
        case .shape(let id):
            guard let s = document.shapes.first(where: { $0.id == id }) else { return true }
            if s.kind.isLineSegmentTool { return true }
            return abs(s.rotationRadians) < 0.002
        case .sketchStroke, .text:
            return true
        }
    }

    var body: some View {
        Group {
            if let b = transformBounds {
                ZStack {
                    Rectangle()
                        .strokeBorder(Self.accent, lineWidth: 2)
                        .frame(width: b.width, height: b.height)
                        .position(x: b.midX, y: b.midY)
                        .allowsHitTesting(false)

                    dimensionBadge(for: b)
                        .position(x: b.midX, y: b.maxY + 18)
                        .allowsHitTesting(false)

                    rotationHandle(bounds: b)

                    if cornerResizeEnabled {
                        ForEach(0..<4, id: \.self) { corner in
                            cornerHandle(corner: corner, bounds: b)
                        }
                    }
                }
            }
        }
    }

    private var transformBounds: CGRect? {
        switch editor {
        case .shape(let id):
            document.shapes.first(where: { $0.id == id }).map(\.selectionHighlightRect)
        case .sketchStroke(let id):
            document.strokes.first(where: { $0.id == id }).map { $0.boundingRect.insetBy(dx: -18, dy: -18) }
        case .text(let id):
            document.texts.first(where: { $0.id == id }).map { document.textAnnotationBounds($0) }
        }
    }

    private func rotationPivot() -> CGPoint? {
        switch editor {
        case .shape(let id):
            guard let s = document.shapes.first(where: { $0.id == id }) else { return nil }
            if s.kind.isLineSegmentTool, let (a, b) = s.lineSegmentEndpoints() {
                return CGPoint(x: (a.x + b.x) / 2, y: (a.y + b.y) / 2)
            }
            let r = s.rect.standardized
            return CGPoint(x: r.midX, y: r.midY)
        case .sketchStroke(let id):
            guard let s = document.strokes.first(where: { $0.id == id }) else { return nil }
            let br = s.boundingRect
            return CGPoint(x: br.midX, y: br.midY)
        case .text(let id):
            return document.texts.first(where: { $0.id == id })?.position
        }
    }

    @ViewBuilder
    private func dimensionBadge(for b: CGRect) -> some View {
        Text(String(format: "%.0f × %.0f", b.width, b.height))
            .font(.system(size: 10, weight: .semibold, design: .rounded))
            .monospacedDigit()
            .foregroundStyle(.white)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
                Capsule(style: .continuous)
                    .fill(Self.accent.opacity(0.92))
            )
    }

    private func cornerPoint(_ i: Int, bounds b: CGRect) -> CGPoint {
        switch i {
        case 0: return CGPoint(x: b.minX, y: b.minY)
        case 1: return CGPoint(x: b.maxX, y: b.minY)
        case 2: return CGPoint(x: b.maxX, y: b.maxY)
        case 3: return CGPoint(x: b.minX, y: b.maxY)
        default: return .zero
        }
    }

    private func cornerHandle(corner: Int, bounds b: CGRect) -> some View {
        RoundedRectangle(cornerRadius: 1, style: .continuous)
            .fill(Color.white)
            .frame(width: Self.handleSize, height: Self.handleSize)
            .overlay(
                RoundedRectangle(cornerRadius: 1, style: .continuous)
                    .strokeBorder(Self.accent, lineWidth: 1.25)
            )
            .frame(width: Self.handleHit, height: Self.handleHit)
            .contentShape(Rectangle())
            .position(x: cornerPoint(corner, bounds: b).x, y: cornerPoint(corner, bounds: b).y)
            .highPriorityGesture(
                DragGesture(minimumDistance: 0, coordinateSpace: .named(canvasCoordinateSpaceName))
                    .onChanged { value in
                        handleResizeChanged(corner: corner, finger: value.location, liveBounds: b)
                    }
                    .onEnded { _ in
                        resizeSession = nil
                        rotateSession = nil
                    }
            )
            .help("Köşeden sürükleyerek boyutlandır")
    }

    private func rotationHandle(bounds b: CGRect) -> some View {
        let knob = CGPoint(x: b.midX, y: b.minY - Self.rotateStem)
        return ZStack {
            Path { p in
                p.move(to: CGPoint(x: b.midX, y: b.minY))
                p.addLine(to: knob)
            }
            .stroke(Self.accent, style: StrokeStyle(lineWidth: 1.5, lineCap: .round))
            .allowsHitTesting(false)

            Circle()
                .fill(Color.white)
                .frame(width: Self.rotateKnobR * 2, height: Self.rotateKnobR * 2)
                .overlay(Circle().strokeBorder(Self.accent, lineWidth: 1.25))
                .frame(width: 28, height: 28)
                .contentShape(Circle())
                .position(x: knob.x, y: knob.y)
                .highPriorityGesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named(canvasCoordinateSpaceName))
                        .onChanged { value in
                            handleRotateChanged(finger: value.location)
                        }
                        .onEnded { _ in
                            rotateSession = nil
                            resizeSession = nil
                        }
                )
                .help("Döndürmek için sürükle")
        }
    }

    private func ensureUndoAndSession(corner: Int, startBounds b: CGRect) {
        rotateSession = nil
        if resizeSession == nil {
            let pivotIdx = (corner + 2) % 4
            let pivot = cornerPoint(pivotIdx, bounds: b)
            var lineHint: CGPoint?
            var sketchPts: [CGPoint]?
            var textFont: CGFloat?

            switch editor {
            case .shape(let id):
                if let s = document.shapes.first(where: { $0.id == id }),
                   s.kind.isLineSegmentTool,
                   let (a, b) = s.lineSegmentEndpoints() {
                    lineHint = CGPoint(x: b.x - a.x, y: b.y - a.y)
                }
            case .sketchStroke(let id):
                if let s = document.strokes.first(where: { $0.id == id }) {
                    sketchPts = s.points
                }
            case .text(let id):
                if let t = document.texts.first(where: { $0.id == id }) {
                    textFont = t.fontSize
                }
            }

            resizeSession = ResizeSession(
                pivot: pivot,
                startBounds: b,
                lineHint: lineHint,
                sketchPointsStart: sketchPts,
                textStartFontSize: textFont,
                undoStarted: false
            )
        }
        if var sess = resizeSession, !sess.undoStarted {
            document.beginAnnotationGeometryEdit()
            sess.undoStarted = true
            resizeSession = sess
        }
    }

    private func handleResizeChanged(corner: Int, finger: CGPoint, liveBounds b: CGRect) {
        ensureUndoAndSession(corner: corner, startBounds: b)
        guard let sess = resizeSession else { return }

        let R = AnnotationTransformGeometry.axisAlignedRect(
            pivot: sess.pivot,
            opposite: finger,
            minSide: Self.minResizeSide
        )

        switch editor {
        case .shape(let id):
            guard let shape = document.shapes.first(where: { $0.id == id }) else { return }
            if shape.kind.isLineSegmentTool, let hint = sess.lineHint {
                let (a, b) = AnnotationTransformGeometry.lineEndpoints(in: R, hint: hint)
                document.replaceShapeLineEndpoints(id: id, from: a, to: b)
            } else {
                document.replaceShapeRect(id: id, with: R)
            }
        case .sketchStroke(let id):
            guard let pts0 = sess.sketchPointsStart else { return }
            let sx = R.width / max(sess.startBounds.width, 1)
            let sy = R.height / max(sess.startBounds.height, 1)
            let piv = sess.pivot
            let scaled = pts0.map { p in
                CGPoint(x: piv.x + (p.x - piv.x) * sx, y: piv.y + (p.y - piv.y) * sy)
            }
            document.replaceSketchStrokePoints(id: id, points: scaled)
        case .text(let id):
            guard let t = document.texts.first(where: { $0.id == id }),
                  let f0 = sess.textStartFontSize else { return }
            let s = min(R.width / max(sess.startBounds.width, 1), R.height / max(sess.startBounds.height, 1))
            let newFont = f0 * s
            let pivotIdx = (corner + 2) % 4
            let pivotWorld = sess.pivot
            var trial = t
            trial.fontSize = newFont
            let half = AnnotationTransformGeometry.textHalfSize(for: trial)
            let newCenter = AnnotationTransformGeometry.textCenter(
                fixedCornerIndex: pivotIdx,
                pivotWorld: pivotWorld,
                half: half
            )
            document.setTextPositionAndFontSize(id: id, position: newCenter, fontSize: newFont)
        }
    }

    private func handleRotateChanged(finger: CGPoint) {
        resizeSession = nil
        if rotateSession == nil {
            guard let piv = rotationPivot() else { return }
            let ang = atan2(finger.y - piv.y, finger.x - piv.x)
            var baseRot: CGFloat = 0
            var sk: [CGPoint]?
            var la: CGPoint?
            var lb: CGPoint?
            switch editor {
            case .shape(let id):
                if let s = document.shapes.first(where: { $0.id == id }) {
                    if s.kind.isLineSegmentTool, let (a, b) = s.lineSegmentEndpoints() {
                        la = a
                        lb = b
                    } else {
                        baseRot = s.rotationRadians
                    }
                }
            case .sketchStroke(let id):
                sk = document.strokes.first(where: { $0.id == id })?.points
            case .text(let id):
                baseRot = document.texts.first(where: { $0.id == id })?.rotationRadians ?? 0
            }
            rotateSession = RotateSession(
                fingerStartAngle: ang,
                pivot: piv,
                baseShapeRotation: baseRot,
                baseSketchPoints: sk,
                baseLineA: la,
                baseLineB: lb,
                undoStarted: false
            )
        }
        if var rs = rotateSession, !rs.undoStarted {
            document.beginAnnotationGeometryEdit()
            rs.undoStarted = true
            rotateSession = rs
        }
        guard let sess = rotateSession else { return }
        let angNow = atan2(finger.y - sess.pivot.y, finger.x - sess.pivot.x)
        let d = AnnotationGeometryMath.shortestAngleDelta(from: sess.fingerStartAngle, to: angNow)

        switch editor {
        case .shape(let id):
            if let a0 = sess.baseLineA, let b0 = sess.baseLineB {
                let c = sess.pivot
                let a1 = AnnotationGeometryMath.rotatePoint(a0, around: c, by: d)
                let b1 = AnnotationGeometryMath.rotatePoint(b0, around: c, by: d)
                document.replaceShapeLineEndpoints(id: id, from: a1, to: b1)
            } else {
                document.setShapeRotation(id: id, radians: sess.baseShapeRotation + d)
            }
        case .sketchStroke(let id):
            guard let pts0 = sess.baseSketchPoints else { return }
            let rotated = pts0.map { AnnotationGeometryMath.rotatePoint($0, around: sess.pivot, by: d) }
            document.replaceSketchStrokePoints(id: id, points: rotated)
        case .text(let id):
            document.setTextRotation(id: id, radians: sess.baseShapeRotation + d)
        }
    }
}

// MARK: - Geometri (ölçek)

private enum AnnotationTransformGeometry {
    static func axisAlignedRect(pivot: CGPoint, opposite: CGPoint, minSide: CGFloat) -> CGRect {
        let minX = min(pivot.x, opposite.x)
        let maxX = max(pivot.x, opposite.x)
        let minY = min(pivot.y, opposite.y)
        let maxY = max(pivot.y, opposite.y)
        return CGRect(
            x: minX,
            y: minY,
            width: max(minSide, maxX - minX),
            height: max(minSide, maxY - minY)
        )
    }

    static func lineEndpoints(in R: CGRect, hint: CGPoint) -> (CGPoint, CGPoint) {
        let tl = CGPoint(x: R.minX, y: R.minY)
        let tr = CGPoint(x: R.maxX, y: R.minY)
        let br = CGPoint(x: R.maxX, y: R.maxY)
        let bl = CGPoint(x: R.minX, y: R.maxY)
        let d1x = br.x - tl.x
        let d1y = br.y - tl.y
        let d2x = bl.x - tr.x
        let d2y = bl.y - tr.y
        let hx = hint.x
        let hy = hint.y
        let hLen = hypot(hx, hy)
        if hLen < 0.5 {
            return (tl, br)
        }
        func cosSim(_ vx: CGFloat, _ vy: CGFloat) -> CGFloat {
            let vLen = hypot(vx, vy)
            if vLen < 0.5 { return -1 }
            return (vx * hx + vy * hy) / (vLen * hLen)
        }
        let s1 = cosSim(d1x, d1y)
        let s2 = cosSim(d2x, d2y)
        return s1 >= s2 ? (tl, br) : (tr, bl)
    }

    static func textHalfSize(for a: TextAnnotation) -> CGSize {
        let halfW = max(80, CGFloat(max(a.text.count, 2)) * a.fontSize * 0.28 + 36)
        let halfH = max(24, a.fontSize * 0.72 + 18)
        return CGSize(width: halfW, height: halfH)
    }

    static func textCenter(fixedCornerIndex: Int, pivotWorld: CGPoint, half: CGSize) -> CGPoint {
        let hw = half.width
        let hh = half.height
        switch fixedCornerIndex {
        case 0: return CGPoint(x: pivotWorld.x + hw, y: pivotWorld.y + hh)
        case 1: return CGPoint(x: pivotWorld.x - hw, y: pivotWorld.y + hh)
        case 2: return CGPoint(x: pivotWorld.x - hw, y: pivotWorld.y - hh)
        case 3: return CGPoint(x: pivotWorld.x + hw, y: pivotWorld.y - hh)
        default: return pivotWorld
        }
    }
}
