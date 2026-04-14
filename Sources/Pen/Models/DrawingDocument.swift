import AppKit
import Combine
import SwiftUI
import SwiftUI

struct DocumentSnapshot {
    var strokes: [Stroke]
    var shapes: [ShapeStroke]
    var texts: [TextAnnotation]
}

@MainActor
final class DrawingDocument: ObservableObject {
    @Published private(set) var strokes: [Stroke] = []
    @Published private(set) var shapes: [ShapeStroke] = []
    @Published private(set) var texts: [TextAnnotation] = []

    private var undoStack: [DocumentSnapshot] = []
    private var redoStack: [DocumentSnapshot] = []

    var canUndo: Bool { !undoStack.isEmpty }
    var canRedo: Bool { !redoStack.isEmpty }

    private func pushUndo() {
        undoStack.append(
            DocumentSnapshot(strokes: strokes, shapes: shapes, texts: texts)
        )
        redoStack.removeAll()
        trimUndoIfNeeded()
    }

    private let maxUndoSteps = 200

    private func trimUndoIfNeeded() {
        if undoStack.count > maxUndoSteps {
            undoStack.removeFirst(undoStack.count - maxUndoSteps)
        }
    }

    func undo() {
        guard let snap = undoStack.popLast() else { return }
        redoStack.append(
            DocumentSnapshot(strokes: strokes, shapes: shapes, texts: texts)
        )
        strokes = snap.strokes
        shapes = snap.shapes
        texts = snap.texts
    }

    func redo() {
        guard let snap = redoStack.popLast() else { return }
        undoStack.append(
            DocumentSnapshot(strokes: strokes, shapes: shapes, texts: texts)
        )
        strokes = snap.strokes
        shapes = snap.shapes
        texts = snap.texts
    }

    func clearAll() {
        pushUndo()
        strokes = []
        shapes = []
        texts = []
    }

    func appendStroke(_ stroke: Stroke) {
        pushUndo()
        strokes.append(stroke)
    }

    func appendShape(_ shape: ShapeStroke) {
        pushUndo()
        shapes.append(shape)
    }

    func appendText(_ text: TextAnnotation) {
        pushUndo()
        texts.append(text)
    }

    /// Typing in a field: no undo step per character.
    func setTextContent(id: UUID, text: String) {
        guard let idx = texts.firstIndex(where: { $0.id == id }) else { return }
        texts[idx].text = text
    }

    /// Begin drag: capture undo once.
    func beginTextMove(id: UUID) {
        pushUndo()
    }

    func moveText(id: UUID, to position: CGPoint) {
        guard let idx = texts.firstIndex(where: { $0.id == id }) else { return }
        texts[idx].position = position
    }

    func setTextFontSize(id: UUID, fontSize: CGFloat) {
        guard let idx = texts.firstIndex(where: { $0.id == id }) else { return }
        texts[idx].fontSize = min(96, max(8, fontSize))
    }

    func setTextColor(id: UUID, color: Color) {
        guard let idx = texts.firstIndex(where: { $0.id == id }) else { return }
        texts[idx].color = color
        texts[idx].styleTemplateId = nil
        texts[idx].usesForegroundGradient = false
        texts[idx].gradientEndColor = color
    }

    func setTextBackgroundColor(id: UUID, color: Color) {
        guard let idx = texts.firstIndex(where: { $0.id == id }) else { return }
        texts[idx].backgroundColor = color
        texts[idx].styleTemplateId = nil
    }

    func applyTextStyleTemplate(id: UUID, template: TextStyleTemplate) {
        guard let idx = texts.firstIndex(where: { $0.id == id }) else { return }
        pushUndo()
        template.apply(to: &texts[idx])
    }

    /// Metin kutusu yaklaşık sınırları (konum = merkez; döndürülmüşse eksen hizalı dış sınır).
    func textAnnotationBounds(_ t: TextAnnotation) -> CGRect {
        let halfW = max(80, CGFloat(max(t.text.count, 2)) * t.fontSize * 0.28 + 36)
        let halfH = max(24, t.fontSize * 0.72 + 18)
        let c = t.position
        if abs(t.rotationRadians) < 1e-5 {
            return CGRect(
                x: c.x - halfW,
                y: c.y - halfH,
                width: 2 * halfW,
                height: 2 * halfH
            )
        }
        let corners = [
            CGPoint(x: c.x - halfW, y: c.y - halfH),
            CGPoint(x: c.x + halfW, y: c.y - halfH),
            CGPoint(x: c.x + halfW, y: c.y + halfH),
            CGPoint(x: c.x - halfW, y: c.y + halfH),
        ]
        let rp = corners.map { AnnotationGeometryMath.rotatePoint($0, around: c, by: t.rotationRadians) }
        let xs = rp.map(\.x)
        let ys = rp.map(\.y)
        guard let minX = xs.min(), let maxX = xs.max(), let minY = ys.min(), let maxY = ys.max() else {
            return CGRect(x: c.x - halfW, y: c.y - halfH, width: 2 * halfW, height: 2 * halfH)
        }
        return CGRect(x: minX, y: minY, width: max(1, maxX - minX), height: max(1, maxY - minY))
    }

