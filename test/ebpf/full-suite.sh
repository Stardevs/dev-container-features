#!/bin/bash
set -e

source dev-container-features-test-lib

check "clang is installed" bash -c "which clang"
check "llvm is installed" bash -c "which llvm-config"
check "ebpf-check exists" bash -c "test -f /usr/local/bin/ebpf-check"

# These may not be available depending on kernel support
check "bpftrace installed" bash -c "which bpftrace" || true
check "bpftool installed" bash -c "which bpftool" || true

reportResults
