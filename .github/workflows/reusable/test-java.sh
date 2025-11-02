#!/usr/bin/env bash
set -euo pipefail

SERVICE_DIR=$1

echo "🧪 Running tests & linting for $SERVICE_DIR..."

cd "$SERVICE_DIR"

mvn -B checkstyle:check
mvn -B test

echo "✅ Lint & tests completed successfully"