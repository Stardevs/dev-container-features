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
