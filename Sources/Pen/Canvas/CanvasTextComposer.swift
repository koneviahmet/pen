import AppKit
import SwiftUI

/// Yeni metin: tıklanan noktada açılan geçici alan; Enter veya «Yerleştir» ile belgeye eklenir.
struct CanvasTextComposer: View {
    @ObservedObject var document: DrawingDocument
    @ObservedObject var appState: AppState
    var canvasSize: CGSize

    @FocusState private var fieldFocused: Bool

    private var anchor: CGPoint {
        appState.textComposerPosition ?? .zero
    }

    private var defaultFontSize: CGFloat {
        min(44, max(16, appState.strokeWidth * 5))
    }

    private let anchorHalfW: CGFloat = 150
    private let anchorHalfH: CGFloat = 100

    var body: some View {
        if appState.textComposerPosition != nil {
            ZStack(alignment: .topLeading) {
                Color.clear
                    .frame(width: canvasSize.width, height: canvasSize.height)
                    .allowsHitTesting(false)

                VStack(alignment: .leading, spacing: 10) {
                    TextField("Yazınızı girin…", text: $appState.textComposerDraft)
                        .textFieldStyle(.plain)
                        .font(.system(size: 18, weight: .medium))
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .fill(Color(nsColor: .textBackgroundColor).opacity(0.94))
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 10, style: .continuous)
                                .strokeBorder(Color.white.opacity(0.18), lineWidth: 1)
                        )
                        .focused($fieldFocused)
                        .onSubmit { commit() }

                    HStack(spacing: 12) {
                        Label("Enter ile yerleştir", systemImage: "return.left")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 8)
                        Button("İptal") {
                            cancel()
                        }
                        .buttonStyle(.bordered)
                        .keyboardShortcut(.escape, modifiers: [])
                        .help("İptal (Esc)")
                        Button("Yerleştir") {
                            commit()
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(appState.textComposerDraft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                }
                .padding(14)
                .frame(minWidth: 280, maxWidth: min(400, max(280, canvasSize.width - 24)))
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.35), radius: 22, x: 0, y: 12)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(Color.white.opacity(0.14), lineWidth: 1)
                )
                .compositingGroup()
                .contentShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
                .offset(
                    x: max(8, min(anchor.x - anchorHalfW, canvasSize.width - 280 - 8)),
                    y: max(8, min(anchor.y - anchorHalfH, canvasSize.height - 120))
                )
            }
            .frame(width: canvasSize.width, height: canvasSize.height, alignment: .topLeading)
            .onAppear {
                NSApp.activate(ignoringOtherApps: true)
                if let w = NSApp.keyWindow ?? NSApp.windows.first(where: { $0.isVisible }) {
                    w.makeKey()
                }
                DispatchQueue.main.async {
                    fieldFocused = true
                }
            }
            .onExitCommand {
                cancel()
            }
        }
    }

    private func commit() {
        let t = appState.textComposerDraft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty, let p = appState.textComposerPosition else {
            cancel()
            return
        }
        var ann = TextAnnotation(
            position: p,
            text: t,
            fontSize: defaultFontSize,
            color: appState.strokeColor,
            backgroundColor: .white
        )
        if let tid = AppPreferences.lastTextStyleTemplateId,
           let tpl = TextStyleTemplate.template(id: tid) {
            tpl.apply(to: &ann)
        }
        document.appendText(ann)
        appState.textComposerPosition = nil
        appState.textComposerDraft = ""
        fieldFocused = false
    }

    private func cancel() {
        appState.textComposerPosition = nil
        appState.textComposerDraft = ""
        fieldFocused = false
    }
}
