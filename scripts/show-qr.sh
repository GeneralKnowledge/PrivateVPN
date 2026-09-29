#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

PEER="${1:-1}"

find_conf() {
  local peer="$1"
  if [[ -f "config/peer${peer}/peer${peer}.conf" ]]; then
    echo "config/peer${peer}/peer${peer}.conf"
    return 0
  fi
  find config -type f -name "peer${peer}.conf" 2>/dev/null | head -n 1
}

conf="$(find_conf "${PEER}" || true)"
if [[ -z "${conf}" || ! -f "${conf}" ]]; then
  echo "No peer${PEER}.conf found. Start the VPN first: ./scripts/setup.sh"
  exit 1
fi

png="$(dirname "${conf}")/peer${PEER}.png"

echo "Config: ${conf}"
echo

if command -v qrencode >/dev/null 2>&1; then
  qrencode -t ansiutf8 < "${conf}"
elif docker compose ps --status running --services 2>/dev/null | grep -qx wireguard; then
  # linuxserver image ships qrencode; config is mounted at /config
  docker compose exec -T wireguard \
    sh -c "qrencode -t ansiutf8 < /config/peer${PEER}/peer${PEER}.conf"
else
  echo "(Install 'qrencode' for a terminal QR, or scan the PNG below.)"
fi

if [[ -f "${png}" ]]; then
  echo
  echo "QR image: ${png}"
fi

echo
echo "Import ${conf} in the WireGuard desktop app, or scan the QR on mobile."
