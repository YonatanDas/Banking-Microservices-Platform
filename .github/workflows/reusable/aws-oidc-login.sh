#!/bin/bash
set -e
AWS_REGION=$1
REGISTRY=$2

echo "Logging in to AWS ECR..." 
aws ecr get-login-password --region "$AWS_REGION" | docker login --username AWS --password-stdin "$REGISTRY"

echo "✅ AWS OIDC setup complete."