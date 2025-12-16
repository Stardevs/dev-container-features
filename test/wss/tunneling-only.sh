#!/bin/bash
set -e

source dev-container-features-test-lib

# tunneling-only scenario: wstunnel and cloudflared are installed
check "wstunnel is installed" bash -c "which wstunnel"
check "wstunnel version" bash -c "wstunnel --version"
check "cloudflared is installed" bash -c "which cloudflared"
check "cloudflared version" bash -c "cloudflared --version"

reportResults
