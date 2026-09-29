#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"
cd "$ROOT_DIR"

LINES="${1:-100}"

if [[ ! -f docker-compose.yml ]]; then
  err "Run from the PrivateVPN repo root."
  exit 1
fi

docker compose logs --tail="${LINES}" -f wireguard
