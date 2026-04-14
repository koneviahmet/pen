import AppKit

@MainActor
final class ShortcutController {
    private var monitors: [Any] = []

    init(document: DrawingDocument) {
        let d = document

        let local = NSEvent.addLocalMonitorForEvents(matching: [.keyDown]) { event in
            guard let chars = event.charactersIgnoringModifiers?.lowercased() else { return event }
            let cmd = event.modifierFlags.contains(.command)
            let shift = event.modifierFlags.contains(.shift)

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
