#!/bin/bash
set -e

ALLOWED_DOMAINS="${ALLOWEDDOMAINS:-""}"
ALLOW_GITHUB="${ALLOWGITHUB:-"true"}"
ALLOW_NPM="${ALLOWNPM:-"true"}"
ALLOW_PYPI="${ALLOWPYPI:-"false"}"
ALLOW_DOCKER="${ALLOWDOCKER:-"false"}"
ALLOW_GOOGLE="${ALLOWGOOGLE:-"false"}"
ALLOW_AWS="${ALLOWAWS:-"false"}"
ENABLE_ON_START="${ENABLEONSTART:-"false"}"
BLOCK_VERIFICATION_DOMAIN="${BLOCKVERIFICATIONDOMAIN:-"example.com"}"
REMOTE_USER="${REMOTEUSER:-""}"
FIX_WORKSPACE_PERMISSIONS="${FIXWORKSPACEPERMISSIONS:-"false"}"
WORKSPACE_PATH="${WORKSPACEPATH:-"/workspace"}"

# Ensure running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Script must be run as root."
    exit 1
fi

# Helper functions
apt_get_update_if_needed() {
    if [ ! -d "/var/lib/apt/lists" ] || [ "$(ls /var/lib/apt/lists/ 2>/dev/null | wc -l)" = "0" ]; then
        apt-get update
    fi
}

export DEBIAN_FRONTEND=noninteractive

echo "Installing firewall tools..."

# Install prerequisites
apt_get_update_if_needed
apt-get install -y --no-install-recommends \
    iptables \
    ipset \
    dnsutils \
    curl \
    jq \
    ca-certificates \
    aggregate

# Build the list of domains to allow
DOMAINS_LIST=""

# Add user-specified domains
if [ -n "${ALLOWED_DOMAINS}" ]; then
    DOMAINS_LIST="${ALLOWED_DOMAINS}"
fi

# Add NPM
if [ "${ALLOW_NPM}" = "true" ]; then
    DOMAINS_LIST="${DOMAINS_LIST},registry.npmjs.org"
fi

# Add PyPI
if [ "${ALLOW_PYPI}" = "true" ]; then
    DOMAINS_LIST="${DOMAINS_LIST},pypi.org,files.pythonhosted.org"
fi

# Add Docker
if [ "${ALLOW_DOCKER}" = "true" ]; then
    DOMAINS_LIST="${DOMAINS_LIST},registry-1.docker.io,auth.docker.io,production.cloudflare.docker.com,docker.io"
fi

# Add Google Cloud
if [ "${ALLOW_GOOGLE}" = "true" ]; then
    DOMAINS_LIST="${DOMAINS_LIST},googleapis.com,google.com,accounts.google.com,oauth2.googleapis.com,storage.googleapis.com"
fi

# Add AWS
if [ "${ALLOW_AWS}" = "true" ]; then
    DOMAINS_LIST="${DOMAINS_LIST},amazonaws.com,aws.amazon.com"
fi

# Remove leading comma if present
DOMAINS_LIST="${DOMAINS_LIST#,}"

# Create the firewall initialization script
cat > /usr/local/bin/init-firewall.sh << 'FIREWALL_SCRIPT'
#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Configuration (can be overridden by environment variables)
ALLOWED_DOMAINS="${FIREWALL_ALLOWED_DOMAINS:-}"
ALLOW_GITHUB="${FIREWALL_ALLOW_GITHUB:-true}"
BLOCK_VERIFICATION_DOMAIN="${FIREWALL_BLOCK_VERIFICATION_DOMAIN:-example.com}"

echo "=== Initializing Whitelist Firewall ==="

# 1. Extract Docker DNS info BEFORE any flushing
DOCKER_DNS_RULES=$(iptables-save -t nat | grep "127\.0\.0\.11" || true)

# Flush existing rules and delete existing ipsets
iptables -F
iptables -X 2>/dev/null || true
iptables -t nat -F
iptables -t nat -X 2>/dev/null || true
iptables -t mangle -F
iptables -t mangle -X 2>/dev/null || true
ipset destroy allowed-domains 2>/dev/null || true

# 2. Selectively restore ONLY internal Docker DNS resolution
if [ -n "$DOCKER_DNS_RULES" ]; then
    echo "Restoring Docker DNS rules..."
    iptables -t nat -N DOCKER_OUTPUT 2>/dev/null || true
    iptables -t nat -N DOCKER_POSTROUTING 2>/dev/null || true
    echo "$DOCKER_DNS_RULES" | while read -r rule; do
        iptables -t nat $rule 2>/dev/null || true
    done
