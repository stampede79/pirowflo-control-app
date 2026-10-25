#!/usr/bin/env bash

set -euo pipefail

REMOTE_HOST="jan@docker-services"
REMOTE_DIR="/opt/app-downloads/html/pirowflo"

APK_SOURCE="build/app/outputs/flutter-apk/app-dev-debug.apk"
APK_REMOTE="pirowflo-control-dev.apk"

echo "========================================"
echo " PiRowFlo Control DEV Build"
echo "========================================"
echo

VERSION_LINE="$(grep '^version:' pubspec.yaml | head -n 1 | awk '{print $2}')"
VERSION="${VERSION_LINE%%+*}"
BUILD_NUMBER="${VERSION_LINE##*+}"

if [ "$VERSION" = "$VERSION_LINE" ]; then
    BUILD_NUMBER="0"
fi

echo "Version: $VERSION-dev"
echo "Build:   $BUILD_NUMBER"
echo

echo "[1/5] Flutter analyze"
flutter analyze

echo
echo "[2/5] Flutter tests"
flutter test

echo
echo "[3/5] Building DEV APK"
flutter build apk \
  --flavor dev \
  --debug \
  --target-platform android-arm64

if [ ! -f "$APK_SOURCE" ]; then
    echo "ERROR: APK not found: $APK_SOURCE"
    exit 1
fi

echo
echo "[4/5] Calculating metadata"

SHA256="$(sha256sum "$APK_SOURCE" | awk '{print $1}')"
SIZE_BYTES="$(stat -c '%s' "$APK_SOURCE")"
SIZE_MB="$(awk "BEGIN {printf \"%.1f\", $SIZE_BYTES / 1024 / 1024}")"
PUBLISHED="$(date '+%d.%m.%Y %H:%M')"

echo "Size:    ${SIZE_MB} MB"
echo "SHA-256: $SHA256"

echo
echo "[5/5] Publishing DEV build"

scp \
    "$APK_SOURCE" \
    "${REMOTE_HOST}:/tmp/${APK_REMOTE}"

ssh "$REMOTE_HOST" "
    set -e
    mkdir -p '$REMOTE_DIR'
    mv '/tmp/${APK_REMOTE}' '$REMOTE_DIR/${APK_REMOTE}'
    chmod 644 '$REMOTE_DIR/${APK_REMOTE}'
"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cat > "$TMP_DIR/dev-version.json" <<EOF
{
  "version": "${VERSION}-dev",
  "build": ${BUILD_NUMBER},
  "published": "${PUBLISHED}",
  "size_bytes": ${SIZE_BYTES},
  "sha256": "${SHA256}",
  "apk": "https://apps.roderwieser.com/pirowflo/${APK_REMOTE}"
}
EOF

scp \
    "$TMP_DIR/dev-version.json" \
    "${REMOTE_HOST}:/tmp/dev-version.json"

ssh "$REMOTE_HOST" "
    set -e
    mv /tmp/dev-version.json '$REMOTE_DIR/dev-version.json'
    chmod 644 '$REMOTE_DIR/dev-version.json'
"

echo
echo "========================================"
echo " DEV build published successfully"
echo "========================================"
echo
echo "Version:  ${VERSION}-dev"
echo "Build:    ${BUILD_NUMBER}"
echo "Size:     ${SIZE_MB} MB"
echo "SHA-256:  ${SHA256}"
echo
echo "Download:"
echo "https://apps.roderwieser.com/pirowflo/${APK_REMOTE}"

./update-download-page.sh
