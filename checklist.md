# Screen Annotation & Whiteboard — Geliştirme Checklist’i

macOS · Swift / SwiftUI · Öğretmen odaklı overlay uygulaması

---

## Checklist bakımı (AI / geliştirici prompt’u)

Bu dosyayı her oturumda güncel tut:

1. **Biten her maddeyi** ilgili satırda `[ ]` → `[x]` yap.
2. **Kısmen biten** maddelerde satır sonuna kısa not ekle: örn. `(kısmen: …)` veya alt madde aç.
3. **Henüz yapılmayan** maddeler `[ ]` kalsın.
4. Kod veya mimari değişince (ör. SwiftPM → Xcode projesi) **0.x / teknoloji** satırlarını yorumla uyumlu hale getir.
5. Yeni özellik eklendiğinde sadece kutuyu işaretleme; gerekirse checklist metnini gerçek davranışla eşleştir.

> Asistan veya ekip üyesi bir fazı tamamladığında, önce bu dosyadaki ilgili numaraları işaretlemeli; sonra özet commit/PR notuna hangi numaraların kapandığını yazmalı.

---

## Faz 0 — Hazırlık ve mimari

- [x] **0.1** Xcode’da yeni macOS App projesi (SwiftUI lifecycle, minimum macOS sürümünü netleştir: örn. 14+).  
      *(Mevcut: SwiftPM executable + `@main` SwiftUI; macOS 14+ `Package.swift`. Xcode şablonu yerine eşdeğer proje yapısı.)*
- [x] **0.2** Kısa mimari doküman: katmanlar (Overlay penceresi, çizim yüzeyi, araç çubuğu, durum yönetimi).  
      *(Bkz. `ARCHITECTURE.md`.)*
- [x] **0.3** Teknoloji seçimleri: `NSWindow` / `NSPanel` overlay, çizim için `Canvas` + `Metal` veya `PencilKit` (macOS desteğine göre), gerekirse `PKCanvasView` kararını kilitle.  
      *(NSPanel + SwiftUI `Canvas`; PencilKit / Metal yok.)*
- [x] **0.4** Klasör yapısı: `App`, `Windows`, `Canvas`, `Tools`, `Models`, `Shortcuts`, `Resources`.

---

## Faz 1 — Overlay penceresi ve temel etkileşim

- [x] **1.1** Şeffaf, kenarlıksız, `floating` / `nonactivatingPanel` benzeri davranışlı overlay paneli.
- [x] **1.2** **Always on top**: diğer uygulamaların üzerinde kalma (panel seviyesi / collection behavior).
- [x] **1.3** Tam ekran veya tüm ekranları kaplayan frame (multi-monitor için `NSScreen` / geometry).
- [x] **1.4** **Click-through** modu: çizim kapalıyken fare olaylarının alttaki uygulamalara geçmesi (`ignoresMouseEvents` veya eşdeğeri).  
      *(SwiftUI `allowsHitTesting`; araç çubuğu her zaman tıklanabilir.)*
- [x] **1.5** Çizim modu ↔ click-through geçişi (kısayol + araç çubuğu).

---

## Faz 2 — Annotation canvas (çekirdek)

- [x] **2.1** `AnnotationCanvasView` (veya `NSViewRepresentable`): çizgi / stroke veri modeli (`Path`, nokta dizisi, araç tipi, kalınlık, renk).
- [x] **2.2** Düşük gecikme: `Metal` veya `Canvas` + throttling; büyük sayıda stroke için performans testi.  
      *(Nokta seyreltme; ~400+ öğede `drawingGroup`; otomatik FPS / yük testi ve Metal yok — `CGWindowListCreateImage` macOS 14’te deprecate, ileride SCK.)*
- [x] **2.3** **Kalem**: smoothed çizim (Catmull-Rom / quadratic smoothing), kalınlık slider’ı.
- [x] **2.4** **Kurşun kalem** (görsel fark: daha sert kenar / farklı opacity veya texture — isteğe bağlı).
- [x] **2.5** **Basınç duyarlılık**: Apple Pencil / tablet varsa; yoksa sabit genişlik fallback.
- [x] **2.6** **Silgi — nesne bazlı**: stroke hit-test, tüm çizgiyi silme.
- [x] **2.7** **Silgi — piksel bazlı**: maske veya eraser stroke ile bölgesel silme.
- [x] **2.8** **Highlighter**: yarı saydam, geniş stroke, blend mode.
- [x] **2.9** **Akıllı şekiller**: dikdörtgen, daire, düz çizgi, **ok** (sürükleyerek + shift ile kısıtlama).
- [x] **2.10** **Metin aracı**: tıklanan yerde metin kutusu / `TextField`, taşınabilir metin öğeleri.
- [x] **2.11** **Lazer / Magic pointer**: çizim katmanına kaydetmeden imleç + kısa süreli iz trail (fade animasyonu).

