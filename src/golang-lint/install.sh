#!/bin/bash
set -e

GO_VERSION="${GOVERSION:-"latest"}"
GOLANGCI_LINT_VERSION="${GOLANGCILINTVERSION:-"latest"}"
INSTALL_GO_TOOLS="${INSTALLGOTOOLS:-"true"}"
TARGET_GOPATH="${GOPATH:-"/go"}"
TARGET_GOROOT="/usr/local/go"

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
        armv7l | armv6l) echo "armv6l" ;;
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
    ca-certificates \
    git

# Install Go
if [ "${GO_VERSION}" != "none" ]; then
    echo "Installing Go ${GO_VERSION} for ${ARCHITECTURE}..."

    # Resolve version
    if [ "${GO_VERSION}" = "latest" ]; then
        GO_VERSION=$(curl -fsSL "https://go.dev/VERSION?m=text" | head -n 1 | sed 's/go//')
        echo "Resolved latest Go version: ${GO_VERSION}"
    else
        # Handle partial versions like "1.22" -> find latest 1.22.x
        # Check if version has exactly 2 parts (major.minor) vs 3 parts (major.minor.patch)
        DOT_COUNT=$(echo "${GO_VERSION}" | tr -cd '.' | wc -c)
        if [ "${DOT_COUNT}" -eq 1 ]; then
            echo "Partial version ${GO_VERSION} detected, resolving to latest patch..."
            # Try to get the latest patch version for this minor
            RESOLVED=$(curl -fsSL "https://go.dev/dl/?mode=json" 2>/dev/null | \
                grep -oE "\"version\":\"go${GO_VERSION}\.[0-9]+\"" | \
                head -1 | sed -E 's/.*go([0-9.]+).*/\1/')
            if [ -n "${RESOLVED}" ]; then
                echo "Resolved ${GO_VERSION} to ${RESOLVED}"
                GO_VERSION="${RESOLVED}"
            else
                # Fallback: append .0 if resolution fails
                echo "Warning: Could not resolve ${GO_VERSION}, trying ${GO_VERSION}.0"
                GO_VERSION="${GO_VERSION}.0"
            fi
        fi
    fi

    # Download and install
    TEMP_DIR=$(mktemp -d)
    cd "${TEMP_DIR}"

    GO_TARBALL="go${GO_VERSION}.linux-${ARCHITECTURE}.tar.gz"
    echo "Downloading ${GO_TARBALL}..."
    curl -fsSL -o "${GO_TARBALL}" "https://go.dev/dl/${GO_TARBALL}"

    # Remove existing Go and extract
    rm -rf "${TARGET_GOROOT}"
    tar -C "$(dirname ${TARGET_GOROOT})" -xzf "${GO_TARBALL}"

    cd /
    rm -rf "${TEMP_DIR}"
fi

# Setup GOPATH
mkdir -p "${TARGET_GOPATH}/bin" "${TARGET_GOPATH}/src" "${TARGET_GOPATH}/pkg"
chmod -R 777 "${TARGET_GOPATH}"

# Add to PATH for all users
cat > /etc/profile.d/go.sh <<EOF
export GOROOT="${TARGET_GOROOT}"
export GOPATH="${TARGET_GOPATH}"
export PATH="\${PATH}:\${GOROOT}/bin:\${GOPATH}/bin"
EOF

# Source for current script
export GOROOT="${TARGET_GOROOT}"
export GOPATH="${TARGET_GOPATH}"
export PATH="${PATH}:${GOROOT}/bin:${GOPATH}/bin"

# Verify Go installation
go version

# Install golangci-lint
echo "Installing golangci-lint..."
if [ "${GOLANGCI_LINT_VERSION}" = "latest" ]; then
    curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | \
        sh -s -- -b "${TARGET_GOPATH}/bin"
else
    curl -sSfL https://raw.githubusercontent.com/golangci/golangci-lint/HEAD/install.sh | \
        sh -s -- -b "${TARGET_GOPATH}/bin" "v${GOLANGCI_LINT_VERSION#v}"
fi

# Install common Go tools
if [ "${INSTALL_GO_TOOLS}" = "true" ]; then
    echo "Installing common Go development tools..."

    # Language server
    go install golang.org/x/tools/gopls@latest

    # Debugger
    go install github.com/go-delve/delve/cmd/dlv@latest

    # Static analysis
    go install honnef.co/go/tools/cmd/staticcheck@latest

    # Import management
    go install golang.org/x/tools/cmd/goimports@latest

    # Code generation
    go install github.com/golang/mock/mockgen@latest 2>/dev/null || true

    # Test coverage
    go install github.com/axw/gocov/gocov@latest 2>/dev/null || true
fi

# Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Go installation complete!"
go version
golangci-lint --version
