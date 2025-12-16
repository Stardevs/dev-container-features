#!/bin/bash
set -e

source dev-container-features-test-lib

check "gcloud is installed" bash -c "which gcloud"
check "gcloud version" bash -c "gcloud version"
check "gcloud components list" bash -c "gcloud components list --format='table(id)' | head -10"

reportResults
