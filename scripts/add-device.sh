#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"
cd "$ROOT_DIR"

# Add another named device. Usage: ./scripts/add-device.sh [name]
# Example: ./scripts/add-device.sh tablet

if [[ ! -f .env ]]; then
  err "No .env found. Run ./scripts/setup.sh first."
  exit 1
fi

NAME="${1:-}"
if [[ -z "$NAME" ]]; then
  existing="$(env_get PEERS || echo "phone,laptop")"
  n="$(echo "$existing" | tr ',' '\n' | grep -c . || true)"
  NAME="device$((n + 1))"
fi

if ! [[ "$NAME" =~ ^[a-zA-Z][a-zA-Z0-9_-]*$ ]]; then
  err "Peer name must start with a letter and use only letters, numbers, _ or -"
  exit 1
fi

current="$(env_get PEERS || echo "")"
if [[ -z "$current" ]]; then
  current="phone,laptop"
fi

# Already present?
if echo ",${current}," | grep -q ",${NAME},"; then
  err "Peer '${NAME}' already exists in PEERS=${current}"
  exit 1
fi

next="${current},${NAME}"
sed -i "s|^PEERS=.*|PEERS=${next}|" .env
info "PEERS: ${current} -> ${next}"

docker compose up -d --force-recreate

info "Waiting for ${NAME} config..."
for _ in $(seq 1 45); do
  conf="$(find_peer_conf "${NAME}" || true)"
  if [[ -n "$conf" && -f "$conf" ]]; then
    echo
    info "New client config: ${conf}"
    echo
    cat "${conf}"
    echo
    info "Show QR: ./scripts/show-qr.sh ${NAME}"
    exit 0
  fi
  sleep 1
done

warn "Config not ready yet. Check: ./scripts/status.sh"
warn "Logs: docker compose logs --tail=50 wireguard"
exit 1
