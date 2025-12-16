#!/bin/bash
set -e

VERSION="${VERSION:-"latest"}"
INSTALL_HELM_DIFF="${INSTALLHELMDIFF:-"false"}"
INSTALL_HELM_SECRETS="${INSTALLHELMSECRETS:-"false"}"
INSTALL_HELMFILE="${INSTALLHELMFILE:-"false"}"
HELMFILE_VERSION="${HELMFILEVERSION:-"latest"}"

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
    ca-certificates \
    git

# Install Helm
echo "Installing Helm..."
if [ "${VERSION}" = "latest" ]; then
    # Use official installer for latest
    curl -fsSL https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
    # Manual install for specific version
    VERSION="${VERSION#v}"

    TEMP_DIR=$(mktemp -d)
    cd "${TEMP_DIR}"

    echo "Downloading Helm v${VERSION}..."
    curl -fsSL -o "helm.tar.gz" \
        "https://get.helm.sh/helm-v${VERSION}-linux-${ARCHITECTURE}.tar.gz"
    curl -fsSL -o "helm.tar.gz.sha256sum" \
        "https://get.helm.sh/helm-v${VERSION}-linux-${ARCHITECTURE}.tar.gz.sha256sum"

    # Verify checksum
    sha256sum --check "helm.tar.gz.sha256sum"

    tar -xzf "helm.tar.gz"
    install -m 755 "linux-${ARCHITECTURE}/helm" /usr/local/bin/helm

    cd /
    rm -rf "${TEMP_DIR}"
fi

# Shell completions
mkdir -p /etc/bash_completion.d
helm completion bash > /etc/bash_completion.d/helm

if command -v zsh >/dev/null 2>&1; then
    mkdir -p /usr/local/share/zsh/site-functions
    helm completion zsh > /usr/local/share/zsh/site-functions/_helm
fi

# Install helm-diff plugin
if [ "${INSTALL_HELM_DIFF}" = "true" ]; then
    echo "Installing helm-diff plugin..."
    helm plugin install https://github.com/databus23/helm-diff || echo "Warning: helm-diff may already be installed"
fi

# Install helm-secrets plugin
if [ "${INSTALL_HELM_SECRETS}" = "true" ]; then
    echo "Installing helm-secrets plugin..."

    # helm-secrets requires sops
    apt_get_update_if_needed
    apt-get install -y --no-install-recommends gnupg

    # Install sops
    SOPS_VERSION=$(resolve_github_version "getsops/sops")
    curl -fsSL -o /usr/local/bin/sops \
        "https://github.com/getsops/sops/releases/download/${SOPS_VERSION}/sops-${SOPS_VERSION}.linux.${ARCHITECTURE}"
    chmod +x /usr/local/bin/sops

    helm plugin install https://github.com/jkroepke/helm-secrets || echo "Warning: helm-secrets may already be installed"
fi

# Install Helmfile
if [ "${INSTALL_HELMFILE}" = "true" ]; then
    echo "Installing Helmfile..."

    if [ "${HELMFILE_VERSION}" = "latest" ]; then
        HELMFILE_VERSION=$(resolve_github_version "helmfile/helmfile")
    fi
    HELMFILE_VERSION="${HELMFILE_VERSION#v}"

    TEMP_DIR=$(mktemp -d)
    cd "${TEMP_DIR}"

    curl -fsSL -o helmfile.tar.gz \
        "https://github.com/helmfile/helmfile/releases/download/v${HELMFILE_VERSION}/helmfile_${HELMFILE_VERSION}_linux_${ARCHITECTURE}.tar.gz"
    tar -xzf helmfile.tar.gz
    install -m 755 helmfile /usr/local/bin/helmfile

    cd /
    rm -rf "${TEMP_DIR}"
fi

# Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Helm installation complete!"
helm version
[ "${INSTALL_HELMFILE}" = "true" ] && helmfile --version || true
