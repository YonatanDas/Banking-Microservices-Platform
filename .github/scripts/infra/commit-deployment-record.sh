#!/usr/bin/env bash
# Commit deployment record to git
set -euo pipefail

SERVICE="$1"
ENVIRONMENT="$2"

if [ -z "$SERVICE" ] || [ -z "$ENVIRONMENT" ]; then
  echo "Usage: $0 <SERVICE> <ENVIRONMENT>" >&2
  exit 1
fi

echo "📝 Committing deployment record for $SERVICE in $ENVIRONMENT..."

# Configure git if not already configured
git config user.name "github-actions[bot]" || true
git config user.email "github-actions[bot]@users.noreply.github.com" || true

# Add deployment records
git add docs/deployments/ || true

if git diff --cached --quiet; then
  echo "ℹ️  No deployment record to commit"
  exit 0
else
  git commit -m "docs: add deployment record for $SERVICE to $ENVIRONMENT" || {
    echo "⚠️  Could not commit deployment record (may already be committed)"
    exit 0
  }
  
  git push origin HEAD || {
    echo "⚠️  Could not push deployment record"
    exit 0
  }
  
  echo "✅ Deployment record committed successfully"
fi

