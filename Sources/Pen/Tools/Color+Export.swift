import AppKit
import SwiftUI

extension Color {
    func resolvedNSColor() -> NSColor {
        let r = resolve(in: EnvironmentValues())
        return NSColor(
            calibratedRed: CGFloat(r.red),
            green: CGFloat(r.green),
            blue: CGFloat(r.blue),
            alpha: CGFloat(r.opacity)
        )
    }

    /// `RRGGBBAA` büyük harf — `UserDefaults` / son renkler için.
    func rgbaHexString() -> String {
        let n = resolvedNSColor().usingColorSpace(.sRGB) ?? resolvedNSColor()
        let r = Int(round(n.redComponent * 255))
        let g = Int(round(n.greenComponent * 255))
        let b = Int(round(n.blueComponent * 255))
        let a = Int(round(n.alphaComponent * 255))
        return String(format: "%02X%02X%02X%02X", r, g, b, a)
    }

    init?(rgbaHex string: String) {
        var hex = string.trimmingCharacters(in: .whitespacesAndNewlines)
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 8 || hex.count == 6 else { return nil }
        if hex.count == 6 { hex.append("FF") }
        var value: UInt64 = 0
        guard Scanner(string: hex).scanHexInt64(&value) else { return nil }
        let r = CGFloat((value >> 24) & 0xFF) / 255
        let g = CGFloat((value >> 16) & 0xFF) / 255
        let b = CGFloat((value >> 8) & 0xFF) / 255
        let a = CGFloat(value & 0xFF) / 255
        self = Color(red: r, green: g, blue: b, opacity: a)
    }

    /// Açık renklerde ince sınır (beyaz kare görünürlüğü).
    var isLightSwatch: Bool {
        let n = resolvedNSColor().usingColorSpace(.sRGB) ?? resolvedNSColor()
        let lum = 0.299 * n.redComponent + 0.587 * n.greenComponent + 0.114 * n.blueComponent
        return lum > 0.82
    }
}
