#!/bin/bash
set -e

source dev-container-features-test-lib

check "psql is installed" bash -c "which psql"
check "psql version" bash -c "psql --version"
check "pg_dump is installed" bash -c "which pg_dump"

reportResults
