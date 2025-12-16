#!/bin/bash
set -e

INSTALL_WSCAT="${INSTALLWSCAT:-"true"}"
INSTALL_WEBSOCAT="${INSTALLWEBSOCAT:-"true"}"
WEBSOCAT_VERSION="${WEBSOCATVERSION:-"latest"}"
INSTALL_WSTUNNEL="${INSTALLWSTUNNEL:-"true"}"
WSTUNNEL_VERSION="${WSTUNNELVERSION:-"latest"}"
INSTALL_CLOUDFLARED="${INSTALLCLOUDFLARED:-"true"}"
CLOUDFLARED_VERSION="${CLOUDFLAREDVERSION:-"latest"}"
INSTALL_WRANGLER="${INSTALLWRANGLER:-"true"}"

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

# Install wscat (npm package)
if [ "${INSTALL_WSCAT}" = "true" ]; then
    echo "Installing wscat..."

    # Check if npm is available
    if command -v npm >/dev/null 2>&1; then
        npm install -g wscat
    else
        echo "Warning: npm not found. Installing Node.js for wscat..."
        apt_get_update_if_needed
        apt-get install -y --no-install-recommends nodejs npm
        npm install -g wscat
    fi
fi

# Install websocat
if [ "${INSTALL_WEBSOCAT}" = "true" ]; then
    echo "Installing websocat..."

    if [ "${WEBSOCAT_VERSION}" = "latest" ]; then
        WEBSOCAT_VERSION=$(resolve_github_version "vi/websocat")
    fi
    WEBSOCAT_VERSION="${WEBSOCAT_VERSION#v}"

    # Map architecture for websocat
    case "${ARCHITECTURE}" in
        amd64) WS_ARCH="x86_64" ;;
        arm64) WS_ARCH="aarch64" ;;
    esac

    curl -fsSL -o /usr/local/bin/websocat \
        "https://github.com/vi/websocat/releases/download/v${WEBSOCAT_VERSION}/websocat.${WS_ARCH}-unknown-linux-musl" 2>/dev/null || \
    curl -fsSL -o /usr/local/bin/websocat \
        "https://github.com/vi/websocat/releases/download/v${WEBSOCAT_VERSION}/websocat_${WS_ARCH}-unknown-linux-musl"

    chmod +x /usr/local/bin/websocat
fi

# Install wstunnel
if [ "${INSTALL_WSTUNNEL}" = "true" ]; then
    echo "Installing wstunnel..."

    if [ "${WSTUNNEL_VERSION}" = "latest" ]; then
        WSTUNNEL_VERSION=$(resolve_github_version "erebe/wstunnel")
    fi
    WSTUNNEL_VERSION="${WSTUNNEL_VERSION#v}"

    TEMP_DIR=$(mktemp -d)
    cd "${TEMP_DIR}"

    # wstunnel uses amd64/arm64 naming
    curl -fsSL -o wstunnel.tar.gz \
        "https://github.com/erebe/wstunnel/releases/download/v${WSTUNNEL_VERSION}/wstunnel_${WSTUNNEL_VERSION}_linux_${ARCHITECTURE}.tar.gz"

    tar -xzf wstunnel.tar.gz
    install -m 755 wstunnel /usr/local/bin/wstunnel

    cd /
    rm -rf "${TEMP_DIR}"

    # Shell completions
    mkdir -p /etc/bash_completion.d
    wstunnel --completions bash > /etc/bash_completion.d/wstunnel 2>/dev/null || true

    if command -v zsh >/dev/null 2>&1; then
        mkdir -p /usr/local/share/zsh/site-functions
        wstunnel --completions zsh > /usr/local/share/zsh/site-functions/_wstunnel 2>/dev/null || true
    fi
fi

# Install cloudflared
if [ "${INSTALL_CLOUDFLARED}" = "true" ]; then
    echo "Installing cloudflared..."

    if [ "${CLOUDFLARED_VERSION}" = "latest" ]; then
        CLOUDFLARED_VERSION=$(resolve_github_version "cloudflare/cloudflared")
    fi
    CLOUDFLARED_VERSION="${CLOUDFLARED_VERSION#v}"

    # Try deb package first (includes service files)
    TEMP_DIR=$(mktemp -d)
    cd "${TEMP_DIR}"

    if curl -fsSL -o cloudflared.deb \
        "https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-linux-${ARCHITECTURE}.deb" 2>/dev/null; then
        dpkg -i cloudflared.deb
    else
        # Fall back to binary download
        curl -fsSL -o /usr/local/bin/cloudflared \
            "https://github.com/cloudflare/cloudflared/releases/download/${CLOUDFLARED_VERSION}/cloudflared-linux-${ARCHITECTURE}"
        chmod +x /usr/local/bin/cloudflared
    fi

    cd /
    rm -rf "${TEMP_DIR}"

    # Shell completions
    mkdir -p /etc/bash_completion.d
    cloudflared completion bash > /etc/bash_completion.d/cloudflared 2>/dev/null || true

    if command -v zsh >/dev/null 2>&1; then
        mkdir -p /usr/local/share/zsh/site-functions
        cloudflared completion zsh > /usr/local/share/zsh/site-functions/_cloudflared 2>/dev/null || true
    fi
fi

# Install Wrangler (Cloudflare Workers CLI)
if [ "${INSTALL_WRANGLER}" = "true" ]; then
    echo "Installing Cloudflare Wrangler..."

    # Check if npm is available
    if command -v npm >/dev/null 2>&1; then
        npm install -g wrangler
    else
        echo "Warning: npm not found. Installing Node.js for wrangler..."
        apt_get_update_if_needed
        apt-get install -y --no-install-recommends nodejs npm
        npm install -g wrangler
    fi

    # Shell completions
    mkdir -p /etc/bash_completion.d
    wrangler completions bash > /etc/bash_completion.d/wrangler 2>/dev/null || true

    if command -v zsh >/dev/null 2>&1; then
        mkdir -p /usr/local/share/zsh/site-functions
        wrangler completions zsh > /usr/local/share/zsh/site-functions/_wrangler 2>/dev/null || true
    fi
fi

# Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "WebSocket and Tunneling tools installation complete!"
[ "${INSTALL_WSCAT}" = "true" ] && wscat --version 2>/dev/null || true
[ "${INSTALL_WEBSOCAT}" = "true" ] && websocat --version 2>/dev/null || true
[ "${INSTALL_WSTUNNEL}" = "true" ] && wstunnel --version 2>/dev/null || true
[ "${INSTALL_CLOUDFLARED}" = "true" ] && cloudflared --version 2>/dev/null || true
[ "${INSTALL_WRANGLER}" = "true" ] && wrangler --version 2>/dev/null || true
