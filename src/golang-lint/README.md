
# Go with golangci-lint (golang-lint)

Installs Go programming language with golangci-lint and common Go development tools.

## Example Usage

```json
"features": {
    "ghcr.io/Stardevs/dev-container-features/golang-lint:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| goVersion | Go version to install ('none' if Go is already installed) | string | latest |
| golangciLintVersion | golangci-lint version to install | string | latest |
| installGoTools | Install common Go tools (gopls, dlv, staticcheck, etc.) | boolean | true |
| goPath | GOPATH directory | string | /go |

## Customizations

### VS Code Extensions

- `golang.Go`

# Go with golangci-lint

This feature installs Go with golangci-lint and common development tools.

## Usage

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/golang-lint:1": {}
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| goVersion | string | latest | Go version (e.g., "1.23", "none" to skip) |
| golangciLintVersion | string | latest | golangci-lint version |
| installGoTools | boolean | true | Install common Go tools |
| goPath | string | /go | GOPATH directory |

## Examples

### Install specific versions

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/golang-lint:1": {
            "goVersion": "1.22",
            "golangciLintVersion": "1.61.0"
        }
    }
}
```

### Use existing Go installation

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/golang-lint:1": {
            "goVersion": "none"
        }
    }
}
```

## Included Tools

When `installGoTools` is true, the following tools are installed:

- **gopls** - Go language server
- **dlv** - Delve debugger
- **staticcheck** - Static analysis
- **goimports** - Import management
- **mockgen** - Mock generation
- **gocov** - Test coverage

## golangci-lint Usage

```bash
# Run all linters
golangci-lint run

# Run with specific linters
golangci-lint run --enable=gofmt,govet

# Run fast (for CI)
golangci-lint run --fast

# Create config file
golangci-lint config init
```

## Environment Variables

- `GOROOT=/usr/local/go` - Go installation directory
- `GOPATH=/go` - Go workspace directory
- `PATH` includes `/go/bin` and `/usr/local/go/bin`

## VS Code Integration

The feature configures VS Code to use golangci-lint automatically:

```json
{
    "go.lintTool": "golangci-lint",
    "go.lintFlags": ["--fast"]
}
```


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/Stardevs/dev-container-features/blob/main/src/golang-lint/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
