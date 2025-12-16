#!/bin/bash
set -e

source dev-container-features-test-lib

check "iptables is installed" bash -c "which iptables"
check "ipset is installed" bash -c "which ipset"
check "init-firewall.sh exists" bash -c "test -f /usr/local/bin/init-firewall.sh"
check "disable-firewall.sh exists" bash -c "test -f /usr/local/bin/disable-firewall.sh"
check "firewall command exists" bash -c "which firewall"
check "firewall.conf exists" bash -c "test -f /etc/firewall.conf"

reportResults
