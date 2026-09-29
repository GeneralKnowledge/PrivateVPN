#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"
cd "$ROOT_DIR"

detect_public_ip() {
  local ip=""
  for url in \
    "https://ifconfig.me" \
    "https://api.ipify.org" \
    "https://icanhazip.com"; do
    ip="$(curl -4 -fsS --max-time 5 "$url" 2>/dev/null | tr -d '[:space:]' || true)"
    if [[ -n "$ip" ]]; then
      echo "$ip"
      return 0
    fi
  done
  return 1
}

require_cmd docker
require_cmd curl

if ! docker compose version >/dev/null 2>&1; then
  err "Docker Compose plugin is required (docker compose)."
  exit 1
fi

if [[ ! -f .env ]]; then
  info "Creating .env from .env.example"
  cp .env.example .env

  detected_ip="$(detect_public_ip || true)"
  if [[ -n "${detected_ip}" ]]; then
    info "Detected public IP: ${detected_ip}"
    sed -i "s|^SERVERURL=.*|SERVERURL=${detected_ip}|" .env
  else
    warn "Could not detect public IP. Edit SERVERURL in .env before starting."
  fi
else
  info "Using existing .env"
fi

SERVERURL="$(env_get SERVERURL || true)"
SERVERPORT="$(env_get SERVERPORT || true)"
SERVERPORT="${SERVERPORT:-51820}"

if [[ -z "${SERVERURL}" || "${SERVERURL}" == "your.vps.ip.or.domain" ]]; then
  err "Set SERVERURL in .env to your VPS public IP or hostname."
  exit 1
fi

mkdir -p config
chmod 700 config

info "Starting WireGuard (PrivateVPN)"
docker compose up -d

info "Waiting for peer config..."
peer_conf=""
for _ in $(seq 1 45); do
  peer_conf="$(list_peer_confs | head -n 1 || true)"
  if [[ -n "${peer_conf}" ]]; then
    break
  fi
  sleep 1
done

echo
info "PrivateVPN is running on ${SERVERURL}:${SERVERPORT}/udp"
echo

if [[ -n "${peer_conf}" ]]; then
  info "Client configs:"
  list_peer_confs | while read -r conf; do
    echo "  - ${conf}"
  done
  echo
  info "First peer config (${peer_conf}):"
  echo
  cat "${peer_conf}"
  echo
  info "Show QR: ./scripts/show-qr.sh phone"
  info "Status:  ./scripts/status.sh"
  info "Firewall: ./scripts/open-firewall.sh"
else
  warn "Peer config not ready yet. Check logs: docker compose logs -f wireguard"
fi

echo
warn "Open UDP port ${SERVERPORT} on your VPS firewall / cloud security group."
