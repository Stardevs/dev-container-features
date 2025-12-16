# AWS CLI

This feature installs AWS CLI v2 with optional Session Manager plugin and SAM CLI.

## Usage

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/aws-cli:1": {}
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| version | string | latest | AWS CLI version |
| installSessionManager | boolean | false | Install Session Manager plugin |
| installSamCli | boolean | false | Install SAM CLI |
| samCliVersion | string | latest | SAM CLI version |

## Examples

### Install with Session Manager

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/aws-cli:1": {
            "installSessionManager": true
        }
    }
}
```

### Install with SAM CLI for serverless development

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/aws-cli:1": {
            "installSamCli": true
        }
    }
}
```

## Authentication

Configure credentials after container starts:

```bash
aws configure
```

Or set environment variables:

```bash
export AWS_ACCESS_KEY_ID=your_access_key
export AWS_SECRET_ACCESS_KEY=your_secret_key
export AWS_DEFAULT_REGION=us-east-1
```

## Session Manager Usage

If Session Manager plugin is installed:

```bash
aws ssm start-session --target i-1234567890abcdef0
```
