import AppKit
import SwiftUI

/// Tahta arka planı — ana overlay ve (gerekirse) PNG dışa aktarma için ortak görünüm.
struct WhiteboardBackgroundLayerContent: View {
    var background: WhiteboardBackground

    var body: some View {
        Group {
            switch background {
            case .transparent:
                Color.clear
            case .white:
                Color.white.opacity(0.95)
            case .black:
                Color.black.opacity(0.92)
            case .gray:
                Color(white: 0.94)
            case .charcoal:
                Color(white: 0.18)
            case .cream:
                Color(red: 0.98, green: 0.96, blue: 0.9)
            case .nightBlue:
                Color(red: 0.08, green: 0.1, blue: 0.18)
            case .pastelBlue:
                Color(red: 0.9, green: 0.94, blue: 0.99).opacity(0.96)
            case .mint:
                Color(red: 0.88, green: 0.97, blue: 0.93).opacity(0.96)
            case .cork:
                Color(red: 0.76, green: 0.62, blue: 0.48).opacity(0.94)
            case .chalkGreen:
                ZStack {
                    Color(red: 0.14, green: 0.32, blue: 0.22)
                    ChalkSmudgeLines()
                }
            case .blueprint:
                ZStack {
                    Color(red: 0.06, green: 0.14, blue: 0.28)
                    SquareGridLines(step: 32, lineColor: Color(red: 0.35, green: 0.55, blue: 0.82).opacity(0.45))
                }
            case .grid:
                ZStack {
                    Color.white.opacity(0.92)
                    SquareGridLines(step: 24, lineColor: Color.gray.opacity(0.35))
                }
            case .gridDark:
                ZStack {
                    Color(white: 0.12)
                    SquareGridLines(step: 28, lineColor: Color.white.opacity(0.22))
                }
            case .graphFine:
                ZStack {
                    Color.white.opacity(0.94)
                    SquareGridLines(step: 12, lineColor: Color.gray.opacity(0.28))
                }
            case .lined:
                ZStack {
                    Color.white.opacity(0.95)
                    HorizontalRuledLines(spacing: 28, lineColor: Color(red: 0.55, green: 0.65, blue: 0.82).opacity(0.55))
                }
            case .linedMargin:
                ZStack {
                    Color(red: 0.99, green: 0.98, blue: 0.95)
                    HorizontalRuledLines(spacing: 28, lineColor: Color(red: 0.55, green: 0.65, blue: 0.82).opacity(0.45))
                    MarginLine(x: 56, color: Color(red: 0.92, green: 0.35, blue: 0.38).opacity(0.65))
                }
            case .dotGrid:
                ZStack {
                    Color.white.opacity(0.94)
                    DotGrid(step: 24, dotDiameter: 2.2, color: Color.gray.opacity(0.4))
                }
            case .dotGridFine:
                ZStack {
                    Color.white.opacity(0.95)
                    DotGrid(step: 14, dotDiameter: 1.4, color: Color.gray.opacity(0.38))
                }
            case .isometric:
                ZStack {
                    Color(red: 0.99, green: 0.99, blue: 0.98)
                    IsometricGridLines(spacing: 26, lineColor: Color.gray.opacity(0.32))
                }
            case .hexGrid:
                ZStack {
                    Color.white.opacity(0.94)
                    HexGridLines(hexRadius: 16, lineColor: Color.gray.opacity(0.32))
                }
            case .softGradient:
                LinearGradient(
                    colors: [
                        Color(red: 0.96, green: 0.97, blue: 0.99),
                        Color.white,
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
    }
}

// MARK: - Pattern pieces

private struct SquareGridLines: View {
    var step: CGFloat
    var lineColor: Color

    var body: some View {
        Canvas { context, size in
            var path = Path()
            var x: CGFloat = 0
            while x <= size.width {
                path.move(to: CGPoint(x: x, y: 0))
                path.addLine(to: CGPoint(x: x, y: size.height))
                x += step
            }
            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += step
            }
            context.stroke(path, with: .color(lineColor), lineWidth: 0.5)
        }
    }
}

private struct HorizontalRuledLines: View {
    var spacing: CGFloat
    var lineColor: Color

    var body: some View {
        Canvas { context, size in
            var path = Path()
            var y: CGFloat = spacing
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += spacing
            }
            context.stroke(path, with: .color(lineColor), lineWidth: 0.45)
        }
    }
}

private struct MarginLine: View {
    var x: CGFloat
    var color: Color

    var body: some View {
        Canvas { context, size in
            var path = Path()
            path.move(to: CGPoint(x: x, y: 0))
            path.addLine(to: CGPoint(x: x, y: size.height))
            context.stroke(path, with: .color(color), lineWidth: 1)
        }
    }
}

private struct DotGrid: View {
    var step: CGFloat
    var dotDiameter: CGFloat
    var color: Color

    var body: some View {
        Canvas { context, size in
            let r = dotDiameter / 2
            var y: CGFloat = 0
            while y <= size.height + step {
                var x: CGFloat = 0
                while x <= size.width + step {
                    let rect = CGRect(x: x - r, y: y - r, width: dotDiameter, height: dotDiameter)
                    context.fill(Path(ellipseIn: rect), with: .color(color))
                    x += step
                }
                y += step
            }
        }
    }
}

private struct IsometricGridLines: View {
    var spacing: CGFloat
    var lineColor: Color

    var body: some View {
        Canvas { context, size in
            var path = Path()
            let tan30: CGFloat = 1 / CGFloat(3).squareRoot()
            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += spacing
            }
            var b: CGFloat = -size.width
            while b < size.height + size.width {
                path.move(to: CGPoint(x: 0, y: b))
                path.addLine(to: CGPoint(x: size.width, y: b + tan30 * size.width))
                b += spacing
            }
            var b2: CGFloat = -size.width
            while b2 < size.height + size.width {
                path.move(to: CGPoint(x: 0, y: b2))
                path.addLine(to: CGPoint(x: size.width, y: b2 - tan30 * size.width))
                b2 += spacing
            }
            context.stroke(path, with: .color(lineColor), lineWidth: 0.45)
        }
    }
}

private struct HexGridLines: View {
    var hexRadius: CGFloat
    var lineColor: Color

