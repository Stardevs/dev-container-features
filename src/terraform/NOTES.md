# Terraform with TFLint and Terragrunt

This feature installs Terraform with optional companion tools.

## Usage

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/terraform:1": {}
    }
}
```

## Options

| Option | Type | Default | Description |
|--------|------|---------|-------------|
| version | string | latest | Terraform version |
| tflintVersion | string | latest | TFLint version ("none" to skip) |
| terragruntVersion | string | none | Terragrunt version ("none" to skip) |
| installTerraformDocs | boolean | false | Install terraform-docs |
| terraformDocsVersion | string | latest | terraform-docs version |
| installTfsec | boolean | false | Install tfsec security scanner |
| installOpenTofu | boolean | false | Install OpenTofu |
| openTofuVersion | string | latest | OpenTofu version |

## Examples

### Full toolchain

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/terraform:1": {
            "terragruntVersion": "latest",
            "installTerraformDocs": true,
            "installTfsec": true
        }
    }
}
```

### OpenTofu instead of Terraform

```json
{
    "features": {
        "ghcr.io/Stardevs/devcontainer-features/terraform:1": {
            "installOpenTofu": true
        }
    }
}
```

## Terraform Usage

```bash
# Initialize
terraform init

# Plan changes
terraform plan

# Apply changes
terraform apply

# Destroy resources
terraform destroy

# Format code
terraform fmt -recursive

# Validate configuration
terraform validate
```

## TFLint Usage

```bash
# Initialize plugins
tflint --init

# Run linting
tflint

# Run with specific ruleset
tflint --enable-rule=terraform_naming_convention
```

## Terragrunt Usage

```bash
# Run terraform through terragrunt
terragrunt init
terragrunt plan
terragrunt apply

# Run across all modules
terragrunt run-all apply
```

## terraform-docs Usage

```bash
# Generate markdown documentation
terraform-docs markdown . > README.md

# Generate with specific format
terraform-docs markdown table .
```

## tfsec Usage

```bash
# Scan current directory
tfsec .

# Scan with specific severity
tfsec --minimum-severity HIGH

# Output as JSON
tfsec --format json
```

## OpenTofu

OpenTofu is an open-source fork of Terraform. Use `tofu` command:

```bash
tofu init
tofu plan
tofu apply
```