else
    echo "No Docker DNS rules to restore"
fi

# First allow DNS and localhost before any restrictions
# Allow outbound DNS
iptables -A OUTPUT -p udp --dport 53 -j ACCEPT
# Allow inbound DNS responses
iptables -A INPUT -p udp --sport 53 -j ACCEPT
# Allow outbound SSH
iptables -A OUTPUT -p tcp --dport 22 -j ACCEPT
# Allow inbound SSH responses
iptables -A INPUT -p tcp --sport 22 -m state --state ESTABLISHED -j ACCEPT
# Allow localhost
iptables -A INPUT -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

# Create ipset with CIDR support
ipset create allowed-domains hash:net

# Fetch GitHub meta information and add their IP ranges
if [ "${ALLOW_GITHUB}" = "true" ]; then
    echo "Fetching GitHub IP ranges..."
    gh_ranges=$(curl -s https://api.github.com/meta)
    if [ -n "$gh_ranges" ] && echo "$gh_ranges" | jq -e '.web and .api and .git' >/dev/null 2>&1; then
        echo "Processing GitHub IPs..."
        while read -r cidr; do
            if [[ "$cidr" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}/[0-9]{1,2}$ ]]; then
                echo "Adding GitHub range $cidr"
                ipset add allowed-domains "$cidr" 2>/dev/null || true
            fi
        done < <(echo "$gh_ranges" | jq -r '(.web + .api + .git)[]' | aggregate -q 2>/dev/null || echo "$gh_ranges" | jq -r '(.web + .api + .git)[]')
    else
        echo "WARNING: Failed to fetch GitHub IP ranges"
    fi
fi

