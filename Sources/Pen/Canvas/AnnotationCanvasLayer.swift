import AppKit
import SwiftUI

struct AnnotationCanvasLayer: View {
    @ObservedObject var document: DrawingDocument
    @ObservedObject var appState: AppState
    @Binding var currentStrokePoints: [CGPoint]
    @Binding var activeTextId: UUID?

    /// `MainOverlayView` ile aynı isim — `DragGesture` konumları `Canvas` ile ortak uzayda olur.
    var canvasCoordinateSpaceName: String

    @State private var strokeEraseSessionStarted = false
    @State private var dragPointerStart: CGPoint?
    @State private var lastQuickTap: (Date, CGPoint)?

    var body: some View {
        GeometryReader { geo in
            let size = geo.size
            ZStack {
                rasterizedDrawing(size: size)
                    .allowsHitTesting(false)
                Color.clear
                    .contentShape(Rectangle())
                    .allowsHitTesting(
                        appState.textComposerPosition == nil
                            && appState.overlayEditor == nil
                    )
                    .onHover { hovering in
                        if appState.currentTool == .select, hovering {
                            NSCursor.pointingHand.set()
                        } else {
                            NSCursor.arrow.set()
                        }
                    }
                    .gesture(canvasDragGesture)
                textAnnotations(size: size)
                annotationEditorDragOverlay(canvasSize: size)
                if let ed = appState.overlayEditor, editorTargetStillExists(ed) {
                    AnnotationTransformHandlesOverlay(
                        document: document,
                        editor: ed,
                        canvasCoordinateSpaceName: canvasCoordinateSpaceName
                    )
                }
                floatingAnnotationEditors(canvasSize: size)
                if appState.textComposerPosition != nil {
                    CanvasTextComposer(document: document, appState: appState, canvasSize: size)
                        .zIndex(50)
                }
            }
            .frame(width: size.width, height: size.height)
            .onChange(of: appState.currentTool) { _, t in
                if t != .text {
                    appState.textComposerPosition = nil
                    appState.textComposerDraft = ""
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var canvasDragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .named(canvasCoordinateSpaceName))
            .onChanged { value in
                let p = value.location
                if dragPointerStart == nil {
                    dragPointerStart = p
                }
                handlePointerMoved(to: p)
            }
            .onEnded { value in
                strokeEraseSessionStarted = false
                let endPoint = value.location
                if appState.currentTool.isShapeTool {
                    appState.shapeDragCurrent = endPoint
                }
                handlePointerUp(at: endPoint)
                dragPointerStart = nil
            }
    }

    /// Çok sayıda stroke’ta Metal tabanlı raster önbellek (`drawingGroup`).
    @ViewBuilder
    private func rasterizedDrawing(size: CGSize) -> some View {
        let heavy = document.strokes.count + document.shapes.count > 400
        let view = drawingCanvas(size: size)
        if heavy {
            view.drawingGroup(opaque: false)
        } else {
            view
        }
    }

    private func drawingCanvas(size: CGSize) -> some View {
        Canvas { context, canvasSize in
            for shape in document.shapes {
                DrawingPathRenderer.drawShape(shape, in: &context)
            }
            if let ed = appState.overlayEditor {
                switch ed {
                case .shape(let sid):
                    if let sel = document.shapes.first(where: { $0.id == sid }) {
                        DrawingPathRenderer.drawSelectionHighlight(for: sel, in: &context)
                    }
                case .sketchStroke(let kid):
                    if let st = document.strokes.first(where: { $0.id == kid }) {
                        DrawingPathRenderer.drawSketchStrokeSelectionHighlight(for: st, in: &context)
                    }
                case .text:
                    break
                }
            }

            for stroke in document.strokes where !stroke.isEraserMask {
                drawStrokeAdjusted(&context, stroke: stroke, canvasSize: canvasSize)
            }

            for stroke in document.strokes where stroke.isEraserMask {
                context.blendMode = .destinationOut
                DrawingPathRenderer.drawStroke(stroke, in: &context)
                context.blendMode = .normal
            }

            if !currentStrokePoints.isEmpty, let preview = previewStroke {
                drawStrokeAdjusted(&context, stroke: preview, canvasSize: canvasSize)
            }

            if let start = appState.shapeDragStart, let cur = appState.shapeDragCurrent {
                let shift = NSEvent.modifierFlags.contains(.shift)
                let rect: CGRect
                switch appState.currentTool {
                case .shapeLine, .shapeArrow, .shapeArrowStart, .shapeArrowDouble:
                    let end = LineArrowTool.constrainedEnd(from: start, to: cur, shiftPressed: shift)
                    rect = LineArrowTool.storageRect(start: start, end: end)
                    let temp = ShapeStroke(rect: rect, kind: appState.currentTool, color: appState.strokeColor, lineWidth: appState.strokeWidth, opacity: appState.strokeOpacity)
                    DrawingPathRenderer.drawShape(temp, in: &context)
                default:
                    rect = StrokeSmoothing.constrainRect(from: start, to: cur, shiftPressed: shift)
                    let temp = ShapeStroke(rect: rect, kind: appState.currentTool, color: appState.strokeColor, lineWidth: appState.strokeWidth, opacity: appState.strokeOpacity)
                    DrawingPathRenderer.drawShape(temp, in: &context)
                }
            }
        }
    }

    private func drawStrokeAdjusted(_ context: inout GraphicsContext, stroke: Stroke, canvasSize: CGSize) {
        let s = stroke
        if s.tool == .highlighter {
            context.blendMode = .multiply
        }
        let scale = appState.lastPressure
        let widthScale: CGFloat = (s.tool == .pen || s.tool == .pencil) ? max(0.4, scale) : 1
        DrawingPathRenderer.drawStroke(s, in: &context, lineWidthScale: widthScale)
        context.blendMode = .normal
    }

    private var previewStroke: Stroke? {
        guard appState.currentTool != .select else { return nil }
        guard !currentStrokePoints.isEmpty else { return nil }
        let tool = appState.currentTool
        let pts: [CGPoint]
        switch tool {
        case .pen, .pencil:
            pts = StrokeSmoothing.smooth(currentStrokePoints)
        default:
            pts = currentStrokePoints
        }
        let width: CGFloat
        let opacity: CGFloat
        let color: Color
        switch tool {
        case .highlighter:
            width = appState.highlighterWidth
            opacity = 0.35
            color = appState.strokeColor
        case .pencil:
            width = appState.strokeWidth * 0.85
            opacity = 0.88
            color = appState.strokeColor.opacity(0.9)
        case .eraserPixel:
            width = appState.strokeWidth * 1.2
            opacity = 1
            color = .white
        default:
            width = appState.strokeWidth * max(0.5, appState.lastPressure)
            opacity = appState.strokeOpacity
            color = appState.strokeColor
        }
        return Stroke(
            points: pts,
            color: color,
            width: width,
            tool: tool == .eraserPixel ? .eraserPixel : tool,
            opacity: opacity,
            isEraserMask: tool == .eraserPixel
        )
    }

    @ViewBuilder
    private func textAnnotations(size: CGSize) -> some View {
        ForEach(document.texts) { t in
            DraggableTextField(
                annotationId: t.id,
                document: document,
                appState: appState,
                activeTextId: $activeTextId,
                canvasCoordinateSpaceName: canvasCoordinateSpaceName
            )
        }
    }

    private func floatingAnnotationEditors(canvasSize: CGSize) -> some View {
        ZStack(alignment: .topLeading) {
            if let editor = appState.overlayEditor, editorTargetStillExists(editor) {
                AnnotationFloatingEditorPanel(
                    editor: editor,
                    document: document,
                    canvasSize: canvasSize,
                    onClose: {
                        appState.overlayEditor = nil
                    }
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .allowsHitTesting(appState.overlayEditor != nil)
    }

    private func editorTargetStillExists(_ editor: AnnotationEditTarget) -> Bool {
        switch editor {
        case .text(let id): return document.texts.contains(where: { $0.id == id })
        case .shape(let id): return document.shapes.contains(where: { $0.id == id })
        case .sketchStroke(let id): return document.strokes.contains(where: { $0.id == id })
        }
    }

    @ViewBuilder
    private func annotationEditorDragOverlay(canvasSize: CGSize) -> some View {
        if let ed = appState.overlayEditor {
            switch ed {
            case .text:
                EmptyView()
            case .shape, .sketchStroke:
                AnnotationEditorCanvasDragLayer(
                    editor: ed,
                    document: document,
                    canvasCoordinateSpaceName: canvasCoordinateSpaceName
                )
            }
        }
    }

    private func handlePointerMoved(to p: CGPoint) {
        let tool = appState.currentTool

        if tool == .select {
            return
        }

        if tool.isShapeTool {
            lastQuickTap = nil
        }
        if !currentStrokePoints.isEmpty {
            lastQuickTap = nil
        }

        if tool == .eraserStroke {
            if !strokeEraseSessionStarted {
                document.beginStrokeEraseSession()
                strokeEraseSessionStarted = true
            }
            document.eraseStrokesNearSession(point: p, threshold: max(appState.strokeWidth * 3, 16))
            syncEraserOverlayStateIfNeeded()
            return
        }

        if tool.isShapeTool {
            if appState.shapeDragStart == nil {
                appState.shapeDragStart = p
            }
            appState.shapeDragCurrent = p
            return
        }

        if tool == .text {
            return
        }

        if tool == .laser || tool == .spotlight {
            return
        }

        guard tool.usesContinuousStroke || tool == .pen || tool == .pencil || tool == .highlighter || tool == .eraserPixel else { return }

        if currentStrokePoints.isEmpty {
            currentStrokePoints = [p]
            return
        }
        if let last = currentStrokePoints.last, hypot(p.x - last.x, p.y - last.y) < 0.4 {
            return
        }
        currentStrokePoints.append(p)
    }

    private func handlePointerUp(at p: CGPoint) {
        let tool = appState.currentTool
        let start = dragPointerStart ?? p
        let clickDist = hypot(p.x - start.x, p.y - start.y)
        let emptySketch = currentStrokePoints.isEmpty
        let noShapePlacement = appState.shapeDragStart == nil
        let isQuickTap = clickDist < 10 && emptySketch && noShapePlacement

        // Seç / Düzenle: çift tıklama sayacını karıştırmamak için önce işle (serbest çizgi tuvalde şekillerin üstünde).
        if tool == .select, clickDist < 16, emptySketch, noShapePlacement {
            lastQuickTap = nil
            if let kid = document.hitTestSketchStroke(at: p) {
                activeTextId = nil
                appState.overlayEditor = .sketchStroke(kid)
                return
            }
            if let sid = document.hitTestShape(at: p) {
                activeTextId = nil
                appState.overlayEditor = .shape(sid)
                return
            }
            activeTextId = nil
            appState.overlayEditor = nil
            return
        }

        if isQuickTap {
            if let (t0, p0) = lastQuickTap,
               Date().timeIntervalSince(t0) < 0.48,
               hypot(p.x - p0.x, p.y - p0.y) < 22 {
                lastQuickTap = nil
                if document.hitTestTextAnnotation(at: p) == nil,
                   let kid = document.hitTestSketchStroke(at: p) {
                    activeTextId = nil
                    appState.overlayEditor = .sketchStroke(kid)
                    appState.textComposerPosition = nil
                    appState.textComposerDraft = ""
                    return
                }
                if document.hitTestTextAnnotation(at: p) == nil,
                   let sid = document.hitTestShape(at: p) {
                    activeTextId = nil
                    appState.overlayEditor = .shape(sid)
                    appState.textComposerPosition = nil
                    appState.textComposerDraft = ""
                    return
                }
            } else {
                lastQuickTap = (Date(), p)
            }
        } else {
            lastQuickTap = nil
        }

        if tool == .text {
            if let hit = document.hitTestTextAnnotation(at: p) {
                appState.textComposerPosition = nil
                appState.textComposerDraft = ""
                activeTextId = hit
                return
            }
            let dist = hypot(p.x - start.x, p.y - start.y)
            if dist < 16 {
                activeTextId = nil
                appState.textComposerPosition = p
                appState.textComposerDraft = ""
            }
            return
        }

        if tool.isShapeTool, let shapeStart = appState.shapeDragStart {
            let shift = NSEvent.modifierFlags.contains(.shift)
            let rect: CGRect
            let lineEndpoints: (CGPoint, CGPoint)?
            switch tool {
            case .shapeLine, .shapeArrow, .shapeArrowStart, .shapeArrowDouble:
                let liveEnd = appState.shapeDragCurrent ?? p
                let end = LineArrowTool.constrainedEnd(from: shapeStart, to: liveEnd, shiftPressed: shift)
                rect = LineArrowTool.storageRect(start: shapeStart, end: end)
                lineEndpoints = (shapeStart, end)
            default:
                rect = StrokeSmoothing.constrainRect(from: shapeStart, to: p, shiftPressed: shift)
                lineEndpoints = nil
            }
            if tool.isLineSegmentTool {
                if hypot(rect.size.width, rect.size.height) > LineArrowTool.minCommitLength,
                   let (a, b) = lineEndpoints {
                    document.appendShape(
                        ShapeStroke(
                            rect: rect,
                            kind: tool,
                            color: appState.strokeColor,
                            lineWidth: appState.strokeWidth,
                            opacity: appState.strokeOpacity,
                            lineFrom: a,
                            lineTo: b
                        )
                    )
                }
            } else if rect.width > 2 || rect.height > 2 {
                document.appendShape(
                    ShapeStroke(rect: rect, kind: tool, color: appState.strokeColor, lineWidth: appState.strokeWidth, opacity: appState.strokeOpacity)
                )
            }
            appState.shapeDragStart = nil
            appState.shapeDragCurrent = nil
            return
        }

        guard !currentStrokePoints.isEmpty else { return }

        let pts: [CGPoint]
        switch tool {
        case .pen, .pencil:
            pts = StrokeSmoothing.smooth(currentStrokePoints)
        default:
            pts = currentStrokePoints
        }

        let width: CGFloat
        let opacity: CGFloat
        let color: Color
        let isEraser: Bool
        switch tool {
        case .highlighter:
            width = appState.highlighterWidth
            opacity = 0.4
            color = appState.strokeColor
            isEraser = false
        case .pencil:
            width = appState.strokeWidth * 0.85
            opacity = 0.9
            color = appState.strokeColor.opacity(0.92)
            isEraser = false
        case .eraserPixel:
            width = appState.strokeWidth * 1.25
            opacity = 1
            color = .white
            isEraser = true
        default:
            width = appState.strokeWidth * max(0.45, appState.lastPressure)
            opacity = appState.strokeOpacity
            color = appState.strokeColor
            isEraser = false
        }

        let stroke = Stroke(
            points: pts,
            color: color,
            width: width,
            tool: tool == .eraserPixel ? .eraserPixel : tool,
            opacity: opacity,
            isEraserMask: isEraser
        )
        if tool == .eraserPixel {
            let t = max(width * 1.35, 12)
            document.appendPixelEraserStroke(stroke, pathPoints: pts, annotationEraseThreshold: t)
            syncEraserOverlayStateIfNeeded()
        } else {
            document.appendStroke(stroke)
        }
        currentStrokePoints = []
    }

    /// Silgi ile kaldırılan öğe için açık paneli kapat.
    private func syncEraserOverlayStateIfNeeded() {
        if let ed = appState.overlayEditor, !editorTargetStillExists(ed) {
            appState.overlayEditor = nil
        }
        if let aid = activeTextId,
           !document.texts.contains(where: { $0.id == aid }) {
            activeTextId = nil
        }
    }
}
