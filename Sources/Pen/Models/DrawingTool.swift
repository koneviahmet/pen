import SwiftUI

enum DrawingTool: String, CaseIterable, Identifiable {
    case pen
    case pencil
    case highlighter
    case eraserStroke
    case eraserPixel
    case shapeRect
    case shapeRoundedRect
    case shapeTriangle
    case shapeEllipse
    case shapeDiamond
    case shapeHexagon
    case shapeLine
    case shapeArrow
    /// Ok ucu sürüklemenin başladığı uçta (çizgi yönü: baş → son).
    case shapeArrowStart
    /// İki uçta ok.
    case shapeArrowDouble
    case text
    /// Metin ve şekilleri tek tıkla seçip düzenleme panelini açar (çizim yapmaz).
    case select
    case laser
    case spotlight

    var id: String { rawValue }

    var label: String {
        switch self {
        case .pen: return "Kalem"
        case .pencil: return "Kurşun"
        case .highlighter: return "Fosforlu"
        case .eraserStroke: return "Silgi (çizgi)"
        case .eraserPixel: return "Silgi (bölge)"
        case .shapeRect: return "Dikdörtgen"
        case .shapeRoundedRect: return "Yuvarlatılmış kare"
        case .shapeTriangle: return "Üçgen"
        case .shapeEllipse: return "Daire"
        case .shapeDiamond: return "Elmas"
        case .shapeHexagon: return "Altıgen"
        case .shapeLine: return "Çizgi"
        case .shapeArrow: return "Ok"
        case .shapeArrowStart: return "Ok (başlangıç)"
        case .shapeArrowDouble: return "Çift ok"
        case .text: return "Metin"
        case .select: return "Seç / Düzenle"
        case .laser: return "Lazer"
        case .spotlight: return "Spotlight"
        }
    }

    /// Fare tooltip’i için kısa başlık (`label` yerine).
    var tooltipTitle: String {
        switch self {
        case .eraserStroke: return "Silgi"
        case .eraserPixel: return "Piksel silgi"
        case .shapeRoundedRect: return "Yuvarlak kare"
        case .select:
            return "Metin ve çizilmiş şekle tek tıkla düzenleme (tuvalde şekil; metne doğrudan tıklayın)"
        default: return label
        }
    }

    /// SF Symbols — çizim uygulamalarında yaygın, birbiriyle uyumlu set (rounded / filled vurgular).
    var systemImage: String {
        switch self {
        case .pen:
            return "pencil.tip.crop.circle.fill"
        case .pencil:
            return "pencil.and.outline"
        case .highlighter:
            return "highlighter"
        case .eraserStroke:
            return "eraser"
        case .eraserPixel:
            return "eraser.fill"
        case .shapeRect:
            return "rectangle.portrait.fill"
        case .shapeRoundedRect:
            return "rectangle.inset.filled"
        case .shapeTriangle:
            return "triangle.fill"
        case .shapeEllipse:
            return "oval.portrait.fill"
        case .shapeDiamond:
            return "diamond.fill"
        case .shapeHexagon:
            return "hexagon.fill"
        case .shapeLine:
            return "line.diagonal"
        case .shapeArrow:
            return "arrow.up.right.circle.fill"
        case .shapeArrowStart:
            return "arrow.backward.circle.fill"
        case .shapeArrowDouble:
            return "arrow.left.and.right.circle.fill"
        case .text:
            return "character.textbox"
        case .select:
            return "cursorarrow.click.2"
        case .laser:
            return "cursorarrow"
        case .spotlight:
            return "light.max"
        }
    }

    var isShapeTool: Bool {
        switch self {
        case .shapeRect, .shapeRoundedRect, .shapeTriangle, .shapeEllipse, .shapeDiamond, .shapeHexagon, .shapeLine, .shapeArrow, .shapeArrowStart, .shapeArrowDouble:
            return true
        default:
            return false
        }
    }

    /// Serbest çizim kalem ailesi — araç çubuğunda tek düğmede gruplanır (şekil paleti gibi).
    static let brushToolFamily: [DrawingTool] = [
        .pen,
        .pencil,
        .highlighter,
    ]

    var isBrushToolFamily: Bool {
        Self.brushToolFamily.contains(self)
    }

