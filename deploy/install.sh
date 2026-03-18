#!/usr/bin/env bash

set -euo pipefail

APP_NAME="mock-opensearch"
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_TEMPLATE="$APP_DIR/deploy/mock-opensearch.service"
SERVICE_TARGET="/etc/systemd/system/${APP_NAME}.service"
TMP_SERVICE="/tmp/${APP_NAME}.service"
APP_USER="${SUDO_USER:-$(whoami)}"

echo "[1/6] Checking OS..."
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  OS_ID="${ID:-unknown}"
else
  echo "Unsupported OS: /etc/os-release not found"
  exit 1
fi

if [[ "$OS_ID" != "ubuntu" && "$OS_ID" != "debian" ]]; then
  echo "This installer currently supports Ubuntu/Debian only. Detected: $OS_ID"
  exit 1
fi

echo "[2/6] Installing Node.js if needed..."
if ! command -v node >/dev/null 2>&1; then
  sudo apt-get update
  sudo apt-get install -y ca-certificates curl gnupg
  sudo mkdir -p /etc/apt/keyrings
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | sudo gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
  NODE_MAJOR=20
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | sudo tee /etc/apt/sources.list.d/nodesource.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y nodejs
fi

echo "[3/6] Installing npm dependencies..."
cd "$APP_DIR"
if [[ -f package-lock.json ]]; then
  npm ci
else
  npm install
fi

echo "[4/6] Preparing environment file..."
if [[ ! -f "$APP_DIR/.env" ]]; then
  cp "$APP_DIR/.env.example" "$APP_DIR/.env"
  echo "Created $APP_DIR/.env from template. Please update BASE_URL to your public HTTPS domain if needed."
fi

echo "[5/6] Installing systemd service..."
sed \
  -e "s|__APP_DIR__|$APP_DIR|g" \
  -e "s|__APP_USER__|$APP_USER|g" \
  "$SERVICE_TEMPLATE" > "$TMP_SERVICE"

sudo cp "$TMP_SERVICE" "$SERVICE_TARGET"
sudo systemctl daemon-reload
sudo systemctl enable "$APP_NAME"
sudo systemctl restart "$APP_NAME"

echo "[6/6] Done. Service status:"
sudo systemctl --no-pager --full status "$APP_NAME" || true

echo
echo "Next steps:"
echo "1. Edit $APP_DIR/.env and set BASE_URL to your public domain or VPS URL."
echo "2. (Optional) Configure nginx using deploy/nginx.conf.example"
echo "3. Restart service after changes: sudo systemctl restart $APP_NAME"