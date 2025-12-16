
# WireGuard (wireguard)

Installs WireGuard VPN tools including wg, wg-quick, and optional wireguard-go for userspace implementation.

## Example Usage

```json
"features": {
    "ghcr.io/Stardevs/dev-container-features/wireguard:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| installTools | Install WireGuard tools (wg, wg-quick) | boolean | true |
| installWireguardGo | Install wireguard-go userspace implementation | boolean | false |
| installBoringtun | Install boringtun (Cloudflare's userspace WireGuard implementation) | boolean | false |
| boringtunVersion | boringtun version (only used if installBoringtun is true) | string | latest |

# WireGuard

This feature installs WireGuard VPN tools for secure network tunneling.

## Usage

```json
{
    "features": {
        "ghcr.io/Stardevs/dev-container-features/wireguard:1": {}
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| installTools | boolean | true | Install wg and wg-quick |
| installWireguardGo | boolean | false | Install wireguard-go userspace implementation |
| installBoringtun | boolean | false | Install boringtun (Cloudflare userspace WireGuard) |
| boringtunVersion | string | latest | boringtun version |

## Examples

### With boringtun for userspace WireGuard

```json
{
    "features": {
        "ghcr.io/Stardevs/dev-container-features/wireguard:1": {
            "installBoringtun": true
        }
    }
}
```

## Container Requirements

WireGuard requires elevated privileges. Add to your devcontainer.json:

```json
{
    "privileged": true,
    "capAdd": ["NET_ADMIN", "SYS_MODULE"]
}
```

## Basic Usage

### Generate Keys

```bash
# Generate private key
wg genkey > privatekey

# Generate public key from private key
wg pubkey < privatekey > publickey

# Generate both at once
wg genkey | tee privatekey | wg pubkey > publickey
```

### Configure Interface

```bash
# Create configuration file
cat > /etc/wireguard/wg0.conf << EOF
[Interface]
PrivateKey = <your-private-key>
Address = 10.0.0.1/24
ListenPort = 51820

[Peer]
PublicKey = <peer-public-key>
AllowedIPs = 10.0.0.2/32
Endpoint = peer.example.com:51820
EOF

# Start interface
wg-quick up wg0

# Check status
wg show

# Stop interface
wg-quick down wg0
```

### Using boringtun (Userspace)

If kernel module is not available:

```bash
# Set environment variable to use boringtun
export WG_QUICK_USERSPACE_IMPLEMENTATION=boringtun

# Then use wg-quick as normal
wg-quick up wg0
```

## Troubleshooting

```bash
# Check if WireGuard module is loaded
lsmod | grep wireguard

# Load WireGuard module
modprobe wireguard

# Check interface status
ip link show wg0

# Debug connection
wg show wg0
```

## Security Notes

- Keep private keys secure and never share them
- Use strong, randomly generated keys
- Regularly rotate keys for production use


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/Stardevs/dev-container-features/blob/main/src/wireguard/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
