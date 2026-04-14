import Foundation

enum AppPreferences {
    private static let ud = UserDefaults.standard

    static let mergeDesktopExportKey = "pen.mergeDesktopExport"
    static let toolbarAutoHideKey = "pen.toolbarAutoHide"
    static let globalToggleKeyCharacterKey = "pen.globalToggleKeyChar"
    static let toolbarOffsetXKey = "pen.toolbarOffsetX"
    static let toolbarOffsetYKey = "pen.toolbarOffsetY"
    static let recentStrokeColorsKey = "pen.recentStrokeColors"
    static let lastTextStyleTemplateIdKey = "pen.lastTextStyleTemplateId"

    static var mergeDesktopExport: Bool {
        get { ud.object(forKey: mergeDesktopExportKey) as? Bool ?? false }
        set { ud.set(newValue, forKey: mergeDesktopExportKey) }
    }

    /// Daraltılmış araç çubuğu: kenardaki şeride gelince genişlet.
    static var toolbarAutoHide: Bool {
        get { ud.object(forKey: toolbarAutoHideKey) as? Bool ?? true }
        set { ud.set(newValue, forKey: toolbarAutoHideKey) }
    }

    /// Küçük harf; ⌘ ile birlikte global tetik (Erişilebilirlik gerekir).
    static var globalToggleKeyCharacter: String {
        get { (ud.string(forKey: globalToggleKeyCharacterKey) ?? "d").lowercased() }
        set { ud.set(newValue.lowercased(), forKey: globalToggleKeyCharacterKey) }
    }

    /// Ana araç çubuğu konumu (sağ-alt varsayılanına göre delta; sürükle-bırak).
    static var floatingToolbarOffset: CGSize {
        get {
            CGSize(
                width: CGFloat(ud.double(forKey: toolbarOffsetXKey)),
                height: CGFloat(ud.double(forKey: toolbarOffsetYKey))
            )
        }
        set {
            ud.set(Double(newValue.width), forKey: toolbarOffsetXKey)
            ud.set(Double(newValue.height), forKey: toolbarOffsetYKey)
        }
    }

    /// Son kullanılan çizim renkleri (en fazla 5), `RRGGBBAA` dizisi.
    static func loadRecentStrokeColorHexes() -> [String] {
        (ud.array(forKey: recentStrokeColorsKey) as? [String])?
            .prefix(5)
            .map { $0 } ?? []
    }

    static func saveRecentStrokeColorHexes(_ hexes: [String]) {
        ud.set(Array(hexes.prefix(5)), forKey: recentStrokeColorsKey)
    }

    /// Son seçilen metin taslağı (`TextStyleTemplate.id`); yeni metin yerleştirmede varsayılan.
    static var lastTextStyleTemplateId: String? {
        get {
            let s = ud.string(forKey: lastTextStyleTemplateIdKey)
            guard let s, !s.isEmpty else { return nil }
            return s
        }
        set {
            if let newValue, !newValue.isEmpty {
                ud.set(newValue, forKey: lastTextStyleTemplateIdKey)
            } else {
                ud.removeObject(forKey: lastTextStyleTemplateIdKey)
            }
        }
    }

}
