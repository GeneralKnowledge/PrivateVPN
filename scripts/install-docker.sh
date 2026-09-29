#!/usr/bin/env bash
set -euo pipefail

# Install Docker Engine + Compose plugin on Debian/Ubuntu VPS hosts.
# Safe to re-run: exits early if docker is already present.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=common.sh
source "${SCRIPT_DIR}/common.sh"

if command -v docker >/dev/null 2>&1 && docker compose version >/dev/null 2>&1; then
  info "Docker and Compose already installed: $(docker --version)"
  exit 0
fi

if [[ "$(id -u)" -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then
    info "Re-running with sudo..."
    exec sudo -E bash "$0" "$@"
  fi
  err "Run as root (or with sudo)."
  exit 1
fi

. /etc/os-release
case "${ID:-}" in
  ubuntu|debian) ;;
  *)
    err "Unsupported distro '${ID:-unknown}'. Install Docker manually: https://docs.docker.com/engine/install/"
    exit 1
    ;;
esac

info "Installing Docker Engine + Compose plugin"
apt-get update -y
apt-get install -y ca-certificates curl
install -m 0755 -d /etc/apt/keyrings
curl -fsSL "https://download.docker.com/linux/${ID}/gpg" -o /etc/apt/keyrings/docker.asc
chmod a+r /etc/apt/keyrings/docker.asc

arch="$(dpkg --print-architecture)"
echo \
  "deb [arch=${arch} signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" \
  > /etc/apt/sources.list.d/docker.list

apt-get update -y
apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
systemctl enable --now docker

# Allow invoking user to use docker without sudo (best-effort)
if [[ -n "${SUDO_USER:-}" && "${SUDO_USER}" != "root" ]]; then
  usermod -aG docker "${SUDO_USER}" || true
  warn "Added ${SUDO_USER} to the docker group. Log out/in (or run: newgrp docker) before ./scripts/setup.sh"
fi

info "Docker installed: $(docker --version)"
info "Next: ./scripts/setup.sh"
