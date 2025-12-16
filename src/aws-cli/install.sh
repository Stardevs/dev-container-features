#!/bin/bash
set -e

VERSION="${VERSION:-"latest"}"
INSTALL_SESSION_MANAGER="${INSTALLSESSIONMANAGER:-"false"}"
INSTALL_SAM_CLI="${INSTALLSAMCLI:-"false"}"
SAM_CLI_VERSION="${SAMCLIVERSION:-"latest"}"

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
        x86_64) echo "x86_64" ;;
        aarch64 | arm64) echo "aarch64" ;;
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

echo "Installing AWS CLI v2 for ${ARCHITECTURE}..."

# Install prerequisites
apt_get_update_if_needed
apt-get install -y --no-install-recommends \
    curl \
    unzip \
    groff \
    less

# Construct download URL
if [ "${VERSION}" = "latest" ]; then
    DOWNLOAD_URL="https://awscli.amazonaws.com/awscli-exe-linux-${ARCHITECTURE}.zip"
else
    DOWNLOAD_URL="https://awscli.amazonaws.com/awscli-exe-linux-${ARCHITECTURE}-${VERSION}.zip"
fi

# Download and install
TEMP_DIR=$(mktemp -d)
cd "${TEMP_DIR}"

echo "Downloading from ${DOWNLOAD_URL}..."
curl -fsSL -o "awscliv2.zip" "${DOWNLOAD_URL}"
unzip -q awscliv2.zip
./aws/install --install-dir /usr/local/aws-cli --bin-dir /usr/local/bin

# Setup shell completions
mkdir -p /etc/bash_completion.d
cat > /etc/bash_completion.d/aws <<'EOF'
complete -C '/usr/local/bin/aws_completer' aws
EOF

# Zsh completion
if command -v zsh >/dev/null 2>&1; then
    mkdir -p /etc/zsh/completion.d
    cat > /etc/zsh/completion.d/_aws <<'EOF'
#compdef aws
autoload -U +X compinit && compinit
autoload -U +X bashcompinit && bashcompinit
complete -C '/usr/local/bin/aws_completer' aws
EOF
fi

# Install Session Manager plugin
if [ "${INSTALL_SESSION_MANAGER}" = "true" ]; then
    echo "Installing AWS Session Manager plugin..."

    if [ "${ARCHITECTURE}" = "x86_64" ]; then
        SSM_URL="https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_64bit/session-manager-plugin.deb"
    else
        SSM_URL="https://s3.amazonaws.com/session-manager-downloads/plugin/latest/ubuntu_arm64/session-manager-plugin.deb"
    fi

    curl -fsSL -o session-manager-plugin.deb "${SSM_URL}"
    dpkg -i session-manager-plugin.deb
fi

# Install SAM CLI
if [ "${INSTALL_SAM_CLI}" = "true" ]; then
    echo "Installing AWS SAM CLI..."

    # SAM CLI requires Python
    apt_get_update_if_needed
    apt-get install -y --no-install-recommends python3 python3-pip python3-venv

    if [ "${SAM_CLI_VERSION}" = "latest" ]; then
        pip3 install --break-system-packages aws-sam-cli 2>/dev/null || pip3 install aws-sam-cli
    else
        pip3 install --break-system-packages "aws-sam-cli==${SAM_CLI_VERSION}" 2>/dev/null || pip3 install "aws-sam-cli==${SAM_CLI_VERSION}"
    fi
fi

# Cleanup
cd /
rm -rf "${TEMP_DIR}"
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "AWS CLI installation complete!"
aws --version
