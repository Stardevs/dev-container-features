#!/bin/bash
set -e

source dev-container-features-test-lib

# File existence checks
check "iptables is installed" bash -c "which iptables"
check "ipset is installed" bash -c "which ipset"
check "init-firewall.sh exists" bash -c "test -f /usr/local/bin/init-firewall.sh"
check "disable-firewall.sh exists" bash -c "test -f /usr/local/bin/disable-firewall.sh"
check "firewall command exists" bash -c "which firewall"
check "firewall.conf exists" bash -c "test -f /etc/firewall.conf"
check "firewall-entrypoint.sh exists" bash -c "test -f /usr/local/bin/firewall-entrypoint.sh"
check "firewall-entrypoint.sh is executable" bash -c "test -x /usr/local/bin/firewall-entrypoint.sh"
check "firewall wrapper has entrypoint command" bash -c "grep -q 'entrypoint)' /usr/local/bin/firewall"

# Scoped sudo checks
check "sudoers file exists for scoped sudo" bash -c "test -f /etc/sudoers.d/firewall-feature"
check "sudoers file has correct permissions" bash -c "stat -c '%a' /etc/sudoers.d/firewall-feature | grep -q '440'"
check "sudoers contains vscode user" bash -c "grep -q 'vscode' /etc/sudoers.d/firewall-feature"

# Config checks
check "firewall.conf has entrypoint settings" bash -c "grep -q 'FIREWALL_ENABLE_ON_START' /etc/firewall.conf"
check "firewall.conf has remoteUser setting" bash -c "grep -q 'FIREWALL_WORKSPACE_USER' /etc/firewall.conf"

reportResults
