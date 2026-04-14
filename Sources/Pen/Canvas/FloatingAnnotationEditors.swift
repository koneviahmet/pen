import AppKit
import SwiftUI

// MARK: - Renk (popover içinde yalnızca ColorPicker macOS’ta tek kare kalabiliyor → palet + tekerlek)

/// Hızlı seçim; `ColorPicker(.wheel)` ile tam spektrum.
private let editorSwatchPalette: [Color] = [
    Color(white: 0.06), Color(white: 0.22), Color(white: 0.38), Color(white: 0.52),
    Color(white: 0.68), Color(white: 0.82), Color(white: 0.93), .white,
    Color(red: 0.92, green: 0.14, blue: 0.18),
    Color(red: 1, green: 0.42, blue: 0.12),
    Color(red: 1, green: 0.78, blue: 0.12),
    Color(red: 0.45, green: 0.88, blue: 0.2),
    Color(red: 0.12, green: 0.68, blue: 0.38),
    Color(red: 0.12, green: 0.62, blue: 0.72),
    Color(red: 0.15, green: 0.42, blue: 0.95),
    Color(red: 0.42, green: 0.28, blue: 0.92),
    Color(red: 0.82, green: 0.22, blue: 0.78),
    Color(red: 0.95, green: 0.45, blue: 0.62),
    Color(red: 0.55, green: 0.32, blue: 0.2),
    Color(red: 0.35, green: 0.55, blue: 0.35),
    Color(red: 0.45, green: 0.55, blue: 0.6),
    Color(red: 0.95, green: 0.75, blue: 0.35),
    Color(red: 0.55, green: 0.75, blue: 0.95),
    Color(red: 0.75, green: 0.55, blue: 0.95),
    Color(red: 0.95, green: 0.55, blue: 0.45),
    Color(red: 0.25, green: 0.35, blue: 0.28),
]

/// macOS yerel renk kuyusu — tıklanınca tam renk paneli (spektrum) açılır; SwiftUI `ColorPicker` popover’da tek kare kalabiliyordu.
private struct EditorNSColorWell: NSViewRepresentable {
    @Binding var selection: Color

    func makeNSView(context: Context) -> NSColorWell {
        let w = NSColorWell(frame: .zero)
        w.isBordered = true
        w.isEnabled = true
        w.target = context.coordinator
        w.action = #selector(Coordinator.changed(_:))
        return w
    }

    func updateNSView(_ well: NSColorWell, context: Context) {
        let n = selection.resolvedNSColor()
        if well.color != n {
            well.color = n
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(selection: $selection)
    }

    final class Coordinator: NSObject {
        var selection: Binding<Color>
        init(selection: Binding<Color>) {
            self.selection = selection
        }

        @objc func changed(_ sender: NSColorWell) {
            selection.wrappedValue = Color(nsColor: sender.color)
        }
    }
}

private struct EditorPopoverColorPicker: View {
    @Binding var selection: Color
    @State private var open = false

    private var swatchColumns: [GridItem] {
        [GridItem(.adaptive(minimum: 26), spacing: 6)]
    }

