
# Istio CLI (istioctl) (istio-cli)

Installs istioctl, the command-line tool for Istio service mesh management.

## Example Usage

```json
"features": {
    "ghcr.io/Stardevs/dev-container-features/istio-cli:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Istio version to install | string | latest |
| enableAutoCompletion | Enable bash/zsh auto-completion for istioctl | boolean | true |

# Istio CLI (istioctl)

This feature installs istioctl for Istio service mesh management.

## Usage

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/istio-cli:1": {}
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| version | string | latest | Istio version |
| enableAutoCompletion | boolean | true | Enable shell completions |

## Examples

### Install specific version

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/istio-cli:1": {
            "version": "1.23.0"
        }
    }
}
```

## Basic Usage

```bash
# Check version
istioctl version

# Install Istio to cluster
istioctl install --set profile=demo

# Verify installation
istioctl verify-install

# Check proxy status
istioctl proxy-status

# Analyze configuration
istioctl analyze
```

## Debugging

```bash
# Get proxy configuration
istioctl proxy-config cluster <pod-name>

# Check routes
istioctl proxy-config routes <pod-name>

# View listeners
istioctl proxy-config listeners <pod-name>

# View endpoints
istioctl proxy-config endpoints <pod-name>

# Debug sidecar
istioctl x describe pod <pod-name>
```

## Traffic Management

```bash
# Inject sidecar automatically
kubectl label namespace default istio-injection=enabled

# Manual sidecar injection
istioctl kube-inject -f deployment.yaml | kubectl apply -f -

# Verify sidecar injection
istioctl x check-inject <pod-name>
```

## Profiles

Istio installation profiles:

- **default** - Production configuration
- **demo** - Demonstration with all features
- **minimal** - Minimal footprint
- **remote** - Remote cluster configuration
- **empty** - Empty profile for customization

```bash
# List profiles
istioctl profile list

# Show profile configuration
istioctl profile dump demo

# Diff profiles
istioctl profile diff default demo
```

## Validation

```bash
# Analyze namespace
istioctl analyze --namespace default

# Analyze all namespaces
istioctl analyze --all-namespaces

# Analyze specific file
istioctl analyze my-config.yaml
```


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/Stardevs/dev-container-features/blob/main/src/istio-cli/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