# Resolve and add other allowed domains
if [ -n "$ALLOWED_DOMAINS" ]; then
    IFS=',' read -ra DOMAIN_ARRAY <<< "$ALLOWED_DOMAINS"
    for domain in "${DOMAIN_ARRAY[@]}"; do
        domain=$(echo "$domain" | xargs)  # Trim whitespace
        if [ -n "$domain" ]; then
            echo "Resolving $domain..."
            ips=$(dig +noall +answer A "$domain" 2>/dev/null | awk '$4 == "A" {print $5}')
            if [ -n "$ips" ]; then
                while read -r ip; do
                    if [[ "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
                        echo "Adding $ip for $domain"
                        ipset add allowed-domains "$ip" 2>/dev/null || true
                    fi
                done < <(echo "$ips")
            else
                echo "WARNING: Failed to resolve $domain"
            fi
        fi
    done
fi

# Get host IP from default route
HOST_IP=$(ip route | grep default | cut -d" " -f3)
if [ -n "$HOST_IP" ]; then
    HOST_NETWORK=$(echo "$HOST_IP" | sed "s/\.[0-9]*$/.0\/24/")
    echo "Host network detected as: $HOST_NETWORK"

    # Allow host network communication
    iptables -A INPUT -s "$HOST_NETWORK" -j ACCEPT
    iptables -A OUTPUT -d "$HOST_NETWORK" -j ACCEPT
else
    echo "WARNING: Failed to detect host IP"
fi

# Set default policies to DROP
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

# Allow established connections for already approved traffic
iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT

# Allow only specific outbound traffic to allowed domains
iptables -A OUTPUT -m set --match-set allowed-domains dst -j ACCEPT

# Explicitly REJECT all other outbound traffic for immediate feedback
iptables -A OUTPUT -j REJECT --reject-with icmp-admin-prohibited

echo "=== Firewall configuration complete ==="

# Verification
echo "Verifying firewall rules..."
if curl --connect-timeout 5 "https://${BLOCK_VERIFICATION_DOMAIN}" >/dev/null 2>&1; then
    echo "WARNING: Firewall verification failed - was able to reach https://${BLOCK_VERIFICATION_DOMAIN}"
else
    echo "Firewall verification passed - unable to reach https://${BLOCK_VERIFICATION_DOMAIN} as expected"
fi

# Verify GitHub API access (if enabled)
if [ "${ALLOW_GITHUB}" = "true" ]; then
    if curl --connect-timeout 5 https://api.github.com/zen >/dev/null 2>&1; then
        echo "Firewall verification passed - able to reach https://api.github.com as expected"
    else
        echo "WARNING: Unable to reach https://api.github.com"
    fi
fi

echo "=== Firewall is active ==="
FIREWALL_SCRIPT

chmod +x /usr/local/bin/init-firewall.sh

# Create disable script
cat > /usr/local/bin/disable-firewall.sh << 'DISABLE_SCRIPT'
#!/bin/bash
set -e

echo "=== Disabling Firewall ==="

# Flush all rules
iptables -F
iptables -X 2>/dev/null || true
iptables -t nat -F
iptables -t nat -X 2>/dev/null || true
iptables -t mangle -F
iptables -t mangle -X 2>/dev/null || true

# Set default policies to ACCEPT
iptables -P INPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -P OUTPUT ACCEPT

# Destroy ipset
ipset destroy allowed-domains 2>/dev/null || true

echo "=== Firewall disabled ==="
DISABLE_SCRIPT

chmod +x /usr/local/bin/disable-firewall.sh

# Create configuration file with the domains and entrypoint settings
cat > /etc/firewall.conf << EOF
# Firewall configuration
# Modify these values and run 'sudo firewall start' to apply

# Domain allowlist
FIREWALL_ALLOWED_DOMAINS="${DOMAINS_LIST}"
FIREWALL_ALLOW_GITHUB="${ALLOW_GITHUB}"
FIREWALL_BLOCK_VERIFICATION_DOMAIN="${BLOCK_VERIFICATION_DOMAIN}"

# Entrypoint settings
FIREWALL_ENABLE_ON_START="${ENABLE_ON_START}"
FIREWALL_FIX_WORKSPACE_PERMISSIONS="${FIX_WORKSPACE_PERMISSIONS}"
FIREWALL_WORKSPACE_PATH="${WORKSPACE_PATH}"
FIREWALL_WORKSPACE_USER="${REMOTE_USER}"
EOF

# Create wrapper that sources config
cat > /usr/local/bin/firewall << 'WRAPPER_SCRIPT'
#!/bin/bash

case "$1" in
    start|enable|init)
        if [ -f /etc/firewall.conf ]; then
            source /etc/firewall.conf
            export FIREWALL_ALLOWED_DOMAINS FIREWALL_ALLOW_GITHUB FIREWALL_BLOCK_VERIFICATION_DOMAIN
        fi
        sudo /usr/local/bin/init-firewall.sh
        ;;
    stop|disable)
        sudo /usr/local/bin/disable-firewall.sh
        ;;
    entrypoint)
        # Run the full entrypoint (includes permission fixes if enabled)
        if [ -f /etc/firewall.conf ]; then
            source /etc/firewall.conf
            export FIREWALL_ENABLE_ON_START FIREWALL_FIX_WORKSPACE_PERMISSIONS
            export FIREWALL_WORKSPACE_PATH FIREWALL_WORKSPACE_USER
            export FIREWALL_ALLOWED_DOMAINS FIREWALL_ALLOW_GITHUB FIREWALL_BLOCK_VERIFICATION_DOMAIN
        fi
        sudo /usr/local/bin/firewall-entrypoint.sh
        ;;
    status)
        echo "=== Firewall Status ==="
        echo "IPTables rules:"
        sudo iptables -L -n --line-numbers 2>/dev/null || echo "Unable to read iptables (need sudo)"
        echo ""
        echo "Allowed IPs (ipset):"
        sudo ipset list allowed-domains 2>/dev/null || echo "No ipset configured or need sudo"
        ;;
    *)
        echo "Usage: firewall {start|stop|status|entrypoint}"
        echo ""
        echo "Commands:"
        echo "  start      - Enable the whitelist firewall"
        echo "  stop       - Disable the firewall (allow all traffic)"
        echo "  status     - Show current firewall rules"
        echo "  entrypoint - Run full entrypoint (firewall + optional permission fixes)"
        exit 1
        ;;
esac
WRAPPER_SCRIPT

chmod +x /usr/local/bin/firewall

# Create entrypoint script
cat > /usr/local/bin/firewall-entrypoint.sh << 'ENTRYPOINT_SCRIPT'
#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# Configuration sourced from environment or defaults
ENABLE_ON_START="${FIREWALL_ENABLE_ON_START:-false}"
FIX_WORKSPACE_PERMISSIONS="${FIREWALL_FIX_WORKSPACE_PERMISSIONS:-false}"
WORKSPACE_PATH="${FIREWALL_WORKSPACE_PATH:-/workspace}"
WORKSPACE_USER="${FIREWALL_WORKSPACE_USER:-}"

echo "=== Firewall Entrypoint ==="

