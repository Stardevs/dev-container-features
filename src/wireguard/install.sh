#!/bin/bash
set -e

INSTALL_TOOLS="${INSTALLTOOLS:-"true"}"
INSTALL_WIREGUARD_GO="${INSTALLWIREGUARDGO:-"false"}"
INSTALL_BORINGTUN="${INSTALLBORINGTUN:-"false"}"
BORINGTUN_VERSION="${BORINGTUNVERSION:-"latest"}"

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

# Install WireGuard tools
if [ "${INSTALL_TOOLS}" = "true" ]; then
    echo "Installing WireGuard tools..."
    apt_get_update_if_needed
    apt-get install -y --no-install-recommends \
        wireguard-tools \
        iptables \
        iproute2

    # Try to install openresolv or resolvconf (optional, for wg-quick)
    apt-get install -y --no-install-recommends openresolv 2>/dev/null || \
        apt-get install -y --no-install-recommends resolvconf 2>/dev/null || \
        echo "Note: Neither openresolv nor resolvconf available. wg-quick DNS management may not work."
fi

# Install wireguard-go (userspace implementation)
if [ "${INSTALL_WIREGUARD_GO}" = "true" ]; then
    echo "Installing wireguard-go..."

    # Check if Go is available
    if command -v go >/dev/null 2>&1; then
        go install golang.zx2c4.com/wireguard/...@latest

        # Copy to system path
        if [ -f "${GOPATH}/bin/wireguard-go" ]; then
            cp "${GOPATH}/bin/wireguard-go" /usr/local/bin/
        elif [ -f "/go/bin/wireguard-go" ]; then
            cp /go/bin/wireguard-go /usr/local/bin/
        elif [ -f "${HOME}/go/bin/wireguard-go" ]; then
            cp "${HOME}/go/bin/wireguard-go" /usr/local/bin/
        fi
    else
        echo "Warning: Go not found. Installing wireguard-go from package..."
        apt-get install -y --no-install-recommends wireguard-go 2>/dev/null || \
            echo "Warning: wireguard-go package not available. Install Go first or use boringtun."
    fi
fi

# Install boringtun (Cloudflare's userspace WireGuard)
if [ "${INSTALL_BORINGTUN}" = "true" ]; then
    echo "Installing boringtun..."

    if [ "${BORINGTUN_VERSION}" = "latest" ]; then
        BORINGTUN_VERSION=$(resolve_github_version "cloudflare/boringtun")
    fi
    BORINGTUN_VERSION="${BORINGTUN_VERSION#v}"

    # Map architecture
    case "${ARCHITECTURE}" in
        amd64) BT_ARCH="x86_64" ;;
        arm64) BT_ARCH="aarch64" ;;
    esac

    TEMP_DIR=$(mktemp -d)
    cd "${TEMP_DIR}"

    # Try to download pre-built binary
    if curl -fsSL -o boringtun.tar.gz \
        "https://github.com/cloudflare/boringtun/releases/download/boringtun-cli-${BORINGTUN_VERSION}/boringtun-cli-linux-${BT_ARCH}.tar.gz" 2>/dev/null; then
        tar -xzf boringtun.tar.gz
        install -m 755 boringtun-cli /usr/local/bin/boringtun
    else
        # Try alternative naming
        if curl -fsSL -o boringtun \
            "https://github.com/cloudflare/boringtun/releases/download/${BORINGTUN_VERSION}/boringtun-linux-${BT_ARCH}" 2>/dev/null; then
            install -m 755 boringtun /usr/local/bin/boringtun
        else
            echo "Warning: Could not download boringtun binary. You may need to build from source."
        fi
    fi

    cd /
    rm -rf "${TEMP_DIR}"
fi

# Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "WireGuard installation complete!"
[ "${INSTALL_TOOLS}" = "true" ] && wg --version || true
[ -f /usr/local/bin/boringtun ] && boringtun --version 2>/dev/null || true
