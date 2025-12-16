
# Python with Poetry and uv (python-poetry-uv)

Installs Python with Poetry package manager and uv (ultra-fast Python package installer).

## Example Usage

```json
"features": {
    "ghcr.io/Stardevs/dev-container-features/python-poetry-uv:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| pythonVersion | Python version to install ('system' uses pre-installed Python) | string | 3.12 |
| poetryVersion | Poetry version to install ('none' to skip) | string | latest |
| uvVersion | uv version to install ('none' to skip) | string | latest |
| installPipx | Install pipx for isolated tool installations | boolean | true |
| additionalTools | Comma-separated list of additional Python tools to install via pipx (e.g., 'black,ruff,mypy') | string | - |

## Customizations

### VS Code Extensions

- `ms-python.python`
- `charliermarsh.ruff`

# Python with Poetry and uv

This feature installs Python with modern package managers Poetry and uv.

## Usage

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/python-poetry-uv:1": {}
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| pythonVersion | string | 3.12 | Python version (3.9-3.12 or "system") |
| poetryVersion | string | latest | Poetry version ("none" to skip) |
| uvVersion | string | latest | uv version ("none" to skip) |
| installPipx | boolean | true | Install pipx |
| additionalTools | string | "" | Comma-separated tools to install via pipx |

## Examples

### Install with specific versions

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/python-poetry-uv:1": {
            "pythonVersion": "3.11",
            "poetryVersion": "1.8.0"
        }
    }
}
```

### Install with additional development tools

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/python-poetry-uv:1": {
            "additionalTools": "black,ruff,mypy,pytest"
        }
    }
}
```

### Poetry only (no uv)

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/python-poetry-uv:1": {
            "uvVersion": "none"
        }
    }
}
```

## Poetry Usage

```bash
# Create new project
poetry new my-project

# Install dependencies
poetry install

# Add a dependency
poetry add requests

# Run in virtual environment
poetry run python script.py
```

## uv Usage

uv is an ultra-fast Python package installer and resolver.

```bash
# Install packages (10-100x faster than pip)
uv pip install requests

# Sync from requirements.txt
uv pip sync requirements.txt

# Create virtual environment
uv venv

# Run tools without installing
uvx ruff check .
```

## Environment Variables

- `POETRY_VIRTUALENVS_IN_PROJECT=true` - Creates .venv in project directory
- `UV_CACHE_DIR=/tmp/uv-cache` - uv cache location


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/Stardevs/dev-container-features/blob/main/src/python-poetry-uv/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
