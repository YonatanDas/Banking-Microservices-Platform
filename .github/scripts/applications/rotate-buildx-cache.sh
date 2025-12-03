CACHE_DIR="/tmp/.buildx-cache"
NEW_CACHE_DIR="/tmp/.buildx-cache-new"

echo "🧹 Cleaning up Docker build cache..."

rm -rf "${CACHE_DIR}"

mv "${NEW_CACHE_DIR}" "${CACHE_DIR}"

echo "✅ Docker cache updated."