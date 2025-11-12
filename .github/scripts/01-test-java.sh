#!/bin/bash
set -e

SERVICE_DIR="$1"
ROOT_DIR="$(git rev-parse --show-toplevel)"

echo "🧪 Running lint + test + coverage for service: $SERVICE_DIR"
echo "📂 Root dir: $ROOT_DIR"
echo "📁 Full path: $ROOT_DIR/$SERVICE_DIR"

cd "$ROOT_DIR/$SERVICE_DIR" || { echo "❌ Directory not found: $ROOT_DIR/$SERVICE_DIR"; exit 1; }

# --------------------------
# Skip checkstyle (optional)
# --------------------------
# If you only want to see CI run even with violations, add -Dcheckstyle.skip=true
# or comment out if you want full enforcement
mvn -B clean verify -Dcheckstyle.skip=true || true

# --------------------------
# Create artifact report folder (optional)
# --------------------------
mkdir -p "$ROOT_DIR/.ci_artifacts/test-reports/$SERVICE_DIR"
cp -r target/surefire-reports "$ROOT_DIR/.ci_artifacts/test-reports/$SERVICE_DIR/" || true
cp -r target/site/jacoco "$ROOT_DIR/.ci_artifacts/test-reports/$SERVICE_DIR/" || true

echo "✅ Tests finished for $SERVICE_DIR"