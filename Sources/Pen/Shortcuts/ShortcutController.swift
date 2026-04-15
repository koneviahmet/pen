import AppKit

@MainActor
final class ShortcutController {
    private var monitors: [Any] = []

    init(document: DrawingDocument, appState: AppState) {
        let d = document
        let state = appState

        let local = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            guard let chars = event.charactersIgnoringModifiers?.lowercased() else { return event }
            let cmd = event.modifierFlags.contains(.command)
            let shift = event.modifierFlags.contains(.shift)

            if event.keyCode == 53 { // Esc
                if state.drawingEnabled {
                    state.drawingEnabled = false
                    return nil
                }
                return event
            }

            if cmd && chars == "z" {
                if shift {
                    d.redo()
                } else {
                    d.undo()
                }
                return nil
            }
            return event
        }
        if let local {
            monitors.append(local)
        }
    }

    deinit {
        for m in monitors {
            NSEvent.removeMonitor(m)
        }
    }
}
