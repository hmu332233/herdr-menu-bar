#!/usr/bin/env bash
# 릴리스 바이너리를 macOS .app 번들로 조립한다.
# 사용: scripts/build-app.sh [출력디렉터리]  (기본: ./dist)
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="herdr-menu-bar"
EXECUTABLE="HerdrMenuBar"
OUT_DIR="${1:-dist}"
APP="${OUT_DIR}/${APP_NAME}.app"

echo "▶ Building release binary…"
swift build -c release --product "${EXECUTABLE}"
BIN_DIR="$(swift build -c release --product "${EXECUTABLE}" --show-bin-path)"
BIN_PATH="${BIN_DIR}/${EXECUTABLE}"
CORE_RESOURCE_BUNDLE="${BIN_DIR}/${EXECUTABLE}_HerdrCore.bundle"

echo "▶ Assembling ${APP}…"
rm -rf "${APP}"
mkdir -p "${APP}/Contents/MacOS" "${APP}/Contents/Resources"

cp "${BIN_PATH}" "${APP}/Contents/MacOS/${EXECUTABLE}"
cp -R "${CORE_RESOURCE_BUNDLE}" "${APP}/Contents/Resources/"
cp Resources/Info.plist "${APP}/Contents/Info.plist"
printf 'APPL????' > "${APP}/Contents/PkgInfo"

echo "▶ Ad-hoc code signing…"
codesign --force --deep --sign - "${APP}"

echo "✓ Built ${APP}"
echo "  실행: open \"${APP}\""
