#!/bin/bash
set -e

KUBECTL_VERSION="${KUBECTLVERSION:-"latest"}"
KUBECTX_VERSION="${KUBECTXVERSION:-"latest"}"
INSTALL_KREW="${INSTALLKREW:-"false"}"
KREW_PLUGINS="${KREWPLUGINS:-""}"
INSTALL_K9S="${INSTALLK9S:-"false"}"
K9S_VERSION="${K9SVERSION:-"latest"}"

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
    git

# Install kubectl
echo "Installing kubectl..."
if [ "${KUBECTL_VERSION}" = "latest" ]; then
    KUBECTL_VERSION=$(curl -fsSL https://dl.k8s.io/release/stable.txt)
else
    KUBECTL_VERSION="v${KUBECTL_VERSION#v}"
fi

echo "Installing kubectl ${KUBECTL_VERSION}..."
curl -fsSL -o /usr/local/bin/kubectl \
    "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCHITECTURE}/kubectl"

# Verify checksum
curl -fsSL -o /tmp/kubectl.sha256 \
    "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${ARCHITECTURE}/kubectl.sha256"
echo "$(cat /tmp/kubectl.sha256)  /usr/local/bin/kubectl" | sha256sum --check
chmod +x /usr/local/bin/kubectl
rm /tmp/kubectl.sha256

# kubectl completions
mkdir -p /etc/bash_completion.d
kubectl completion bash > /etc/bash_completion.d/kubectl

if command -v zsh >/dev/null 2>&1; then
    mkdir -p /usr/local/share/zsh/site-functions
    kubectl completion zsh > /usr/local/share/zsh/site-functions/_kubectl
fi

# Install kubectx and kubens
echo "Installing kubectx and kubens..."
if [ "${KUBECTX_VERSION}" = "latest" ]; then
    KUBECTX_VERSION=$(resolve_github_version "ahmetb/kubectx")
fi
KUBECTX_VERSION="${KUBECTX_VERSION#v}"

TEMP_DIR=$(mktemp -d)
cd "${TEMP_DIR}"

# Download kubectx
curl -fsSL -o kubectx.tar.gz \
    "https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_VERSION}/kubectx_v${KUBECTX_VERSION}_linux_${ARCHITECTURE}.tar.gz"
tar -xzf kubectx.tar.gz
install -m 755 kubectx /usr/local/bin/kubectx

# Download kubens
curl -fsSL -o kubens.tar.gz \
    "https://github.com/ahmetb/kubectx/releases/download/v${KUBECTX_VERSION}/kubens_v${KUBECTX_VERSION}_linux_${ARCHITECTURE}.tar.gz"
tar -xzf kubens.tar.gz
install -m 755 kubens /usr/local/bin/kubens

cd /
rm -rf "${TEMP_DIR}"

# kubectx/kubens completions
cat > /etc/bash_completion.d/kubectx <<'EOF'
_kubectx() {
    COMPREPLY=( $(compgen -W "$(kubectl config get-contexts -o name 2>/dev/null)" -- "${COMP_WORDS[COMP_CWORD]}") )
}
complete -F _kubectx kubectx
EOF

cat > /etc/bash_completion.d/kubens <<'EOF'
_kubens() {
    COMPREPLY=( $(compgen -W "$(kubectl get namespaces -o jsonpath='{.items[*].metadata.name}' 2>/dev/null)" -- "${COMP_WORDS[COMP_CWORD]}") )
}
complete -F _kubens kubens
EOF

# Install Krew
if [ "${INSTALL_KREW}" = "true" ]; then
    echo "Installing Krew..."

    KREW_VERSION=$(resolve_github_version "kubernetes-sigs/krew")

    TEMP_DIR=$(mktemp -d)
    cd "${TEMP_DIR}"

    curl -fsSL -o krew.tar.gz \
        "https://github.com/kubernetes-sigs/krew/releases/download/${KREW_VERSION}/krew-linux_${ARCHITECTURE}.tar.gz"
    tar -xzf krew.tar.gz

    ./krew-linux_${ARCHITECTURE} install krew

    # Make krew available
    export PATH="${PATH}:${HOME}/.krew/bin"

    # Add to profile
    cat >> /etc/profile.d/krew.sh <<'EOF'
export PATH="${PATH}:${HOME}/.krew/bin"
EOF

    # Install plugins
    if [ -n "${KREW_PLUGINS}" ]; then
        echo "Installing Krew plugins: ${KREW_PLUGINS}"
        IFS=',' read -ra PLUGINS <<< "${KREW_PLUGINS}"
        for plugin in "${PLUGINS[@]}"; do
            plugin=$(echo "${plugin}" | xargs)
            if [ -n "${plugin}" ]; then
                kubectl krew install "${plugin}" || echo "Warning: Could not install ${plugin}"
            fi
        done
    fi

    cd /
    rm -rf "${TEMP_DIR}"
fi

# Install K9s
if [ "${INSTALL_K9S}" = "true" ]; then
    echo "Installing K9s..."

    if [ "${K9S_VERSION}" = "latest" ]; then
        K9S_VERSION=$(resolve_github_version "derailed/k9s")
    fi
    K9S_VERSION="${K9S_VERSION#v}"

    TEMP_DIR=$(mktemp -d)
    cd "${TEMP_DIR}"

    # K9s uses different architecture naming
    K9S_ARCH="${ARCHITECTURE}"
    if [ "${ARCHITECTURE}" = "amd64" ]; then
        K9S_ARCH="amd64"
    elif [ "${ARCHITECTURE}" = "arm64" ]; then
        K9S_ARCH="arm64"
    fi

    curl -fsSL -o k9s.tar.gz \
        "https://github.com/derailed/k9s/releases/download/v${K9S_VERSION}/k9s_Linux_${K9S_ARCH}.tar.gz"
    tar -xzf k9s.tar.gz
    install -m 755 k9s /usr/local/bin/k9s

    cd /
    rm -rf "${TEMP_DIR}"
fi

# Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Kubernetes tools installation complete!"
kubectl version --client
kubectx --help | head -1
kubens --help | head -1
[ "${INSTALL_K9S}" = "true" ] && k9s version --short || true
