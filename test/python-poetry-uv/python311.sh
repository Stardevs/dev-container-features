#!/bin/bash
set -e

source dev-container-features-test-lib

check "python3 is installed" bash -c "which python3"
check "python3 version" bash -c "python3 --version"
check "poetry is installed" bash -c "which poetry"
check "poetry version" bash -c "poetry --version"
check "uv is installed" bash -c "which uv"
check "uv version" bash -c "uv --version"

reportResults
