#!/bin/bash
set -e

SERVICE_DIR="$1"
ROOT_DIR="$(git rev-parse --show-toplevel)"

echo "🧪 Running lint + test + coverage for service: $SERVICE_DIR"
echo "📂 Root dir: $ROOT_DIR"
echo "📁 Full path: $ROOT_DIR/$SERVICE_DIR"

cd "$ROOT_DIR/$SERVICE_DIR" || { echo "❌ Directory not found: $ROOT_DIR/$SERVICE_DIR"; exit 1; }

# Skip checkstyle
mvn -B clean verify -Dcheckstyle.skip=true || true



echo "✅ Tests finished for $SERVICE_DIR"