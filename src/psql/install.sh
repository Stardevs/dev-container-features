#!/bin/bash
set -e

VERSION="${VERSION:-"latest"}"
INSTALL_SERVER="${INSTALLSERVER:-"false"}"
INSTALL_CONTRIB="${INSTALLCONTRIB:-"true"}"
INSTALL_PGCLI="${INSTALLPGCLI:-"false"}"

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

echo "Installing PostgreSQL client..."

# Install prerequisites
apt_get_update_if_needed
apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    lsb-release

# Add PostgreSQL official repository
curl -fsSL https://www.postgresql.org/media/keys/ACCC4CF8.asc | gpg --dearmor -o /usr/share/keyrings/postgresql-keyring.gpg
chmod 644 /usr/share/keyrings/postgresql-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/postgresql-keyring.gpg] http://apt.postgresql.org/pub/repos/apt $(lsb_release -cs)-pgdg main" | \
    tee /etc/apt/sources.list.d/pgdg.list

apt-get update

# Determine version
if [ "${VERSION}" = "latest" ]; then
    # Get latest version number
    PG_VERSION=$(apt-cache search "^postgresql-[0-9]+$" | sort -t- -k2 -n | tail -1 | sed 's/postgresql-\([0-9]*\).*/\1/')
else
    PG_VERSION="${VERSION}"
fi

echo "Installing PostgreSQL ${PG_VERSION} client..."

# Install PostgreSQL client
apt-get install -y --no-install-recommends "postgresql-client-${PG_VERSION}"

# Install contrib utilities
if [ "${INSTALL_CONTRIB}" = "true" ]; then
    apt-get install -y --no-install-recommends "postgresql-contrib" 2>/dev/null || \
    apt-get install -y --no-install-recommends "postgresql-${PG_VERSION}-contrib" 2>/dev/null || true
fi

# Install server
if [ "${INSTALL_SERVER}" = "true" ]; then
    echo "Installing PostgreSQL ${PG_VERSION} server..."
    apt-get install -y --no-install-recommends "postgresql-${PG_VERSION}"

    # Disable auto-start (user can start manually)
    systemctl disable postgresql 2>/dev/null || true
    update-rc.d postgresql disable 2>/dev/null || true
fi

# Install pgcli (enhanced CLI)
if [ "${INSTALL_PGCLI}" = "true" ]; then
    echo "Installing pgcli..."

    # Check if pip is available
    if command -v pip3 >/dev/null 2>&1; then
        pip3 install --break-system-packages pgcli 2>/dev/null || pip3 install pgcli
    else
        apt-get install -y --no-install-recommends python3-pip
        pip3 install --break-system-packages pgcli 2>/dev/null || pip3 install pgcli
    fi
fi

# Setup bash completion for psql
mkdir -p /etc/bash_completion.d
if [ -f /usr/share/bash-completion/completions/psql ]; then
    ln -sf /usr/share/bash-completion/completions/psql /etc/bash_completion.d/psql
else
    # Create basic completion if not provided by package
    cat > /etc/bash_completion.d/psql <<'EOF'
_psql() {
    local cur="${COMP_WORDS[COMP_CWORD]}"
    local prev="${COMP_WORDS[COMP_CWORD-1]}"

    case "${prev}" in
        -h|--host)
            COMPREPLY=($(compgen -A hostname -- "${cur}"))
            return 0
            ;;
        -d|--dbname|-U|--username)
            return 0
            ;;
        -f|--file|-o|--output|-L|--log-file)
            COMPREPLY=($(compgen -f -- "${cur}"))
            return 0
            ;;
    esac

    if [[ "${cur}" == -* ]]; then
        local opts="-h --host -p --port -U --username -d --dbname -c --command -f --file -l --list -v --variable -X --no-psqlrc -a --echo-all -b --echo-errors -e --echo-queries -E --echo-hidden -q --quiet -s --single-step -S --single-line"
        COMPREPLY=($(compgen -W "${opts}" -- "${cur}"))
    fi
}
complete -F _psql psql
EOF
fi

# Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "PostgreSQL client installation complete!"
psql --version
[ "${INSTALL_PGCLI}" = "true" ] && pgcli --version || true
