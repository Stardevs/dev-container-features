#!/bin/bash
set -e

source dev-container-features-test-lib

check "istioctl is installed" bash -c "which istioctl"
check "istioctl version" bash -c "istioctl version --remote=false"

reportResults
