# Dağıtım: imzalama ve notarization (Faz 7.3)

Bu depo geliştirme odaklıdır; **Apple Developer Program** üyeliği ve **Developer ID Application** sertifikası olmadan App Store dışı dağıtım tamamlanamaz.

## Önkoşullar

- Apple Developer hesabı, **Developer ID Application** sertifikası (Keychain’de).
- Uygulama kimliği: örn. `com.sirket.Pen` (`build.sh` / `CFBundleIdentifier` ile uyumlu yapın).
- [Hardened Runtime](https://developer.apple.com/documentation/security/hardened_runtime) açık olmalı (genelde `codesign --options runtime`).

## İmzalama (özet)

```bash
codesign --force --deep --options runtime --sign "Developer ID Application: Adınız (TAKIM ID)" Pen.app
```

Entitlements dosyası gerekiyorsa:

```bash
codesign --force --deep --options runtime \
  --entitlements distribution/Pen.entitlements \
  --sign "Developer ID Application: …" Pen.app
```

`distribution/Pen.entitlements` şu an minimal bir şablondur; gereksinime göre (ör. sandbox, kütüphane yükleme) genişletin.

## Notarization (özet)

1. `.app` veya zip’i Apple’a yükleyin (`notarytool` veya `altool` — Apple dokümantasyonuna bakın).
2. Onaydan sonra **staple**: `xcrun stapler staple Pen.app`
3. Kullanıcılar Gatekeeper uyarısı görmeden açabilir (yine de doğru imza + notarization şart).

Örnek komut iskeleti: `scripts/notarize_example.sh` (kimlik bilgileri yer tutucu).

## build.sh

`build.sh` yalnızca **ad-hoc** (`codesign -`) imza üretir; dağıtım için yeterli değildir.
