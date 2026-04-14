import AppKit

/// Sistem geneli ⌘+harf (varsayılan ⌘D). **Sistem Ayarları → Gizlilik ve Güvenlik → Erişilebilirlik** içinde Pen gerekir.
@MainActor
final class GlobalShortcutMonitor {
    private var globalMonitor: Any?
    private var localMonitor: Any?

    func start(toggleDrawing: @escaping () -> Void) {
        stop()
        let handler: (NSEvent) -> NSEvent? = { event in
            guard event.modifierFlags.contains(.command) else { return event }
            let want = AppPreferences.globalToggleKeyCharacter
            let got = event.charactersIgnoringModifiers?.lowercased() ?? ""
            if got == want || got == want.uppercased() {
                Task { @MainActor in
                    toggleDrawing()
                }
                return nil
            }
            return event
        }
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.keyDown]) { event in
            guard event.modifierFlags.contains(.command) else { return }
            let want = AppPreferences.globalToggleKeyCharacter
            let got = event.charactersIgnoringModifiers?.lowercased() ?? ""
            if got == want {
                Task { @MainActor in
                    toggleDrawing()
                }
            }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.keyDown], handler: handler)
    }

    func stop() {
        if let g = globalMonitor {
            NSEvent.removeMonitor(g)
            globalMonitor = nil
        }
        if let l = localMonitor {
            NSEvent.removeMonitor(l)
            localMonitor = nil
        }
    }
}
