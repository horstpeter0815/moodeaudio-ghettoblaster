#!/bin/bash
################################################################################
# Quick Check: Ollama Installation Status
################################################################################

echo "=== OLLAMA INSTALLATION CHECK ==="
echo ""

# Check if Ollama is installed
if command -v ollama &> /dev/null; then
    echo "✅ Ollama ist installiert"
    ollama --version
else
    echo "❌ Ollama ist NICHT installiert"
    echo "   Führe aus: brew install ollama"
    exit 1
fi

echo ""
echo "=== OLLAMA SERVER STATUS ==="

# Check if Ollama server is running
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "✅ Ollama Server läuft"
else
    echo "⚠️  Ollama Server läuft NICHT"
    echo "   Starte mit: ollama serve"
    echo "   (Oder im Hintergrund: ollama serve &)"
fi

echo ""
echo "=== INSTALLIERTE MODELLE ==="

# List installed models
if command -v ollama &> /dev/null; then
    MODELS=$(ollama list 2>&1)
    if echo "$MODELS" | grep -q "NAME"; then
        echo "$MODELS"
    else
        echo "⚠️  Keine Modelle installiert"
        echo "   Installiere mit: ollama pull llama3.2:3b"
    fi
else
    echo "❌ Kann Modelle nicht auflisten (Ollama nicht gefunden)"
fi

echo ""
echo "=== NÄCHSTE SCHRITTE ==="
echo ""
echo "1. Falls Server nicht läuft:"
echo "   ollama serve &"
echo ""
echo "2. Falls keine Modelle installiert:"
echo "   ollama pull llama3.2:3b"
echo ""
echo "3. Testen:"
echo "   ollama run llama3.2:3b"
echo ""
echo "4. Dann Open WebUI installieren (siehe LOCAL_AI_SETUP.md)"
echo ""

