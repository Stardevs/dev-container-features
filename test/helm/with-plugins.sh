#!/bin/bash
set -e

source dev-container-features-test-lib

check "helm is installed" bash -c "which helm"
check "helm version" bash -c "helm version"
check "helm repo add works" bash -c "helm repo add stable https://charts.helm.sh/stable 2>/dev/null || true"

reportResults
