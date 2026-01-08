#!/bin/bash
################################################################################
# AUTOMATE RAG UPLOAD - Attempt to upload files via Open WebUI API
# Note: This may require authentication and API access
################################################################################

set -e

WEBUI_URL="http://localhost:3000"
RAG_DIR="$HOME/moodeaudio-cursor/rag-upload-files"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🤖 ATTEMPTING AUTOMATED RAG UPLOAD                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if Open WebUI is accessible
if ! curl -s "$WEBUI_URL" > /dev/null 2>&1; then
    echo "❌ Open WebUI is not accessible at $WEBUI_URL"
    exit 1
fi

echo "✅ Open WebUI is accessible"

# Note: Open WebUI typically requires authentication for API access
# This script attempts to use the API, but manual upload may be required

echo ""
echo "⚠️  Note: Open WebUI API typically requires authentication."
echo "   This script will attempt API upload, but manual upload may be needed."
echo ""

# Try to find API endpoints (this is exploratory)
echo "Checking available API endpoints..."
API_ENDPOINTS=(
    "/api/v1/knowledge"
    "/api/v1/documents"
    "/api/v1/rag"
    "/api/knowledge"
    "/api/documents"
)

for endpoint in "${API_ENDPOINTS[@]}"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$WEBUI_URL$endpoint" 2>&1)
    if [ "$STATUS" != "000" ] && [ "$STATUS" != "404" ]; then
        echo "   Found endpoint: $endpoint (Status: $STATUS)"
    fi
done

echo ""
echo "📋 For now, manual upload is recommended:"
echo "   1. Open http://localhost:3000"
echo "   2. Go to Knowledge/RAG section"
echo "   3. Upload files from: $RAG_DIR"
echo ""
echo "   See RAG_UPLOAD_GUIDE.md for detailed instructions"

