#!/usr/bin/env bash
set -euo pipefail

# Add another device (peer) for the same user by bumping PEERS and recreating.
# Existing peer configs/keys are preserved by the linuxserver image.

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ ! -f .env ]]; then
  echo "No .env found. Run ./scripts/setup.sh first."
  exit 1
fi

# shellcheck disable=SC1091
source .env

current="${PEERS:-1}"
if ! [[ "$current" =~ ^[0-9]+$ ]]; then
  echo "PEERS in .env must be a number"
  exit 1
fi

next=$((current + 1))
sed -i "s|^PEERS=.*|PEERS=${next}|" .env
echo "PEERS: ${current} -> ${next}"

docker compose up -d

echo "Waiting for peer${next} config..."
for _ in $(seq 1 30); do
  conf="$(find config -type f -name "peer${next}.conf" 2>/dev/null | head -n 1 || true)"
  if [[ -n "$conf" ]]; then
    echo
    echo "New client config: ${conf}"
    cat "${conf}"
    echo
    echo "Show QR: ./scripts/show-qr.sh ${next}"
    exit 0
  fi
  sleep 1
done

echo "Config not ready yet. Check: ./scripts/status.sh"
