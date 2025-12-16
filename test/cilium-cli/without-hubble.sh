#!/bin/bash
set -e

source dev-container-features-test-lib

# without-hubble scenario: only cilium CLI, no hubble
check "cilium is installed" bash -c "which cilium"
check "cilium version" bash -c "cilium version --client"
# hubble should NOT be installed in this scenario

reportResults
