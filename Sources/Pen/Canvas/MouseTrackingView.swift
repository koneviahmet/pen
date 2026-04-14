import AppKit
import SwiftUI

/// Delivers mouse moves (and optional pressure) in the overlay coordinate space for laser / spotlight follow.
final class MouseTrackingNSView: NSView {
    var onMove: ((CGPoint, CGFloat) -> Void)?

    override var isFlipped: Bool { true }

    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        window?.acceptsMouseMovedEvents = true
    }

    override func layout() {
        super.layout()
        trackingAreas.forEach { removeTrackingArea($0) }
        let options: NSTrackingArea.Options = [.activeAlways, .mouseMoved, .inVisibleRect, .cursorUpdate]
        addTrackingArea(NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil))
    }

    override func mouseMoved(with event: NSEvent) {
        deliver(event)
    }

    override func mouseDragged(with event: NSEvent) {
        deliver(event)
    }

    override func pressureChange(with event: NSEvent) {
        deliver(event)
    }

    private func deliver(_ event: NSEvent) {
        let p = convert(event.locationInWindow, from: nil)
        let pressure = CGFloat(event.pressure)
        onMove?(p, pressure)
    }
}

struct MouseTrackingRepresentable: NSViewRepresentable {
    var enabled: Bool
    var onMove: (CGPoint, CGFloat) -> Void

    func makeNSView(context: Context) -> MouseTrackingNSView {
        let v = MouseTrackingNSView()
        v.onMove = { p, pr in
            if enabled { onMove(p, pr) }
        }
        return v
    }

    func updateNSView(_ nsView: MouseTrackingNSView, context: Context) {
        nsView.onMove = { p, pr in
            if enabled { onMove(p, pr) }
        }
    }
}
