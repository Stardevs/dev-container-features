#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

echo "=== Container Entrypoint ==="

# Run firewall entrypoint (handles permissions + firewall)
if [ -f /usr/local/bin/firewall-entrypoint.sh ]; then
    /usr/local/bin/firewall-entrypoint.sh
else
    echo "Warning: firewall-entrypoint.sh not found, skipping firewall setup"
fi

# Add custom startup commands below
# Example:
# echo "Running custom setup..."
# /usr/local/bin/my-custom-script.sh

echo "=== Entrypoint complete ==="
