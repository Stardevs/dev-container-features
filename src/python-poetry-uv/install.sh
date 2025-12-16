#!/bin/bash
set -e

PYTHON_VERSION="${PYTHONVERSION:-"3.12"}"
POETRY_VERSION="${POETRYVERSION:-"latest"}"
UV_VERSION="${UVVERSION:-"latest"}"
INSTALL_PIPX="${INSTALLPIPX:-"true"}"
ADDITIONAL_TOOLS="${ADDITIONALTOOLS:-""}"

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

echo "Installing Python ${PYTHON_VERSION} with Poetry and uv..."

# Install prerequisites
apt_get_update_if_needed
apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    build-essential \
    libssl-dev \
    libffi-dev \
    software-properties-common

# Install Python
if [ "${PYTHON_VERSION}" != "system" ]; then
    echo "Installing Python ${PYTHON_VERSION}..."

    # Check if we're on Ubuntu (deadsnakes PPA only works on Ubuntu)
    if grep -q "ubuntu" /etc/os-release 2>/dev/null; then
        # Add deadsnakes PPA for specific Python versions
        add-apt-repository -y ppa:deadsnakes/ppa
        apt-get update

        apt-get install -y --no-install-recommends \
            "python${PYTHON_VERSION}" \
            "python${PYTHON_VERSION}-venv" \
            "python${PYTHON_VERSION}-dev" \
            "python${PYTHON_VERSION}-distutils" 2>/dev/null || true

        # Set as default python3
        update-alternatives --install /usr/bin/python3 python3 "/usr/bin/python${PYTHON_VERSION}" 1 2>/dev/null || true
        update-alternatives --install /usr/bin/python python "/usr/bin/python${PYTHON_VERSION}" 1 2>/dev/null || true
    else
        # On Debian, try to install the requested version or fall back to system
        apt-get install -y --no-install-recommends \
            "python${PYTHON_VERSION}" \
            "python${PYTHON_VERSION}-venv" \
            "python${PYTHON_VERSION}-dev" 2>/dev/null || \
        apt-get install -y --no-install-recommends python3 python3-venv python3-dev
    fi
else
    apt-get install -y --no-install-recommends python3 python3-venv python3-dev
fi

# Ensure pip is available - try for both system and target Python
apt-get install -y --no-install-recommends python3-pip python3-venv 2>/dev/null || true
python3 -m ensurepip --upgrade 2>/dev/null || true

# If we installed a specific version, ensure pip works for it
if [ "${PYTHON_VERSION}" != "system" ] && command -v "python${PYTHON_VERSION}" >/dev/null 2>&1; then
    "python${PYTHON_VERSION}" -m ensurepip --upgrade 2>/dev/null || true
fi

# Install pipx
if [ "${INSTALL_PIPX}" = "true" ]; then
    echo "Installing pipx..."
    # Use the target Python version if available
    TARGET_PYTHON="python3"
    if [ "${PYTHON_VERSION}" != "system" ] && command -v "python${PYTHON_VERSION}" >/dev/null 2>&1; then
        TARGET_PYTHON="python${PYTHON_VERSION}"
    fi

    ${TARGET_PYTHON} -m pip install --break-system-packages pipx 2>/dev/null || \
    ${TARGET_PYTHON} -m pip install pipx 2>/dev/null || \
    python3 -m pip install --break-system-packages pipx 2>/dev/null || \
    python3 -m pip install pipx

    ${TARGET_PYTHON} -m pipx ensurepath 2>/dev/null || python3 -m pipx ensurepath

    # Make pipx available system-wide
    PIPX_BIN="/root/.local/bin"
    if [ -d "${PIPX_BIN}" ]; then
        cp -r "${PIPX_BIN}"/* /usr/local/bin/ 2>/dev/null || true
    fi
fi

# Install Poetry
if [ "${POETRY_VERSION}" != "none" ]; then
    echo "Installing Poetry..."

    if [ "${POETRY_VERSION}" = "latest" ]; then
        curl -sSL https://install.python-poetry.org | python3 -
    else
        curl -sSL https://install.python-poetry.org | python3 - --version "${POETRY_VERSION}"
    fi

    # Make poetry available system-wide
    if [ -f "/root/.local/bin/poetry" ]; then
        cp /root/.local/bin/poetry /usr/local/bin/poetry
        chmod +x /usr/local/bin/poetry
    fi

    # Setup completions
    mkdir -p /etc/bash_completion.d
    /usr/local/bin/poetry completions bash > /etc/bash_completion.d/poetry 2>/dev/null || true

    if command -v zsh >/dev/null 2>&1; then
        mkdir -p /usr/local/share/zsh/site-functions
        /usr/local/bin/poetry completions zsh > /usr/local/share/zsh/site-functions/_poetry 2>/dev/null || true
    fi
fi

# Install uv
if [ "${UV_VERSION}" != "none" ]; then
    echo "Installing uv..."

    if [ "${UV_VERSION}" = "latest" ]; then
        curl -LsSf https://astral.sh/uv/install.sh | sh
    else
        curl -LsSf "https://astral.sh/uv/${UV_VERSION}/install.sh" | sh
    fi

    # Make uv available system-wide
    if [ -f "/root/.local/bin/uv" ]; then
        cp /root/.local/bin/uv /usr/local/bin/uv
        cp /root/.local/bin/uvx /usr/local/bin/uvx 2>/dev/null || true
        chmod +x /usr/local/bin/uv
        chmod +x /usr/local/bin/uvx 2>/dev/null || true
    fi

    # Also check cargo bin
    if [ -f "/root/.cargo/bin/uv" ]; then
        cp /root/.cargo/bin/uv /usr/local/bin/uv
        cp /root/.cargo/bin/uvx /usr/local/bin/uvx 2>/dev/null || true
        chmod +x /usr/local/bin/uv
        chmod +x /usr/local/bin/uvx 2>/dev/null || true
    fi

    # Setup completions
    mkdir -p /etc/bash_completion.d
    /usr/local/bin/uv generate-shell-completion bash > /etc/bash_completion.d/uv 2>/dev/null || true

    if command -v zsh >/dev/null 2>&1; then
        mkdir -p /usr/local/share/zsh/site-functions
        /usr/local/bin/uv generate-shell-completion zsh > /usr/local/share/zsh/site-functions/_uv 2>/dev/null || true
    fi
fi

# Install additional tools via pipx
if [ -n "${ADDITIONAL_TOOLS}" ] && [ "${INSTALL_PIPX}" = "true" ]; then
    echo "Installing additional tools: ${ADDITIONAL_TOOLS}"
    IFS=',' read -ra TOOLS <<< "${ADDITIONAL_TOOLS}"
    for tool in "${TOOLS[@]}"; do
        tool=$(echo "${tool}" | xargs)  # Trim whitespace
        if [ -n "${tool}" ]; then
            echo "Installing ${tool}..."
            pipx install "${tool}" || echo "Warning: Could not install ${tool}"
        fi
    done
fi

# Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "Python installation complete!"
python3 --version
[ "${POETRY_VERSION}" != "none" ] && poetry --version || true
[ "${UV_VERSION}" != "none" ] && uv --version || true
