
# Cilium CLI (cilium-cli)

Installs Cilium CLI for managing Cilium CNI and Hubble observability.

## Example Usage

```json
"features": {
    "ghcr.io/Stardevs/dev-container-features/cilium-cli:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| ciliumVersion | Cilium CLI version to install | string | latest |
| installHubble | Install Hubble CLI for network observability | boolean | true |
| hubbleVersion | Hubble CLI version (only used if installHubble is true) | string | latest |

# Cilium CLI

This feature installs the Cilium CLI and optional Hubble CLI for network observability.

## Usage

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/cilium-cli:1": {}
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| ciliumVersion | string | latest | Cilium CLI version |
| installHubble | boolean | true | Install Hubble CLI |
| hubbleVersion | string | latest | Hubble CLI version |

## Examples

### Install without Hubble

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/cilium-cli:1": {
            "installHubble": false
        }
    }
}
```

### Specific versions

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/cilium-cli:1": {
            "ciliumVersion": "0.16.0",
            "hubbleVersion": "1.16.0"
        }
    }
}
```

## Cilium CLI Usage

```bash
# Check Cilium status
cilium status

# Install Cilium
cilium install

# Upgrade Cilium
cilium upgrade

# Uninstall Cilium
cilium uninstall

# Run connectivity test
cilium connectivity test

# View Cilium configuration
cilium config view
```

## Hubble CLI Usage

Hubble provides network observability for Cilium:

```bash
# Enable Hubble
cilium hubble enable

# Port forward to Hubble Relay
cilium hubble port-forward &

# Observe network flows
hubble observe

# Filter by namespace
hubble observe --namespace default

# Filter by pod
hubble observe --pod my-pod

# Filter by verdict
hubble observe --verdict DROPPED

# Watch flows in real-time
hubble observe --follow

# Get flow summary
hubble observe --summary
```

## Connectivity Testing

```bash
# Run full connectivity test
cilium connectivity test

# Run specific tests
cilium connectivity test --test pod-to-pod

# Include external tests
cilium connectivity test --include-unsafe-tests
```

## Troubleshooting

```bash
# View Cilium agent logs
cilium sysdump

# Check network policies
cilium policy get

# Debug endpoint
cilium endpoint list

# View BPF maps
cilium bpf
```

## Environment Variables

- `CILIUM_NAMESPACE` - Namespace where Cilium is installed (default: kube-system)


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/Stardevs/dev-container-features/blob/main/src/cilium-cli/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
