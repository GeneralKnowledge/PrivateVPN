#!/usr/bin/env bash
# Shared helpers for PrivateVPN scripts.
# shellcheck shell=bash

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

info() { echo -e "\033[0;32m==>\033[0m $*"; }
warn() { echo -e "\033[1;33m==>\033[0m $*"; }
err()  { echo -e "\033[0;31m==>\033[0m $*" >&2; }

require_cmd() {
  if ! command -v "$1" >/dev/null 2>&1; then
    err "Missing required command: $1"
    exit 1
  fi
}

env_get() {
  local key="$1"
  local file="${2:-$ROOT_DIR/.env}"
  [[ -f "$file" ]] || return 1
  local line
  line="$(grep -E "^${key}=" "$file" | tail -n 1 || true)"
  [[ -n "$line" ]] || return 1
  printf '%s\n' "${line#*=}"
}

# Resolve a peer name to its .conf path (numbered or named peers).
find_peer_conf() {
  local peer="$1"
  local candidates=(
    "config/peer_${peer}/peer_${peer}.conf"
    "config/${peer}/${peer}.conf"
    "config/peer${peer}/peer${peer}.conf"
  )
  local path
  for path in "${candidates[@]}"; do
    if [[ -f "$ROOT_DIR/$path" ]]; then
      echo "$path"
      return 0
    fi
  done
  # Fallback: any matching conf under config/
  find "$ROOT_DIR/config" -type f \( -name "peer_${peer}.conf" -o -name "${peer}.conf" -o -name "peer${peer}.conf" \) 2>/dev/null | head -n 1 | sed "s|^$ROOT_DIR/||"
}

list_peer_confs() {
  find "$ROOT_DIR/config" -type f -name '*.conf' ! -path '*/wg_confs/*' ! -name 'wg0.conf' 2>/dev/null | sort | sed "s|^$ROOT_DIR/||"
}

container_running() {
  docker compose -f "$ROOT_DIR/docker-compose.yml" --project-directory "$ROOT_DIR" \
    ps --status running --services 2>/dev/null | grep -qx wireguard
}
