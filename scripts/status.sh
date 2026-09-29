#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if ! docker compose ps --status running --services 2>/dev/null | grep -qx wireguard; then
  echo "WireGuard is not running. Start it with: ./scripts/setup.sh"
  exit 1
fi

echo "=== Container ==="
docker compose ps
echo
echo "=== Handshake / peers ==="
docker compose exec -T wireguard wg show || true
echo
echo "=== Client configs ==="
find config -type f \( -name 'peer*.conf' -o -name '*.png' \) 2>/dev/null | sort || echo "(none yet)"
