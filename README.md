# PrivateVPN

A single-user WireGuard VPN you can host on any VPS. One command brings up the server and prints a client config (plus a QR code for phones).

## Requirements

- A VPS with a public IP (Ubuntu 22.04/24.04 works well)
- Docker with Compose plugin
- UDP port `51820` open in the VPS firewall / cloud security group

## Quick start

```bash
git clone <your-repo-url> PrivateVPN
cd PrivateVPN
chmod +x scripts/*.sh
./scripts/setup.sh
```

`setup.sh` will:

1. Create `.env` (auto-fills your public IP when possible)
2. Start WireGuard in Docker
3. Print your client config

Then connect:

- **Phone:** `./scripts/show-qr.sh` and scan with the [WireGuard](https://www.wireguard.com/install/) app
- **Desktop:** import `config/peer1/peer1.conf` into the WireGuard app

## Configuration

Edit `.env` (from `.env.example`):

| Variable | Meaning | Default |
|----------|---------|---------|
| `SERVERURL` | VPS public IP or DNS name | *(required)* |
| `SERVERPORT` | UDP listen port | `51820` |
| `PEERS` | Number of client devices | `1` |
| `PEERDNS` | DNS for clients | `1.1.1.1` |
| `ALLOWEDIPS` | Routes through VPN (`0.0.0.0/0` = all traffic) | `0.0.0.0/0` |

After changing env vars that affect peer configs, recreate:

```bash
docker compose up -d --force-recreate
```

## Useful commands

```bash
./scripts/status.sh       # container + handshake status
./scripts/show-qr.sh      # QR for peer1 (phone)
./scripts/show-qr.sh 2    # QR for peer2
./scripts/add-device.sh   # add another device (peer2, peer3, ...)
./scripts/stop.sh         # stop the VPN
```

## Firewall

Allow WireGuard UDP on the VPS:

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

- Keep `config/` private — it contains private keys (already gitignored)
- Do not commit `.env` or any `*.conf` files
- Rotate by deleting `config/` and running `./scripts/setup.sh` again (clients must re-import)
- This is intentionally single-user / few-device; not a multi-tenant VPN product

## Optional: split tunnel

To only send some traffic through the VPN, set in `.env`:

```bash
# Example: only tunnel traffic to a private LAN / specific ranges
ALLOWEDIPS=10.0.0.0/8,192.168.0.0/16
```

Then recreate the container and re-import the client config.

## Uninstall

```bash
./scripts/stop.sh
docker compose rm -f
rm -rf config .env
```