    /// Kapalı çokgen / kare ailesi — araç çubuğunda tek düğmede gruplanır.
    static let closedShapeFamily: [DrawingTool] = [
        .shapeRect,
        .shapeRoundedRect,
        .shapeTriangle,
        .shapeEllipse,
        .shapeDiamond,
        .shapeHexagon,
    ]

    var isClosedShapeFamily: Bool {
        Self.closedShapeFamily.contains(self)
    }

    /// Çizgi ve ok — araç çubuğunda tek düğmede gruplanır.
    static let lineArrowFamily: [DrawingTool] = [
        .shapeLine,
        .shapeArrow,
        .shapeArrowStart,
        .shapeArrowDouble,
    ]

    var isLineArrowFamily: Bool {
        Self.lineArrowFamily.contains(self)
    }

    /// Sürükleme segmenti (çizgi / ok çeşitleri).
    var isLineSegmentTool: Bool {
        switch self {
        case .shapeLine, .shapeArrow, .shapeArrowStart, .shapeArrowDouble:
            return true
        default:
            return false
        }
    }

    var usesContinuousStroke: Bool {
        switch self {
        case .pen, .pencil, .highlighter, .eraserPixel: return true
        default: return false
        }
    }

    /// Seçim modu: tuvalden tek tıkla metin/şekil düzenleme.
    var isSelectTool: Bool {
        self == .select
    }
}

enum WhiteboardBackground: String, CaseIterable, Identifiable {
    case transparent
    case white
    case black
    case grid
    case gray
    case charcoal
    case cream
    case nightBlue
    case pastelBlue
    case mint
    case cork
    case chalkGreen
    case blueprint
    case gridDark
    case graphFine
    case lined
    case linedMargin
    case dotGrid
    case dotGridFine
    case isometric
    case hexGrid
    case softGradient

    var id: String { rawValue }

    var label: String {
        switch self {
        case .transparent: return "Şeffaf"
        case .white: return "Beyaz"
        case .black: return "Siyah"
        case .grid: return "Kareli"
        case .gray: return "Açık gri"
        case .charcoal: return "Antrasit"
        case .cream: return "Krem kağıt"
        case .nightBlue: return "Gece mavisi"
        case .pastelBlue: return "Buz mavisi"
        case .mint: return "Nane"
        case .cork: return "Mantar"
        case .chalkGreen: return "Yeşil tahta"
        case .blueprint: return "Mimari (mavi)"
        case .gridDark: return "Koyu kareli"
        case .graphFine: return "İnce kareli"
        case .lined: return "Çizgili defter"
        case .linedMargin: return "Kenar çizgili"
        case .dotGrid: return "Noktalı"
        case .dotGridFine: return "İnce nokta"
        case .isometric: return "İzometrik"
        case .hexGrid: return "Petek"
        case .softGradient: return "Yumuşak gradient"
        }
    }

    /// Ayarlar / seçici tooltip başlığı.
    var tooltipTitle: String { label }

    /// Araç çubuğu flyout ikonu (kalem paletiyle aynı SF Symbol stili).
    var systemImage: String {
        switch self {
        case .transparent: return "rectangle.dashed"
        case .white: return "square"
        case .black: return "square.fill"
        case .grid: return "square.grid.3x3"
        case .gray: return "circle.lefthalf.filled"
        case .charcoal: return "square.fill.tophalf.filled"
        case .cream: return "doc.plaintext"
        case .nightBlue: return "moon.stars"
        case .pastelBlue: return "drop.fill"
        case .mint: return "leaf.fill"
        case .cork: return "square.stack.3d.up.fill"
        case .chalkGreen: return "sidebar.left"
        case .blueprint: return "square.grid.3x3.fill"
        case .gridDark: return "moon.fill"
        case .graphFine: return "point.3.connected.trianglepath.dotted"
        case .lined: return "list.bullet"
        case .linedMargin: return "text.book.closed"
        case .dotGrid: return "circle.grid.cross"
        case .dotGridFine: return "circle.grid.3x3"
        case .isometric: return "triangle"
        case .hexGrid: return "hexagon.fill"
        case .softGradient: return "sun.horizon.fill"
        }
    }
}
