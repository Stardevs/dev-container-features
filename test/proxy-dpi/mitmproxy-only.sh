#!/bin/bash
set -e

source dev-container-features-test-lib

# mitmproxy-only scenario: only mitmproxy, no packet capture tools
check "mitmproxy is installed" bash -c "which mitmproxy"
check "mitmproxy version" bash -c "mitmproxy --version"
# tshark, tcpdump, ngrep should NOT be installed in this scenario

reportResults
