#!/bin/bash
set -e

source dev-container-features-test-lib

check "wscat is installed" bash -c "which wscat"
check "websocat is installed" bash -c "which websocat"
check "websocat version" bash -c "websocat --version"
check "wstunnel is installed" bash -c "which wstunnel"
check "wstunnel version" bash -c "wstunnel --version"
check "cloudflared is installed" bash -c "which cloudflared"
check "cloudflared version" bash -c "cloudflared --version"
check "wrangler is installed" bash -c "which wrangler"

reportResults