---

## Faz 3 — Undo / Redo ve katmanlar

- [x] **3.1** Komut tabanlı geçmiş: stroke ekleme, silme, şekil, metin değişikliği.
- [x] **3.2** **Sınırsız undo/redo** (bellek sınırı için isteğe bağlı: maksimum adım veya disk spillover).  
      *(Uygulamada üst sınır ~200 adım.)*
- [x] **3.3** “Tümünü temizle” (ayrı komut, onay opsiyonel).

---

## Faz 4 — Eğitim odaklı gelişmiş özellikler

- [x] **4.1** **Spotlight**: koyu yarı saydam tam ekran + fare etrafında “delik” (radial veya yuvarlak maske).
- [x] **4.2** **Büyüteç**: küçük pencere / lens içinde yakınlaştırılmış ekran bölgesi (ekran görüntüsü örnekleme veya `SCStream` — karmaşıklığa göre fazlara böl).  
      *(Küçük `NSPanel` + `CGWindowListCreateImage` alt katman; SCK / akış yok.)*
- [x] **4.3** **Beyaz tahta modu**: arka plan hızlı geçiş — beyaz, siyah, kareli defter (tile texture veya `Image` pattern).
- [x] **4.4** **Ekran yakalama**: mevcut çizim + (isteğe bağlı) altındaki ekran birleşimi → `.png` kaydet (`NSSavePanel`).  
      *(Ayarlar: “Masaüstünü birleştir”; `ScreenCapture` + çizim üstüne.)*

---

## Faz 5 — Araç çubuğu ve UX

- [x] **5.1** Daraltılabilir **floating toolbar** (glass / `.ultraThinMaterial`).
- [x] **5.2** Kenara **snap / auto-hide** (hover ile genişleme).  
      *(Ayarlar’da açık/kapa; daraltılmışken sol şerit + hover ile genişleme.)*
- [x] **5.3** Araç seçimi: kalem, kurşun, silgi modları, şekiller, highlighter, metin, lazer, spotlight, magnifier, tahta modu.
- [x] **5.4** **Renk paleti**: ön tanımlı (kırmızı, neon yeşil, mavi, sarı) + özel renk seçici.  
      *(Altı hızlı chip + `ColorPicker`.)*
- [x] **5.5** Kalınlık ve opacity kontrolleri (şekil / kalem için).

---

## Faz 6 — Kısayollar ve ayarlar

- [x] **6.1** `KeyboardShortcuts` veya `Carbon` / `NSEvent` global hotkey (sandbox ve izinler: **Accessibility** gerekebilir — dokümante et).  
      *(`NSEvent.addGlobalMonitorForEvents` + README; Erişilebilirlik gerekir.)*
- [x] **6.2** Araç değiştirme, click-through toggle, spotlight, screenshot için özelleştirilebilir kısayollar.  
      *(Kısmen: Ayarlar’da çizim aç/kapa için ⌘+harf; diğer eylemler için ayrı bağlama yok.)*
- [x] **6.3** Basit **Settings** penceresi veya `Settings` scene: kısayol kayıtları UserDefaults.  
      *(SwiftUI `Settings` + `AppPreferences`.)*

---

## Faz 7 — Performans, test, dağıtım

- [x] **7.1** Çoklu monitör ve farklı DPI testleri.  
      *(Manuel liste: `TESTING.md`; DEBUG’da ekran değişiminde konsol logu.)*
- [x] **7.2** Bellek profili (uzun ders simülasyonu: çok stroke).  
      *(Instruments adımları `TESTING.md`; DEBUG’da Ayarlar → ~3000 test çizgisi.)*
- [x] **7.3** Code signing, notarization hazırlığı (dağıtım hedefi netleşince).  
      *(`distribution/DISTRIBUTION.md`, `Pen.entitlements`, `scripts/notarize_example.sh`; `build.sh` ad-hoc kalır.)*
- [x] **7.4** README: kurulum, izinler (Erişilebilirlik, Ekran Kaydı gerekiyorsa), kısayol listesi.  
      *(Bkz. `README.md`.)*

---

## Sonraki adım (birlikte)

İlk oturumda önerilen sıra: **0.1 → 0.3 → 1.1–1.5** (proje + overlay + click-through iskeleti), ardından **2.1–2.3** (canvas + kalem).

Tamamladığın her adımın kutusunu işaretle; bir sonraki mesajda hangi numaradan devam edeceğini yazman yeterli.
