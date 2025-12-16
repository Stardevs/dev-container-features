
# Whitelist Firewall (firewall)

Configures a whitelist-based firewall using iptables and ipset. Only allows outbound traffic to specified domains/IPs.

## Example Usage

```json
"features": {
    "ghcr.io/Stardevs/dev-container-features/firewall:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| allowedDomains | Comma-separated list of domains to allow (e.g., 'api.github.com,registry.npmjs.org') | string | - |
| allowGitHub | Allow all GitHub IP ranges (fetched from api.github.com/meta) | boolean | true |
| allowNpm | Allow registry.npmjs.org | boolean | true |
| allowPypi | Allow pypi.org and files.pythonhosted.org | boolean | false |
| allowDocker | Allow Docker Hub and related registries | boolean | false |
| allowGoogle | Allow Google Cloud APIs | boolean | false |
| allowAws | Allow AWS APIs | boolean | false |
| enableOnStart | Automatically enable firewall on container start (requires postStartCommand) | boolean | false |
| blockVerificationDomain | Domain to verify firewall is blocking (should fail to connect) | string | example.com |

# Whitelist Firewall

This feature configures a whitelist-based firewall using iptables and ipset. Only allows outbound traffic to specified domains/IPs.

## Usage

```json
{
    "features": {
        "ghcr.io/Stardevs/dev-container-features/firewall:1": {}
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| allowedDomains | string | "" | Comma-separated list of allowed domains |
| allowGitHub | boolean | true | Allow all GitHub IP ranges |
| allowNpm | boolean | true | Allow registry.npmjs.org |
| allowPypi | boolean | false | Allow pypi.org |
| allowDocker | boolean | false | Allow Docker Hub registries |
| allowGoogle | boolean | false | Allow Google Cloud APIs |
| allowAws | boolean | false | Allow AWS APIs |
| enableOnStart | boolean | false | Auto-enable on container start |
| blockVerificationDomain | string | example.com | Domain to verify blocking |

## Examples

### Basic development setup

```json
{
    "features": {
        "ghcr.io/Stardevs/dev-container-features/firewall:1": {
            "allowGitHub": true,
            "allowNpm": true
        }
    }
}
```

### Python development

```json
{
    "features": {
        "ghcr.io/Stardevs/dev-container-features/firewall:1": {
            "allowGitHub": true,
            "allowPypi": true,
            "allowedDomains": "api.anthropic.com"
        }
    }
}
```

### Full cloud development

```json
{
    "features": {
        "ghcr.io/Stardevs/dev-container-features/firewall:1": {
            "allowGitHub": true,
            "allowNpm": true,
            "allowDocker": true,
            "allowGoogle": true,
            "allowAws": true
        }
    }
}
```

### Auto-enable on start

```json
{
    "features": {
        "ghcr.io/Stardevs/dev-container-features/firewall:1": {
            "enableOnStart": true
        }
    },
    "postStartCommand": "sudo firewall start"
}
```

## Container Requirements

The firewall requires elevated privileges:

```json
{
    "privileged": true,
    "capAdd": ["NET_ADMIN"]
}
```

## Commands

### Enable Firewall

```bash
sudo firewall start
```

### Disable Firewall

```bash
sudo firewall stop
```

### Check Status

```bash
sudo firewall status
```

## Configuration

The firewall configuration is stored in `/etc/firewall.conf`:

```bash
# View configuration
cat /etc/firewall.conf

# Edit configuration
sudo nano /etc/firewall.conf

# Apply changes
sudo firewall start
```

## How It Works

1. **Preserves Docker DNS** - Saves and restores Docker's internal DNS rules
2. **Allows essential traffic** - DNS (port 53), SSH (port 22), localhost
3. **Creates IP whitelist** - Uses ipset for efficient IP matching
4. **Fetches GitHub IPs** - Dynamically fetches GitHub IP ranges from api.github.com/meta
5. **Resolves domains** - DNS lookups for specified domains
6. **Sets DROP policy** - Default deny for all non-whitelisted traffic
7. **Verifies configuration** - Tests that blocked domains are unreachable

## Adding Custom Domains

### At build time

```json
{
    "features": {
        "ghcr.io/Stardevs/dev-container-features/firewall:1": {
            "allowedDomains": "api.example.com,cdn.example.com"
        }
    }
}
```

### At runtime

Edit `/etc/firewall.conf`:

```bash
FIREWALL_ALLOWED_DOMAINS="api.example.com,cdn.example.com,new-domain.com"
```

Then restart:

```bash
sudo firewall start
```

## Troubleshooting

### Check if firewall is active

```bash
sudo iptables -L -n
```

### View allowed IPs

```bash
sudo ipset list allowed-domains
```

### Test connectivity

```bash
# Should fail (blocked)
curl https://example.com

# Should work (if GitHub is allowed)
curl https://api.github.com/zen
```

### Temporarily disable

```bash
sudo firewall stop
```

## Security Notes

- The firewall uses a whitelist approach - only explicitly allowed destinations are reachable
- DNS is always allowed (required for domain resolution)
- The host network is allowed for container-host communication
- GitHub IPs are fetched dynamically and may change over time
- Consider the security implications of each allowed domain


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/Stardevs/dev-container-features/blob/main/src/firewall/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
