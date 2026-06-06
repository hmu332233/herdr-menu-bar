#!/usr/bin/env bash
# .app 번들을 빌드하고 GitHub Release 업로드용 zip으로 묶는다.
# 사용: scripts/package-release.sh [버전]   (기본: Info.plist의 CFBundleShortVersionString)
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="herdr-menu-bar"
OUT_DIR="dist"
APP="${OUT_DIR}/${APP_NAME}.app"

# 1) .app 빌드
scripts/build-app.sh "${OUT_DIR}"

# 2) 버전 결정 (인자 우선, 없으면 Info.plist에서)
VERSION="${1:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${APP}/Contents/Info.plist")}"
ZIP="${OUT_DIR}/${APP_NAME}-${VERSION}.zip"

# 3) zip (ditto가 macOS 메타데이터·서명을 보존)
echo "▶ Packaging ${ZIP}…"
rm -f "${ZIP}"
ditto -c -k --keepParent "${APP}" "${ZIP}"

echo "✓ ${ZIP}"
echo "  GitHub Release에 이 zip을 끌어다 업로드하세요."
