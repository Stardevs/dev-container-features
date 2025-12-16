#!/bin/bash
set -e

INSTALL_MITMPROXY="${INSTALLMITMPROXY:-"true"}"
MITMPROXY_VERSION="${MITMPROXYVERSION:-"latest"}"
INSTALL_TSHARK="${INSTALLTSHARK:-"true"}"
INSTALL_SQUID="${INSTALLSQUID:-"false"}"
INSTALL_NGREP="${INSTALLNGREP:-"true"}"
INSTALL_TCPDUMP="${INSTALLTCPDUMP:-"true"}"
INSTALL_SSLSPLIT="${INSTALLSSLSPLIT:-"false"}"

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

echo "Installing proxy and DPI tools..."

# Install prerequisites
apt_get_update_if_needed
apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    python3 \
    python3-pip \
    python3-venv

# Install tcpdump
if [ "${INSTALL_TCPDUMP}" = "true" ]; then
    echo "Installing tcpdump..."
    apt-get install -y --no-install-recommends tcpdump
fi

# Install ngrep
if [ "${INSTALL_NGREP}" = "true" ]; then
    echo "Installing ngrep..."
    apt-get install -y --no-install-recommends ngrep
fi

# Install tshark (Wireshark CLI)
if [ "${INSTALL_TSHARK}" = "true" ]; then
    echo "Installing tshark..."

    # Pre-answer the Wireshark SUID question
    echo "wireshark-common wireshark-common/install-setuid boolean false" | debconf-set-selections

    apt-get install -y --no-install-recommends \
        tshark \
        wireshark-common

    # Allow non-root capture
    setcap 'CAP_NET_RAW+eip CAP_NET_ADMIN+eip' /usr/bin/dumpcap 2>/dev/null || true
fi

# Install mitmproxy
if [ "${INSTALL_MITMPROXY}" = "true" ]; then
    echo "Installing mitmproxy..."

    # Install via pip for latest version
    if [ "${MITMPROXY_VERSION}" = "latest" ]; then
        pip3 install --break-system-packages mitmproxy 2>/dev/null || pip3 install mitmproxy
    else
        pip3 install --break-system-packages "mitmproxy==${MITMPROXY_VERSION}" 2>/dev/null || \
        pip3 install "mitmproxy==${MITMPROXY_VERSION}"
    fi

    # Create CA directory
    mkdir -p /root/.mitmproxy

    # Generate initial CA certificate
    cat > /usr/local/bin/mitmproxy-setup << 'EOF'
#!/bin/bash
echo "=== mitmproxy Setup ==="
echo ""
echo "Starting mitmproxy to generate CA certificate..."
timeout 5 mitmproxy --mode regular 2>/dev/null || true
echo ""
echo "CA certificate generated at: ~/.mitmproxy/mitmproxy-ca-cert.pem"
echo ""
echo "To trust the CA certificate:"
echo "  1. Copy ~/.mitmproxy/mitmproxy-ca-cert.pem to your system"
echo "  2. Import it as a trusted root CA"
echo ""
echo "Or for curl/wget, use:"
echo "  export SSL_CERT_FILE=~/.mitmproxy/mitmproxy-ca-cert.pem"
echo "  # or"
echo "  curl --cacert ~/.mitmproxy/mitmproxy-ca-cert.pem https://example.com"
EOF
    chmod +x /usr/local/bin/mitmproxy-setup
fi

# Install Squid transparent proxy
if [ "${INSTALL_SQUID}" = "true" ]; then
    echo "Installing Squid..."
    apt-get install -y --no-install-recommends \
        squid \
        squid-openssl 2>/dev/null || \
    apt-get install -y --no-install-recommends squid

    # Disable auto-start
    systemctl disable squid 2>/dev/null || true
    update-rc.d squid disable 2>/dev/null || true

    # Create basic transparent proxy config
    cat > /etc/squid/squid-transparent.conf << 'EOF'
# Squid transparent proxy configuration
http_port 3128 transparent
https_port 3129 transparent ssl-bump cert=/etc/squid/ssl_cert/squid.pem generate-host-certificates=on dynamic_cert_mem_cache_size=4MB

# SSL bump configuration
acl step1 at_step SslBump1
ssl_bump peek step1
ssl_bump bump all

# Access control
acl localnet src 10.0.0.0/8
acl localnet src 172.16.0.0/12
acl localnet src 192.168.0.0/16
http_access allow localnet
http_access allow localhost
http_access deny all

# Logging
access_log /var/log/squid/access.log squid
cache_log /var/log/squid/cache.log

# Cache settings
cache_dir ufs /var/spool/squid 100 16 256
maximum_object_size 4096 KB
EOF

    # Create SSL directory
    mkdir -p /etc/squid/ssl_cert

    # Create setup script
    cat > /usr/local/bin/squid-setup << 'EOF'
#!/bin/bash
echo "=== Squid Transparent Proxy Setup ==="

