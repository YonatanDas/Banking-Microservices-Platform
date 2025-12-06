#!/bin/bash
set -e

echo "🔧 Setting up Docker Buildx and cache..."

# Setup Buildx
docker buildx create --name mybuilder --driver docker-container --use || true
docker buildx inspect --bootstrap || true

# Create local cache directory
mkdir -p /tmp/.buildx-cache
mkdir -p /tmp/.buildx-cache-new

echo "✅ Buildx and cache initialized successfully."