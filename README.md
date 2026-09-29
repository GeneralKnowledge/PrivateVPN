# PrivateVPN

A single-user WireGuard VPN you can host on any VPS. One command brings up the server and prints client configs (plus QR codes for phones).

## Requirements

- A VPS with a public IP and a normal Linux network stack (KVM/Xen). OpenVZ/LXC hosts often lack WireGuard kernel support.
- Ubuntu 22.04/24.04 (or Debian) recommended
- Docker with Compose plugin
- UDP port `51820` open in the VPS firewall / cloud security group

## Quick start

```bash
git clone <your-repo-url> PrivateVPN
cd PrivateVPN
chmod +x scripts/*.sh
./scripts/install-docker.sh  # skip if Docker is already installed
./scripts/setup.sh
./scripts/open-firewall.sh   # ufw / firewalld if present
```

`setup.sh` will:

1. Create `.env` (auto-fills your public IP when possible)
2. Start WireGuard in Docker
3. Print your first client config

Then connect:

- **Phone:** `./scripts/show-qr.sh phone` and scan with the [WireGuard](https://www.wireguard.com/install/) app
- **Laptop:** import the laptop conf (see `./scripts/status.sh` for paths), or copy it off the VPS:

```bash
scp user@YOUR_VPS:~/PrivateVPN/config/peer_laptop/peer_laptop.conf .
```

Confirm the tunnel with `./scripts/verify.sh`, then on the client: `curl -4 https://ifconfig.me` (should show the VPS IP).

## Configuration

Edit `.env` (from `.env.example`):

| Variable | Meaning | Default |
|----------|---------|---------|
| `SERVERURL` | VPS public IP or DNS name | *(required)* |
| `SERVERPORT` | UDP listen port | `51820` |
| `PEERS` | Comma-separated device names | `phone,laptop` |
| `PEERDNS` | DNS for clients | `1.1.1.1` |
| `ALLOWEDIPS` | Routes through VPN | `0.0.0.0/0,::/0` (full tunnel) |

After changing env vars that affect peer configs, recreate:

```bash
docker compose up -d --force-recreate
```

## Useful commands

```bash
./scripts/status.sh              # container + handshake status
./scripts/verify.sh              # expected egress IP + wg show
./scripts/show-qr.sh phone       # QR for phone
./scripts/show-qr.sh laptop      # QR for laptop
./scripts/add-device.sh tablet   # add another named device
./scripts/open-firewall.sh       # open UDP port (ufw/firewalld)
./scripts/logs.sh                # follow container logs
./scripts/restart.sh             # restart WireGuard
./scripts/stop.sh                # stop the VPN
```

## Firewall

Prefer `./scripts/open-firewall.sh`. Manually:

```bash
# ufw
sudo ufw allow 51820/udp
sudo ufw reload

# firewalld
sudo firewall-cmd --permanent --add-port=51820/udp
sudo firewall-cmd --reload
```

Also open `51820/udp` in your cloud provider security group (AWS, Hetzner, DigitalOcean, etc.).

## How it works

Traffic from your device → encrypted WireGuard tunnel → your VPS → internet.

Your public IP becomes the VPS IP while connected. Only devices with a generated peer config can connect.

## Security notes

- Keep `config/` private — it contains private keys (gitignored; setup sets mode `700`)
- Do not commit `.env` or any `*.conf` files
- The Docker image is pinned to a specific tag (not `:latest`) for reproducible deploys
- Rotate by deleting `config/` and running `./scripts/setup.sh` again (clients must re-import)
- This is intentionally single-user / few-device; not a multi-tenant VPN product

## Optional: split tunnel

To only send some traffic through the VPN, set in `.env`:

```bash
# Example: only tunnel traffic to a private LAN / specific ranges
ALLOWEDIPS=10.0.0.0/8,192.168.0.0/16
```

Then recreate the container and re-import the client configs.

## Uninstall

```bash
./scripts/stop.sh
docker compose rm -f
rm -rf config .env
```
