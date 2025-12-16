#!/bin/bash
set -e

cd "$(dirname "$0")/.."

errors=0
warnings=0

echo "=== Devcontainer Features Validation ==="
echo ""

# 1. JSON Validation
echo "1. Validating JSON syntax..."
for f in src/*/devcontainer-feature.json; do
    if jq empty "$f" 2>/dev/null; then
        echo "   [OK] $f"
    else
        echo "   [FAIL] $f - Invalid JSON"
        errors=$((errors + 1))
    fi
done
echo ""

# 2. Required Files
echo "2. Checking required files..."
for feature_dir in src/*/; do
    feature=$(basename "$feature_dir")

    if [ ! -f "$feature_dir/devcontainer-feature.json" ]; then
        echo "   [FAIL] $feature: missing devcontainer-feature.json"
        errors=$((errors + 1))
    elif [ ! -f "$feature_dir/install.sh" ]; then
        echo "   [FAIL] $feature: missing install.sh"
        errors=$((errors + 1))
    elif [ ! -x "$feature_dir/install.sh" ]; then
        echo "   [FAIL] $feature: install.sh is not executable"
        errors=$((errors + 1))
    else
        echo "   [OK] $feature"
    fi

    if [ ! -f "test/$feature/test.sh" ]; then
        echo "   [WARN] $feature: missing test/test.sh"
        warnings=$((warnings + 1))
    fi
done
echo ""

# 3. Metadata Validation
echo "3. Validating feature metadata..."
for f in src/*/devcontainer-feature.json; do
    feature=$(dirname "$f" | xargs basename)

    id=$(jq -r '.id // empty' "$f")
    version=$(jq -r '.version // empty' "$f")
    name=$(jq -r '.name // empty' "$f")

    feature_errors=0

    if [ -z "$id" ]; then
        echo "   [FAIL] $feature: missing 'id' field"
        feature_errors=$((feature_errors + 1))
    elif [ "$id" != "$feature" ]; then
        echo "   [FAIL] $feature: id '$id' doesn't match directory name"
        feature_errors=$((feature_errors + 1))
    fi

    if [ -z "$version" ]; then
        echo "   [FAIL] $feature: missing 'version' field"
        feature_errors=$((feature_errors + 1))
    fi

    if [ -z "$name" ]; then
        echo "   [FAIL] $feature: missing 'name' field"
        feature_errors=$((feature_errors + 1))
    fi

    # Validate options
    if jq -e '.options' "$f" > /dev/null 2>&1; then
        for opt in $(jq -r '.options | keys[]' "$f"); do
            opt_type=$(jq -r ".options[\"$opt\"].type // empty" "$f")
            if [ -z "$opt_type" ]; then
                echo "   [FAIL] $feature: option '$opt' missing type"
                feature_errors=$((feature_errors + 1))
            fi
        done
    fi

    if [ $feature_errors -eq 0 ]; then
        echo "   [OK] $feature"
    fi
    errors=$((errors + feature_errors))
done
echo ""

# 4. Shell Script Syntax
echo "4. Checking shell script syntax..."
for script in src/*/install.sh; do
    feature=$(dirname "$script" | xargs basename)

    if bash -n "$script" 2>/dev/null; then
        echo "   [OK] $feature/install.sh"
    else
        echo "   [FAIL] $feature/install.sh - syntax error"
        errors=$((errors + 1))
    fi
done
echo ""

# 5. Shellcheck (if available)
if command -v shellcheck &> /dev/null; then
    echo "5. Running shellcheck..."
    for script in src/*/install.sh; do
        feature=$(dirname "$script" | xargs basename)
        if shellcheck -S warning "$script" 2>/dev/null; then
            echo "   [OK] $feature/install.sh"
        else
            echo "   [WARN] $feature/install.sh - shellcheck warnings"
            warnings=$((warnings + 1))
        fi
    done
    echo ""
else
    echo "5. Shellcheck not installed, skipping..."
    echo "   Install with: sudo apt-get install shellcheck"
    echo ""
fi

# Summary
echo "=== Summary ==="
echo "Features: $(ls -1 src/ | wc -l)"
echo "Errors: $errors"
echo "Warnings: $warnings"
echo ""

if [ $errors -gt 0 ]; then
    echo "Validation FAILED"
    exit 1
else
    echo "Validation PASSED"
    exit 0
fi
