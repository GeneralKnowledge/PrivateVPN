#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"
cd "$ROOT_DIR"

PEER="${1:-phone}"

conf="$(find_peer_conf "${PEER}" || true)"
if [[ -z "${conf}" || ! -f "${conf}" ]]; then
  err "No config found for peer '${PEER}'."
  echo "Available:"
  list_peer_confs || echo "  (none — run ./scripts/setup.sh first)"
  exit 1
fi

png="$(dirname "${conf}")/$(basename "${conf}" .conf).png"

echo "Config: ${conf}"
echo

if command -v qrencode >/dev/null 2>&1; then
  qrencode -t ansiutf8 < "${conf}"
elif container_running; then
  docker compose exec -T wireguard \
    sh -c "qrencode -t ansiutf8 < /${conf}"
else
  warn "Install 'qrencode' for a terminal QR, or scan the PNG below."
fi

if [[ -f "${png}" ]]; then
  echo
  echo "QR image: ${png}"
fi

echo
echo "Import ${conf} in the WireGuard desktop app, or scan the QR on mobile."
