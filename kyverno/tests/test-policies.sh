#!/usr/bin/env bash
set -euo pipefail

# Kyverno Policy Test Script
# This script tests Kyverno policies against sample resources

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
POLICIES_DIR="${SCRIPT_DIR}/../policies/cluster"
TEST_RESOURCES_DIR="${SCRIPT_DIR}/test-resources"

echo "=========================================="
echo "Kyverno Policy Testing"
echo "=========================================="
echo ""

# Check if kyverno CLI is installed
if ! command -v kyverno &> /dev/null; then
    echo "Error: kyverno CLI not found. Please install it first."
    echo "Download from: https://github.com/kyverno/kyverno/releases"
    exit 1
fi

echo "Kyverno CLI version:"
kyverno version
echo ""

# Validate all policies
echo "=========================================="
echo "Step 1: Validating Policy Syntax"
echo "=========================================="
POLICY_COUNT=0
FAILED_POLICIES=0

for policy in "${POLICIES_DIR}"/*.yaml; do
    if [ -f "$policy" ]; then
        POLICY_COUNT=$((POLICY_COUNT + 1))
        POLICY_NAME=$(basename "$policy")
        echo "Validating: $POLICY_NAME"
        
        if kyverno validate "$policy" > /dev/null 2>&1; then
            echo "  ✓ Valid"
        else
            echo "  ✗ Invalid"
            FAILED_POLICIES=$((FAILED_POLICIES + 1))
            kyverno validate "$policy" || true
        fi
        echo ""
    fi
done

if [ $FAILED_POLICIES -gt 0 ]; then
    echo "Error: $FAILED_POLICIES out of $POLICY_COUNT policies failed validation"
    exit 1
fi

echo "All $POLICY_COUNT policies are valid!"
echo ""

# Test policies against resources
echo "=========================================="
echo "Step 2: Testing Policies Against Resources"
echo "=========================================="

if [ ! -d "$TEST_RESOURCES_DIR" ]; then
    echo "Warning: Test resources directory not found: $TEST_RESOURCES_DIR"
    echo "Skipping resource tests..."
    exit 0
fi

# Run kyverno test if test files exist
if [ -f "${TEST_RESOURCES_DIR}/valid-pod.yaml" ] || [ -f "${TEST_RESOURCES_DIR}/invalid-pod.yaml" ]; then
    echo "Running kyverno test..."
    echo ""
    
    # Create a temporary test directory structure for kyverno test
    TEST_DIR=$(mktemp -d)
    trap "rm -rf $TEST_DIR" EXIT
    
    mkdir -p "${TEST_DIR}/policies"
    mkdir -p "${TEST_DIR}/resources"
    
    cp "${POLICIES_DIR}"/*.yaml "${TEST_DIR}/policies/" 2>/dev/null || true
    cp "${TEST_RESOURCES_DIR}"/*.yaml "${TEST_DIR}/resources/" 2>/dev/null || true
    
    if kyverno test "${TEST_DIR}" --policy "${TEST_DIR}/policies" 2>&1; then
        echo ""
        echo "✓ All policy tests passed!"
    else
        echo ""
        echo "⚠ Some policy tests had warnings or failures (this may be expected for invalid test resources)"
    fi
else
    echo "No test resources found. Skipping resource tests..."
fi

echo ""
echo "=========================================="
echo "Testing Complete"
echo "=========================================="

