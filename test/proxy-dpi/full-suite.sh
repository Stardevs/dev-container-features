#!/bin/bash
set -e

source dev-container-features-test-lib

check "mitmproxy is installed" bash -c "which mitmproxy"
check "mitmproxy version" bash -c "mitmproxy --version"
check "tshark is installed" bash -c "which tshark"
check "tcpdump is installed" bash -c "which tcpdump"
check "ngrep is installed" bash -c "which ngrep"
check "netinspect exists" bash -c "test -f /usr/local/bin/netinspect"

reportResults
