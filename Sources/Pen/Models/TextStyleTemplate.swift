import SwiftUI

/// Instagram Hikâye tarzı hazır metin görünümleri (tek satır, yatay kaydırma).
struct TextStyleTemplate: Identifiable, Equatable {
    let id: String
    let title: String
    private let applyFn: (inout TextAnnotation) -> Void
    private let previewFn: () -> AnyView

    func apply(to text: inout TextAnnotation) {
        applyFn(&text)
    }

    @ViewBuilder
    func previewChip() -> some View {
        previewFn()
    }

    static func == (lhs: TextStyleTemplate, rhs: TextStyleTemplate) -> Bool {
        lhs.id == rhs.id
    }

    private init(
        id: String,
        title: String,
        apply: @escaping (inout TextAnnotation) -> Void,
        preview: @escaping () -> AnyView
    ) {
        self.id = id
        self.title = title
        self.applyFn = apply
        self.previewFn = preview
    }

    private static func make(
        id: String,
        title: String,
        apply: @escaping (inout TextAnnotation) -> Void,
        @ViewBuilder preview: @escaping () -> some View
    ) -> TextStyleTemplate {
        TextStyleTemplate(id: id, title: title, apply: apply, preview: { AnyView(preview()) })
    }

    // MARK: - Katalog

    static let all: [TextStyleTemplate] = [
        // Önceki beş
        make(id: "classicSerif", title: "Klasik", apply: { t in
            t.styleTemplateId = "classicSerif"
            t.fontDesign = .serif
            t.fontWeightKind = .bold
            t.isItalic = false
            t.usesForegroundGradient = false
            t.color = .black
            t.gradientEndColor = .black
            t.backgroundColor = .white
        }, preview: {
            Text("Aa").font(.system(size: 15, weight: .bold, design: .serif)).foregroundStyle(Color.primary)
        }),
        make(id: "modernItalic", title: "İtalik", apply: { t in
            t.styleTemplateId = "modernItalic"
            t.fontDesign = .default
            t.fontWeightKind = .semibold
            t.isItalic = true
            t.usesForegroundGradient = false
            t.color = Color(white: 0.15)
            t.gradientEndColor = t.color
            t.backgroundColor = Color(white: 0.94)
        }, preview: {
            Text("Aa")
                .font(.system(size: 15, weight: .semibold, design: .default).italic())
                .foregroundStyle(Color(white: 0.92))
        }),
        make(id: "sunsetGradient", title: "Gün batımı", apply: { t in
            t.styleTemplateId = "sunsetGradient"
            t.fontDesign = .rounded
            t.fontWeightKind = .bold
            t.isItalic = false
            t.usesForegroundGradient = true
            t.color = Color(red: 1, green: 0.45, blue: 0.2)
            t.gradientEndColor = Color(red: 1, green: 0.35, blue: 0.65)
            t.backgroundColor = .white
        }, preview: {
            Text("Aa").font(.system(size: 15, weight: .bold, design: .rounded)).foregroundStyle(
                LinearGradient(
                    colors: [Color(red: 1, green: 0.45, blue: 0.2), Color(red: 1, green: 0.35, blue: 0.65)],
                    startPoint: .leading,
                    endPoint: .trailing
                )
            )
        }),
        make(id: "elegantThin", title: "İnce", apply: { t in
            t.styleTemplateId = "elegantThin"
            t.fontDesign = .serif
            t.fontWeightKind = .ultraLight
            t.isItalic = false
            t.usesForegroundGradient = false
            t.color = Color(white: 0.55)
            t.gradientEndColor = t.color
            t.backgroundColor = Color.white.opacity(0.35)
        }, preview: {
            Text("Aa").font(.system(size: 15, weight: .ultraLight, design: .serif)).foregroundStyle(Color(white: 0.78))
        }),
        make(id: "boldOnDark", title: "Kontrast", apply: { t in
            t.styleTemplateId = "boldOnDark"
            t.fontDesign = .default
            t.fontWeightKind = .heavy
            t.isItalic = false
            t.usesForegroundGradient = false
            t.color = .white
            t.gradientEndColor = .white
            t.backgroundColor = Color(white: 0.12)
        }, preview: {
            ZStack {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(white: 0.14))
                    .frame(width: 40, height: 40)
                Text("Aa").font(.system(size: 15, weight: .heavy, design: .default)).foregroundStyle(Color.white)
            }
        }),

