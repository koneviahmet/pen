#!/usr/bin/env bash
# Örnek: notarytool ile gönderim (Apple hesabı ve uygulama şifresi gerekir).
# Gerçek değerleri Xcode / developer.apple.com dokümantasyonundan alın.
set -euo pipefail

APP="${1:?Pen.app yolu verin}"

echo "==> Zip oluşturuluyor"
ditto -c -k --keepParent "${APP}" "${APP%.app}.zip"

echo "==> Notarytool gönderimi (örnek — parametreleri kendinize göre düzenleyin)"
# xcrun notarytool submit "${APP%.app}.zip" --apple-id "..." --team-id "..." --password "@keychain:AC_PASSWORD" --wait

echo "==> Onay sonrası:"
echo "    xcrun stapler staple \"${APP}\""
