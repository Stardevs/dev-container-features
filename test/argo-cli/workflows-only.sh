#!/bin/bash
set -e

source dev-container-features-test-lib

# workflows-only scenario: only Argo Workflows CLI, no Argo CD
check "argo is installed" bash -c "which argo"
check "argo version" bash -c "argo version --client"
# argocd should NOT be installed in this scenario

reportResults
