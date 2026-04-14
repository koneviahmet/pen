import AppKit
import SwiftUI

@main
struct PenApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        MenuBarExtra("Pen", systemImage: ToolbarChrome.appMenuBar) {
            Button("Çizimi aç/kapa") {
                appDelegate.appState.toggleDrawingThrough()
            }
            .help("Çizim")
            .keyboardShortcut("d", modifiers: [.command])

            Button("Ayarlar…") {
                NSApp.sendAction(Selector(("showSettingsWindow:")), to: nil, from: nil)
            }
            .help("Ayarlar")
            .keyboardShortcut(",", modifiers: [.command])

            Divider()

            Button("Çıkış") {
                NSApplication.shared.terminate(nil)
            }
            .help("Çıkış")
        }

        Settings {
            PreferencesView()
                .environmentObject(appDelegate.document)
        }
    }
}
