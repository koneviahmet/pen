import AppKit
import Combine
import SwiftUI

/// Yüzen düzenleyicide hangi öğe açık; tek panel ve tuval sürüklemesi bu tür üzerinden yönetilir.
enum AnnotationEditTarget: Equatable {
    case text(UUID)
    case shape(UUID)
    case sketchStroke(UUID)
}

@MainActor
final class AppState: ObservableObject {
    /// Varsayılan kapalı: overlay çizim yapmaz, tıklamalar geçer; minimal kalem ile açılır.
    @Published var drawingEnabled: Bool = false
    @Published var currentTool: DrawingTool = .pen
    @Published var strokeWidth: CGFloat = 4
    @Published var strokeOpacity: CGFloat = 1
    @Published var strokeColor: Color = .red
    /// Son seçilen renkler (en fazla 5); `AppPreferences` ile kalıcı.
    @Published private(set) var recentStrokeColors: [Color] = []
    @Published var whiteboard: WhiteboardBackground = .transparent
    @Published var spotlightEnabled: Bool = false
    @Published var magnifierEnabled: Bool = false
    @Published var toolbarCollapsed: Bool = false
    @Published var toolbarEdge: ToolbarEdge = .leading
    @Published var qrScanInProgress: Bool = false
    @Published var qrScanValue: String?
    @Published var qrScanMessage: String?

    /// Ana araç çubuğu sürükleme ofseti (sağ-alt + padding referansına göre).
    @Published var floatingToolbarOffset: CGSize = AppPreferences.floatingToolbarOffset

    /// Laser pointer position in overlay coordinates (nil = hidden)
    @Published var laserPosition: CGPoint?
    @Published var laserTrail: [CGPoint] = []

    /// Spotlight center (overlay coords)
    @Published var spotlightCenter: CGPoint = .zero

    /// Shape drag preview
    @Published var shapeDragStart: CGPoint?
    @Published var shapeDragCurrent: CGPoint?

    /// Yeni metin yerleştirme: tuval koordinatında geçici düzenleyici (nil = kapalı).
    @Published var textComposerPosition: CGPoint?
    @Published var textComposerDraft: String = ""

    /// Seç / Düzenle: metin, şekil veya serbest çizgi için tek yüzen panel (`AnnotationFloatingEditorPanel`).
    @Published var overlayEditor: AnnotationEditTarget?

    /// Pressure from tablet (0...1), 1 if unavailable
    @Published var lastPressure: CGFloat = 1

    var highlighterWidth: CGFloat { max(strokeWidth * 3, 12) }

    private var cancellables = Set<AnyCancellable>()

    init() {
        recentStrokeColors = AppPreferences.loadRecentStrokeColorHexes().compactMap { Color(rgbaHex: $0) }
        $drawingEnabled
            .sink { [weak self] enabled in
                guard enabled else { return }
                self?.currentTool = .pen
            }
            .store(in: &cancellables)
    }

    func selectStrokeColor(_ color: Color) {
        strokeColor = color
        pushRecentStrokeColor(color)
    }

    /// Aynı renk tekrar seçilirse başa alınır; en fazla 5 kayıt.
    func pushRecentStrokeColor(_ color: Color) {
        let hex = color.rgbaHexString()
        var hexes = recentStrokeColors.map { $0.rgbaHexString() }
        hexes.removeAll { $0 == hex }
        hexes.insert(hex, at: 0)
        hexes = Array(hexes.prefix(5))
        recentStrokeColors = hexes.compactMap { Color(rgbaHex: $0) }
        AppPreferences.saveRecentStrokeColorHexes(hexes)
    }

    func toggleDrawingThrough() {
        drawingEnabled.toggle()
    }
}

enum ToolbarEdge: String, CaseIterable, Identifiable {
    case leading
    case trailing
    case top
    case bottom

    var id: String { rawValue }
}
