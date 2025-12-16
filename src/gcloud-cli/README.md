
# Google Cloud CLI (gcloud-cli)

Installs the Google Cloud CLI (gcloud) with optional components.

## Example Usage

```json
"features": {
    "ghcr.io/Stardevs/dev-container-features/gcloud-cli:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Google Cloud CLI version to install | string | latest |
| installComponents | Comma-separated list of additional gcloud components to install (e.g., 'gke-gcloud-auth-plugin,cloud-sql-proxy') | string | - |
| installGkeAuthPlugin | Install gke-gcloud-auth-plugin for GKE authentication | boolean | true |

## Customizations

### VS Code Extensions

- `GoogleCloudTools.cloudcode`

# Google Cloud CLI

This feature installs the Google Cloud CLI (gcloud) and optional components.

## Usage

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/gcloud-cli:1": {}
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| version | string | latest | Google Cloud CLI version |
| installComponents | string | "" | Comma-separated list of additional components |
| installGkeAuthPlugin | boolean | true | Install gke-gcloud-auth-plugin |

## Examples

### Install with specific version

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/gcloud-cli:1": {
            "version": "504.0.0"
        }
    }
}
```

### Install with additional components

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/gcloud-cli:1": {
            "installComponents": "cloud-sql-proxy,pubsub-emulator"
        }
    }
}
```

## Authentication

After the container starts, authenticate with:

```bash
gcloud auth login
gcloud config set project YOUR_PROJECT_ID
```

For application default credentials:

```bash
gcloud auth application-default login
```

## Environment Variables

- `USE_GKE_GCLOUD_AUTH_PLUGIN=True` - Enables the new GKE authentication plugin


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/Stardevs/dev-container-features/blob/main/src/gcloud-cli/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
