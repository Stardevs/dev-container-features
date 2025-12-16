#!/bin/bash
set -e

VERSION="${VERSION:-"latest"}"
INSTALL_SERVER="${INSTALLSERVER:-"false"}"
INSTALL_REDIS_TOOLS="${INSTALLREDISTOOLS:-"true"}"

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

echo "Installing Redis CLI..."

# Install prerequisites
apt_get_update_if_needed
apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    lsb-release

# Add Redis official repository for latest versions
curl -fsSL https://packages.redis.io/gpg | gpg --dearmor -o /usr/share/keyrings/redis-archive-keyring.gpg
chmod 644 /usr/share/keyrings/redis-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/redis-archive-keyring.gpg] https://packages.redis.io/deb $(lsb_release -cs) main" | \
    tee /etc/apt/sources.list.d/redis.list

apt-get update

# Determine packages to install
PACKAGES="redis-tools"

if [ "${INSTALL_SERVER}" = "true" ]; then
    PACKAGES="redis"
fi

# Install Redis
if [ "${VERSION}" = "latest" ]; then
    apt-get install -y --no-install-recommends ${PACKAGES}
else
    # Try to install specific version
    apt-get install -y --no-install-recommends "${PACKAGES}=${VERSION}*" 2>/dev/null || \
    apt-get install -y --no-install-recommends ${PACKAGES}
fi

# If server is installed, disable auto-start (user can start manually)
if [ "${INSTALL_SERVER}" = "true" ]; then
    # Disable service auto-start
    systemctl disable redis-server 2>/dev/null || true
    update-rc.d redis-server disable 2>/dev/null || true
fi

# Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Redis CLI installation complete!"
redis-cli --version
[ "${INSTALL_SERVER}" = "true" ] && redis-server --version || true
