#!/usr/bin/env bash
# Setup common tools (yq) and make scripts executable
set -euo pipefail

# Accept optional script directory patterns (defaults to common locations)
SCRIPT_PATTERNS="${1:-.github/scripts/applications/*.sh .github/scripts/infra/*.sh .github/platform/scripts/*.sh}"

echo "🔧 Setting up common tools..."

# Install yq if not present
if ! command -v yq &> /dev/null; then
  echo "📦 Installing yq..."
  wget -qO /usr/local/bin/yq https://github.com/mikefarah/yq/releases/latest/download/yq_linux_amd64
  chmod +x /usr/local/bin/yq
  echo "✅ yq installed successfully"
else
  echo "✅ yq already installed"
fi

# Make scripts executable
for pattern in $SCRIPT_PATTERNS; do
  # Use find to handle glob patterns properly
  if find . -wholename "$pattern" -type f 2>/dev/null | head -1 | grep -q .; then
    find . -wholename "$pattern" -type f -exec chmod +x {} \;
    echo "✅ Made scripts executable: $pattern"
  fi
done

echo "✅ Common tools setup complete"