# Fix workspace permissions if enabled
if [ "${FIX_WORKSPACE_PERMISSIONS}" = "true" ] && [ -n "${WORKSPACE_USER}" ]; then
    echo "Fixing workspace permissions for ${WORKSPACE_USER}..."
    if [ -d "${WORKSPACE_PATH}" ]; then
        # Fast path: skip if already owned correctly
        if [ "$(stat -c '%U' "${WORKSPACE_PATH}" 2>/dev/null || echo 'unknown')" != "${WORKSPACE_USER}" ]; then
            # Handle git pack files specially (they may be read-only)
            find "${WORKSPACE_PATH}" -path '*/.git/objects/pack/*' -type f -exec chmod u+w {} + 2>/dev/null || true
            chown -R "${WORKSPACE_USER}:${WORKSPACE_USER}" "${WORKSPACE_PATH}" 2>/dev/null || true
            find "${WORKSPACE_PATH}" -path '*/.git/objects/pack/*' -type f -exec chmod 444 {} + 2>/dev/null || true
            echo "Workspace permissions fixed"
        else
            echo "Workspace permissions already correct, skipping"
        fi
    else
        echo "Warning: Workspace path ${WORKSPACE_PATH} does not exist"
    fi
fi

# Enable firewall if configured
if [ "${ENABLE_ON_START}" = "true" ]; then
    echo "Auto-starting firewall..."
    # Source config and export for init-firewall.sh
    if [ -f /etc/firewall.conf ]; then
        source /etc/firewall.conf
        export FIREWALL_ALLOWED_DOMAINS FIREWALL_ALLOW_GITHUB FIREWALL_BLOCK_VERIFICATION_DOMAIN
    fi
    /usr/local/bin/init-firewall.sh
else
    echo "Firewall auto-start disabled (enableOnStart=false)"
fi

echo "=== Entrypoint complete ==="
ENTRYPOINT_SCRIPT

chmod +x /usr/local/bin/firewall-entrypoint.sh

# Create scoped sudoers configuration if remoteUser is specified
if [ -n "${REMOTE_USER}" ] && [ "${REMOTE_USER}" != "root" ]; then
    echo "Configuring scoped sudo for user: ${REMOTE_USER}"
    cat > /etc/sudoers.d/firewall-feature << EOF
# Scoped sudo for firewall feature
# Only allows running specific firewall scripts, not full sudo access

${REMOTE_USER} ALL=(root) NOPASSWD: /usr/local/bin/firewall-entrypoint.sh
${REMOTE_USER} ALL=(root) NOPASSWD: /usr/local/bin/init-firewall.sh
${REMOTE_USER} ALL=(root) NOPASSWD: /usr/local/bin/disable-firewall.sh
${REMOTE_USER} ALL=(root) NOPASSWD: /sbin/iptables
${REMOTE_USER} ALL=(root) NOPASSWD: /sbin/iptables-save
${REMOTE_USER} ALL=(root) NOPASSWD: /sbin/ipset
${REMOTE_USER} ALL=(root) NOPASSWD: /usr/sbin/iptables
${REMOTE_USER} ALL=(root) NOPASSWD: /usr/sbin/iptables-save
${REMOTE_USER} ALL=(root) NOPASSWD: /usr/sbin/ipset
EOF
    chmod 0440 /etc/sudoers.d/firewall-feature
    echo "Scoped sudo configured for user: ${REMOTE_USER}"
fi

# Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Firewall feature installation complete!"
echo ""
echo "Commands:"
echo "  sudo firewall start      - Enable the whitelist firewall"
echo "  sudo firewall stop       - Disable the firewall"
echo "  sudo firewall status     - Show current firewall rules"
echo "  sudo firewall entrypoint - Run full entrypoint (firewall + permission fixes)"
echo ""
echo "Configuration file: /etc/firewall.conf"

# If enableOnStart is true, print a note about postStartCommand
if [ "${ENABLE_ON_START}" = "true" ]; then
    echo ""
    echo "=== Auto-Start Configuration ==="
    echo "Add to your devcontainer.json:"
    echo '  "postStartCommand": "sudo firewall entrypoint"'
    echo ""
    echo "Or run the entrypoint directly:"
    echo '  "postStartCommand": "sudo /usr/local/bin/firewall-entrypoint.sh"'
fi

# If remoteUser is configured, show scoped sudo info
if [ -n "${REMOTE_USER}" ] && [ "${REMOTE_USER}" != "root" ]; then
    echo ""
    echo "=== Scoped Sudo ==="
    echo "Sudo configured for user '${REMOTE_USER}' with access to firewall scripts only."
    echo "No full sudo access granted."
fi
