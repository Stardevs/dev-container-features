#!/bin/bash
set -e

VERSION="${VERSION:-"latest"}"
ENABLE_AUTO_COMPLETION="${ENABLEAUTOCOMPLETION:-"true"}"

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
    local response
    response=$(curl -fsSL "https://api.github.com/repos/${repo}/releases/latest" 2>/dev/null) || return 1
    # Extract tag_name value more reliably
    echo "$response" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/'
}

export DEBIAN_FRONTEND=noninteractive

# Install prerequisites
apt_get_update_if_needed
apt-get install -y --no-install-recommends \
    curl \
    ca-certificates

# Resolve version
echo "Installing Istio CLI..."
if [ "${VERSION}" = "latest" ]; then
    VERSION=$(resolve_github_version "istio/istio")
fi
VERSION="${VERSION#v}"

echo "Installing istioctl ${VERSION}..."

TEMP_DIR=$(mktemp -d)
cd "${TEMP_DIR}"

# Download and extract
curl -fsSL -o "istio-${VERSION}-linux-${ARCHITECTURE}.tar.gz" \
    "https://github.com/istio/istio/releases/download/${VERSION}/istio-${VERSION}-linux-${ARCHITECTURE}.tar.gz"

tar -xzf "istio-${VERSION}-linux-${ARCHITECTURE}.tar.gz"

# Install istioctl
install -m 755 "istio-${VERSION}/bin/istioctl" /usr/local/bin/istioctl

# Optionally install samples (commented out to save space)
# mkdir -p /usr/local/share/istio
# cp -r "istio-${VERSION}/samples" /usr/local/share/istio/
# cp -r "istio-${VERSION}/manifests" /usr/local/share/istio/

cd /
rm -rf "${TEMP_DIR}"

# Shell completions
if [ "${ENABLE_AUTO_COMPLETION}" = "true" ]; then
    mkdir -p /etc/bash_completion.d
    istioctl completion bash > /etc/bash_completion.d/istioctl

    if command -v zsh >/dev/null 2>&1; then
        mkdir -p /usr/local/share/zsh/site-functions
        istioctl completion zsh > /usr/local/share/zsh/site-functions/_istioctl
    fi
fi

# Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Istio CLI installation complete!"
istioctl version --remote=false
