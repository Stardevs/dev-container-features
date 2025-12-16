#!/bin/bash
set -e

source dev-container-features-test-lib

check "wg is installed" bash -c "which wg"
check "wg version" bash -c "wg --version"
check "wg-quick is installed" bash -c "which wg-quick"

reportResults
