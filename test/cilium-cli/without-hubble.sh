#!/bin/bash
set -e

source dev-container-features-test-lib

check "cilium is installed" bash -c "which cilium"
check "cilium version" bash -c "cilium version --client"
check "hubble is installed" bash -c "which hubble"
check "hubble version" bash -c "hubble version"

reportResults