        // Gradient’ler
        gradient(id: "oceanGradient", title: "Okyanus", design: .rounded, weight: .bold,
                 c1: Color(red: 0.1, green: 0.45, blue: 0.95), c2: Color(red: 0.2, green: 0.85, blue: 0.9)),
        gradient(id: "plumGradient", title: "Mürdüm", design: .default, weight: .bold,
                 c1: Color(red: 0.45, green: 0.2, blue: 0.75), c2: Color(red: 0.95, green: 0.35, blue: 0.55)),
        gradient(id: "skyGradient", title: "Gök", design: .rounded, weight: .semibold,
                 c1: Color(red: 0.35, green: 0.65, blue: 1), c2: Color(red: 0.85, green: 0.92, blue: 1)),
        gradient(id: "roseGold", title: "Rose", design: .serif, weight: .semibold,
                 c1: Color(red: 0.72, green: 0.45, blue: 0.38), c2: Color(red: 0.95, green: 0.75, blue: 0.65)),
        gradient(id: "limePop", title: "Limon", design: .rounded, weight: .heavy,
                 c1: Color(red: 0.2, green: 0.85, blue: 0.35), c2: Color(red: 0.95, green: 0.92, blue: 0.2)),
        gradient(id: "magentaNeon", title: "Neon", design: .default, weight: .black,
                 c1: Color(red: 1, green: 0.2, blue: 0.75), c2: Color(red: 0.55, green: 0.15, blue: 1)),
        gradient(id: "icyGradient", title: "Buz", design: .rounded, weight: .medium,
                 c1: Color(red: 0.55, green: 0.8, blue: 1), c2: Color(red: 0.95, green: 0.98, blue: 1)),
        gradient(id: "emberGradient", title: "Alev", design: .serif, weight: .bold,
                 c1: Color(red: 1, green: 0.35, blue: 0.1), c2: Color(red: 1, green: 0.85, blue: 0.2)),

        // Düz renk / zemin
        solid(id: "cherryRed", title: "Vişne", design: .default, weight: .bold, italic: false,
              fg: Color(red: 0.75, green: 0.05, blue: 0.12), bg: Color.white),
        solid(id: "forestGreen", title: "Orman", design: .serif, weight: .semibold, italic: false,
              fg: Color(red: 0.05, green: 0.35, blue: 0.18), bg: Color(red: 0.88, green: 0.96, blue: 0.9)),
        solid(id: "lavenderSoft", title: "Lavanta", design: .rounded, weight: .medium, italic: false,
              fg: Color(red: 0.35, green: 0.2, blue: 0.55), bg: Color(red: 0.93, green: 0.88, blue: 0.98)),
        solid(id: "goldenHour", title: "Altın", design: .serif, weight: .bold, italic: false,
              fg: Color(red: 0.55, green: 0.38, blue: 0.08), bg: Color(red: 1, green: 0.96, blue: 0.82)),
        solid(id: "midnightBlue", title: "Gece", design: .default, weight: .semibold, italic: false,
              fg: Color.white, bg: Color(red: 0.08, green: 0.14, blue: 0.35)),
        solid(id: "slateCard", title: "Arduvaz", design: .rounded, weight: .semibold, italic: false,
              fg: Color.white, bg: Color(red: 0.25, green: 0.32, blue: 0.38)),
        solid(id: "grapeJuice", title: "Üzüm", design: .default, weight: .heavy, italic: false,
              fg: Color.white, bg: Color(red: 0.35, green: 0.12, blue: 0.45)),
        solid(id: "candyPink", title: "Şeker", design: .rounded, weight: .bold, italic: false,
              fg: Color(red: 0.85, green: 0.15, blue: 0.45), bg: Color(red: 1, green: 0.9, blue: 0.94)),
        solid(id: "peachTea", title: "Şeftali", design: .serif, weight: .medium, italic: false,
              fg: Color(red: 0.45, green: 0.22, blue: 0.12), bg: Color(red: 1, green: 0.88, blue: 0.78)),
        solid(id: "sandStone", title: "Kum", design: .default, weight: .semibold, italic: false,
              fg: Color(red: 0.35, green: 0.28, blue: 0.2), bg: Color(red: 0.96, green: 0.92, blue: 0.84)),
        solid(id: "linkBlue", title: "Bağlantı", design: .default, weight: .semibold, italic: false,
              fg: Color(red: 0.1, green: 0.45, blue: 0.95), bg: Color.white),
        solid(id: "charcoal", title: "Antrasit", design: .default, weight: .bold, italic: false,
              fg: Color.white, bg: Color(white: 0.22)),
        solid(id: "creamInk", title: "Mürekkep", design: .serif, weight: .regular, italic: false,
              fg: Color(red: 0.12, green: 0.1, blue: 0.09), bg: Color(red: 0.99, green: 0.97, blue: 0.92)),
        solid(id: "mintChip", title: "Nane", design: .rounded, weight: .semibold, italic: false,
              fg: Color(red: 0.05, green: 0.45, blue: 0.38), bg: Color(red: 0.88, green: 0.98, blue: 0.94)),

