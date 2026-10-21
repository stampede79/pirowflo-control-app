#!/usr/bin/env bash

set -euo pipefail

REMOTE_HOST="jan@docker-services"
REMOTE_ROOT="/opt/app-downloads/html"

TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

cat > "$TMP_DIR/index.html" <<'EOF'
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
      margin-bottom: 20px;
      border: 1px solid #8885;
      border-radius: 16px;
    }

    .download {
      display: inline-block;
      padding: 12px 18px;
      margin-top: 8px;
      text-decoration: none;
      border: 1px solid currentColor;
      border-radius: 10px;
      font-weight: 600;
    }

    .meta {
      opacity: 0.75;
    }
  </style>
</head>

<body>
  <h1>App Downloads</h1>

  <div class="card">
    <h2>PiRowFlo Control</h2>

    <p>
      Stabile Version für die normale Nutzung.
    </p>

    <a class="download"
       href="/pirowflo/pirowflo-control.apk">
      Stable herunterladen
    </a>
  </div>

  <div class="card">
    <h2>PiRowFlo Control Dev</h2>

    <p>
      Entwicklungs- und Testversion.
    </p>

    <p class="meta">
      Wird unabhängig von der stabilen Version installiert und
      verwendet eigene App-Daten.
    </p>

    <a class="download"
       href="/pirowflo/pirowflo-control-dev.apk">
      Dev-Version herunterladen
    </a>
  </div>
</body>
</html>
EOF

scp \
  "$TMP_DIR/index.html" \
  "${REMOTE_HOST}:/tmp/app-downloads-index.html"

ssh "$REMOTE_HOST" "
  set -e
  mv /tmp/app-downloads-index.html '$REMOTE_ROOT/index.html'
  chmod 644 '$REMOTE_ROOT/index.html'
"

echo "Download page updated:"
echo "https://apps.roderwieser.com/"
