#!/bin/bash
set -e
TIMESTAMP=$(date +%Y%m%d-%H%M)
TAG=${GITHUB_SHA::7}
DEST="s3://ci-artifacts/${SERVICE}/${TAG}_${TIMESTAMP}/"

mkdir -p reports
cp -r trivy-reports/*.txt reports/ || true
cp -r ${SERVICE}-trivy-image-report.txt reports/ || true
cp -r ${SERVICE}-sbom.xml reports/ || true
cp -r ${SERVICE_DIR}/target/site/jacoco reports/coverage || true

aws s3 sync reports/ "$DEST" --delete
echo "✅ Reports uploaded to $DEST"