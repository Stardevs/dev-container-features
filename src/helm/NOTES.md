# Helm

This feature installs Helm with optional plugins and Helmfile.

## Usage

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/helm:1": {}
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| version | string | latest | Helm version |
| installHelmDiff | boolean | false | Install helm-diff plugin |
| installHelmSecrets | boolean | false | Install helm-secrets plugin |
| installHelmfile | boolean | false | Install Helmfile |
| helmfileVersion | string | latest | Helmfile version |

## Examples

### Install with plugins

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/helm:1": {
            "installHelmDiff": true,
            "installHelmSecrets": true
        }
    }
}
```

### Install with Helmfile

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/helm:1": {
            "installHelmfile": true
        }
    }
}
```

## Helm Usage

```bash
# Add a repository
helm repo add bitnami https://charts.bitnami.com/bitnami

# Update repositories
helm repo update

# Search for charts
helm search repo nginx

# Install a chart
helm install my-nginx bitnami/nginx

# List releases
helm list

# Upgrade a release
helm upgrade my-nginx bitnami/nginx

# Uninstall a release
helm uninstall my-nginx
```

## helm-diff Usage

Compare a release with a chart:

```bash
helm diff upgrade my-release chart/ -f values.yaml
```

## helm-secrets Usage

Encrypt values files with SOPS:

```bash
# Encrypt
helm secrets encrypt secrets.yaml

# Decrypt and use
helm secrets install my-release chart/ -f secrets.yaml
```

## Helmfile Usage

```bash
# Apply helmfile
helmfile apply

# Diff changes
helmfile diff

# Sync specific releases
helmfile -l name=my-release sync
```
