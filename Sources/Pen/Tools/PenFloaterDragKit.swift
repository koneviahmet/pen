import AppKit
import SwiftUI

/// Küçük kalem paneli SwiftUI `DragGesture` ile güvenilir takip etmiyor (pencere sürekli taşınıyor).
/// Ekran koordinatlı fare olayları 1:1 hareket sağlar.
final class PenFloaterDragNSView: NSView {
    weak var appState: AppState?
    var containerSize: CGSize = .zero

    private var lastMouseScreen: CGPoint?
    private var startMouseScreen: CGPoint?
    private var offsetAtGestureStart: CGSize?

    override var isOpaque: Bool { false }

    override func draw(_ dirtyRect: NSRect) {}

    override var acceptsFirstResponder: Bool { true }

    override func hitTest(_ point: NSPoint) -> NSView? {
        bounds.contains(point) ? self : nil
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        let p = NSEvent.mouseLocation
        lastMouseScreen = p
        startMouseScreen = p
        offsetAtGestureStart = appState?.floatingToolbarOffset
    }

    override func mouseDragged(with event: NSEvent) {
        guard let appState, let last = lastMouseScreen else { return }
        let now = NSEvent.mouseLocation
        let dx = now.x - last.x
        // Ekran: Y yukarı pozitif. SwiftUI offset Y: aşağı pozitif → fare aşağı = ekran Y azalır.
        let dyOffset = -(now.y - last.y)
        lastMouseScreen = now
        var next = appState.floatingToolbarOffset
        next.width += dx
        next.height += dyOffset
        appState.floatingToolbarOffset = ToolbarOffsetClamp.clamp(next, containerSize: containerSize)
    }

    override func mouseUp(with event: NSEvent) {
        defer {
            lastMouseScreen = nil
            startMouseScreen = nil
            offsetAtGestureStart = nil
        }
        guard let appState else { return }
        let end = NSEvent.mouseLocation
        let start = startMouseScreen ?? end
        let d = hypot(end.x - start.x, end.y - start.y)
        if d < ToolbarOffsetClamp.tapVsDragThreshold {
            if let o = offsetAtGestureStart {
                appState.floatingToolbarOffset = o
            }
            withAnimation(.spring(response: 0.34, dampingFraction: 0.82)) {
                appState.drawingEnabled = true
            }
        } else {
            AppPreferences.floatingToolbarOffset = appState.floatingToolbarOffset
        }
    }
}

struct PenFloaterDragRepresentable: NSViewRepresentable {
    @ObservedObject var appState: AppState
    var containerSize: CGSize

    func makeNSView(context: Context) -> PenFloaterDragNSView {
        let v = PenFloaterDragNSView()
        v.wantsLayer = true
        v.layer?.backgroundColor = NSColor.clear.cgColor
        v.appState = appState
        v.containerSize = containerSize
        return v
    }

    func updateNSView(_ nsView: PenFloaterDragNSView, context: Context) {
        nsView.appState = appState
        nsView.containerSize = containerSize
    }
}