    var body: some View {
        Canvas { context, size in
            let r = hexRadius
            let sqrt3 = CGFloat(3).squareRoot()
            let dx = sqrt3 * r
            let dy = 1.5 * r
            var j = 0
            while CGFloat(j) * dy < size.height + 2 * r {
                let rowY = r + CGFloat(j) * dy
                let iMax = Int(size.width / dx) + 3
                for ii in -1 ... iMax {
                    let cx = sqrt3 * r * (CGFloat(ii) + 0.5 * CGFloat(j % 2))
                    let cy = rowY
                    guard cx > -r, cx < size.width + r, cy > -r, cy < size.height + r else { continue }
                    let hex = hexPath(center: CGPoint(x: cx, y: cy), radius: r)
                    context.stroke(hex, with: .color(lineColor), lineWidth: 0.45)
                }
                j += 1
            }
        }
    }

    private func hexPath(center: CGPoint, radius: CGFloat) -> Path {
        var p = Path()
        for i in 0 ..< 6 {
            let a = -CGFloat.pi / 2 + CGFloat(i) * CGFloat.pi / 3
            let px = center.x + radius * cos(a)
            let py = center.y + radius * sin(a)
            if i == 0 {
                p.move(to: CGPoint(x: px, y: py))
            } else {
                p.addLine(to: CGPoint(x: px, y: py))
            }
        }
        p.closeSubpath()
        return p
    }
}

private struct ChalkSmudgeLines: View {
    var body: some View {
        Canvas { context, size in
            var path = Path()
            let step: CGFloat = 40
            var y: CGFloat = 0
            while y <= size.height {
                path.move(to: CGPoint(x: 0, y: y))
                path.addLine(to: CGPoint(x: size.width, y: y))
                y += step
            }
            context.stroke(path, with: .color(Color.white.opacity(0.06)), lineWidth: 0.5)
        }
    }
}

// MARK: - PNG export

enum WhiteboardBackgroundExport {
    /// `mergeDesktop` false iken tahta dolgusu — SwiftUI ile ekran görünümüyle uyum.
    @MainActor
    static func drawIntoContext(
        background: WhiteboardBackground,
        ctx: CGContext,
        rect: CGRect,
        scale: CGFloat
    ) {
        guard background != .transparent else {
            ctx.clear(rect)
            return
        }
        guard rect.width > 0.5, rect.height > 0.5 else { return }
        let view = WhiteboardBackgroundLayerContent(background: background)
            .frame(width: rect.width, height: rect.height)
        let renderer = ImageRenderer(content: view)
        renderer.scale = scale
        guard let nsImage = renderer.nsImage,
              let tiff = nsImage.tiffRepresentation,
              let rep = NSBitmapImageRep(data: tiff),
              let cg = rep.cgImage
        else {
            ctx.setFillColor(NSColor.white.cgColor)
            ctx.fill(rect)
            return
        }
        ctx.saveGState()
        ctx.translateBy(x: rect.minX, y: rect.minY)
        ctx.draw(cg, in: CGRect(origin: .zero, size: rect.size))
        ctx.restoreGState()
    }
}
