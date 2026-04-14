import AppKit
import Combine
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let document = DrawingDocument()
    let appState = AppState()
    private var overlay: OverlayWindowController?
    private var shortcuts: ShortcutController?
    private var globalShortcuts: GlobalShortcutMonitor?
    private var magnifier: MagnifierWindowController?
    private var cancellables = Set<AnyCancellable>()

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)

        let controller = OverlayWindowController()
        let main = MainOverlayView(document: document, appState: appState)
            .environment(\.colorScheme, .dark)
            .environment(\.overlayWindowNumber, UInt32(0))

        controller.install(rootView: AnyView(main), appState: appState)
        overlay = controller

        if let wn = controller.panel?.windowNumber {
            let updated = MainOverlayView(document: document, appState: appState)
                .environment(\.colorScheme, .dark)
                .environment(\.overlayWindowNumber, UInt32(wn))
            controller.updateRootView(AnyView(updated))
        }

        let winNum = UInt32(controller.panel?.windowNumber ?? 0)
        if winNum != 0 {
            magnifier = MagnifierWindowController(appState: appState, overlayWindowNumber: Int(winNum))
        }

        shortcuts = ShortcutController(document: document)

        globalShortcuts = GlobalShortcutMonitor()
        globalShortcuts?.start { [weak self] in
            self?.appState.toggleDrawingThrough()
        }

        appState.$magnifierEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] enabled in
                guard let self else { return }
                guard let m = self.magnifier else { return }
                if enabled {
                    m.start()
                } else {
                    m.stop()
                }
            }
            .store(in: &cancellables)

        if appState.magnifierEnabled {
            magnifier?.start()
        }
    }
}
