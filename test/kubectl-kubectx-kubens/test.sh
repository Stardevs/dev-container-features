#!/bin/bash
set -e

source dev-container-features-test-lib

check "kubectl is installed" bash -c "which kubectl"
check "kubectl version" bash -c "kubectl version --client"
check "kubectx is installed" bash -c "which kubectx"
check "kubens is installed" bash -c "which kubens"

reportResults
