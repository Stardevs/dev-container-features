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
