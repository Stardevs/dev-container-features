# eBPF Development Tools

This feature installs eBPF (Extended Berkeley Packet Filter) development and tracing tools.

## Usage

```json
{
    "features": {
        "ghcr.io/Stardevs/dev-container-features/ebpf:1": {}
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| installBcc | boolean | true | Install BCC tools |
| installBpftrace | boolean | true | Install bpftrace |
| installLibbpf | boolean | true | Install libbpf library |
| installBpfTool | boolean | true | Install bpftool |
| installPerfTools | boolean | true | Install perf tools |
| installKernelHeaders | boolean | true | Install kernel headers |

## Container Requirements

eBPF requires elevated privileges:

```json
{
    "privileged": true,
    "capAdd": ["SYS_ADMIN", "SYS_PTRACE", "NET_ADMIN", "BPF", "PERFMON"],
    "securityOpt": ["seccomp=unconfined"]
}
```

## Included Tools

### BCC (BPF Compiler Collection)

Pre-built tools in `/usr/share/bcc/tools/`:

```bash
# Trace new processes
sudo execsnoop

# Trace file opens
sudo opensnoop

# Trace TCP connections
sudo tcpconnect
sudo tcpaccept

# Disk I/O latency
sudo biolatency

# Function latency
sudo funclatency 'vfs_read'

# Memory allocation tracing
sudo memleak
```

### bpftrace

High-level tracing language:

```bash
# List probes
sudo bpftrace -l 'tracepoint:syscalls:*'

# One-liner: count syscalls by process
sudo bpftrace -e 'tracepoint:raw_syscalls:sys_enter { @[comm] = count(); }'

# Trace file opens
sudo bpftrace -e 'tracepoint:syscalls:sys_enter_openat { printf("%s %s\n", comm, str(args->filename)); }'

# Function timing
sudo bpftrace -e 'kprobe:vfs_read { @start[tid] = nsecs; } kretprobe:vfs_read /@start[tid]/ { @ns = hist(nsecs - @start[tid]); delete(@start[tid]); }'
```

### bpftool

Inspect and manage eBPF:

```bash
# List loaded programs
sudo bpftool prog list

# Show program details
sudo bpftool prog show id 1

# Dump program instructions
sudo bpftool prog dump xlated id 1

# List maps
sudo bpftool map list

# Dump map contents
sudo bpftool map dump id 1

# Show BTF info
sudo bpftool btf list
```

### perf

Performance analysis:

```bash
# CPU profiling
sudo perf record -g ./myprogram
sudo perf report

# System-wide tracing
sudo perf top

# Count events
sudo perf stat ./myprogram

# Trace syscalls
sudo perf trace ./myprogram
```

## Verification

Check your eBPF environment:

```bash
ebpf-check
```

## Writing eBPF Programs

### Using libbpf (C)

```c
#include <bpf/libbpf.h>
#include <bpf/bpf.h>

// Compile with:
// clang -O2 -target bpf -c prog.bpf.c -o prog.bpf.o
```

### Using BCC (Python)

```python
from bcc import BPF

b = BPF(text='''
int hello(void *ctx) {
    bpf_trace_printk("Hello, eBPF!\\n");
    return 0;
}
''')
b.attach_kprobe(event="sys_clone", fn_name="hello")
b.trace_print()
```

## Common Use Cases

### Network Debugging

```bash
# TCP retransmits
sudo tcpretrans

# TCP connection latency
sudo tcpconnlat

# Socket tracing
sudo sofdsnoop
```

### Performance Analysis

```bash
# CPU flame graphs
sudo profile -F 99 30 > out.perf
# Use flamegraph.pl to visualize

# Off-CPU analysis
sudo offcputime 30 > out.offcpu
```

### Security Monitoring

```bash
# Trace privilege escalation
sudo capable

# Monitor file access
sudo filetop

# Track process execution
sudo execsnoop
```

## Troubleshooting

### "Operation not permitted"

Ensure the container has proper capabilities:
- Run with `--privileged`
- Or add: `--cap-add=SYS_ADMIN --cap-add=BPF`

### "BPF not supported"

Check kernel support:
```bash
cat /proc/config.gz | gunzip | grep BPF
```

### Kernel headers not found

Install matching headers:
```bash
apt-get install linux-headers-$(uname -r)
```
