
# kubectl, kubectx, and kubens (kubectl-kubectx-kubens)

Installs kubectl, kubectx, and kubens for Kubernetes cluster management with context and namespace switching.

## Example Usage

```json
"features": {
    "ghcr.io/Stardevs/dev-container-features/kubectl-kubectx-kubens:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| kubectlVersion | kubectl version to install | string | latest |
| kubectxVersion | kubectx/kubens version to install | string | latest |
| installKrew | Install Krew kubectl plugin manager | boolean | false |
| krewPlugins | Comma-separated list of Krew plugins to install (e.g., 'ctx,ns,neat') | string | - |
| installK9s | Install K9s terminal UI for Kubernetes | boolean | false |
| k9sVersion | K9s version (only used if installK9s is true) | string | latest |

## Customizations

### VS Code Extensions

- `ms-kubernetes-tools.vscode-kubernetes-tools`

# kubectl, kubectx, and kubens

This feature installs kubectl with kubectx and kubens for easy context and namespace switching.

## Usage

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/kubectl-kubectx-kubens:1": {}
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| kubectlVersion | string | latest | kubectl version |
| kubectxVersion | string | latest | kubectx/kubens version |
| installKrew | boolean | false | Install Krew plugin manager |
| krewPlugins | string | "" | Comma-separated Krew plugins |
| installK9s | boolean | false | Install K9s terminal UI |
| k9sVersion | string | latest | K9s version |

## Examples

### Install with K9s

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/kubectl-kubectx-kubens:1": {
            "installK9s": true
        }
    }
}
```

### Install with Krew and plugins

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/kubectl-kubectx-kubens:1": {
            "installKrew": true,
            "krewPlugins": "ctx,ns,neat,tree"
        }
    }
}
```

## kubectx Usage

```bash
# List contexts
kubectx

# Switch context
kubectx my-cluster

# Switch to previous context
kubectx -

# Rename context
kubectx new-name=old-name

# Delete context
kubectx -d my-context
```

## kubens Usage

```bash
# List namespaces
kubens

# Switch namespace
kubens kube-system

# Switch to previous namespace
kubens -

# Set default namespace for current context
kubens default
```

## K9s Usage

K9s provides a terminal UI for Kubernetes:

```bash
# Start K9s
k9s

# Start with specific context
k9s --context my-cluster

# Start with specific namespace
k9s -n kube-system
```

## Recommended Aliases

Add to your shell profile:

```bash
alias k=kubectl
alias kctx=kubectx
alias kns=kubens
```

## Krew Plugins

Popular Krew plugins:

- **ctx** - Context switcher (alternative to kubectx)
- **ns** - Namespace switcher (alternative to kubens)
- **neat** - Clean up YAML output
- **tree** - Show resource hierarchy
- **whoami** - Show current user/context info


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/Stardevs/dev-container-features/blob/main/src/kubectl-kubectx-kubens/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