    /// Metin kutusu konturuna olan mesafe (içeride 0).
    private func distanceToTextAnnotationBounds(_ point: CGPoint, _ t: TextAnnotation) -> CGFloat {
        let r = textAnnotationBounds(t).standardized
        if r.contains(point) { return 0 }
        let x = min(max(point.x, r.minX), r.maxX)
        let y = min(max(point.y, r.minY), r.maxY)
        return hypot(point.x - x, point.y - y)
    }

    func hitTestTextAnnotation(at point: CGPoint) -> UUID? {
        for t in texts.reversed() {
            if textAnnotationBounds(t).contains(point) {
                return t.id
            }
        }
        return nil
    }

    /// Son çizilen üstte; çizgi/şekil çift tıklama seçimi.
    func hitTestShape(at point: CGPoint) -> UUID? {
        for s in shapes.reversed() where s.kind.isShapeTool {
            if s.isHit(by: point) {
                return s.id
            }
        }
        return nil
    }

    /// Tuvalde üstte çizilen serbest çizgiler (`strokes`); şekillerden sonra boyanır, seçimde önce bakılır.
    func hitTestSketchStroke(at point: CGPoint) -> UUID? {
        for s in strokes.reversed() {
            guard !s.isEraserMask else { continue }
            switch s.tool {
            case .pen, .pencil, .highlighter: break
            default: continue
            }
            let tol = max(18, s.width * 2.5 + 8)
            if s.distanceToPoint(point) <= tol {
                return s.id
            }
        }
        return nil
    }

    func setSketchStrokeColor(id: UUID, color: Color) {
        guard let idx = strokes.firstIndex(where: { $0.id == id }) else { return }
        pushUndo()
        strokes[idx].color = color
    }

    func setSketchStrokeWidth(id: UUID, width: CGFloat) {
        guard let idx = strokes.firstIndex(where: { $0.id == id }) else { return }
        pushUndo()
        strokes[idx].width = min(48, max(0.5, width))
    }

    func setSketchStrokeOpacity(id: UUID, opacity: CGFloat) {
        guard let idx = strokes.firstIndex(where: { $0.id == id }) else { return }
        pushUndo()
        strokes[idx].opacity = min(1, max(0, opacity))
    }

    func beginSketchStrokeMove(id: UUID) {
        pushUndo()
    }

    /// Serbest çizgiyi taşı: tüm örnek noktaları delta ile öteler.
    func translateSketchStroke(id: UUID, by delta: CGSize) {
        guard let idx = strokes.firstIndex(where: { $0.id == id }) else { return }
        var s = strokes[idx]
        s.points = s.points.map { CGPoint(x: $0.x + delta.width, y: $0.y + delta.height) }
        strokes[idx] = s
    }

    func beginShapeMove(id: UUID) {
        pushUndo()
    }

    func moveShape(id: UUID, by delta: CGSize) {
        translateShape(id: id, by: delta)
    }

    /// Şekli taşı: çizgi/ok için uç noktalar doğrudan ötelenir (`rect` yalnızca türetilir), böylece yön asla aynalanmaz.
    func translateShape(id: UUID, by delta: CGSize) {
        guard let idx = shapes.firstIndex(where: { $0.id == id }) else { return }
        var s = shapes[idx]
        if s.kind.isLineSegmentTool, let a = s.lineFrom, let b = s.lineTo {
            let na = CGPoint(x: a.x + delta.width, y: a.y + delta.height)
            let nb = CGPoint(x: b.x + delta.width, y: b.y + delta.height)
            s.lineFrom = na
            s.lineTo = nb
            s.rect = LineArrowTool.storageRect(start: na, end: nb)
        } else {
            s.rect = s.rect.offsetBy(dx: delta.width, dy: delta.height)
        }
        shapes[idx] = s
    }

