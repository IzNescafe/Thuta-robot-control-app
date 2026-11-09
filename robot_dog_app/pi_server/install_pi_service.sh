#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 1 ]]; then
  echo "Usage: bash install_pi_service.sh /absolute/path/to/Thuta-Code-Updated"
  exit 2
fi

AI_DIR="$(realpath "$1")"
BRIDGE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SERVICE_USER="$(id -un)"
VENV_DIR="$BRIDGE_DIR/.venv"

if [[ ! -f "$AI_DIR/core_brain/inferencing.py" ]]; then
  echo "Missing $AI_DIR/core_brain/inferencing.py"
  exit 3
fi

python3 -m venv "$VENV_DIR"
"$VENV_DIR/bin/python" -m pip install --upgrade pip
"$VENV_DIR/bin/python" -m pip install -r "$BRIDGE_DIR/requirements.txt"

SERVICE_FILE="$(mktemp)"
trap 'rm -f "$SERVICE_FILE"' EXIT

sed \
  -e "s|__USER__|$SERVICE_USER|g" \
  -e "s|__AI_DIR__|$AI_DIR|g" \
  -e "s|__BRIDGE_DIR__|$BRIDGE_DIR|g" \
  "$BRIDGE_DIR/thuta-ai.service.template" > "$SERVICE_FILE"

sudo install -m 0644 "$SERVICE_FILE" /etc/systemd/system/thuta-ai.service
sudo systemctl daemon-reload
sudo systemctl enable --now thuta-ai.service

echo
echo "Thuta AI service installed."
echo "Status: sudo systemctl status thuta-ai.service"
echo "Logs:   journalctl -u thuta-ai.service -f"
echo "Health: curl http://127.0.0.1:8000/health"
