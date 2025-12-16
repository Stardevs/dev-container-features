#!/bin/bash
set -e

source dev-container-features-test-lib

check "terraform is installed" bash -c "which terraform"
check "terraform version" bash -c "terraform version"
check "tflint is installed" bash -c "which tflint"
check "tflint version" bash -c "tflint --version"

reportResults
