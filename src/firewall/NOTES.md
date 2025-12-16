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
| remoteUser | string | "" | Non-root user for scoped sudo (e.g., 'node', 'vscode') |
| fixWorkspacePermissions | boolean | false | Fix workspace ownership on start |
| workspacePath | string | /workspace | Path to workspace directory |

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
    "postStartCommand": "sudo firewall entrypoint"
}
```

### Auto-enable with scoped sudo (recommended)

```json
{
    "features": {
        "ghcr.io/Stardevs/dev-container-features/firewall:1": {
            "allowGitHub": true,
            "allowNpm": true,
            "allowedDomains": "api.anthropic.com,sentry.io",
            "enableOnStart": true,
            "remoteUser": "node",
            "fixWorkspacePermissions": true
        }
    },
    "remoteUser": "node",
    "postStartCommand": "sudo /usr/local/bin/firewall-entrypoint.sh"
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

### Run Entrypoint (firewall + permission fixes)

```bash
sudo firewall entrypoint
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

## Scoped Sudo

When `remoteUser` is specified, the feature creates a sudoers configuration that only allows running specific firewall scripts. This follows the principle of least privilege.

### What's allowed

The specified user can run:
- `/usr/local/bin/firewall-entrypoint.sh`
- `/usr/local/bin/init-firewall.sh`
- `/usr/local/bin/disable-firewall.sh`
- `/sbin/iptables` and `/usr/sbin/iptables`
- `/sbin/iptables-save` and `/usr/sbin/iptables-save`
- `/sbin/ipset` and `/usr/sbin/ipset`

### What's NOT allowed

- Full sudo access
- Running arbitrary commands as root
- Modifying system files outside of firewall scope

### Configuration file location

```
/etc/sudoers.d/firewall-feature
```

## Security Notes

- The firewall uses a whitelist approach - only explicitly allowed destinations are reachable
- DNS is always allowed (required for domain resolution)
- The host network is allowed for container-host communication
- GitHub IPs are fetched dynamically and may change over time
- Consider the security implications of each allowed domain
- When using scoped sudo, the user only has access to firewall-related commands
