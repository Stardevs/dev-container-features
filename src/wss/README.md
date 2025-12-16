
# WebSocket and Tunneling Tools (wss)

Installs WebSocket tools (wscat, websocat), wstunnel, Cloudflare Tunnel (cloudflared), and Cloudflare Wrangler CLI.

## Example Usage

```json
"features": {
    "ghcr.io/Stardevs/dev-container-features/wss:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| installWscat | Install wscat (WebSocket CLI client via npm) | boolean | true |
| installWebsocat | Install websocat (WebSocket CLI client, Rust-based) | boolean | true |
| websocatVersion | websocat version | string | latest |
| installWstunnel | Install wstunnel for tunneling over WebSocket | boolean | true |
| wstunnelVersion | wstunnel version | string | latest |
| installCloudflared | Install Cloudflare Tunnel daemon (cloudflared) | boolean | true |
| cloudflaredVersion | cloudflared version | string | latest |
| installWrangler | Install Cloudflare Wrangler CLI for Workers development | boolean | true |

## Customizations

### VS Code Extensions

- `nicecrab.crab-wrangler`

# WebSocket and Tunneling Tools

This feature installs WebSocket testing tools, tunneling utilities, and Cloudflare tools.

## Usage

```json
{
    "features": {
        "ghcr.io/Stardevs/dev-container-features/wss:1": {}
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| installWscat | boolean | true | Install wscat (npm-based WebSocket client) |
| installWebsocat | boolean | true | Install websocat (Rust-based WebSocket client) |
| websocatVersion | string | latest | websocat version |
| installWstunnel | boolean | true | Install wstunnel |
| wstunnelVersion | string | latest | wstunnel version |
| installCloudflared | boolean | true | Install Cloudflare Tunnel daemon |
| cloudflaredVersion | string | latest | cloudflared version |
| installWrangler | boolean | true | Install Cloudflare Wrangler CLI |

## Examples

### Only WebSocket tools

```json
{
    "features": {
        "ghcr.io/Stardevs/dev-container-features/wss:1": {
            "installCloudflared": false,
            "installWrangler": false
        }
    }
}
```

### Only Cloudflare tools

```json
{
    "features": {
        "ghcr.io/Stardevs/dev-container-features/wss:1": {
            "installWscat": false,
            "installWebsocat": false,
            "installWstunnel": false
        }
    }
}
```

## wscat Usage

wscat is a WebSocket client for testing WebSocket servers:

```bash
# Connect to a WebSocket server
wscat -c ws://localhost:8080

# Connect with headers
wscat -c ws://localhost:8080 -H "Authorization: Bearer token"

# Listen as server
wscat -l 8080
```

## websocat Usage

websocat is a powerful WebSocket client with many features:

```bash
# Connect to WebSocket
websocat ws://localhost:8080

# WebSocket to TCP proxy
websocat --binary ws-l:127.0.0.1:8080 tcp:127.0.0.1:22

# Connect with text mode
websocat -t ws://echo.websocket.org

# Pipe stdin/stdout
echo "hello" | websocat ws://echo.websocket.org
```

## wstunnel Usage

wstunnel tunnels TCP/UDP traffic over WebSocket:

```bash
# Server mode - listen on port 8080, forward to local services
wstunnel server ws://0.0.0.0:8080

# Client mode - connect to server and tunnel local port
wstunnel client -L tcp://localhost:2222:localhost:22 ws://server:8080

# UDP tunnel
wstunnel client -L udp://localhost:5353:8.8.8.8:53 ws://server:8080

# With TLS
wstunnel client -L tcp://localhost:2222:localhost:22 wss://server:443
```

## Cloudflare Tunnel (cloudflared) Usage

cloudflared creates secure tunnels to Cloudflare's network:

```bash
# Quick tunnel (no account needed)
cloudflared tunnel --url http://localhost:8080

# Login to Cloudflare
cloudflared tunnel login

# Create named tunnel
cloudflared tunnel create my-tunnel

# Run tunnel
cloudflared tunnel run my-tunnel

# Access a service through tunnel
cloudflared access tcp --hostname app.example.com --url localhost:2222
```

## Cloudflare Wrangler Usage

Wrangler is the CLI for Cloudflare Workers:

```bash
# Login to Cloudflare
wrangler login

# Create new Workers project
wrangler init my-worker

# Develop locally
wrangler dev

# Deploy to Cloudflare
wrangler deploy

# Tail logs
wrangler tail

# Manage KV namespaces
wrangler kv:namespace create MY_KV

# Manage R2 buckets
wrangler r2 bucket create my-bucket

# Manage D1 databases
wrangler d1 create my-database
```

## Common Use Cases

### Expose local development server

```bash
# Quick tunnel for development
cloudflared tunnel --url http://localhost:3000
```

### Test WebSocket endpoints

```bash
# Using wscat
wscat -c ws://localhost:8080/ws

# Using websocat with JSON
echo '{"type":"ping"}' | websocat ws://localhost:8080/ws
```

### Tunnel SSH over WebSocket

```bash
# Server (behind firewall)
wstunnel server wss://0.0.0.0:443

# Client
wstunnel client -L tcp://localhost:2222:localhost:22 wss://server.com:443
ssh -p 2222 localhost
```


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/Stardevs/dev-container-features/blob/main/src/wss/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
