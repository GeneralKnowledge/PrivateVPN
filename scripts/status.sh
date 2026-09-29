#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"
cd "$ROOT_DIR"

if ! container_running; then
  err "WireGuard is not running. Start it with: ./scripts/setup.sh"
  exit 1
fi

echo "=== Container ==="
docker compose ps
echo
echo "=== Handshake / peers ==="
docker compose exec -T wireguard wg show || true
echo
echo "=== Client configs ==="
confs="$(list_peer_confs || true)"
if [[ -n "${confs}" ]]; then
  echo "${confs}"
else
  echo "(none yet)"
fi
