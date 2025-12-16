
# Terraform with TFLint and Terragrunt (terraform)

Installs Terraform CLI with optional TFLint, Terragrunt, terraform-docs, and tfsec.

## Example Usage

```json
"features": {
    "ghcr.io/Stardevs/dev-container-features/terraform:1": {}
}
```

## Options

| Options Id | Description | Type | Default Value |
|-----|-----|-----|-----|
| version | Terraform version to install | string | latest |
| tflintVersion | TFLint version to install ('none' to skip) | string | latest |
| terragruntVersion | Terragrunt version to install ('none' to skip) | string | none |
| installTerraformDocs | Install terraform-docs for documentation generation | boolean | false |
| terraformDocsVersion | terraform-docs version | string | latest |
| installTfsec | Install tfsec for security scanning | boolean | false |
| installOpenTofu | Install OpenTofu as an alternative to Terraform | boolean | false |
| openTofuVersion | OpenTofu version (only used if installOpenTofu is true) | string | latest |

## Customizations

### VS Code Extensions

- `HashiCorp.terraform`

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


---

_Note: This file was auto-generated from the [devcontainer-feature.json](https://github.com/Stardevs/dev-container-features/blob/main/src/terraform/devcontainer-feature.json).  Add additional notes to a `NOTES.md`._
