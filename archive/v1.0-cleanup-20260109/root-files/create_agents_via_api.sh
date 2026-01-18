#!/bin/bash
################################################################################
# CREATE AGENTS VIA API - Attempt to create agents programmatically
# Note: This requires authentication token from Open WebUI
################################################################################

WEBUI_URL="http://localhost:3000"
API_BASE="$WEBUI_URL/api/v1"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🤖 ATTEMPTING TO CREATE AGENTS VIA API                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if Open WebUI is accessible
if ! curl -s "$WEBUI_URL" > /dev/null 2>&1; then
    echo "❌ Open WebUI is not accessible at $WEBUI_URL"
    exit 1
fi

echo "✅ Open WebUI is accessible"
echo ""
echo "⚠️  Note: Creating agents via API requires authentication."
echo "   You need to:"
echo "   1. Get your session token from browser (F12 → Application → Cookies)"
echo "   2. Or use the web UI to create agents (recommended)"
echo ""
echo "Checking available API endpoints..."

# Try to find agent endpoints
ENDPOINTS=(
    "/api/v1/agents"
    "/api/v1/agent"
    "/api/agents"
    "/api/agent"
)

for endpoint in "${ENDPOINTS[@]}"; do
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$WEBUI_URL$endpoint" 2>&1)
    if [ "$STATUS" != "000" ] && [ "$STATUS" != "404" ]; then
        echo "   Found endpoint: $endpoint (Status: $STATUS)"
        if [ "$STATUS" = "401" ] || [ "$STATUS" = "403" ]; then
            echo "      ⚠️  Requires authentication"
        fi
    fi
done

echo ""
echo "📋 RECOMMENDED: Use web UI to create agents"
echo "   The API requires authentication tokens that are"
echo "   difficult to obtain programmatically."
echo ""
echo "   Quick way:"
echo "   1. Open http://localhost:3000"
echo "   2. Go to Create → Agent"
echo "   3. Copy-paste from AGENT_CONFIGURATIONS_READY.md"
echo ""
echo "   This takes only 5 minutes for all 3 agents!"

