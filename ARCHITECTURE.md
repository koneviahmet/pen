# Pen — kısa mimari

## Katmanlar

1. **Uygulama kabuğu** (`PenApp`, `AppDelegate`)  
   - Menü çubuğu ekstra, `Settings` sahnesi, `NSApplication` accessory modu.

2. **Tam ekran overlay** (`OverlayWindowController`)  
   - Tek `NSPanel`: `borderless`, `nonactivatingPanel`, `floating`, birleşik `NSScreen` çerçevesi.  
   - İçerik: SwiftUI kök görünüm.

3. **Kök görünüm** (`MainOverlayView`)  
   - **Tahta arka planı** (şeffaf / düz renk / kareli).  
   - **Annotation canvas** (SwiftUI `Canvas`): stroke, şekil, silgi, önizleme.  
   - **Metin** katmanı: `TextField` ile taşınabilir öğeler.  
   - **Lazer** ve **Spotlight**: ayrı `Canvas` / maske, çizime kaydedilmez.  
   - **Fare izleme** (`MouseTrackingRepresentable`): basınç / lazer / spotlight.  
   - **FloatingToolbar**: cam malzeme, tıklanabilir; çizim kapalıyken geri kalan yüzey `allowsHitTesting(false)`.

4. **Durum**  
   - `DrawingDocument`: stroke / şekil / metin + anlık görüntü ile undo/redo.  
   - `AppState`: araç, renk, çizim açık, spotlight, büyüteç vb.

5. **Yardımcılar**  
   - `ImageExport`: bitmap bağlamında vektör çizim + isteğe bağlı masaüstü yakalama (`CGWindowListCreateImage`, Pen penceresinin **altı**).  
   - `MagnifierWindowController`: küçük panel + periyodik ekran örneği.  
   - `GlobalShortcutMonitor`: yerel + global `NSEvent` (⌘+harf).

## Veri akışı

Çizim jestleri → `AnnotationCanvasLayer` → `DrawingDocument` güncellemesi → `Canvas` yeniden çizim.  
PNG dışa aktarma okuma yolu: belge + `AppPreferences.mergeDesktopExport` + `overlayWindowNumber`.
