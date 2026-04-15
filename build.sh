#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Pen"
BUNDLE_ID="com.orbey.Pen"
VERSION="1.0"
BUILD_NUMBER="1"

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${ROOT_DIR}/.build/arm64-apple-macosx/release"
BIN_PATH="${BUILD_DIR}/${APP_NAME}"
APP_PATH="${HOME}/Applications/${APP_NAME}.app"
CONTENTS_PATH="${APP_PATH}/Contents"
MACOS_PATH="${CONTENTS_PATH}/MacOS"
RESOURCES_PATH="${CONTENTS_PATH}/Resources"
PLIST_PATH="${CONTENTS_PATH}/Info.plist"

if pgrep -x "${APP_NAME}" > /dev/null; then
  echo "==> ${APP_NAME} is running, closing it before build"
  pkill -x "${APP_NAME}"
  while pgrep -x "${APP_NAME}" > /dev/null; do
    sleep 0.2
  done
fi

echo "==> Building release binary"
swift build -c release --package-path "${ROOT_DIR}"

if [[ ! -f "${BIN_PATH}" ]]; then
  echo "Build output not found: ${BIN_PATH}"
  exit 1
fi

echo "==> Creating app bundle at ${APP_PATH}"
mkdir -p "${MACOS_PATH}" "${RESOURCES_PATH}"
cp "${BIN_PATH}" "${MACOS_PATH}/${APP_NAME}"
chmod +x "${MACOS_PATH}/${APP_NAME}"

cat > "${PLIST_PATH}" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleDevelopmentRegion</key>
    <string>tr</string>
    <key>CFBundleExecutable</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIdentifier</key>
    <string>${BUNDLE_ID}</string>
    <key>CFBundleInfoDictionaryVersion</key>
    <string>6.0</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>${VERSION}</string>
    <key>CFBundleVersion</key>
    <string>${BUILD_NUMBER}</string>
    <key>LSMinimumSystemVersion</key>
    <string>14.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSScreenCaptureUsageDescription</key>
    <string>Pen, masaüstü ve diğer pencerelerin görüntüsünü PNG dışa aktarma ve büyüteç için yakalar.</string>
</dict>
</plist>
EOF

echo "==> Codesigning app bundle (ad-hoc)"
codesign --force --deep --sign - "${APP_PATH}"

echo "==> Launching app"
open "${APP_PATH}"

echo "==> Done"
echo "App: ${APP_PATH}"
