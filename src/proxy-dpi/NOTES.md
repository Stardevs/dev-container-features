# Proxy and Deep Packet Inspection Tools

This feature installs proxy and deep packet inspection tools for network debugging and analysis.

## Usage

```json
{
    "features": {
        "ghcr.io/Stardevs/dev-container-features/proxy-dpi:1": {}
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| installMitmproxy | boolean | true | Install mitmproxy |
| mitmproxyVersion | string | latest | mitmproxy version |
| installTshark | boolean | true | Install tshark/Wireshark CLI |
| installSquid | boolean | false | Install Squid transparent proxy |
| installNgrep | boolean | true | Install ngrep |
| installTcpdump | boolean | true | Install tcpdump |
| installSslsplit | boolean | false | Install SSLsplit |

## Examples

### Full network debugging suite

```json
{
    "features": {
        "ghcr.io/Stardevs/dev-container-features/proxy-dpi:1": {
            "installSquid": true,
            "installSslsplit": true
        }
    }
}
```

### Minimal setup

```json
{
    "features": {
        "ghcr.io/Stardevs/dev-container-features/proxy-dpi:1": {
            "installMitmproxy": true,
            "installTshark": false,
            "installSquid": false
        }
    }
}
```

## Container Requirements

```json
{
    "privileged": true,
    "capAdd": ["NET_ADMIN", "NET_RAW"]
}
```

## Quick Start

Use the `netinspect` helper:

```bash
# Capture HTTP traffic
netinspect http

# Capture DNS queries
netinspect dns

# Capture traffic on specific port
netinspect tcp 8080

# Capture all traffic
netinspect all
```

## mitmproxy

Interactive HTTPS proxy for debugging APIs:

### Basic Usage

```bash
# Start interactive proxy
mitmproxy

# Start web interface
mitmweb

# Start as transparent proxy
mitmproxy --mode transparent

# Dump mode (command line)
mitmdump -w traffic.flow
```

### Intercept Application Traffic

```bash
# Set proxy environment variables
export HTTP_PROXY=http://localhost:8080
export HTTPS_PROXY=http://localhost:8080

# Run your application
curl https://api.example.com

# Or for a specific command
HTTP_PROXY=http://localhost:8080 curl https://api.example.com
```

### SSL/TLS Interception

```bash
# Generate CA certificate
mitmproxy-setup

# Trust the CA (copy to your system)
cat ~/.mitmproxy/mitmproxy-ca-cert.pem

# Use with curl
curl --cacert ~/.mitmproxy/mitmproxy-ca-cert.pem \
     --proxy http://localhost:8080 \
     https://example.com
```

### Scripting

```python
# script.py
from mitmproxy import http

def request(flow: http.HTTPFlow):
    # Modify requests
    flow.request.headers["X-Custom"] = "value"

def response(flow: http.HTTPFlow):
    # Log responses
    print(f"{flow.request.url}: {flow.response.status_code}")
```

```bash
mitmproxy -s script.py
```

## tshark (Wireshark CLI)

Command-line packet analyzer:

### Capture Traffic

```bash
# Capture on any interface
sudo tshark -i any

# Capture specific interface
sudo tshark -i eth0

# Capture with filter
sudo tshark -i any -f "port 80"

# Save to file
sudo tshark -i any -w capture.pcap
```

### Analyze Traffic

```bash
# Read pcap file
tshark -r capture.pcap

# Filter by protocol
tshark -r capture.pcap -Y "http"

# Show specific fields
tshark -r capture.pcap -Y "http.request" \
    -T fields -e http.host -e http.request.uri

# Follow TCP stream
tshark -r capture.pcap -q -z follow,tcp,ascii,0
```

### Display Filters

```bash
# HTTP requests
tshark -Y "http.request"

# DNS queries
tshark -Y "dns.flags.response == 0"

# TCP SYN packets
tshark -Y "tcp.flags.syn == 1 and tcp.flags.ack == 0"

# Specific IP
tshark -Y "ip.addr == 192.168.1.1"
```

## tcpdump

Classic packet capture:

```bash
# Capture all traffic
sudo tcpdump -i any

# Capture specific port
sudo tcpdump -i any port 443

# Capture with content
sudo tcpdump -i any -A port 80

# Save to file
sudo tcpdump -i any -w capture.pcap

# Read from file
tcpdump -r capture.pcap
```

## ngrep

Network grep for packet content:

```bash
# Search for string in HTTP
sudo ngrep -W byline -d any "password" port 80

# Search in any traffic
sudo ngrep -d any "error"

# Case insensitive
sudo ngrep -i -d any "api"

# Show packet payload
sudo ngrep -W byline -d any port 80
```

## Squid Transparent Proxy

For transparent HTTP/HTTPS proxying:

```bash
# Setup Squid
sudo squid-setup

# Start Squid
sudo squid -f /etc/squid/squid-transparent.conf

# Redirect traffic (requires iptables)
sudo iptables -t nat -A OUTPUT -p tcp --dport 80 -j REDIRECT --to-port 3128
sudo iptables -t nat -A OUTPUT -p tcp --dport 443 -j REDIRECT --to-port 3129

# View logs
tail -f /var/log/squid/access.log
```

## SSLsplit

SSL/TLS interception:

```bash
# Setup SSLsplit
sudo sslsplit-setup

# Start SSLsplit
sudo sslsplit -D \
    -k /etc/sslsplit/ca.key \
    -c /etc/sslsplit/ca.crt \
    -l connections.log \
    -S /tmp/sslsplit \
    ssl 0.0.0.0 8443

# Redirect traffic
sudo iptables -t nat -A OUTPUT -p tcp --dport 443 -j REDIRECT --to-port 8443
```

## Common Use Cases

### Debug API Calls

```bash
# Start mitmproxy
mitmproxy -p 8080

# In another terminal, make API calls through proxy
HTTP_PROXY=http://localhost:8080 HTTPS_PROXY=http://localhost:8080 \
    curl https://api.example.com/endpoint
```

### Capture Specific Application Traffic

```bash
# Capture only traffic to specific host
sudo tshark -i any -Y "ip.host contains api.example.com"
```

### Analyze Performance

```bash
# Show TCP retransmissions
sudo tshark -i any -Y "tcp.analysis.retransmission"

# Show slow responses
sudo tshark -i any -Y "http.time > 1"
```
