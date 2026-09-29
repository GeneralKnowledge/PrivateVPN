#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

info() { echo -e "${GREEN}==>${NC} $*"; }
warn() { echo -e "${YELLOW}==>${NC} $*"; }
err()  { echo -e "${RED}==>${NC} $*" >&2; }

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    err "Missing required command: $1"
    exit 1
  fi
}

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

# shellcheck disable=SC1091
source .env

if [[ -z "${SERVERURL:-}" || "${SERVERURL}" == "your.vps.ip.or.domain" ]]; then
  err "Set SERVERURL in .env to your VPS public IP or hostname."
  exit 1
fi

mkdir -p config

info "Starting WireGuard (PrivateVPN)"
docker compose up -d

info "Waiting for peer config..."
peer_conf=""
for _ in $(seq 1 30); do
  peer_conf="$(find config -type f -name 'peer*.conf' 2>/dev/null | sort | head -n 1 || true)"
  if [[ -n "${peer_conf}" ]]; then
    break
  fi
  sleep 1
done

echo
info "PrivateVPN is running on ${SERVERURL}:${SERVERPORT:-51820}/udp"
echo

if [[ -n "${peer_conf}" ]]; then
  info "Client config: ${peer_conf}"
  echo
  cat "${peer_conf}"
  echo
  qr_png="$(dirname "${peer_conf}")/peer1.png"
  if [[ -f "${qr_png}" ]]; then
    info "QR code image: ${qr_png}"
  fi
  info "Show QR in terminal: ./scripts/show-qr.sh"
  info "Status: ./scripts/status.sh"
else
  warn "Peer config not ready yet. Run: ./scripts/status.sh"
fi

echo
warn "Open UDP port ${SERVERPORT:-51820} on your VPS firewall / cloud security group."
