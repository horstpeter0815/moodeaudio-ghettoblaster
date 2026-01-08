#!/bin/bash
################################################################################
# CREATE AGENTS QUICK - Opens Open WebUI and displays agent configurations
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🤖 AGENT CREATION HELPER                                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if Open WebUI is running
if ! curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "❌ Open WebUI is not running at http://localhost:3000"
    echo "   Start it with: cd ~/open-webui && docker-compose up -d"
    exit 1
fi

echo "✅ Open WebUI is running"
echo ""
echo "📋 Agent configurations are ready in:"
echo "   AGENT_CONFIGURATIONS_READY.md"
echo ""
echo "🌐 Opening Open WebUI in browser..."
echo ""

# Try to open browser (works on Mac)
if command -v open &> /dev/null; then
    open http://localhost:3000
    echo "✅ Browser opened"
elif command -v xdg-open &> /dev/null; then
    xdg-open http://localhost:3000
    echo "✅ Browser opened"
else
    echo "⚠️  Please open http://localhost:3000 manually"
fi

echo ""
echo "📝 QUICK STEPS:"
echo "   1. In Open WebUI, go to: Create → Agent"
echo "   2. Open: AGENT_CONFIGURATIONS_READY.md"
echo "   3. Copy-paste each agent configuration"
echo "   4. Save and test"
echo ""
echo "📄 Full guide: AGENT_CONFIGURATIONS_READY.md"
echo ""

# Display first agent as example
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  EXAMPLE: Network Configuration Agent                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Agent Name: moOde Network Config Agent"
echo ""
echo "Description:"
echo "Automatically checks and fixes moOde network configuration issues."
echo ""
echo "System Prompt: (see AGENT_CONFIGURATIONS_READY.md for full prompt)"
echo ""
echo "Knowledge Base: Select all uploaded collections"
echo "Model: llama3.2:3b"
echo ""
echo "📋 See AGENT_CONFIGURATIONS_READY.md for all 3 agents!"

