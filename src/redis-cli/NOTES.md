# Redis CLI

This feature installs Redis CLI tools for interacting with Redis databases.

## Usage

```json
{
    "features": {
        "ghcr.io/Stardevs/dev-container-features/redis-cli:1": {}
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| version | string | latest | Redis version |
| installServer | boolean | false | Install redis-server for local development |
| installRedisTools | boolean | true | Install benchmark and check tools |

## Examples

### With local Redis server

```json
{
    "features": {
        "ghcr.io/Stardevs/dev-container-features/redis-cli:1": {
            "installServer": true
        }
    }
}
```

### Specific version

```json
{
    "features": {
        "ghcr.io/Stardevs/dev-container-features/redis-cli:1": {
            "version": "7.2"
        }
    }
}
```

## redis-cli Usage

### Connect to Redis

```bash
# Connect to local Redis
redis-cli

# Connect to remote Redis
redis-cli -h hostname -p 6379

# Connect with password
redis-cli -h hostname -a password

# Connect with URL
redis-cli -u redis://user:password@hostname:6379/0

# Connect to Redis cluster
redis-cli -c -h hostname -p 6379
```

### Common Commands

```bash
# Set and get values
redis-cli SET mykey "Hello"
redis-cli GET mykey

# List keys
redis-cli KEYS "*"

# Check server info
redis-cli INFO

# Monitor commands in real-time
redis-cli MONITOR

# Check latency
redis-cli --latency

# Scan keys (production-safe)
redis-cli SCAN 0 MATCH "prefix:*" COUNT 100

# Pub/Sub
redis-cli SUBSCRIBE channel
redis-cli PUBLISH channel "message"
```

### Interactive Mode

```bash
# Start interactive mode
redis-cli

# In interactive mode:
127.0.0.1:6379> SET foo bar
OK
127.0.0.1:6379> GET foo
"bar"
127.0.0.1:6379> HSET user:1 name "John" age 30
(integer) 2
127.0.0.1:6379> HGETALL user:1
1) "name"
2) "John"
3) "age"
4) "30"
```

### Redis Tools

```bash
# Benchmark Redis performance
redis-benchmark -h localhost -p 6379 -n 10000

# Check AOF file
redis-check-aof appendonly.aof

# Check RDB file
redis-check-rdb dump.rdb
```

## Local Development Server

If `installServer` is true:

```bash
# Start Redis server
redis-server

# Start with custom config
redis-server /path/to/redis.conf

# Start with specific port
redis-server --port 6380

# Start in background
redis-server --daemonize yes
```

## TLS/SSL Connection

```bash
# Connect with TLS
redis-cli --tls -h hostname -p 6379

# With certificates
redis-cli --tls \
    --cert /path/to/client.crt \
    --key /path/to/client.key \
    --cacert /path/to/ca.crt \
    -h hostname -p 6379
```
