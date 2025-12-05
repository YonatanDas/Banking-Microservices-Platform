#!/usr/bin/env bash
set -euo pipefail

# Grant cluster developer access to an IAM user
# Usage: grant-access-to-user.sh <iam-user-arn> [role-name]

USER_ARN="${1:-}"
ROLE="${2:-cluster-developer}"

if [ -z "$USER_ARN" ]; then
  echo "Usage: $0 <iam-user-arn> [role-name]"
  echo "Example: $0 arn:aws:iam::063630846340:user/john.doe cluster-developer"
  echo ""
  echo "Available roles:"
  echo "  - cluster-admin"
  echo "  - cluster-developer"
  echo "  - cluster-viewer"
  echo "  - cluster-operator"
  exit 1
fi

# Extract username from ARN
USERNAME=$(echo "$USER_ARN" | awk -F'/' '{print $NF}')

# Validate role name
VALID_ROLES=("cluster-admin" "cluster-developer" "cluster-viewer" "cluster-operator")
if [[ ! " ${VALID_ROLES[@]} " =~ " ${ROLE} " ]]; then
  echo "Error: Invalid role '$ROLE'"
  echo "Valid roles: ${VALID_ROLES[*]}"
  exit 1
fi

BINDING_NAME="${USERNAME}-${ROLE}"

cat <<EOF | kubectl apply -f -
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: ${BINDING_NAME}
  labels:
    rbac.bankingapp.io/binding: ${ROLE}
    rbac.bankingapp.io/scope: cluster
    rbac.bankingapp.io/managed-by: manual
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ${ROLE}
subjects:
  - kind: User
    name: ${USER_ARN}
EOF

echo "✅ Granted ${ROLE} access to ${USER_ARN}"
echo "User can now run: aws eks update-kubeconfig --name <cluster-name> --region <region>"

