
# Argo CLI Tools (argo-cli)

Installs Argo CLI tools including Argo Workflows CLI, Argo CD CLI, and Argo Rollouts kubectl plugin.

## Example Usage

```json
"features": {
    "ghcr.io/Stardevs/dev-container-features/argo-cli:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| argoWorkflowsVersion | Argo Workflows CLI version ('none' to skip) | string | none |
| argoCdVersion | Argo CD CLI version ('none' to skip) | string | latest |
| argoRolloutsVersion | Argo Rollouts kubectl plugin version ('none' to skip) | string | none |

# Argo CLI Tools

This feature installs Argo project CLI tools for GitOps and workflow automation.

## Usage

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/argo-cli:1": {}
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| argoWorkflowsVersion | string | none | Argo Workflows CLI version |
| argoCdVersion | string | latest | Argo CD CLI version |
| argoRolloutsVersion | string | none | Argo Rollouts plugin version |

## Examples

### Install all Argo tools

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/argo-cli:1": {
            "argoWorkflowsVersion": "latest",
            "argoCdVersion": "latest",
            "argoRolloutsVersion": "latest"
        }
    }
}
```

### Only Argo CD

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/argo-cli:1": {
            "argoCdVersion": "latest"
        }
    }
}
```

## Argo CD CLI Usage

```bash
# Login to Argo CD server
argocd login argocd.example.com

# List applications
argocd app list

# Get application details
argocd app get my-app

# Sync application
argocd app sync my-app

# Create application
argocd app create my-app \
    --repo https://github.com/org/repo.git \
    --path kubernetes/ \
    --dest-server https://kubernetes.default.svc \
    --dest-namespace default

# Delete application
argocd app delete my-app
```

## Argo Workflows CLI Usage

```bash
# Submit a workflow
argo submit workflow.yaml

# List workflows
argo list

# Get workflow details
argo get my-workflow

# Watch workflow
argo watch my-workflow

# Get logs
argo logs my-workflow
```

## Argo Rollouts Usage

```bash
# Get rollout status
kubectl argo rollouts get rollout my-rollout

# Promote a rollout
kubectl argo rollouts promote my-rollout

# Abort a rollout
kubectl argo rollouts abort my-rollout

# Restart rollout
kubectl argo rollouts restart my-rollout

# Watch rollout
kubectl argo rollouts get rollout my-rollout --watch
```

## Authentication

### Argo CD

```bash
# Get initial admin password (if using default installation)
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Login
argocd login argocd.example.com --username admin --password <password>
```

### Argo Workflows

```bash
# Port forward to access UI
kubectl -n argo port-forward svc/argo-server 2746:2746

# Get token for authentication
SECRET=$(kubectl get sa argo-server -n argo -o=jsonpath='{.secrets[0].name}')
TOKEN=$(kubectl get secret $SECRET -n argo -o=jsonpath='{.data.token}' | base64 --decode)
```


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/Stardevs/dev-container-features/blob/main/src/argo-cli/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
