import SwiftUI

struct PreferencesView: View {
    @EnvironmentObject private var document: DrawingDocument
    @AppStorage(AppPreferences.mergeDesktopExportKey) private var mergeDesktopExport = false
    @AppStorage(AppPreferences.toolbarAutoHideKey) private var toolbarAutoHide = true
    @AppStorage(AppPreferences.globalToggleKeyCharacterKey) private var toggleChar = "d"

    var body: some View {
        Form {
            Section {
                Toggle("Masaüstünü arka plan olarak birleştir (Pen penceresinin altı)", isOn: $mergeDesktopExport)
                    .help("PNG birleştir")
                Text("Ekranın geri kalanını yakalamak için Sistem Ayarları → Gizlilik → **Ekran Kaydı** izni istenebilir.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } header: {
                Label("PNG dışa aktarma", systemImage: "photo.on.rectangle.angled")
            }

            Section {
                Toggle("Daraltılmışken kenar şeridine gelince genişlet", isOn: $toolbarAutoHide)
                    .help("Kenarda genişlet")
            } header: {
                Label("Araç çubuğu", systemImage: "rectangle.and.pencil.and.ellipsis")
            }

            Section {
                LabeledContent("Kısayol") {
                    TextField("", text: $toggleChar)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 56)
                        .multilineTextAlignment(.center)
                        .help("Kısayol harfi")
                }
                Text("⌘ ile birlikte kullanılır (ör. **d** → ⌘D). Sistem genelinde çalışması için uygulamanın **Erişilebilirlik** listesinde olması gerekir; izin yoksa yalnızca Pen odaktayken çalışır.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            } header: {
                Label("Global kısayol", systemImage: "keyboard")
            }

            #if DEBUG
            Section {
                Text("Bellek / çizim performansı için çok sayıda stroke ekler; Instruments ile birlikte kullanın. Bkz. `TESTING.md`.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                Button("~3000 test çizgisi ekle") {
                    document.appendStressStrokes(strokeCount: 3000)
                }
                .help("Test çizgileri")
            } header: {
                Label("Geliştirici", systemImage: "hammer.fill")
            }
            #endif
        }
        .formStyle(.grouped)
        .frame(minWidth: 460, minHeight: 340)
        .padding(20)
    }
}
