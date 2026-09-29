#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"
cd "$ROOT_DIR"

# Print expected egress IP (the VPS) so you can compare after connecting a client.

SERVERURL="$(env_get SERVERURL 2>/dev/null || true)"
if [[ -z "${SERVERURL}" || "${SERVERURL}" == "your.vps.ip.or.domain" ]]; then
  err "SERVERURL is not set in .env"
  exit 1
fi

info "VPN server (SERVERURL): ${SERVERURL}"

resolved=""
if command -v getent >/dev/null 2>&1; then
  resolved="$(getent ahostsv4 "${SERVERURL}" 2>/dev/null | awk '{print $1; exit}' || true)"
fi
if [[ -n "${resolved}" ]]; then
  info "Resolves to: ${resolved}"
fi

echo
echo "On a connected client, your public IP should match the VPS:"
echo "  curl -4 https://ifconfig.me && echo"
echo "  curl -6 https://ifconfig.me && echo   # if IPv6 is enabled"
echo
if container_running; then
  echo "Server peer status:"
  docker compose exec -T wireguard wg show || true
else
  warn "Container is not running. Start with ./scripts/setup.sh"
fi
