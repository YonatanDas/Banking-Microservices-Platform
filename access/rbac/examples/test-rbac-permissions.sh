#!/usr/bin/env bash
set -euo pipefail

# Test RBAC permissions for the current user
# Usage: test-rbac-permissions.sh

echo "🔍 Testing RBAC permissions for current user..."
echo ""

# Get current user context
CURRENT_USER=$(kubectl config view --minify -o jsonpath='{.users[0].name}' 2>/dev/null || echo "unknown")
echo "Current user context: $CURRENT_USER"
echo ""

# Test common permissions
echo "=== Cluster-Level Permissions ==="
echo -n "Can create deployments: "
kubectl auth can-i create deployments --all-namespaces 2>/dev/null && echo "✅ YES" || echo "❌ NO"

echo -n "Can delete pods: "
kubectl auth can-i delete pods --all-namespaces 2>/dev/null && echo "✅ YES" || echo "❌ NO"

echo -n "Can get secrets: "
kubectl auth can-i get secrets --all-namespaces 2>/dev/null && echo "✅ YES" || echo "❌ NO"

echo -n "Can create namespaces: "
kubectl auth can-i create namespaces 2>/dev/null && echo "✅ YES" || echo "❌ NO"

echo -n "Can modify RBAC: "
kubectl auth can-i create clusterroles 2>/dev/null && echo "✅ YES" || echo "❌ NO"

echo ""
echo "=== Namespace-Level Permissions (default) ==="
echo -n "Can create deployments in default: "
kubectl auth can-i create deployments -n default 2>/dev/null && echo "✅ YES" || echo "❌ NO"

echo -n "Can delete pods in default: "
kubectl auth can-i delete pods -n default 2>/dev/null && echo "✅ YES" || echo "❌ NO"

echo -n "Can get secrets in default: "
kubectl auth can-i get secrets -n default 2>/dev/null && echo "✅ YES" || echo "❌ NO"

echo ""
echo "=== Resource Access ==="
echo -n "Can list nodes: "
kubectl auth can-i list nodes 2>/dev/null && echo "✅ YES" || echo "❌ NO"

echo -n "Can list namespaces: "
kubectl auth can-i list namespaces 2>/dev/null && echo "✅ YES" || echo "❌ NO"

echo -n "Can list pods: "
kubectl auth can-i list pods --all-namespaces 2>/dev/null && echo "✅ YES" || echo "❌ NO"

echo ""
echo "=== Detailed Permission Check ==="
echo "All permissions:"
kubectl auth can-i --list --all-namespaces 2>/dev/null | head -20 || echo "Unable to list permissions"

