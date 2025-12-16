#!/bin/bash
set -e

ARGO_WORKFLOWS_VERSION="${ARGOWORKFLOWSVERSION:-"none"}"
ARGO_CD_VERSION="${ARGOCDVERSION:-"latest"}"
ARGO_ROLLOUTS_VERSION="${ARGOROLLOUTSVERSION:-"none"}"

# Ensure running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Script must be run as root."
    exit 1
fi

# Architecture detection
detect_arch() {
    local arch
    arch="$(uname -m)"
    case "${arch}" in
        x86_64) echo "amd64" ;;
        aarch64 | arm64) echo "arm64" ;;
        *) echo "ERROR: Unsupported architecture: ${arch}" >&2; exit 1 ;;
    esac
}

ARCHITECTURE=$(detect_arch)

# Helper functions
apt_get_update_if_needed() {
    if [ ! -d "/var/lib/apt/lists" ] || [ "$(ls /var/lib/apt/lists/ 2>/dev/null | wc -l)" = "0" ]; then
        apt-get update
    fi
}

resolve_github_version() {
    local repo="$1"
    curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" | \
        grep '"tag_name"' | sed -E 's/.*"([^"]+)".*/\1/'
}

export DEBIAN_FRONTEND=noninteractive

# Install prerequisites
apt_get_update_if_needed
apt-get install -y --no-install-recommends \
    curl \
    ca-certificates

# Install Argo Workflows CLI
if [ "${ARGO_WORKFLOWS_VERSION}" != "none" ]; then
    echo "Installing Argo Workflows CLI..."

    if [ "${ARGO_WORKFLOWS_VERSION}" = "latest" ]; then
        ARGO_WORKFLOWS_VERSION=$(resolve_github_version "argoproj/argo-workflows")
        if [ -z "${ARGO_WORKFLOWS_VERSION}" ]; then
            echo "Warning: Could not resolve Argo Workflows version, skipping..."
            ARGO_WORKFLOWS_VERSION="none"
        fi
    fi

    if [ "${ARGO_WORKFLOWS_VERSION}" != "none" ]; then
        ARGO_WORKFLOWS_VERSION="${ARGO_WORKFLOWS_VERSION#v}"
        echo "Downloading Argo Workflows v${ARGO_WORKFLOWS_VERSION}..."

        # Download .gz file to temp and extract
        if curl -fsSL -o /tmp/argo.gz \
            "https://github.com/argoproj/argo-workflows/releases/download/v${ARGO_WORKFLOWS_VERSION}/argo-linux-${ARCHITECTURE}.gz" 2>/dev/null; then
            gunzip -c /tmp/argo.gz > /usr/local/bin/argo
            rm /tmp/argo.gz
        else
            # Try direct binary download
            curl -fsSL -o /usr/local/bin/argo \
                "https://github.com/argoproj/argo-workflows/releases/download/v${ARGO_WORKFLOWS_VERSION}/argo-linux-${ARCHITECTURE}"
        fi

        chmod +x /usr/local/bin/argo
    fi

    # Shell completions
    mkdir -p /etc/bash_completion.d
    argo completion bash > /etc/bash_completion.d/argo 2>/dev/null || true

    if command -v zsh >/dev/null 2>&1; then
        mkdir -p /usr/local/share/zsh/site-functions
        argo completion zsh > /usr/local/share/zsh/site-functions/_argo 2>/dev/null || true
    fi
fi

# Install Argo CD CLI
if [ "${ARGO_CD_VERSION}" != "none" ]; then
    echo "Installing Argo CD CLI..."

    if [ "${ARGO_CD_VERSION}" = "latest" ]; then
        # Argo CD uses a stable VERSION file
        ARGO_CD_VERSION=$(curl -fsSL https://raw.githubusercontent.com/argoproj/argo-cd/stable/VERSION 2>/dev/null) || \
            ARGO_CD_VERSION=$(resolve_github_version "argoproj/argo-cd")
    fi
    ARGO_CD_VERSION="${ARGO_CD_VERSION#v}"

    curl -fsSL -o /usr/local/bin/argocd \
        "https://github.com/argoproj/argo-cd/releases/download/v${ARGO_CD_VERSION}/argocd-linux-${ARCHITECTURE}"
    chmod +x /usr/local/bin/argocd

    # Shell completions
    mkdir -p /etc/bash_completion.d
    argocd completion bash > /etc/bash_completion.d/argocd 2>/dev/null || true

    if command -v zsh >/dev/null 2>&1; then
        mkdir -p /usr/local/share/zsh/site-functions
        argocd completion zsh > /usr/local/share/zsh/site-functions/_argocd 2>/dev/null || true
    fi
fi

# Install Argo Rollouts kubectl plugin
if [ "${ARGO_ROLLOUTS_VERSION}" != "none" ]; then
    echo "Installing Argo Rollouts kubectl plugin..."

    if [ "${ARGO_ROLLOUTS_VERSION}" = "latest" ]; then
        ARGO_ROLLOUTS_VERSION=$(resolve_github_version "argoproj/argo-rollouts")
    fi
    ARGO_ROLLOUTS_VERSION="${ARGO_ROLLOUTS_VERSION#v}"

    curl -fsSL -o /usr/local/bin/kubectl-argo-rollouts \
        "https://github.com/argoproj/argo-rollouts/releases/download/v${ARGO_ROLLOUTS_VERSION}/kubectl-argo-rollouts-linux-${ARCHITECTURE}"
    chmod +x /usr/local/bin/kubectl-argo-rollouts

    # Shell completions
    mkdir -p /etc/bash_completion.d
    kubectl-argo-rollouts completion bash > /etc/bash_completion.d/kubectl-argo-rollouts 2>/dev/null || true
fi

# Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Argo CLI installation complete!"
[ "${ARGO_WORKFLOWS_VERSION}" != "none" ] && argo version 2>/dev/null || true
[ "${ARGO_CD_VERSION}" != "none" ] && argocd version --client 2>/dev/null || true
[ "${ARGO_ROLLOUTS_VERSION}" != "none" ] && kubectl-argo-rollouts version 2>/dev/null || true
