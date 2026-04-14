import AppKit
import SwiftUI

/// SwiftUI / AppKit ile uyumlu sistem font tasarımı.
enum TextFontDesign: String, Equatable {
    case `default`
    case serif
    case rounded
    case monospaced

    var swiftUI: Font.Design {
        switch self {
        case .default: return .default
        case .serif: return .serif
        case .rounded: return .rounded
        case .monospaced: return .monospaced
        }
    }

    var nsDesign: NSFontDescriptor.SystemDesign {
        switch self {
        case .default: return .default
        case .serif: return .serif
        case .rounded: return .rounded
        case .monospaced: return .monospaced
        }
    }
}

enum TextFontWeightKind: Int, Equatable {
    case ultraLight = 0
    case light = 1
    case regular = 2
    case medium = 3
    case semibold = 4
    case bold = 5
    case heavy = 6
    case black = 7

    var swiftUI: Font.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        }
    }

    var ns: NSFont.Weight {
        switch self {
        case .ultraLight: return .ultraLight
        case .light: return .light
        case .regular: return .regular
        case .medium: return .medium
        case .semibold: return .semibold
        case .bold: return .bold
        case .heavy: return .heavy
        case .black: return .black
        }
    }
}

extension TextAnnotation {
    func resolvedSwiftUIFont() -> Font {
        var f = Font.system(size: fontSize, weight: fontWeightKind.swiftUI, design: fontDesign.swiftUI)
        if isItalic {
            f = f.italic()
        }
        return f
    }

    /// PNG ve ölçüm için NSFont.
    func resolvedNSFont() -> NSFont {
        let size = fontSize
        let weight = fontWeightKind.ns
        let base = NSFont.systemFont(ofSize: size, weight: weight)
        let descriptor: NSFontDescriptor
        if let withDesign = base.fontDescriptor.withDesign(fontDesign.nsDesign) {
            descriptor = withDesign
        } else {
            descriptor = base.fontDescriptor
        }
        let built = NSFont(descriptor: descriptor, size: size) ?? base
        if isItalic {
            return NSFontManager.shared.convert(built, toHaveTrait: .italicFontMask)
        }
        return built
    }

    /// Dışa aktarımda gradient için tek renk (iki rengin karışımı).
    func resolvedExportForegroundNSColor() -> NSColor {
        if usesForegroundGradient {
            let a = color.resolvedNSColor().usingColorSpace(.sRGB) ?? color.resolvedNSColor()
            let b = gradientEndColor.resolvedNSColor().usingColorSpace(.sRGB) ?? gradientEndColor.resolvedNSColor()
            let r = (a.redComponent + b.redComponent) / 2
            let g = (a.greenComponent + b.greenComponent) / 2
            let bl = (a.blueComponent + b.blueComponent) / 2
            let al = (a.alphaComponent + b.alphaComponent) / 2
            return NSColor(calibratedRed: r, green: g, blue: bl, alpha: al)
        }
        return color.resolvedNSColor()
    }
}