    var body: some View {
        Button {
            open = true
        } label: {
            RoundedRectangle(cornerRadius: 4, style: .continuous)
                .fill(selection)
                .frame(width: 30, height: 22)
                .overlay(
                    RoundedRectangle(cornerRadius: 4, style: .continuous)
                        .strokeBorder(Color.primary.opacity(0.22), lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Renk")
        .popover(isPresented: $open, arrowEdge: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Hızlı renkler")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(.secondary)
                    LazyVGrid(columns: swatchColumns, spacing: 6) {
                        ForEach(0..<editorSwatchPalette.count, id: \.self) { i in
                            let c = editorSwatchPalette[i]
                            Button {
                                selection = c
                            } label: {
                                Circle()
                                    .fill(c)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Circle()
                                            .strokeBorder(Color.primary.opacity(c.isLightSwatch ? 0.4 : 0.18), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    Divider().opacity(0.35)
                    HStack(alignment: .center, spacing: 10) {
                        Text("Özel")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundStyle(.secondary)
                        EditorNSColorWell(selection: $selection)
                            .frame(width: 52, height: 28)
                        Text("tıkla → tam panel")
                            .font(.system(size: 9))
                            .foregroundStyle(.tertiary)
                    }
                }
                .padding(14)
            }
            .frame(minWidth: 268, maxHeight: 380)
        }
    }
}

// MARK: - Panel konumu (içerik görünür kalsın)

private enum AnnotationPanelLayout {
    /// Yaklaşık panel boyu — offset hesabı için (GeometryReader yok).
    static let textPanelEstimatedHeight: CGFloat = 400
    static let shapePanelEstimatedHeight: CGFloat = 120
    static let strokePanelEstimatedHeight: CGFloat = 100
    static let gap: CGFloat = 12
    static let margin: CGFloat = 8

    /// Metin kutusu yaklaşık yarı boyutu (`DrawingDocument.hitTestTextAnnotation` ile uyumlu).
    static func textHalfSize(for a: TextAnnotation) -> CGSize {
        let halfW = max(80, CGFloat(max(a.text.count, 2)) * a.fontSize * 0.28 + 36)
        let halfH = max(24, a.fontSize * 0.72 + 18)
        return CGSize(width: halfW, height: halfH)
    }

    /// Panel sol üst köşesi: içeriğin üstüne veya altına, ekranda sığdığı yere.
    static func textPanelTopLeading(contentCenter: CGPoint, half: CGSize, canvas: CGSize) -> CGPoint {
        let contentTop = contentCenter.y - half.height
        let contentBottom = contentCenter.y + half.height
        let W = min(420, canvas.width - 2 * margin)
        let H = textPanelEstimatedHeight
        var x = contentCenter.x - W / 2
        x = min(max(margin, x), canvas.width - W - margin)

        let topIfAbove = contentTop - gap - H
        let topIfBelow = contentBottom + gap

        let canAbove = topIfAbove >= margin
        let canBelow = topIfBelow + H <= canvas.height - margin

        let y: CGFloat
        if canBelow && canAbove {
            let roomAbove = contentTop - margin
            let roomBelow = canvas.height - contentBottom - margin
            if roomBelow >= roomAbove {
                y = topIfBelow
            } else {
                y = topIfAbove
            }
        } else if canBelow {
            y = topIfBelow
        } else if canAbove {
            y = topIfAbove
        } else {
            y = min(max(margin, topIfBelow), canvas.height - H - margin)
        }
        return CGPoint(x: x, y: y)
    }

    static func shapePanelTopLeading(shape: ShapeStroke, canvas: CGSize) -> CGPoint {
        let hr = shape.selectionHighlightRect
        let contentTop = hr.minY
        let contentBottom = hr.maxY
        let centerX = hr.midX
        let W = min(268, canvas.width - 2 * margin)
        let H = shapePanelEstimatedHeight

        var x = centerX - W / 2
        x = min(max(margin, x), canvas.width - W - margin)

        let topIfAbove = contentTop - gap - H
        let topIfBelow = contentBottom + gap

        let canAbove = topIfAbove >= margin
        let canBelow = topIfBelow + H <= canvas.height - margin

        let y: CGFloat
        if canBelow && canAbove {
            let roomAbove = contentTop - margin
            let roomBelow = canvas.height - contentBottom - margin
            if roomBelow >= roomAbove {
                y = topIfBelow
            } else {
                y = topIfAbove
            }
        } else if canBelow {
            y = topIfBelow
        } else if canAbove {
            y = topIfAbove
        } else {
            y = min(max(margin, topIfBelow), canvas.height - H - margin)
        }
        return CGPoint(x: x, y: y)
    }

    /// Serbest çizgi (kalem) sınırlayıcısına göre panel köşesi.
    static func strokePanelTopLeading(stroke: Stroke, canvas: CGSize) -> CGPoint {
        let hr = stroke.boundingRect.insetBy(dx: -18, dy: -18)
        let contentTop = hr.minY
        let contentBottom = hr.maxY
        let centerX = hr.midX
        let W = min(268, canvas.width - 2 * margin)
        let H = strokePanelEstimatedHeight

        var x = centerX - W / 2
        x = min(max(margin, x), canvas.width - W - margin)

        let topIfAbove = contentTop - gap - H
        let topIfBelow = contentBottom + gap

        let canAbove = topIfAbove >= margin
        let canBelow = topIfBelow + H <= canvas.height - margin

        let y: CGFloat
        if canBelow && canAbove {
            let roomAbove = contentTop - margin
            let roomBelow = canvas.height - contentBottom - margin
            if roomBelow >= roomAbove {
                y = topIfBelow
            } else {
                y = topIfAbove
            }
        } else if canBelow {
            y = topIfBelow
        } else if canAbove {
            y = topIfAbove
        } else {
            y = min(max(margin, topIfBelow), canvas.height - H - margin)
        }
        return CGPoint(x: x, y: y)
    }

    @MainActor
    static func editorPanelTopLeading(editor: AnnotationEditTarget, document: DrawingDocument, canvas: CGSize) -> CGPoint? {
        switch editor {
        case .text(let id):
            guard let a = document.texts.first(where: { $0.id == id }) else { return nil }
            let half = textHalfSize(for: a)
            return textPanelTopLeading(contentCenter: a.position, half: half, canvas: canvas)
        case .shape(let id):
            guard let s = document.shapes.first(where: { $0.id == id }) else { return nil }
            return shapePanelTopLeading(shape: s, canvas: canvas)
        case .sketchStroke(let id):
            guard let s = document.strokes.first(where: { $0.id == id }) else { return nil }
            return strokePanelTopLeading(stroke: s, canvas: canvas)
        }
    }

    static func editorPanelMinWidth(editor: AnnotationEditTarget) -> CGFloat {
        switch editor {
        case .text: return 280
        case .shape, .sketchStroke: return 200
        }
    }

    static func editorPanelMaxWidth(editor: AnnotationEditTarget, canvas: CGSize) -> CGFloat {
        switch editor {
        case .text: return min(400, canvas.width - 20)
        case .shape, .sketchStroke: return min(268, canvas.width - 20)
        }
    }
}

// MARK: - Panel açıkken tuval üzerinden taşıma (şekil + serbest çizgi; metin kutusunda sürükleme ayrı)

struct AnnotationEditorCanvasDragLayer: View {
    let editor: AnnotationEditTarget
    @ObservedObject var document: DrawingDocument
    var canvasCoordinateSpaceName: String

    @State private var lastDragTranslation: CGSize = .zero
    @State private var moveUndoRegistered = false

    var body: some View {
        switch editor {
        case .text:
            EmptyView()
        case .shape(let shapeId):
            shapeDrag(shapeId: shapeId)
        case .sketchStroke(let strokeId):
            sketchDrag(strokeId: strokeId)
        }
    }

    @ViewBuilder
    private func shapeDrag(shapeId: UUID) -> some View {
        if let s = document.shapes.first(where: { $0.id == shapeId }) {
            let r = s.selectionHighlightRect
            let w = max(r.width, 36)
            let h = max(r.height, 36)
            Color.clear
                .frame(width: w, height: h)
                .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .position(x: r.midX, y: r.midY)
                .gesture(dragGesture(
                    begin: { document.beginShapeMove(id: shapeId) },
                    apply: { document.translateShape(id: shapeId, by: $0) }
                ))
                .help("Sürükleyerek taşı")
        }
    }

    @ViewBuilder
    private func sketchDrag(strokeId: UUID) -> some View {
        if let s = document.strokes.first(where: { $0.id == strokeId }) {
            let r = s.boundingRect.insetBy(dx: -18, dy: -18)
            let w = max(r.width, 36)
            let h = max(r.height, 36)
            Color.clear
                .frame(width: w, height: h)
                .contentShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                .position(x: r.midX, y: r.midY)
                .gesture(dragGesture(
                    begin: { document.beginSketchStrokeMove(id: strokeId) },
                    apply: { document.translateSketchStroke(id: strokeId, by: $0) }
                ))
                .help("Sürükleyerek taşı")
        }
    }

    private func dragGesture(begin: @escaping () -> Void, apply: @escaping (CGSize) -> Void) -> some Gesture {
        DragGesture(minimumDistance: 2, coordinateSpace: .named(canvasCoordinateSpaceName))
            .onChanged { value in
                let d = CGSize(
                    width: value.translation.width - lastDragTranslation.width,
                    height: value.translation.height - lastDragTranslation.height
                )
                lastDragTranslation = value.translation
                if !moveUndoRegistered {
                    begin()
                    moveUndoRegistered = true
                }
                apply(d)
            }
            .onEnded { _ in
                lastDragTranslation = .zero
                moveUndoRegistered = false
            }
    }
}


// MARK: - Tek yüzen düzenleyici (metin / şekil / serbest çizgi)

struct AnnotationFloatingEditorPanel: View {
    let editor: AnnotationEditTarget
    @ObservedObject var document: DrawingDocument
    var canvasSize: CGSize
    var onClose: () -> Void

    var body: some View {
        if let topLeading = AnnotationPanelLayout.editorPanelTopLeading(editor: editor, document: document, canvas: canvasSize) {
            VStack(alignment: .leading, spacing: 0) {
                editorHeader
                switch editor {
                case .text(let id):
                    textForm(annotationId: id)
                case .shape(let id):
                    shapeForm(shapeId: id)
                case .sketchStroke(let id):
                    sketchForm(strokeId: id)
                }
            }
            .frame(
                minWidth: AnnotationPanelLayout.editorPanelMinWidth(editor: editor),
                maxWidth: AnnotationPanelLayout.editorPanelMaxWidth(editor: editor, canvas: canvasSize)
            )
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(Color.black.opacity(0.56))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .strokeBorder(Color.white.opacity(0.09), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.22), radius: 10, x: 0, y: 4)
            .offset(x: topLeading.x, y: topLeading.y)
            .onExitCommand { onClose() }
        }
    }

    private var editorHeader: some View {
        HStack(spacing: 8) {
            Text(editorHeaderTitle)
                .font(.system(size: 11, weight: .semibold))
                .foregroundStyle(.primary.opacity(0.92))
            Spacer(minLength: 4)
            Button(role: .destructive) {
                switch editor {
                case .text(let id): document.removeText(id: id)
                case .shape(let id): document.removeShape(id: id)
                case .sketchStroke(let id): document.removeStroke(id: id)
                }
                onClose()
            } label: {
                Image(systemName: "trash")
                    .font(.system(size: 11, weight: .medium))
            }
            .buttonStyle(.plain)
            Button {
                onClose()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.escape, modifiers: [])
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
    }

    private var editorHeaderTitle: String {
        switch editor {
        case .text: return "Metin"
        case .shape: return "Şekil"
        case .sketchStroke: return "Çizgi"
        }
    }

    @ViewBuilder
    private func textForm(annotationId: UUID) -> some View {
        if let a = document.texts.first(where: { $0.id == annotationId }) {
            let binding = Binding(
                get: { document.texts.first(where: { $0.id == annotationId })?.text ?? "" },
                set: { document.setTextContent(id: annotationId, text: $0) }
            )
            VStack(alignment: .leading, spacing: 8) {
                TextField("Metin", text: binding, axis: .vertical)
                    .textFieldStyle(.plain)
                    .font(a.resolvedSwiftUIFont())
                    .textAnnotationForeground(a)
                    .lineLimit(3...16)
                    .padding(8)
                    .background(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(Color(nsColor: .textBackgroundColor).opacity(0.88))
                    )

                templateStrip(annotationId: annotationId, annotation: a)

                HStack(spacing: 8) {
                    Picker("", selection: Binding(
                        get: { a.fontWeightKind },
                        set: { document.setTextFontWeight(id: annotationId, weight: $0) }
                    )) {
                        Text("İnce").tag(TextFontWeightKind.light)
                        Text("Normal").tag(TextFontWeightKind.regular)
                        Text("Orta").tag(TextFontWeightKind.medium)
                        Text("Kalın").tag(TextFontWeightKind.bold)
                    }
                    .pickerStyle(.menu)
                    .controlSize(.small)
                    .frame(maxWidth: 120)
                    Toggle("İ", isOn: Binding(
                        get: { a.isItalic },
                        set: { document.setTextItalic(id: annotationId, italic: $0) }
                    ))
                    .toggleStyle(.checkbox)
                    .controlSize(.small)
                    Spacer(minLength: 0)
                    Button { document.setTextFontSize(id: annotationId, fontSize: a.fontSize - 2) } label: {
                        Image(systemName: "minus").font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                    Text("\(Int(a.fontSize))")
                        .font(.system(size: 10, weight: .semibold, design: .rounded))
                        .monospacedDigit()
                        .frame(minWidth: 22)
                    Button { document.setTextFontSize(id: annotationId, fontSize: a.fontSize + 2) } label: {
                        Image(systemName: "plus").font(.system(size: 11, weight: .semibold))
                    }
                    .buttonStyle(.plain)
                }

                HStack(spacing: 10) {
                    EditorPopoverColorPicker(selection: Binding(
                        get: { document.texts.first(where: { $0.id == annotationId })?.color ?? .black },
                        set: { document.setTextColor(id: annotationId, color: $0) }
                    ))
                    EditorPopoverColorPicker(selection: Binding(
                        get: { document.texts.first(where: { $0.id == annotationId })?.backgroundColor ?? .white },
                        set: { document.setTextBackgroundColor(id: annotationId, color: $0) }
                    ))
                    Text("yazı · arka")
                        .font(.system(size: 9))
                        .foregroundStyle(.tertiary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 10)
        }
    }

    @ViewBuilder
    private func templateStrip(annotationId: UUID, annotation a: TextAnnotation) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach(TextStyleTemplate.all) { tpl in
                    let selected = a.styleTemplateId == tpl.id
                    Button {
                        document.applyTextStyleTemplate(id: annotationId, template: tpl)
                        AppPreferences.lastTextStyleTemplateId = tpl.id
                    } label: {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .fill(selected ? TextStyleTemplate.chipBackgroundSelected : TextStyleTemplate.chipBackgroundUnselected)
                                .frame(width: 36, height: 36)
                            tpl.previewChip()
                        }
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .strokeBorder(selected ? Color.accentColor.opacity(0.55) : Color.clear, lineWidth: 1.5)
                        )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .frame(height: 42)
    }

    @ViewBuilder
    private func shapeForm(shapeId: UUID) -> some View {
        if let s = document.shapes.first(where: { $0.id == shapeId }) {
            HStack(spacing: 10) {
                EditorPopoverColorPicker(selection: Binding(
                    get: { document.shapes.first(where: { $0.id == shapeId })?.color ?? .black },
                    set: { document.setShapeColor(id: shapeId, color: $0) }
                ))
                Text(s.kind.label)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                compactStepper(
                    value: Int(s.lineWidth),
                    decrement: {
                        guard let cur = document.shapes.first(where: { $0.id == shapeId }) else { return }
                        document.setShapeLineWidth(id: shapeId, width: cur.lineWidth - 1)
                    },
                    increment: {
                        guard let cur = document.shapes.first(where: { $0.id == shapeId }) else { return }
                        document.setShapeLineWidth(id: shapeId, width: cur.lineWidth + 1)
                    }
                )
                Slider(
                    value: Binding(
                        get: { Double(document.shapes.first(where: { $0.id == shapeId })?.opacity ?? 1) },
                        set: { document.setShapeOpacity(id: shapeId, opacity: CGFloat($0)) }
                    ),
                    in: 0.05...1
                )
                .controlSize(.small)
                .frame(maxWidth: 110)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 9)
        }
    }

    @ViewBuilder
    private func sketchForm(strokeId: UUID) -> some View {
        if let s = document.strokes.first(where: { $0.id == strokeId }) {
            HStack(spacing: 10) {
                EditorPopoverColorPicker(selection: Binding(
                    get: { document.strokes.first(where: { $0.id == strokeId })?.color ?? .black },
                    set: { document.setSketchStrokeColor(id: strokeId, color: $0) }
                ))
                Text(s.tool.label)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
                    .lineLimit(1)
                Spacer(minLength: 0)
                compactStepper(
                    value: Int(s.width),
                    decrement: {
                        guard let cur = document.strokes.first(where: { $0.id == strokeId }) else { return }
                        document.setSketchStrokeWidth(id: strokeId, width: cur.width - 1)
                    },
                    increment: {
                        guard let cur = document.strokes.first(where: { $0.id == strokeId }) else { return }
                        document.setSketchStrokeWidth(id: strokeId, width: cur.width + 1)
                    }
                )
                Slider(
                    value: Binding(
                        get: { Double(document.strokes.first(where: { $0.id == strokeId })?.opacity ?? 1) },
                        set: { document.setSketchStrokeOpacity(id: strokeId, opacity: CGFloat($0)) }
                    ),
                    in: 0.05...1
                )
                .controlSize(.small)
                .frame(maxWidth: 110)
            }
            .padding(.horizontal, 10)
            .padding(.bottom, 9)
        }
    }

    private func compactStepper(value: Int, decrement: @escaping () -> Void, increment: @escaping () -> Void) -> some View {
        HStack(spacing: 2) {
            Button(action: decrement) {
                Image(systemName: "minus")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 20, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            Text("\(value)")
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .frame(minWidth: 20)
            Button(action: increment) {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .bold))
                    .frame(width: 20, height: 22)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
    }
}
