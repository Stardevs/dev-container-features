#!/bin/bash
set -e

INSTALL_BCC="${INSTALLBCC:-"true"}"
INSTALL_BPFTRACE="${INSTALLBPFTRACE:-"true"}"
INSTALL_LIBBPF="${INSTALLLIBBPF:-"true"}"
INSTALL_BPFTOOL="${INSTALLBPFTOOL:-"true"}"
INSTALL_PERF_TOOLS="${INSTALLPERFTOOLS:-"true"}"
INSTALL_KERNEL_HEADERS="${INSTALLKERNELHEADERS:-"true"}"

# Ensure running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "ERROR: Script must be run as root."
    exit 1
fi

# Architecture detection
detect_arch() {
    local arch
    arch="$(uname -m)"
    case "${arch}" in
        x86_64) echo "amd64" ;;
        aarch64 | arm64) echo "arm64" ;;
        *) echo "ERROR: Unsupported architecture: ${arch}" >&2; exit 1 ;;
    esac
}

# Helper functions
apt_get_update_if_needed() {
    if [ ! -d "/var/lib/apt/lists" ] || [ "$(ls /var/lib/apt/lists/ 2>/dev/null | wc -l)" = "0" ]; then
        apt-get update
    fi
}

export DEBIAN_FRONTEND=noninteractive

echo "Installing eBPF development tools..."

# Install prerequisites
apt_get_update_if_needed
apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    software-properties-common \
    build-essential \
    git \
    cmake \
    pkg-config \
    libelf-dev \
    zlib1g-dev \
    llvm \
    clang

# Install kernel headers
if [ "${INSTALL_KERNEL_HEADERS}" = "true" ]; then
    echo "Installing kernel headers..."
    apt-get install -y --no-install-recommends \
        linux-headers-generic 2>/dev/null || \
    apt-get install -y --no-install-recommends \
        "linux-headers-$(uname -r)" 2>/dev/null || \
    echo "WARNING: Could not install kernel headers for current kernel. eBPF programs may not compile."
fi

# Install BCC (BPF Compiler Collection)
if [ "${INSTALL_BCC}" = "true" ]; then
    echo "Installing BCC tools..."

    # Try to install from packages first
    apt_get_update_if_needed
    if apt-get install -y --no-install-recommends \
        bpfcc-tools \
        libbpfcc \
        libbpfcc-dev \
        python3-bpfcc 2>/dev/null; then
        echo "BCC installed from packages"
    else
        # Fallback: try bcc package
        apt-get install -y --no-install-recommends \
            bcc \
            bcc-tools \
            libbcc \
            python3-bcc 2>/dev/null || \
        echo "WARNING: BCC packages not available. May need to build from source."
    fi
fi

# Install bpftrace
if [ "${INSTALL_BPFTRACE}" = "true" ]; then
    echo "Installing bpftrace..."
    apt-get install -y --no-install-recommends bpftrace || \
    echo "WARNING: bpftrace package not available"
fi

# Install libbpf
if [ "${INSTALL_LIBBPF}" = "true" ]; then
    echo "Installing libbpf..."
    apt-get install -y --no-install-recommends \
        libbpf-dev \
        libbpf1 2>/dev/null || \
    apt-get install -y --no-install-recommends \
        libbpf-dev \
        libbpf0 2>/dev/null || \
    echo "WARNING: libbpf packages not available"
fi

# Install bpftool
if [ "${INSTALL_BPFTOOL}" = "true" ]; then
    echo "Installing bpftool..."
    apt-get install -y --no-install-recommends \
        bpftool 2>/dev/null || \
    apt-get install -y --no-install-recommends \
        linux-tools-common \
        linux-tools-generic 2>/dev/null || \
    echo "WARNING: bpftool not available in packages"
fi

# Install perf and performance tools
if [ "${INSTALL_PERF_TOOLS}" = "true" ]; then
    echo "Installing perf tools..."
    apt-get install -y --no-install-recommends \
        linux-tools-common \
        linux-tools-generic 2>/dev/null || \
    apt-get install -y --no-install-recommends \
        linux-perf 2>/dev/null || \
    echo "WARNING: perf tools not available"

    # Additional tracing tools
    apt-get install -y --no-install-recommends \
        trace-cmd \
        strace \
        ltrace 2>/dev/null || true
fi

# Create helpful wrapper scripts
cat > /usr/local/bin/ebpf-check << 'EOF'
#!/bin/bash
echo "=== eBPF System Check ==="
echo ""

echo "Kernel version: $(uname -r)"
echo ""

echo "eBPF support:"
if [ -d /sys/fs/bpf ]; then
    echo "  /sys/fs/bpf: mounted"
else
    echo "  /sys/fs/bpf: NOT mounted (try: mount -t bpf bpf /sys/fs/bpf)"
fi

if [ -f /proc/config.gz ]; then
    echo "  CONFIG_BPF: $(zcat /proc/config.gz 2>/dev/null | grep CONFIG_BPF= || echo 'unknown')"
    echo "  CONFIG_BPF_SYSCALL: $(zcat /proc/config.gz 2>/dev/null | grep CONFIG_BPF_SYSCALL || echo 'unknown')"
fi
echo ""

echo "Installed tools:"
command -v bpftrace >/dev/null && echo "  bpftrace: $(bpftrace --version 2>/dev/null || echo 'installed')"
command -v bpftool >/dev/null && echo "  bpftool: $(bpftool version 2>/dev/null | head -1 || echo 'installed')"
command -v perf >/dev/null && echo "  perf: installed"
command -v trace-cmd >/dev/null && echo "  trace-cmd: installed"
[ -d /usr/share/bcc/tools ] && echo "  BCC tools: /usr/share/bcc/tools/"
echo ""

echo "Capabilities needed for eBPF:"
echo "  CAP_SYS_ADMIN, CAP_BPF, CAP_PERFMON, CAP_SYS_PTRACE"
echo ""
echo "To run most eBPF tools, use: sudo <tool>"
EOF
chmod +x /usr/local/bin/ebpf-check

# Cleanup
apt-get clean
rm -rf /var/lib/apt/lists/*

echo "eBPF tools installation complete!"
echo ""
echo "Run 'ebpf-check' to verify your eBPF environment"
echo ""
[ "${INSTALL_BCC}" = "true" ] && echo "BCC tools: /usr/share/bcc/tools/ (if installed)"
[ "${INSTALL_BPFTRACE}" = "true" ] && command -v bpftrace >/dev/null && echo "bpftrace: $(bpftrace --version 2>/dev/null || echo 'installed')"
[ "${INSTALL_BPFTOOL}" = "true" ] && command -v bpftool >/dev/null && echo "bpftool: installed"
