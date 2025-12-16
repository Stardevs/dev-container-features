#!/bin/bash
set -e

source dev-container-features-test-lib

# without-tools scenario: only Go and golangci-lint, no additional tools
check "go is installed" bash -c "which go"
check "go version" bash -c "go version"
check "golangci-lint is installed" bash -c "which golangci-lint"
check "golangci-lint version" bash -c "golangci-lint --version"
# gopls should NOT be installed in this scenario

reportResults
