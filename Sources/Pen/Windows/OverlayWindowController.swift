import AppKit
import Combine
import SwiftUI

/// Tam ekran çizim katmanı: `nonactivatingPanel` ile birlikte bile metin alanı odak alabilsin diye `canBecomeKey`.
private final class KeyableOverlayPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

@MainActor
final class OverlayWindowController: NSObject {
    private(set) var panel: NSPanel?
    private var hostingView: NSHostingView<AnyView>?

    /// Çizim kapalıyken kalem; ana panel `ignoresMouseEvents` iken tıklamalar burada yakalanır.
    private var penPanel: NSPanel?
    private var penHostingView: NSHostingView<AnyView>?

    private weak var appState: AppState?
    private var cancellables = Set<AnyCancellable>()

    static var combinedScreenFrame: CGRect {
        let screens = NSScreen.screens
        guard !screens.isEmpty else { return .zero }
        return screens.reduce(CGRect.null) { $0.union($1.frame) }
    }

    /// `MainOverlayView` / `MinimalPenFloater` ile aynı: sağ-alt padding 18, 50×50, `floatingToolbarOffset`.
    static func penFloaterRect(bounds: CGSize, offset: CGSize) -> CGRect {
        let side: CGFloat = 50
        let pad: CGFloat = 18
        return CGRect(
            x: bounds.width - pad - side + offset.width,
            y: bounds.height - pad - side + offset.height,
            width: side,
            height: side
        )
    }

    func install(rootView: AnyView, appState: AppState) {
        self.appState = appState

        let frame = Self.combinedScreenFrame
        let panel = KeyableOverlayPanel(
            contentRect: frame,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        panel.isOpaque = false
        panel.backgroundColor = .clear
        panel.hasShadow = false
        panel.level = .floating
        panel.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        panel.isMovable = false
        panel.hidesOnDeactivate = false
        panel.titleVisibility = .hidden
        panel.titlebarAppearsTransparent = true
        panel.ignoresMouseEvents = false
        panel.acceptsMouseMovedEvents = true

        let hosting = NSHostingView(rootView: rootView)
        hosting.layer?.backgroundColor = NSColor.clear.cgColor
        panel.contentView = hosting
        panel.setFrame(frame, display: true)

        panel.orderFrontRegardless()
        self.panel = panel
        self.hostingView = hosting

        setupPenPanel(appState: appState, mainLevel: panel.level)
        bindPenPanel(appState: appState)
        syncPenPanelFrame()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    private func setupPenPanel(appState: AppState, mainLevel: NSWindow.Level) {
        let side: CGFloat = 50
        let off = NSRect(x: -16000, y: -16000, width: side, height: side)
        let pen = NSPanel(
            contentRect: off,
            styleMask: [.borderless, .nonactivatingPanel, .fullSizeContentView],
            backing: .buffered,
            defer: false
        )
        pen.isOpaque = false
        pen.backgroundColor = .clear
        pen.hasShadow = false
        pen.level = NSWindow.Level(rawValue: mainLevel.rawValue + 1)
        pen.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary, .stationary]
        pen.isMovable = false
        pen.hidesOnDeactivate = false
        pen.titleVisibility = .hidden
        pen.titlebarAppearsTransparent = true
        pen.ignoresMouseEvents = false

        let container = Self.combinedScreenFrame.size
        let penRoot = MinimalPenFloater(appState: appState, containerSize: container)
        let hv = NSHostingView(rootView: AnyView(penRoot))
        hv.layer?.backgroundColor = NSColor.clear.cgColor
        pen.contentView = hv
        pen.setFrame(off, display: false)

        self.penPanel = pen
        self.penHostingView = hv
    }

    private func bindPenPanel(appState: AppState) {
        cancellables.removeAll()
        Publishers.CombineLatest(appState.$drawingEnabled, appState.$floatingToolbarOffset)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _, _ in
                self?.syncPenPanelFrame()
            }
            .store(in: &cancellables)
    }

    /// Çizim kapalı: ana pencere fareyi geçirir (`ignoresMouseEvents`), kalem ayrı panelde.
    private func syncPenPanelFrame() {
        guard let mainPanel = panel, let appState else { return }
        guard let penPanel else { return }

        if appState.drawingEnabled {
            mainPanel.ignoresMouseEvents = false
            penPanel.orderOut(nil)
            return
        }

        mainPanel.ignoresMouseEvents = true

        guard let cv = mainPanel.contentView else { return }
        let r = Self.penFloaterRect(bounds: cv.bounds.size, offset: appState.floatingToolbarOffset)
        let rectInWindow = cv.convert(r, to: nil)
        let rectScreen = mainPanel.convertToScreen(rectInWindow)
        penPanel.setFrame(rectScreen, display: true)
        penPanel.orderFrontRegardless()
    }

    @objc private func screenChanged() {
        guard let panel else { return }
        let frame = Self.combinedScreenFrame
        panel.setFrame(frame, display: true)
        if let appState, let hv = penHostingView {
            let c = Self.combinedScreenFrame.size
            hv.rootView = AnyView(MinimalPenFloater(appState: appState, containerSize: c))
        }
        syncPenPanelFrame()
        #if DEBUG
        for s in NSScreen.screens {
            let name = s.localizedName
            Swift.print(
                "[Pen] Ekran “\(name)” frame=\(s.frame) backingScale=\(s.backingScaleFactor)"
            )
        }
        Swift.print("[Pen] Birleşik overlay çerçevesi: \(frame)")
        #endif
    }

    func updateRootView(_ view: AnyView) {
        hostingView?.rootView = view
    }
}
