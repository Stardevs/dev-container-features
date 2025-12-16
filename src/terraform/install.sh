#!/bin/bash
set -e

VERSION="${VERSION:-"latest"}"
TFLINT_VERSION="${TFLINTVERSION:-"latest"}"
TERRAGRUNT_VERSION="${TERRAGRUNTVERSION:-"none"}"
INSTALL_TERRAFORM_DOCS="${INSTALLTERRAFORMDOCS:-"false"}"
TERRAFORM_DOCS_VERSION="${TERRAFORMDOCSVERSION:-"latest"}"
INSTALL_TFSEC="${INSTALLTFSEC:-"false"}"
INSTALL_OPENTOFU="${INSTALLOPENTOFU:-"false"}"
OPENTOFU_VERSION="${OPENTOFUVERSION:-"latest"}"

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
    gnupg \
    software-properties-common \
    lsb-release \
    unzip

# Install Terraform via HashiCorp APT repository
echo "Installing Terraform..."

# Add HashiCorp GPG key
curl -fsSL https://apt.releases.hashicorp.com/gpg | \
    gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
chmod 644 /usr/share/keyrings/hashicorp-archive-keyring.gpg

# Add repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] \
https://apt.releases.hashicorp.com $(lsb_release -cs) main" | \
    tee /etc/apt/sources.list.d/hashicorp.list

apt-get update

if [ "${VERSION}" = "latest" ]; then
    apt-get install -y --no-install-recommends terraform
else
    apt-get install -y --no-install-recommends "terraform=${VERSION}-*" || \
        apt-get install -y --no-install-recommends "terraform=${VERSION}"
fi

# Enable tab completion
terraform -install-autocomplete 2>/dev/null || true

# Install TFLint
if [ "${TFLINT_VERSION}" != "none" ]; then
    echo "Installing TFLint..."

    if [ "${TFLINT_VERSION}" = "latest" ]; then
        TFLINT_VERSION=$(resolve_github_version "terraform-linters/tflint")
        # Fallback if API fails
        if [ -z "${TFLINT_VERSION}" ]; then
            echo "Warning: Could not resolve TFLint version from API, using installer script..."
            curl -s https://raw.githubusercontent.com/terraform-linters/tflint/master/install_linux.sh | bash
        fi
    fi

    # Only download directly if we have a version
    if [ -n "${TFLINT_VERSION}" ]; then
        TFLINT_VERSION="${TFLINT_VERSION#v}"
        echo "Downloading TFLint v${TFLINT_VERSION}..."
        curl -fsSL -o /tmp/tflint.zip \
            "https://github.com/terraform-linters/tflint/releases/download/v${TFLINT_VERSION}/tflint_linux_${ARCHITECTURE}.zip"
        unzip -o /tmp/tflint.zip -d /usr/local/bin
        chmod +x /usr/local/bin/tflint
        rm /tmp/tflint.zip
    fi
fi

# Install Terragrunt
if [ "${TERRAGRUNT_VERSION}" != "none" ]; then
    echo "Installing Terragrunt..."

    if [ "${TERRAGRUNT_VERSION}" = "latest" ]; then
        TERRAGRUNT_VERSION=$(resolve_github_version "gruntwork-io/terragrunt")
    fi
    TERRAGRUNT_VERSION="${TERRAGRUNT_VERSION#v}"

    curl -fsSL -o /usr/local/bin/terragrunt \
        "https://github.com/gruntwork-io/terragrunt/releases/download/v${TERRAGRUNT_VERSION}/terragrunt_linux_${ARCHITECTURE}"
    chmod +x /usr/local/bin/terragrunt
fi

# Install terraform-docs
if [ "${INSTALL_TERRAFORM_DOCS}" = "true" ]; then
    echo "Installing terraform-docs..."

    if [ "${TERRAFORM_DOCS_VERSION}" = "latest" ]; then
        TERRAFORM_DOCS_VERSION=$(resolve_github_version "terraform-docs/terraform-docs")
    fi
    TERRAFORM_DOCS_VERSION="${TERRAFORM_DOCS_VERSION#v}"

    curl -fsSL -o /tmp/terraform-docs.tar.gz \
        "https://github.com/terraform-docs/terraform-docs/releases/download/v${TERRAFORM_DOCS_VERSION}/terraform-docs-v${TERRAFORM_DOCS_VERSION}-linux-${ARCHITECTURE}.tar.gz"
    tar -xzf /tmp/terraform-docs.tar.gz -C /usr/local/bin terraform-docs
    chmod +x /usr/local/bin/terraform-docs
    rm /tmp/terraform-docs.tar.gz
fi

# Install tfsec
if [ "${INSTALL_TFSEC}" = "true" ]; then
    echo "Installing tfsec..."

    TFSEC_VERSION=$(resolve_github_version "aquasecurity/tfsec")
    TFSEC_VERSION="${TFSEC_VERSION#v}"

    curl -fsSL -o /usr/local/bin/tfsec \
        "https://github.com/aquasecurity/tfsec/releases/download/v${TFSEC_VERSION}/tfsec-linux-${ARCHITECTURE}"
    chmod +x /usr/local/bin/tfsec
fi

# Install OpenTofu
if [ "${INSTALL_OPENTOFU}" = "true" ]; then
    echo "Installing OpenTofu..."

    if [ "${OPENTOFU_VERSION}" = "latest" ]; then
        OPENTOFU_VERSION=$(resolve_github_version "opentofu/opentofu")
    fi
    OPENTOFU_VERSION="${OPENTOFU_VERSION#v}"

    curl -fsSL -o /tmp/tofu.zip \
        "https://github.com/opentofu/opentofu/releases/download/v${OPENTOFU_VERSION}/tofu_${OPENTOFU_VERSION}_linux_${ARCHITECTURE}.zip"
    unzip -o /tmp/tofu.zip -d /usr/local/bin tofu
    chmod +x /usr/local/bin/tofu
    rm /tmp/tofu.zip
fi

# Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Terraform installation complete!"
terraform version
[ "${TFLINT_VERSION}" != "none" ] && tflint --version || true
[ "${TERRAGRUNT_VERSION}" != "none" ] && terragrunt --version || true
[ "${INSTALL_TERRAFORM_DOCS}" = "true" ] && terraform-docs --version || true
[ "${INSTALL_TFSEC}" = "true" ] && tfsec --version || true
[ "${INSTALL_OPENTOFU}" = "true" ] && tofu version || true
