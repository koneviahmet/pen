# Pen

`Pen`, macOS 14+ üzerinde çalışan Swift tabanli bir ekran ustu cizim ve beyaz tahta katmani uygulamasidir (SwiftPM + SwiftUI).

## Proje yapisi

- Dil: Swift 5.9+
- Paket yonetimi: Swift Package Manager
- Hedef platform: macOS 14+
- Giris noktasi: `Sources/Pen`

## Hizli baslangic

```bash
cd /path/to/pen
swift run Pen
```

## build.sh ile derleme ve calistirma

`build.sh` scripti release derlemesi alir, `~/Applications/Pen.app` bundle'ini olusturur, ad-hoc imzalar ve uygulamayi acar.

1. Script calistirma izni verin (ilk seferde):
   ```bash
   chmod +x build.sh
   ```
2. Scripti calistirin:
   ```bash
   ./build.sh
   ```
3. Uygulama yolu:
   - `~/Applications/Pen.app`

Not: `build.sh` yerel deneme icin uygundur. Uretim dagitimi icin notarization adimlarini takip etmelisiniz.

## Izinler

| Ozellik | Izin |
|--------|------|
| Cizim ac/kapa **sistem genelinde** ⌘+harf | **Sistem Ayarlari → Gizlilik ve Guvenlik → Erisilebilirlik** — Pen'i etkinlestirin. |
| Masaustu + uygulama goruntusu (PNG birlestirme, buyutec) | Genelde **Ekran Kaydi** (Screen Recording) istemi; macOS surumune gore degisebilir. |

Izin verilmezse: kisayollar yalnizca Pen odaktayken calisir; ekran yakalama bos veya kisitli olabilir.

## Kisayollar (varsayilan)

| Eylem | Tus |
|--------|-----|
| Geri | ⌘Z |
| Ileri | ⇧⌘Z |
| Cizim ac/kapa | ⌘D (Ayarlardan harf degistirilebilir) |

Menu cubugu ikonundan **Ayarlar...** (⌘,) ile PNG birlestirme, kenar genisletme ve global harf ayari yapilir.

## Coklu monitor ve DPI

Ayrintili manuel kontrol listesi: **[TESTING.md](TESTING.md)** (Faz 7.1).  
DEBUG derlemesinde ekran yapilandirmasi degisince Xcode konsoluna `[Pen] Ekran ...` loglari duser.

## Bellek / performans (Faz 7.2)

Uzun cizim oturumu veya stres icin adimlar **TESTING.md** icinde. DEBUG surumunde **Ayarlar → Gelistirici → ~3000 test cizgisi ekle** ile buyuk stroke seti uretilebilir; ardindan Instruments (Allocations / Leaks) onerilir.

## Imzalama / notarization (Faz 7.3)

- `build.sh` yalnizca **ad-hoc** imza uretir (yerel deneme).
- Uretim dagitimi icin: **[distribution/DISTRIBUTION.md](distribution/DISTRIBUTION.md)** ve sablon **`distribution/Pen.entitlements`**.
- Ornek notarize akisi: **`scripts/notarize_example.sh`** (parametreleri kendinize gore doldurun).

## Lisans ve kullanim notu

Bu uygulama yapay zeka destekli olarak olusturulmustur. Ihtiyaciniza gore degistirebilir, gelistirebilir ve dilediginiz gibi kullanabilirsiniz.
