#!/bin/bash
set -e

source dev-container-features-test-lib

# packet-capture scenario: only packet capture tools, no mitmproxy
check "tshark is installed" bash -c "which tshark"
check "tcpdump is installed" bash -c "which tcpdump"
check "ngrep is installed" bash -c "which ngrep"
# mitmproxy should NOT be installed in this scenario

reportResults