    func setShapeColor(id: UUID, color: Color) {
        guard let idx = shapes.firstIndex(where: { $0.id == id }) else { return }
        pushUndo()
        shapes[idx].color = color
    }

    func setShapeLineWidth(id: UUID, width: CGFloat) {
        guard let idx = shapes.firstIndex(where: { $0.id == id }) else { return }
        pushUndo()
        shapes[idx].lineWidth = min(48, max(0.5, width))
    }

    func setShapeOpacity(id: UUID, opacity: CGFloat) {
        guard let idx = shapes.firstIndex(where: { $0.id == id }) else { return }
        pushUndo()
        shapes[idx].opacity = min(1, max(0, opacity))
    }

    func setTextFontWeight(id: UUID, weight: TextFontWeightKind) {
        guard let idx = texts.firstIndex(where: { $0.id == id }) else { return }
        pushUndo()
        texts[idx].fontWeightKind = weight
        texts[idx].styleTemplateId = nil
    }

    func setTextItalic(id: UUID, italic: Bool) {
        guard let idx = texts.firstIndex(where: { $0.id == id }) else { return }
        pushUndo()
        texts[idx].isItalic = italic
        texts[idx].styleTemplateId = nil
    }

    func removeText(id: UUID) {
        guard texts.contains(where: { $0.id == id }) else { return }
        pushUndo()
        texts.removeAll { $0.id == id }
    }

    func removeStrokes(ids: Set<UUID>, recordUndo: Bool = true) {
        guard !ids.isEmpty else { return }
        if recordUndo { pushUndo() }
        strokes.removeAll { ids.contains($0.id) }
    }

    /// Tek bir silgi hareketi için: önce `beginStrokeEraseSession()`, sonra birden fazla `eraseStrokesNearSession`, sonra bitiş.
    func beginStrokeEraseSession() {
        pushUndo()
    }

    /// Silgi noktasına yakın şekil ve metinleri siler (`beginStrokeEraseSession` undo’su içinde; ayrı undo yok).
    private func eraseShapesAndTextsNear(point: CGPoint, threshold: CGFloat) {
        let shapeTol = max(threshold, 16)
        let toRemoveShapes = shapes.filter { s in
            s.hitDistance(to: point) <= max(shapeTol, s.lineWidth * 2.5 + 10)
        }.map(\.id)
        if !toRemoveShapes.isEmpty {
            shapes.removeAll { toRemoveShapes.contains($0.id) }
        }
        let toRemoveTexts = texts.filter { distanceToTextAnnotationBounds(point, $0) < threshold }.map(\.id)
        if !toRemoveTexts.isEmpty {
            texts.removeAll { toRemoveTexts.contains($0.id) }
        }
    }

    func eraseStrokesNearSession(point: CGPoint, threshold: CGFloat) {
        let toRemove = strokes.filter { $0.distanceToPoint(point) < threshold }.map(\.id)
        if !toRemove.isEmpty {
            strokes.removeAll { toRemove.contains($0.id) }
        }
        eraseShapesAndTextsNear(point: point, threshold: threshold)
    }

    func removeStroke(id: UUID) {
        removeStrokes(ids: [id])
    }

    /// Object eraser (tek tık / kısa işlem): tam undo adımı ile.
    func eraseStrokesNear(point: CGPoint, threshold: CGFloat) {
        let strokeIds = strokes.filter { $0.distanceToPoint(point) < threshold }.map(\.id)
        let shapeTol = max(threshold, 16)
        let shapeIds = shapes.filter { s in
            s.hitDistance(to: point) <= max(shapeTol, s.lineWidth * 2.5 + 10)
        }.map(\.id)
        let textIds = texts.filter { distanceToTextAnnotationBounds(point, $0) < threshold }.map(\.id)
        guard !strokeIds.isEmpty || !shapeIds.isEmpty || !textIds.isEmpty else { return }
        pushUndo()
        if !strokeIds.isEmpty {
            strokes.removeAll { strokeIds.contains($0.id) }
        }
        if !shapeIds.isEmpty {
            shapes.removeAll { shapeIds.contains($0.id) }
        }
        if !textIds.isEmpty {
            texts.removeAll { textIds.contains($0.id) }
        }
    }