        // Tipografi varyantları
        solid(id: "monoType", title: "Terminal", design: .monospaced, weight: .medium, italic: false,
              fg: Color(red: 0.2, green: 0.85, blue: 0.45), bg: Color(red: 0.04, green: 0.06, blue: 0.05)),
        solid(id: "monoBold", title: "Kod", design: .monospaced, weight: .bold, italic: false,
              fg: Color(white: 0.1), bg: Color(white: 0.94)),
        solid(id: "roundedSoft", title: "Yumuşak", design: .rounded, weight: .medium, italic: false,
              fg: Color(white: 0.25), bg: Color(white: 0.93)),
        solid(id: "serifItalic", title: "Serif italik", design: .serif, weight: .semibold, italic: true,
              fg: Color(white: 0.18), bg: Color.white),
        solid(id: "ultraBlack", title: "Siyah", design: .default, weight: .black, italic: false,
              fg: Color.white, bg: Color.black),
        solid(id: "outlineFeel", title: "Pastel", design: .rounded, weight: .bold, italic: false,
              fg: Color(red: 0.25, green: 0.55, blue: 0.65), bg: Color(red: 0.9, green: 0.96, blue: 0.98)),
        solid(id: "wineRed", title: "Şarap", design: .serif, weight: .bold, italic: false,
              fg: Color(red: 0.45, green: 0.08, blue: 0.15), bg: Color(red: 1, green: 0.94, blue: 0.95)),
        solid(id: "electricCyan", title: "Elektrik", design: .default, weight: .heavy, italic: false,
              fg: Color(red: 0.2, green: 0.95, blue: 0.95), bg: Color(red: 0.05, green: 0.08, blue: 0.12)),
        solid(id: "blushRose", title: "Gül", design: .rounded, weight: .semibold, italic: false,
              fg: Color(red: 0.55, green: 0.12, blue: 0.28), bg: Color(red: 1, green: 0.9, blue: 0.93)),
    ]

    /// Seçili olmayan chip zemini.
    static let chipBackgroundUnselected = Color.primary.opacity(0.12)
    /// Seçili chip (Instagram’daki beyaz kare).
    static let chipBackgroundSelected = Color.white.opacity(0.94)

    // MARK: - Fabrika (tekrarı azaltmak için)

    private static func gradient(
        id: String,
        title: String,
        design: TextFontDesign,
        weight: TextFontWeightKind,
        c1: Color,
        c2: Color,
        bg: Color = .white
    ) -> TextStyleTemplate {
        make(id: id, title: title, apply: { t in
            t.styleTemplateId = id
            t.fontDesign = design
            t.fontWeightKind = weight
            t.isItalic = false
            t.usesForegroundGradient = true
            t.color = c1
            t.gradientEndColor = c2
            t.backgroundColor = bg
        }, preview: {
            let sw = weight.swiftUI
            let sd = design.swiftUI
            Text("Aa")
                .font(.system(size: 15, weight: sw, design: sd))
                .foregroundStyle(
                    LinearGradient(colors: [c1, c2], startPoint: .leading, endPoint: .trailing)
                )
        })
    }

    private static func solid(
        id: String,
        title: String,
        design: TextFontDesign,
        weight: TextFontWeightKind,
        italic: Bool,
        fg: Color,
        bg: Color
    ) -> TextStyleTemplate {
        make(id: id, title: title, apply: { t in
            t.styleTemplateId = id
            t.fontDesign = design
            t.fontWeightKind = weight
            t.isItalic = italic
            t.usesForegroundGradient = false
            t.color = fg
            t.gradientEndColor = fg
            t.backgroundColor = bg
        }, preview: {
            solidPreview(design: design, weight: weight, italic: italic, fg: fg, bg: bg)
        })
    }

    @ViewBuilder
    private static func solidPreview(
        design: TextFontDesign,
        weight: TextFontWeightKind,
        italic: Bool,
        fg: Color,
        bg: Color
    ) -> some View {
        let base = Font.system(size: 15, weight: weight.swiftUI, design: design.swiftUI)
        ZStack {
            RoundedRectangle(cornerRadius: 8, style: .continuous)
                .fill(bg)
                .frame(width: 40, height: 40)
            Text("Aa")
                .font(italic ? base.italic() : base)
                .foregroundStyle(fg)
        }
    }

    static func template(id: String) -> TextStyleTemplate? {
        all.first(where: { $0.id == id })
    }
}
