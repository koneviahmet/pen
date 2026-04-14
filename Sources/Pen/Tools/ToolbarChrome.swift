import SwiftUI

/// Uygulama genelinde aynı SF Symbols ailesi: dolu / çember çerçeveli çizim araçları, oklar, metin.
/// macOS 14+ SF Symbols 5 ile uyumlu isimler.
enum ToolbarChrome {
    /// Menü çubuğu ikonu
    static let appMenuBar = "pencil.tip.crop.circle.fill"

    /// Araç çubuğu sabit düğmeler
    static let undo = "arrow.uturn.backward.circle.fill"
    static let more = "ellipsis.circle.fill"

    static let toolbarIconFont: Font = .system(size: 16, weight: .medium, design: .rounded)

    // MARK: - Koyu yüzen palet (hafif soğuk gri, üst vurgu, seçili = beyaz daire)

    /// Ana gövde — nötr koyu (System Gray benzeri, hafif mavi gölgeli)
    static let darkBarFill = Color(red: 0.13, green: 0.14, blue: 0.17)
    /// Yan şekil paneli — ana çubuktan bir ton açık
    static let darkPanelFill = Color(red: 0.16, green: 0.17, blue: 0.20)

    /// Üst kenar cam parlaması (LinearGradient ile kullanılır)
    static let barHighlightTop = Color.white.opacity(0.14)

    static let iconOnBar = Color.white.opacity(0.95)
    static let iconOnBarMuted = Color.white.opacity(0.42)
    static let selectionCircleFill = Color.white
    static let selectionIconOnCircle = Color(red: 0.12, green: 0.13, blue: 0.16)

    static let barEdgeStroke = Color.white.opacity(0.12)
    static let dragGripColor = Color.white.opacity(0.48)

    /// Gruplar arası ince ayırıcı
    static let dividerColor = Color.white.opacity(0.14)

    /// Kalınlık önizlemesi zemin
    static let swatchWellFill = Color.white.opacity(0.1)
}
