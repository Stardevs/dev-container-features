#!/bin/bash
set -e

VERSION="${VERSION:-"latest"}"
INSTALL_COMPONENTS="${INSTALLCOMPONENTS:-""}"
INSTALL_GKE_AUTH_PLUGIN="${INSTALLGKEAUTHPLUGIN:-"true"}"

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

echo "Installing Google Cloud CLI..."

# Install prerequisites
apt_get_update_if_needed
apt-get install -y --no-install-recommends \
    curl \
    apt-transport-https \
    ca-certificates \
    gnupg

# Add Google Cloud GPG key
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg | \
    gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg
chmod 644 /usr/share/keyrings/cloud.google.gpg

# Add repository
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
    > /etc/apt/sources.list.d/google-cloud-sdk.list

# Install Google Cloud CLI
apt-get update
if [ "${VERSION}" = "latest" ]; then
    apt-get install -y --no-install-recommends google-cloud-cli
else
    apt-get install -y --no-install-recommends "google-cloud-cli=${VERSION}-0"
fi

# Install GKE auth plugin
if [ "${INSTALL_GKE_AUTH_PLUGIN}" = "true" ]; then
    echo "Installing gke-gcloud-auth-plugin..."
    apt-get install -y --no-install-recommends google-cloud-cli-gke-gcloud-auth-plugin
fi

# Install additional components
if [ -n "${INSTALL_COMPONENTS}" ]; then
    echo "Installing additional components: ${INSTALL_COMPONENTS}"
    IFS=',' read -ra COMPONENTS <<< "${INSTALL_COMPONENTS}"
    for component in "${COMPONENTS[@]}"; do
        component=$(echo "${component}" | xargs)  # Trim whitespace
        if [ -n "${component}" ]; then
            # Try apt package first, then gcloud components
            if apt-get install -y --no-install-recommends "google-cloud-cli-${component}" 2>/dev/null; then
                echo "Installed ${component} via apt"
            else
                gcloud components install "${component}" --quiet || echo "Warning: Could not install ${component}"
            fi
        fi
    done
fi

# Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Google Cloud CLI installation complete!"
gcloud version
