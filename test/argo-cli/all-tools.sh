#!/bin/bash
set -e

source dev-container-features-test-lib

check "argocd is installed" bash -c "which argocd"
check "argocd version" bash -c "argocd version --client"

reportResults