# Generate SSL certificate
if [ ! -f /etc/squid/ssl_cert/squid.pem ]; then
    echo "Generating SSL certificate..."
    openssl req -new -newkey rsa:2048 -days 365 -nodes -x509 \
        -subj "/C=US/ST=State/L=City/O=Org/CN=squid-proxy" \
        -keyout /etc/squid/ssl_cert/squid.key \
        -out /etc/squid/ssl_cert/squid.crt
    cat /etc/squid/ssl_cert/squid.key /etc/squid/ssl_cert/squid.crt > /etc/squid/ssl_cert/squid.pem
    chown proxy:proxy /etc/squid/ssl_cert/*
fi

# Initialize cache
squid -z -f /etc/squid/squid-transparent.conf 2>/dev/null || true

echo ""
echo "To start Squid transparent proxy:"
echo "  sudo squid -f /etc/squid/squid-transparent.conf"
echo ""
echo "To redirect traffic through Squid (requires iptables):"
echo "  sudo iptables -t nat -A OUTPUT -p tcp --dport 80 -j REDIRECT --to-port 3128"
echo "  sudo iptables -t nat -A OUTPUT -p tcp --dport 443 -j REDIRECT --to-port 3129"
EOF
    chmod +x /usr/local/bin/squid-setup
fi

# Install SSLsplit
if [ "${INSTALL_SSLSPLIT}" = "true" ]; then
    echo "Installing SSLsplit..."
    apt-get install -y --no-install-recommends sslsplit

    # Create setup script
    cat > /usr/local/bin/sslsplit-setup << 'EOF'
#!/bin/bash
echo "=== SSLsplit Setup ==="

CERT_DIR="/etc/sslsplit"
mkdir -p "${CERT_DIR}"

if [ ! -f "${CERT_DIR}/ca.crt" ]; then
    echo "Generating CA certificate..."
    openssl genrsa -out "${CERT_DIR}/ca.key" 4096
    openssl req -new -x509 -days 1826 -key "${CERT_DIR}/ca.key" \
        -out "${CERT_DIR}/ca.crt" \
        -subj "/C=US/ST=State/L=City/O=SSLsplit/CN=SSLsplit CA"
fi

echo ""
echo "CA certificate: ${CERT_DIR}/ca.crt"
echo ""
echo "To intercept HTTPS traffic:"
echo "  sudo sslsplit -D -k ${CERT_DIR}/ca.key -c ${CERT_DIR}/ca.crt \\"
echo "    -l connections.log -S /tmp/sslsplit \\"
echo "    ssl 0.0.0.0 8443"
echo ""
echo "Then redirect traffic:"
echo "  sudo iptables -t nat -A OUTPUT -p tcp --dport 443 -j REDIRECT --to-port 8443"
EOF
    chmod +x /usr/local/bin/sslsplit-setup
fi

# Create network inspection helper
cat > /usr/local/bin/netinspect << 'EOF'
#!/bin/bash

case "$1" in
    http)
        echo "Capturing HTTP traffic on all interfaces..."
        sudo ngrep -W byline -d any port 80
        ;;
    https)
        echo "To inspect HTTPS, use mitmproxy:"
        echo "  mitmproxy --mode regular -p 8080"
        echo "  # Then set HTTP_PROXY=http://localhost:8080"
        ;;
    dns)
        echo "Capturing DNS traffic..."
        sudo tcpdump -i any -n port 53
        ;;
    tcp)
        shift
        PORT="${1:-80}"
        echo "Capturing TCP traffic on port ${PORT}..."
        sudo tcpdump -i any -n port "${PORT}"
        ;;
    all)
        echo "Capturing all traffic (Ctrl+C to stop)..."
        sudo tcpdump -i any -n
        ;;
    *)
        echo "Usage: netinspect {http|https|dns|tcp [port]|all}"
        echo ""
        echo "Commands:"
        echo "  http   - Capture HTTP traffic with content"
        echo "  https  - Show how to inspect HTTPS"
        echo "  dns    - Capture DNS queries"
        echo "  tcp    - Capture TCP on specific port"
        echo "  all    - Capture all network traffic"
        ;;
esac
EOF
chmod +x /usr/local/bin/netinspect

# Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Proxy and DPI tools installation complete!"
echo ""
[ "${INSTALL_MITMPROXY}" = "true" ] && mitmproxy --version 2>/dev/null && echo ""
[ "${INSTALL_TSHARK}" = "true" ] && echo "tshark: $(tshark --version 2>/dev/null | head -1)"
[ "${INSTALL_TCPDUMP}" = "true" ] && echo "tcpdump: $(tcpdump --version 2>&1 | head -1)"
[ "${INSTALL_NGREP}" = "true" ] && echo "ngrep: installed"
[ "${INSTALL_SQUID}" = "true" ] && echo "squid: installed (run 'squid-setup' to configure)"
[ "${INSTALL_SSLSPLIT}" = "true" ] && echo "sslsplit: installed (run 'sslsplit-setup' to configure)"
echo ""
echo "Quick start: netinspect --help"
