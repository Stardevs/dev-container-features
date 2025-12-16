#!/bin/bash
set -e

CILIUM_VERSION="${CILIUMVERSION:-"latest"}"
INSTALL_HUBBLE="${INSTALLHUBBLE:-"true"}"
HUBBLE_VERSION="${HUBBLEVERSION:-"latest"}"

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

export DEBIAN_FRONTEND=noninteractive

# Install prerequisites
apt_get_update_if_needed
apt-get install -y --no-install-recommends \
    curl \
    ca-certificates

echo "Installing Cilium CLI..."

TEMP_DIR=$(mktemp -d)
cd "${TEMP_DIR}"

# Resolve Cilium CLI version
if [ "${CILIUM_VERSION}" = "latest" ]; then
    CILIUM_CLI_VERSION=$(curl -fsSL https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
else
    CILIUM_CLI_VERSION="v${CILIUM_VERSION#v}"
fi

echo "Installing Cilium CLI ${CILIUM_CLI_VERSION}..."

# Download with checksum
curl -fsSL --remote-name-all \
    "https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${ARCHITECTURE}.tar.gz{,.sha256sum}"

# Verify checksum
sha256sum --check "cilium-linux-${ARCHITECTURE}.tar.gz.sha256sum"

# Extract and install
tar -xzf "cilium-linux-${ARCHITECTURE}.tar.gz"
install -m 755 cilium /usr/local/bin/cilium

# Shell completions
mkdir -p /etc/bash_completion.d
cilium completion bash > /etc/bash_completion.d/cilium

if command -v zsh >/dev/null 2>&1; then
    mkdir -p /usr/local/share/zsh/site-functions
    cilium completion zsh > /usr/local/share/zsh/site-functions/_cilium
fi

# Install Hubble CLI
if [ "${INSTALL_HUBBLE}" = "true" ]; then
    echo "Installing Hubble CLI..."

    if [ "${HUBBLE_VERSION}" = "latest" ]; then
        HUBBLE_CLI_VERSION=$(curl -fsSL https://raw.githubusercontent.com/cilium/hubble/master/stable.txt)
    else
        HUBBLE_CLI_VERSION="v${HUBBLE_VERSION#v}"
    fi

    echo "Installing Hubble CLI ${HUBBLE_CLI_VERSION}..."

    curl -fsSL --remote-name-all \
        "https://github.com/cilium/hubble/releases/download/${HUBBLE_CLI_VERSION}/hubble-linux-${ARCHITECTURE}.tar.gz{,.sha256sum}"

    # Verify checksum
    sha256sum --check "hubble-linux-${ARCHITECTURE}.tar.gz.sha256sum"

    tar -xzf "hubble-linux-${ARCHITECTURE}.tar.gz"
    install -m 755 hubble /usr/local/bin/hubble

    # Shell completions
    hubble completion bash > /etc/bash_completion.d/hubble

    if command -v zsh >/dev/null 2>&1; then
        hubble completion zsh > /usr/local/share/zsh/site-functions/_hubble
    fi
fi

cd /
rm -rf "${TEMP_DIR}"

# Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Cilium CLI installation complete!"
cilium version --client
[ "${INSTALL_HUBBLE}" = "true" ] && hubble version || true
