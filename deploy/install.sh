#!/usr/bin/env bash

set -euo pipefail

APP_NAME="mock-opensearch"
APP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SERVICE_TEMPLATE="$APP_DIR/deploy/mock-opensearch.service"
SERVICE_TARGET="/etc/systemd/system/${APP_NAME}.service"
TMP_SERVICE="/tmp/${APP_NAME}.service"
APP_USER="${SUDO_USER:-$(whoami)}"
NODE_MAJOR="20"

SUDO=""
if command -v sudo >/dev/null 2>&1; then
  SUDO="sudo"
fi

echo "[1/6] Checking OS..."
if [[ -f /etc/os-release ]]; then
  . /etc/os-release
  OS_ID="${ID:-unknown}"
else
  echo "Unsupported OS: /etc/os-release not found"
  exit 1
fi

install_node_debian() {
  $SUDO apt-get update
  $SUDO apt-get install -y ca-certificates curl gnupg
  $SUDO mkdir -p /etc/apt/keyrings
  curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | $SUDO gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg
  echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_$NODE_MAJOR.x nodistro main" | $SUDO tee /etc/apt/sources.list.d/nodesource.list >/dev/null
  $SUDO apt-get update
  $SUDO apt-get install -y nodejs
}

install_node_rhel() {
  if command -v dnf >/dev/null 2>&1; then
    $SUDO dnf install -y curl
    curl -fsSL "https://rpm.nodesource.com/setup_${NODE_MAJOR}.x" | $SUDO bash -
    $SUDO dnf install -y nodejs
  elif command -v yum >/dev/null 2>&1; then
    $SUDO yum install -y curl
    curl -fsSL "https://rpm.nodesource.com/setup_${NODE_MAJOR}.x" | $SUDO bash -
    $SUDO yum install -y nodejs
  else
    echo "Neither dnf nor yum is available. Cannot install Node.js automatically."
    exit 1
  fi
}

echo "Detected OS: $OS_ID"

echo "[2/6] Installing Node.js if needed..."
if ! command -v node >/dev/null 2>&1; then
  case "$OS_ID" in
    ubuntu|debian)
      install_node_debian
      ;;
    alinux|amzn|centos|rhel|rocky|almalinux|fedora)
      install_node_rhel
      ;;
    *)
      echo "Unsupported OS for automatic Node.js installation: $OS_ID"
      echo "Please install Node.js ${NODE_MAJOR}+ manually, then rerun this script."
      exit 1
      ;;
  esac
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

$SUDO cp "$TMP_SERVICE" "$SERVICE_TARGET"
$SUDO systemctl daemon-reload
$SUDO systemctl enable "$APP_NAME"
$SUDO systemctl restart "$APP_NAME"

echo "[6/6] Done. Service status:"
$SUDO systemctl --no-pager --full status "$APP_NAME" || true

echo
echo "Next steps:"
echo "1. Edit $APP_DIR/.env and set BASE_URL to your public domain or VPS URL."
echo "2. (Optional) Configure nginx using deploy/nginx.conf.example"
echo "3. Restart service after changes: ${SUDO:+sudo }systemctl restart $APP_NAME"