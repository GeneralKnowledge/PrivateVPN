#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"
cd "$ROOT_DIR"

PORT="$(env_get SERVERPORT 2>/dev/null || true)"
PORT="${PORT:-51820}"

if command -v ufw >/dev/null 2>&1; then
  info "Opening UDP ${PORT} with ufw"
  sudo ufw allow "${PORT}/udp"
  sudo ufw reload
  info "Done. Also open ${PORT}/udp in your cloud security group if you have one."
  exit 0
fi

if command -v firewall-cmd >/dev/null 2>&1; then
  info "Opening UDP ${PORT} with firewalld"
  sudo firewall-cmd --permanent --add-port="${PORT}/udp"
  sudo firewall-cmd --reload
  info "Done. Also open ${PORT}/udp in your cloud security group if you have one."
  exit 0
fi

warn "No ufw or firewalld found."
warn "Open UDP port ${PORT} manually in your VPS firewall / cloud security group."
exit 1
