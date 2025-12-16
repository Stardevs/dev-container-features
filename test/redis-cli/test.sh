#!/bin/bash
set -e

source dev-container-features-test-lib

check "redis-cli is installed" bash -c "which redis-cli"
check "redis-cli version" bash -c "redis-cli --version"

reportResults
