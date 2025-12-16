#!/bin/bash
set -e

source dev-container-features-test-lib

# poetry-only scenario: only Poetry, no UV
check "python3 is installed" bash -c "which python3"
check "python3 version" bash -c "python3 --version"
check "poetry is installed" bash -c "which poetry"
check "poetry version" bash -c "poetry --version"
# uv should NOT be installed in this scenario

reportResults
