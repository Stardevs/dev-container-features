# PostgreSQL Client (psql)

This feature installs PostgreSQL client tools for interacting with PostgreSQL databases.

## Usage

```json
{
    "features": {
        "ghcr.io/Stardevs/dev-container-features/psql:1": {}
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| version | string | latest | PostgreSQL version (13-17) |
| installServer | boolean | false | Install PostgreSQL server |
| installContrib | boolean | true | Install contrib utilities |
| installPgcli | boolean | false | Install pgcli (enhanced CLI) |

## Examples

### With local PostgreSQL server

```json
{
    "features": {
        "ghcr.io/Stardevs/dev-container-features/psql:1": {
            "installServer": true
        }
    }
}
```

### With pgcli for better experience

```json
{
    "features": {
        "ghcr.io/Stardevs/dev-container-features/psql:1": {
            "installPgcli": true
        }
    }
}
```

### Specific version

```json
{
    "features": {
        "ghcr.io/Stardevs/dev-container-features/psql:1": {
            "version": "16"
        }
    }
}
```

## psql Usage

### Connect to PostgreSQL

```bash
# Connect to local database
psql -d mydatabase

# Connect to remote database
psql -h hostname -p 5432 -U username -d database

# Connect with URL
psql "postgresql://user:password@hostname:5432/database"

# Connect with SSL
psql "postgresql://user:password@hostname:5432/database?sslmode=require"
```

### Common Commands

```bash
# List databases
psql -l

# Execute single command
psql -d database -c "SELECT * FROM users LIMIT 10;"

# Execute SQL file
psql -d database -f script.sql

# Output to file
psql -d database -c "SELECT * FROM users;" -o output.txt

# CSV output
psql -d database -c "COPY (SELECT * FROM users) TO STDOUT WITH CSV HEADER;"
```

### Interactive Mode

```bash
# Start interactive mode
psql -d database

# In interactive mode:
database=# \l              -- List databases
database=# \c otherdb      -- Connect to another database
database=# \dt             -- List tables
database=# \d tablename    -- Describe table
database=# \du             -- List users/roles
database=# \dn             -- List schemas
database=# \df             -- List functions
database=# \di             -- List indexes
database=# \x              -- Toggle expanded display
database=# \timing         -- Toggle query timing
database=# \q              -- Quit
```

### Backup and Restore

```bash
# Dump database
pg_dump -h hostname -U user database > backup.sql

# Dump with compression
pg_dump -h hostname -U user -Fc database > backup.dump

# Dump specific tables
pg_dump -h hostname -U user -t table1 -t table2 database > tables.sql

# Dump schema only
pg_dump -h hostname -U user --schema-only database > schema.sql

# Dump data only
pg_dump -h hostname -U user --data-only database > data.sql

# Restore from SQL file
psql -h hostname -U user -d database < backup.sql

# Restore from custom format
pg_restore -h hostname -U user -d database backup.dump

# Restore specific table
pg_restore -h hostname -U user -d database -t tablename backup.dump
```

## pgcli Usage

pgcli provides auto-completion and syntax highlighting:

```bash
# Connect with pgcli
pgcli -h hostname -U user -d database

# Features:
# - Auto-completion for tables, columns, keywords
# - Syntax highlighting
# - Multi-line editing
# - History search with Ctrl+R
```

## Environment Variables

```bash
# Set default connection parameters
export PGHOST=hostname
export PGPORT=5432
export PGUSER=username
export PGPASSWORD=password
export PGDATABASE=database

# Then simply:
psql
```

## .pgpass File

Store passwords securely in `~/.pgpass`:

```
hostname:port:database:username:password
```

```bash
chmod 600 ~/.pgpass
```

## Local Development Server

If `installServer` is true:

```bash
# Start PostgreSQL server
sudo service postgresql start

# Create user
sudo -u postgres createuser -P myuser

# Create database
sudo -u postgres createdb -O myuser mydatabase

# Access as postgres user
sudo -u postgres psql
```
