#!/bin/bash
set -e

source dev-container-features-test-lib

check "go is installed" bash -c "which go"
check "go version" bash -c "go version"
check "golangci-lint is installed" bash -c "which golangci-lint"
check "golangci-lint version" bash -c "golangci-lint --version"
check "gopls is installed" bash -c "which gopls"

reportResults
