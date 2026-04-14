import AppKit
import SwiftUI

enum ImageExport {
    @MainActor
    static func savePanel(document: DrawingDocument, appState: AppState, overlayWindowNumber: UInt32) {
        let panel = NSSavePanel()
        panel.allowedContentTypes = [.png]
        panel.nameFieldStringValue = "Pen-ekran.png"
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            let merge = AppPreferences.mergeDesktopExport
            guard let data = renderPNG(
                document: document,
                appState: appState,
                overlayWindowNumber: overlayWindowNumber,
                mergeDesktop: merge
            ) else { return }
            try? data.write(to: url)
        }
    }

    @MainActor
    private static func renderPNG(
        document: DrawingDocument,
        appState: AppState,
        overlayWindowNumber: UInt32,
        mergeDesktop: Bool
    ) -> Data? {
        let screens = NSScreen.screens
        let frame = screens.reduce(CGRect.null) { $0.union($1.frame) }
        guard frame.width > 0, frame.height > 0 else { return nil }

        let scale = NSScreen.main?.backingScaleFactor ?? 2
        let w = Int(frame.width * scale)
        let h = Int(frame.height * scale)

        guard let rep = NSBitmapImageRep(
            bitmapDataPlanes: nil,
            pixelsWide: w,
            pixelsHigh: h,
            bitsPerSample: 8,
            samplesPerPixel: 4,
            hasAlpha: true,
            isPlanar: false,
            colorSpaceName: .deviceRGB,
            bytesPerRow: 0,
            bitsPerPixel: 0
        ) else { return nil }

        rep.size = frame.size

        guard let nsGCtx = NSGraphicsContext(bitmapImageRep: rep) else { return nil }
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = nsGCtx
        defer { NSGraphicsContext.restoreGraphicsState() }

        let ctx = nsGCtx.cgContext
        ctx.scaleBy(x: scale, y: scale)
        ctx.translateBy(x: -frame.origin.x, y: -frame.origin.y)
        ctx.setShouldAntialias(true)

        var drewDesktop = false
        if mergeDesktop, overlayWindowNumber != 0,
           let bg = ScreenCapture.imageBelowOverlay(
               overlayWindowNumber: overlayWindowNumber,
               rectInScreenSpace: frame
           )
        {
            let ns = NSImage(cgImage: bg, size: frame.size)
            ns.draw(
                in: CGRect(origin: .zero, size: frame.size),
                from: CGRect(origin: .zero, size: frame.size),
                operation: .copy,
                fraction: 1
            )
            drewDesktop = true
        }

        if !drewDesktop {
            WhiteboardBackgroundExport.drawIntoContext(
                background: appState.whiteboard,
                ctx: ctx,
                rect: CGRect(origin: .zero, size: frame.size),
                scale: scale
            )
        }

        for shape in document.shapes {
            drawShape(shape, in: ctx)
        }

        for stroke in document.strokes where !stroke.isEraserMask {
            drawStroke(stroke, in: ctx)
        }

        ctx.setBlendMode(.destinationOut)
        for stroke in document.strokes where stroke.isEraserMask {
            drawStroke(stroke, in: ctx)
        }
        ctx.setBlendMode(.normal)

        for t in document.texts {
            let ns = NSAttributedString(
                string: t.text,
                attributes: [
                    .font: t.resolvedNSFont(),
                    .foregroundColor: t.resolvedExportForegroundNSColor(),
                ]
            )
            let s = ns.size()
            let pad: CGFloat = 6
            let bg = t.backgroundColor.resolvedNSColor()
            let left = -(s.width / 2 + pad)
            let top = -(s.height / 2 + pad)
            ctx.saveGState()
            ctx.translateBy(x: t.position.x, y: t.position.y)
            if abs(t.rotationRadians) > 1e-6 {
                ctx.rotate(by: CGFloat(t.rotationRadians))
            }
            if bg.alphaComponent > 0.02 {
                let rect = CGRect(x: left, y: top, width: s.width + pad * 2, height: s.height + pad * 2)
                let path = CGPath(
                    roundedRect: rect,
                    cornerWidth: 6,
                    cornerHeight: 6,
                    transform: nil
                )
                ctx.addPath(path)
                ctx.setFillColor(bg.cgColor)
                ctx.fillPath()
            }
            ns.draw(at: CGPoint(x: left + pad, y: top + pad))
            ctx.restoreGState()
        }

        return rep.representation(using: .png, properties: [:])
    }

    /// Kapalı şekil çizimini `rect` merkezinde döndürür.
    private static func strokeClosedShape(_ shape: ShapeStroke, rect rs: CGRect, in ctx: CGContext, draw: () -> Void) {
        guard abs(shape.rotationRadians) > 1e-6 else {
            draw()
            return
        }
        ctx.saveGState()
        let c = CGPoint(x: rs.midX, y: rs.midY)
        ctx.translateBy(x: c.x, y: c.y)
        ctx.rotate(by: CGFloat(shape.rotationRadians))
        ctx.translateBy(x: -c.x, y: -c.y)
        draw()
        ctx.restoreGState()
    }

    private static func drawShape(_ shape: ShapeStroke, in ctx: CGContext) {
        ctx.saveGState()
        let c = shape.color.resolvedNSColor().withAlphaComponent(CGFloat(shape.opacity)).cgColor
        ctx.setStrokeColor(c)
        ctx.setLineWidth(shape.lineWidth)
        let r = shape.rect
        switch shape.kind {
        case .shapeLine, .shapeArrow, .shapeArrowStart, .shapeArrowDouble:
            guard let (start, end) = shape.lineSegmentEndpoints() else {
                ctx.restoreGState()
                return
            }
            guard hypot(end.x - start.x, end.y - start.y) > 0.5 else {
                ctx.restoreGState()
                return
            }
            ctx.move(to: start)
            ctx.addLine(to: end)
            ctx.strokePath()
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            switch shape.kind {
            case .shapeArrow:
                LineArrowTool.drawStrokedHeadCG(
                    ctx: ctx,
                    tip: end,
                    start: start,
                    end: end,
                    lineWidth: shape.lineWidth,
                    tipAtEnd: true
                )
            case .shapeArrowStart:
                LineArrowTool.drawStrokedHeadCG(
                    ctx: ctx,
                    tip: start,
                    start: start,
                    end: end,
                    lineWidth: shape.lineWidth,
                    tipAtEnd: false
                )
            case .shapeArrowDouble:
                LineArrowTool.drawStrokedHeadCG(
                    ctx: ctx,
                    tip: end,
                    start: start,
                    end: end,
                    lineWidth: shape.lineWidth,
                    tipAtEnd: true
                )
                LineArrowTool.drawStrokedHeadCG(
                    ctx: ctx,
                    tip: start,
                    start: start,
                    end: end,
                    lineWidth: shape.lineWidth,
                    tipAtEnd: false
                )
            default:
                break
            }
        case .shapeRect:
            let rs = r.standardized
            guard rs.width > 1, rs.height > 1 else { break }
            strokeClosedShape(shape, rect: rs, in: ctx) {
                ctx.addRect(rs)
                ctx.strokePath()
            }
        case .shapeRoundedRect:
            let rs = r.standardized
            guard rs.width > 1, rs.height > 1 else { break }
            let cr = min(min(rs.width, rs.height) * 0.22, 22)
            strokeClosedShape(shape, rect: rs, in: ctx) {
                let rp = CGPath(roundedRect: rs, cornerWidth: cr, cornerHeight: cr, transform: nil)
                ctx.addPath(rp)
                ctx.strokePath()
            }
        case .shapeTriangle:
            let rs = r.standardized
            guard rs.width > 1, rs.height > 1 else { break }
            strokeClosedShape(shape, rect: rs, in: ctx) {
                let p = CGMutablePath()
                p.move(to: CGPoint(x: rs.midX, y: rs.minY))
                p.addLine(to: CGPoint(x: rs.maxX, y: rs.maxY))
                p.addLine(to: CGPoint(x: rs.minX, y: rs.maxY))
                p.closeSubpath()
                ctx.addPath(p)
                ctx.strokePath()
            }
        case .shapeEllipse:
            let rs = r.standardized
            guard rs.width > 1, rs.height > 1 else { break }
            strokeClosedShape(shape, rect: rs, in: ctx) {
                ctx.strokeEllipse(in: rs)
            }
        case .shapeDiamond:
            let rs = r.standardized
            guard rs.width > 1, rs.height > 1 else { break }
            strokeClosedShape(shape, rect: rs, in: ctx) {
                let p = CGMutablePath()
                p.move(to: CGPoint(x: rs.midX, y: rs.minY))
                p.addLine(to: CGPoint(x: rs.maxX, y: rs.midY))
                p.addLine(to: CGPoint(x: rs.midX, y: rs.maxY))
                p.addLine(to: CGPoint(x: rs.minX, y: rs.midY))
                p.closeSubpath()
                ctx.addPath(p)
                ctx.strokePath()
            }
        case .shapeHexagon:
            let rs = r.standardized
            guard rs.width > 1, rs.height > 1 else { break }
            strokeClosedShape(shape, rect: rs, in: ctx) {
                let cx = rs.midX
                let cy = rs.midY
                let rad = min(rs.width, rs.height) / 2
                let p = CGMutablePath()
                for i in 0 ..< 6 {
                    let a = -CGFloat.pi / 2 + CGFloat(i) * CGFloat.pi / 3
                    let px = cx + rad * cos(a)
                    let py = cy + rad * sin(a)
                    if i == 0 {
                        p.move(to: CGPoint(x: px, y: py))
                    } else {
                        p.addLine(to: CGPoint(x: px, y: py))
                    }
                }
                p.closeSubpath()
                ctx.addPath(p)
                ctx.strokePath()
            }
        case .pen, .pencil, .highlighter, .eraserStroke, .eraserPixel, .text, .select, .laser, .spotlight:
            break
        }
        ctx.restoreGState()
    }

    private static func drawStroke(_ stroke: Stroke, in ctx: CGContext) {
        guard stroke.points.count >= 2 else { return }
        ctx.saveGState()
        let path = CGMutablePath()
        path.move(to: stroke.points[0])
        for p in stroke.points.dropFirst() {
            path.addLine(to: p)
        }
        ctx.addPath(path)
        if stroke.isEraserMask {
            ctx.setStrokeColor(NSColor.white.cgColor)
            ctx.setLineWidth(stroke.width)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            ctx.strokePath()
        } else if stroke.tool == .highlighter {
            ctx.setBlendMode(.multiply)
            ctx.setStrokeColor(stroke.color.resolvedNSColor().withAlphaComponent(0.4).cgColor)
            ctx.setLineWidth(stroke.width)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            ctx.strokePath()
        } else {
            ctx.setStrokeColor(stroke.color.resolvedNSColor().withAlphaComponent(CGFloat(stroke.opacity)).cgColor)
            ctx.setLineWidth(stroke.width)
            ctx.setLineCap(.round)
            ctx.setLineJoin(.round)
            ctx.strokePath()
        }
        ctx.restoreGState()
    }
}