    /// Piksel silgi maskesi ile aynı undo adımında: yol üzerindeki ok/şekil/metinleri siler.
    func appendPixelEraserStroke(_ stroke: Stroke, pathPoints: [CGPoint], annotationEraseThreshold: CGFloat) {
        pushUndo()
        let step = max(5.0, annotationEraseThreshold * 0.4)
        var lastSample: CGPoint?
        for p in pathPoints {
            if let q = lastSample, hypot(p.x - q.x, p.y - q.y) < step { continue }
            lastSample = p
            eraseShapesAndTextsNear(point: p, threshold: annotationEraseThreshold)
        }
        if lastSample == nil, let first = pathPoints.first {
            eraseShapesAndTextsNear(point: first, threshold: annotationEraseThreshold)
        }
        strokes.append(stroke)
    }

    func removeShape(id: UUID) {
        guard shapes.contains(where: { $0.id == id }) else { return }
        pushUndo()
        shapes.removeAll { $0.id == id }
    }

    /// Sürükleme sırasında tek undo oturumu (`beginShapeMove`); anlık konum güncellemesi.
    func replaceShapeRect(id: UUID, with rect: CGRect) {
        guard let idx = shapes.firstIndex(where: { $0.id == id }) else { return }
        var s = shapes[idx]
        if s.kind.isLineSegmentTool {
            let (a, b) = LineArrowTool.endpoints(from: rect)
            s.lineFrom = a
            s.lineTo = b
            s.rect = LineArrowTool.storageRect(start: a, end: b)
        } else {
            s.rect = rect.standardized
        }
        shapes[idx] = s
    }

    /// Köşe ölçekleme vb. tek hareket için bir kez (`beginShapeMove` / `beginSketchStrokeMove` yerine).
    func beginAnnotationGeometryEdit() {
        pushUndo()
    }

    /// Çizgi / ok: uçları doğrudan yazar (`replaceShapeRect` yalnızca `rect` köşegenine bağlı kaldığı için).
    func replaceShapeLineEndpoints(id: UUID, from a: CGPoint, to b: CGPoint) {
        guard let idx = shapes.firstIndex(where: { $0.id == id }) else { return }
        var s = shapes[idx]
        guard s.kind.isLineSegmentTool else { return }
        s.lineFrom = a
        s.lineTo = b
        s.rect = LineArrowTool.storageRect(start: a, end: b)
        shapes[idx] = s
    }

    /// Serbest çizgi ölçeklemesi: undo dışında anlık güncelleme.
    func replaceSketchStrokePoints(id: UUID, points: [CGPoint]) {
        guard let idx = strokes.firstIndex(where: { $0.id == id }) else { return }
        strokes[idx].points = points
    }

    /// Metin kutusu ölçeklemesi sırasında undo yok; başta `beginAnnotationGeometryEdit`.
    func setTextPositionAndFontSize(id: UUID, position: CGPoint, fontSize: CGFloat) {
        guard let idx = texts.firstIndex(where: { $0.id == id }) else { return }
        texts[idx].position = position
        texts[idx].fontSize = min(96, max(8, fontSize))
    }

    /// Kapalı şekil dönüşü (undo yok; jest başında `beginAnnotationGeometryEdit`).
    func setShapeRotation(id: UUID, radians: CGFloat) {
        guard let idx = shapes.firstIndex(where: { $0.id == id }) else { return }
        var s = shapes[idx]
        guard !s.kind.isLineSegmentTool else { return }
        s.rotationRadians = radians
        shapes[idx] = s
    }

    func setTextRotation(id: UUID, radians: CGFloat) {
        guard let idx = texts.firstIndex(where: { $0.id == id }) else { return }
        texts[idx].rotationRadians = radians
    }
}

#if DEBUG
extension DrawingDocument {
    /// Uzun ders / bellek senaryosu: tek undo adımında çok sayıda stroke ekler (Ayarlar → Geliştirici).
    func appendStressStrokes(strokeCount: Int = 3000, pointsPerStroke: Int = 14) {
        pushUndo()
        var next = strokes
        next.reserveCapacity(next.count + strokeCount)
        for i in 0..<strokeCount {
            let base = CGFloat(i % 600)
            let pts = (0..<pointsPerStroke).map { j in
                CGPoint(
                    x: base + CGFloat(j) * 2.5,
                    y: 80 + CGFloat(i % 300) + sin(CGFloat(j + i) * 0.15) * 6
                )
            }
            next.append(Stroke(points: pts, color: .red, width: 2, tool: .pen, opacity: 1))
        }
        strokes = next
    }
}
#endif
