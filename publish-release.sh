#!/usr/bin/env bash

set -euo pipefail

REMOTE_HOST="jan@docker-services"
REMOTE_DIR="/opt/app-downloads/html/pirowflo"

APK_SOURCE="build/app/outputs/flutter-apk/app-release.apk"

echo "========================================"
echo " PiRowFlo Control Release"
echo "========================================"
echo

VERSION_LINE="$(grep '^version:' pubspec.yaml | head -n 1 | awk '{print $2}')"
VERSION="${VERSION_LINE%%+*}"
BUILD_NUMBER="${VERSION_LINE##*+}"

if [ "$VERSION" = "$VERSION_LINE" ]; then
    BUILD_NUMBER="0"
fi

APK_VERSIONED="pirowflo-control-${VERSION}.apk"
APK_LATEST="pirowflo-control.apk"

echo "Version: $VERSION"
echo "Build:   $BUILD_NUMBER"
echo

echo "[1/6] Flutter analyze"
flutter analyze

echo
echo "[2/6] Flutter tests"
flutter test

echo
echo "[3/6] Building release APK"
flutter build apk --release

if [ ! -f "$APK_SOURCE" ]; then
    echo "ERROR: APK not found: $APK_SOURCE"
    exit 1
fi

echo
echo "[4/6] Calculating metadata"

SHA256="$(sha256sum "$APK_SOURCE" | awk '{print $1}')"
SIZE_BYTES="$(stat -c '%s' "$APK_SOURCE")"
SIZE_MB="$(awk "BEGIN {printf \"%.1f\", $SIZE_BYTES / 1024 / 1024}")"
PUBLISHED="$(date '+%d.%m.%Y %H:%M')"

echo "Size:    ${SIZE_MB} MB"
echo "SHA-256: $SHA256"

echo
echo "[5/6] Uploading APK"

scp \
    "$APK_SOURCE" \
    "${REMOTE_HOST}:/tmp/${APK_VERSIONED}"

ssh "$REMOTE_HOST" "
    set -e
    mkdir -p '$REMOTE_DIR'
    mv '/tmp/${APK_VERSIONED}' '$REMOTE_DIR/${APK_VERSIONED}'
    cp '$REMOTE_DIR/${APK_VERSIONED}' '$REMOTE_DIR/${APK_LATEST}'
    chmod 644 '$REMOTE_DIR/${APK_VERSIONED}' '$REMOTE_DIR/${APK_LATEST}'
"

echo
echo "[6/6] Updating download page"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cat > "$TMP_DIR/index.html" <<EOF
<!doctype html>
<html lang="de">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>App Downloads</title>
  <style>
    body {
      font-family: system-ui, sans-serif;
      max-width: 720px;
      margin: 0 auto;
      padding: 32px 20px;
      line-height: 1.5;
    }

    .card {
      padding: 24px;
      border: 1px solid #8885;
      border-radius: 16px;
    }

    .download {
      display: inline-block;
      padding: 12px 18px;
      margin: 8px 0 16px;
      text-decoration: none;
      border: 1px solid currentColor;
      border-radius: 10px;
      font-weight: 600;
    }

    .meta {
      opacity: 0.75;
    }

    code {
      overflow-wrap: anywhere;
    }
  </style>
</head>
<body>
  <h1>App Downloads</h1>

  <div class="card">
    <h2>PiRowFlo Control</h2>

    <p>
      Android-App zur Steuerung von PiRowFlo und für geführte
      Rudertrainings.
    </p>

    <p>
      <a class="download"
         href="/pirowflo/${APK_LATEST}">
        APK herunterladen
      </a>
    </p>

    <div class="meta">
      <p>
        Version ${VERSION} · Build ${BUILD_NUMBER}<br>
        Veröffentlicht: ${PUBLISHED}<br>
        Größe: ${SIZE_MB} MB
      </p>

      <p>
        SHA-256:<br>
        <code>${SHA256}</code>
      </p>

      <p>
        <a href="/pirowflo/${APK_VERSIONED}">
          Version ${VERSION} direkt herunterladen
        </a>
      </p>
    </div>
  </div>
</body>
</html>
EOF

cat > "$TMP_DIR/version.json" <<EOF
{
  "version": "${VERSION}",
  "build": ${BUILD_NUMBER},
  "published": "${PUBLISHED}",
  "size_bytes": ${SIZE_BYTES},
  "sha256": "${SHA256}",
  "apk": "https://apps.roderwieser.com/pirowflo/${APK_LATEST}"
}
EOF

scp \
    "$TMP_DIR/index.html" \
    "$TMP_DIR/version.json" \
    "${REMOTE_HOST}:/tmp/"

ssh "$REMOTE_HOST" "
    set -e
    mv /tmp/index.html /opt/app-downloads/html/index.html
    mv /tmp/version.json /opt/app-downloads/html/pirowflo/version.json
    chmod 644 \
      /opt/app-downloads/html/index.html \
      /opt/app-downloads/html/pirowflo/version.json
"

echo
echo "========================================"
echo " Release published successfully"
echo "========================================"
echo
echo "Version:  $VERSION"
echo "Build:    $BUILD_NUMBER"
echo "Size:     ${SIZE_MB} MB"
echo "SHA-256:  $SHA256"
echo
echo "Download:"
echo "https://apps.roderwieser.com/"
