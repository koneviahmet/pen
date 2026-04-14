import SwiftUI

struct DraggableTextField: View {
    let annotationId: UUID
    @ObservedObject var document: DrawingDocument
    @ObservedObject var appState: AppState
    @Binding var activeTextId: UUID?

    var canvasCoordinateSpaceName: String

    @State private var moveUndoRegistered = false
    @State private var lastDragTranslation: CGSize = .zero

    private var annotation: TextAnnotation? {
        document.texts.first(where: { $0.id == annotationId })
    }

    private var isActive: Bool { activeTextId == annotationId }

    private var panelOpenForThis: Bool {
        if case .text(let id) = appState.overlayEditor { return id == annotationId }
        return false
    }

    private var selectMode: Bool { appState.currentTool == .select }

    var body: some View {
        if let a = annotation {
            let textBlock = Text(a.text.isEmpty ? "\u{200B}" : a.text)
                .font(a.resolvedSwiftUIFont())
                .textAnnotationForeground(a)
                .multilineTextAlignment(.leading)
                .lineLimit(nil)
                .fixedSize(horizontal: true, vertical: true)
                .frame(minWidth: 8, minHeight: 4)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .fill(a.backgroundColor)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 6, style: .continuous)
                        .strokeBorder(
                            (isActive || panelOpenForThis) ? Color.accentColor.opacity(0.85) : Color.primary.opacity(0.12),
                            lineWidth: (isActive || panelOpenForThis) ? 2 : 0.5
                        )
                )
                .contentShape(Rectangle())

            Group {
                if selectMode {
                    textBlock
                        .onTapGesture {
                            activeTextId = annotationId
                            appState.overlayEditor = .text(annotationId)
                        }
                } else {
                    textBlock
                        .highPriorityGesture(
                            TapGesture(count: 2)
                                .onEnded {
                                    activeTextId = annotationId
                                    appState.overlayEditor = .text(annotationId)
                                }
                        )
                        .onTapGesture {
                            activeTextId = annotationId
                        }
                }
            }
            .rotationEffect(.radians(a.rotationRadians), anchor: .center)
            .highPriorityGesture(
                DragGesture(
                    minimumDistance: 2,
                    coordinateSpace: .named(canvasCoordinateSpaceName)
                )
                .onChanged { value in
                    let d = CGSize(
                        width: value.translation.width - lastDragTranslation.width,
                        height: value.translation.height - lastDragTranslation.height
                    )
                    lastDragTranslation = value.translation
                    if !moveUndoRegistered {
                        document.beginTextMove(id: annotationId)
                        moveUndoRegistered = true
                    }
                    activeTextId = annotationId
                    guard let cur = document.texts.first(where: { $0.id == annotationId })?.position else { return }
                    document.moveText(
                        id: annotationId,
                        to: CGPoint(x: cur.x + d.width, y: cur.y + d.height)
                    )
                }
                .onEnded { _ in
                    lastDragTranslation = .zero
                    moveUndoRegistered = false
                }
            )
            .fixedSize(horizontal: true, vertical: true)
            .position(a.position)
            .help(selectMode ? "Tıkla: düzenle · Kutudan sürükle: taşı (panel açıkken de)" : "Çift tık: düzenle · Sürükle: taşı")
            .onChange(of: activeTextId) { _, new in
                if new != annotationId, panelOpenForThis {
                    appState.overlayEditor = nil
                }
            }
        }
    }
}

// MARK: - Metin rengi / gradient

extension View {
    @ViewBuilder
    func textAnnotationForeground(_ a: TextAnnotation) -> some View {
        if a.usesForegroundGradient {
            self.foregroundStyle(
                LinearGradient(
                    colors: [a.color, a.gradientEndColor],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        } else {
            self.foregroundStyle(a.color)
        }
    }
}
