#!/bin/bash
set -e

source dev-container-features-test-lib

check "aws is installed" bash -c "which aws"
check "aws version" bash -c "aws --version"
check "aws help works" bash -c "aws help | head -5"

reportResults
