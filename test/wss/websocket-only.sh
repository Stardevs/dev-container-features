#!/bin/bash
set -e

source dev-container-features-test-lib

# websocket-only scenario: only wscat and websocat are installed
check "wscat is installed" bash -c "which wscat"
check "websocat is installed" bash -c "which websocat"
check "websocat version" bash -c "websocat --version"

reportResults
