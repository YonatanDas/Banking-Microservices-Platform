#!/usr/bin/env bash
set -e  # Exit immediately on error

SERVICE_DIR=$1

echo "[$(date +'%H:%M:%S')] ⏳ 🔍 Running lint and unit tests in $SERVICE_DIR..."

cd "$SERVICE_DIR"

# Run Checkstyle
mvn -B clean verify -f ${SERVICE_DIR}/pom.xml 

# Run Unit Tests
mvn -T 1C test -DskipITs

# Generate Code Coverage Report
mvn jacoco:report

echo "[$(date +'%H:%M:%S')] ⏳ ✅ Lint, tests, and coverage completed for $SERVICE_DIR"