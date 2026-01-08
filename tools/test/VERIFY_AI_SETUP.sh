#!/bin/bash
################################################################################
# VERIFY AI SETUP - Check all components of moOde AI integration
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 VERIFYING MOODE AI SETUP                                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

ERRORS=0

# Check 1: Ollama
echo "1. Checking Ollama..."
if command -v ollama &> /dev/null; then
    echo "   ✅ Ollama installed"
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "   ✅ Ollama server running"
        MODELS=$(ollama list 2>&1 | grep -v "NAME" | wc -l | tr -d ' ')
        if [ "$MODELS" -gt 0 ]; then
            echo "   ✅ Models available: $MODELS"
            ollama list 2>&1 | grep -v "NAME" | head -3 | sed 's/^/      /'
        else
            echo "   ⚠️  No models installed"
        fi
    else
        echo "   ❌ Ollama server not running"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "   ❌ Ollama not installed"
    ERRORS=$((ERRORS + 1))
fi

# Check 2: Docker
echo ""
echo "2. Checking Docker..."
if command -v docker &> /dev/null; then
    echo "   ✅ Docker installed"
    if docker ps > /dev/null 2>&1; then
        echo "   ✅ Docker daemon running"
    else
        echo "   ❌ Docker daemon not running"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "   ❌ Docker not installed"
    ERRORS=$((ERRORS + 1))
fi

# Check 3: Open WebUI
echo ""
echo "3. Checking Open WebUI..."
if docker ps | grep -q open-webui; then
    echo "   ✅ Open WebUI container running"
    if curl -s http://localhost:3000 > /dev/null 2>&1; then
        echo "   ✅ Open WebUI accessible at http://localhost:3000"
    else
        echo "   ⚠️  Container running but web interface not responding"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo "   ❌ Open WebUI container not running"
    echo "   Start with: cd ~/open-webui && docker-compose up -d"
    ERRORS=$((ERRORS + 1))
fi

# Check 4: RAG Files Prepared
echo ""
echo "4. Checking RAG file preparation..."
if [ -d "$HOME/moodeaudio-cursor/rag-upload-files" ]; then
    FILE_COUNT=$(find "$HOME/moodeaudio-cursor/rag-upload-files" -type f ! -name "FILE_LIST.txt" | wc -l | tr -d ' ')
    echo "   ✅ RAG files prepared: $FILE_COUNT files"
    echo "   Location: ~/moodeaudio-cursor/rag-upload-files/"
else
    echo "   ⚠️  RAG files not prepared"
    echo "   Run: cd ~/moodeaudio-cursor && ./PREPARE_MOODE_FILES_FOR_RAG.sh"
fi

# Check 5: Guides Created
echo ""
echo "5. Checking documentation..."
GUIDES=(
    "RAG_UPLOAD_GUIDE.md"
    "CREATE_MOODE_AGENTS_GUIDE.md"
    "MOODE_AI_INTEGRATION_STATUS.md"
    "MOODE_AI_WORKFLOW_GUIDE.md"
)

GUIDES_FOUND=0
for guide in "${GUIDES[@]}"; do
    if [ -f "$HOME/moodeaudio-cursor/$guide" ]; then
        GUIDES_FOUND=$((GUIDES_FOUND + 1))
    fi
done

if [ $GUIDES_FOUND -eq ${#GUIDES[@]} ]; then
    echo "   ✅ All guides created ($GUIDES_FOUND/${#GUIDES[@]})"
else
    echo "   ⚠️  Some guides missing ($GUIDES_FOUND/${#GUIDES[@]})"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
if [ $ERRORS -eq 0 ]; then
    echo "║  ✅ SETUP VERIFICATION PASSED                              ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Next steps (manual in Open WebUI):"
    echo "  1. Open http://localhost:3000"
    echo "  2. Enable RAG (Settings → RAG)"
    echo "  3. Upload files (Knowledge section)"
    echo "  4. Create agents (Create → Agent)"
    echo ""
    exit 0
else
    echo "║  ⚠️  FOUND $ERRORS ISSUE(S)                                ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    exit 1
fi

