import AppKit
import SwiftUI

/// Küçük yüzen panel: imleç çevresindeki ekranı `CGWindowListCreateImage` ile yakalar (Pen katmanının altı).
@MainActor
final class MagnifierWindowController {
    private weak var appState: AppState?
    private let overlayWindowNumber: CGWindowID
    private var panel: NSPanel?
    private var imageView: NSImageView?
    private var timer: Timer?

    private let lensLogical: CGFloat = 120
    private let panelSize: CGFloat = 220
    private let zoom: CGFloat = 2.2

    init(appState: AppState, overlayWindowNumber: Int) {
        self.appState = appState
        self.overlayWindowNumber = CGWindowID(overlayWindowNumber)
    }

    func start() {
        guard panel == nil else { return }
        let p = NSPanel(
            contentRect: NSRect(x: 100, y: 100, width: panelSize, height: panelSize),
            styleMask: [.borderless, .nonactivatingPanel],
            backing: .buffered,
            defer: false
        )
        p.isOpaque = false
        p.backgroundColor = .clear
        p.hasShadow = true
        p.level = .floating + 1
        p.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        p.isMovableByWindowBackground = false
        p.ignoresMouseEvents = true

        let iv = NSImageView(frame: NSRect(origin: .zero, size: NSSize(width: panelSize, height: panelSize)))
        iv.imageScaling = .scaleAxesIndependently
        iv.wantsLayer = true
        iv.layer?.cornerRadius = 10
        iv.layer?.masksToBounds = true
        iv.layer?.borderWidth = 1
        iv.layer?.borderColor = NSColor.white.withAlphaComponent(0.35).cgColor
        p.contentView = iv

        panel = p
        imageView = iv
        p.orderFrontRegardless()

        timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 45.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.tick()
            }
        }
        RunLoop.current.add(timer!, forMode: .common)
    }

    func stop() {
        timer?.invalidate()
        timer = nil
        panel?.orderOut(nil)
        panel = nil
        imageView = nil
    }

    private func tick() {
        guard let appState, appState.magnifierEnabled else { return }
        guard let panel, let imageView else { return }

        let mouse = NSEvent.mouseLocation
        let half = lensLogical / 2
        let rect = CGRect(
            x: mouse.x - half,
            y: mouse.y - half,
            width: lensLogical,
            height: lensLogical
        )

        if let cg = ScreenCapture.imageBelowOverlay(overlayWindowNumber: overlayWindowNumber, rectInScreenSpace: rect) {
            let size = NSSize(width: CGFloat(cg.width) / zoom, height: CGFloat(cg.height) / zoom)
            imageView.image = NSImage(cgImage: cg, size: size)
        }

        let offset: CGFloat = 28
        let sz = panel.frame.size
        var origin = NSPoint(x: mouse.x + offset, y: mouse.y - offset - sz.height)
        let pad: CGFloat = 8
        if let screen = NSScreen.screens.first(where: { NSMouseInRect(mouse, $0.frame, false) }) ?? NSScreen.main {
            let sf = screen.visibleFrame
            if origin.x + sz.width > sf.maxX - pad {
                origin.x = mouse.x - offset - sz.width
            }
            if origin.x < sf.minX + pad {
                origin.x = sf.minX + pad
            }
            if origin.y < sf.minY + pad {
                origin.y = sf.minY + pad
            }
            if origin.y + sz.height > sf.maxY - pad {
                origin.y = sf.maxY - pad - sz.height
            }
        }
        panel.setFrame(NSRect(origin: origin, size: sz), display: true)
    }
}
