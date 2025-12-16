#!/bin/bash
set -e

source dev-container-features-test-lib

# cloudflare-only scenario: only cloudflared and wrangler are installed
check "cloudflared is installed" bash -c "which cloudflared"
check "cloudflared version" bash -c "cloudflared --version"
check "wrangler is installed" bash -c "which wrangler"

reportResults
