# Test notları (Faz 7)

## 7.1 Çoklu monitör ve DPI — manuel kontrol listesi

Aşağıdakileri her önemli sürüm öncesi veya donanım değişiminde gözden geçirin.

- [ ] **İki veya daha fazla ekran**: Pen açıkken ikinci monitörü bağla / çıkar; overlay tüm ekranların birleşik dikdörtgenini kaplamalı, çizim tüm yüzeyde hizalı olmalı.
- [ ] **Ekran düzenini değiştir** (Sistem Ayarları → Monitörler): üst/alt veya yan yana; Pen yeniden boyanmalı (pencere `screenChanged` ile güncellenir).
- [ ] **Retina vs standart**: farklı `backingScaleFactor` olan ekranlarda çizgi kalınlığı görsel olarak tutarlı mı; PNG dışa aktarma beklenen çözünürlükte mi.
- [ ] **DEBUG**: Ekran parametre değişince Xcode konsolunda `[Pen] Ekran: frame=… backingScale=…` logları görünür.

## 7.2 Bellek / uzun ders — Instruments

1. **Xcode** veya komut satırından **Debug** derlemesi ile Pen’i çalıştırın.
2. **Ayarlar** (DEBUG) → **~3000 test çizgisi ekle** ile büyük bellek ayak izi oluşturun.
3. **Xcode → Open Developer Tool → Instruments → Leaks / Allocations** ile `Pen` sürecini izleyin.
4. Çizim sırasında ve undo sonrası bellek eğrisinin sürekli yükselmediğini doğrulayın (beklenmeyen tutma varsa raporlayın).

Komut satırı (yüzeysel): Activity Monitor’da Pen sürecinin bellek kullanımını gözlemleyin.

## Otomasyon

Şu an CI’da otomatik UI testi yok; yukarıdakiler manuel kalite kontrol listesidir.
