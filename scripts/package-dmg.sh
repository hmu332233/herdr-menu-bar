#!/usr/bin/env bash
# .app 번들을 빌드하고 드래그&드롭 설치용 .dmg로 묶는다.
# 사용: scripts/package-dmg.sh [버전]   (기본: Info.plist의 CFBundleShortVersionString)
set -euo pipefail

cd "$(dirname "$0")/.."

APP_NAME="herdr-menu-bar"
OUT_DIR="dist"
APP="${OUT_DIR}/${APP_NAME}.app"

# 1) .app 빌드
scripts/build-app.sh "${OUT_DIR}"

# 2) 버전 결정 (인자 우선, 없으면 Info.plist에서)
VERSION="${1:-$(/usr/libexec/PlistBuddy -c 'Print :CFBundleShortVersionString' "${APP}/Contents/Info.plist")}"
DMG="${OUT_DIR}/${APP_NAME}-${VERSION}.dmg"

# 3) dmg 스테이징 (앱 + /Applications 별칭)
echo "▶ Staging dmg contents…"
STAGE="$(mktemp -d)"
trap 'rm -rf "${STAGE}"' EXIT
cp -R "${APP}" "${STAGE}/"
ln -s /Applications "${STAGE}/Applications"

# 4) dmg 생성
echo "▶ Building ${DMG}…"
rm -f "${DMG}"
hdiutil create \
	-volname "${APP_NAME}" \
	-srcfolder "${STAGE}" \
	-fs HFS+ \
	-format UDZO \
	-quiet \
	"${DMG}"

echo "✓ ${DMG}"
echo "  GitHub Release에 이 dmg를 끌어다 업로드하세요."
