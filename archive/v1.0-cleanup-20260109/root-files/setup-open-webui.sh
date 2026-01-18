#!/bin/bash
################################################################################
# Setup Open WebUI für Ollama
#
# Dieses Script installiert Open WebUI mit Docker
################################################################################

set -e

echo "=== OPEN WEBUI SETUP ==="
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker ist nicht installiert"
    echo ""
    echo "Installiere Docker Desktop für Mac:"
    echo "  brew install --cask docker"
    echo ""
    echo "Oder lade es von: https://www.docker.com/products/docker-desktop"
    exit 1
fi

echo "✅ Docker ist installiert"
docker --version

echo ""
echo "=== PRÜFE OLLAMA SERVER ==="

# Check if Ollama server is running
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "✅ Ollama Server läuft"
else
    echo "⚠️  Ollama Server läuft NICHT"
    echo "   Starte zuerst: ollama serve &"
    echo ""
    read -p "Soll ich versuchen, Ollama zu starten? (j/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Jj]$ ]]; then
        ollama serve &
        sleep 3
        echo "✅ Ollama Server gestartet"
    else
        echo "❌ Bitte starte Ollama manuell und führe dieses Script erneut aus"
        exit 1
    fi
fi

echo ""
echo "=== INSTALLIERE OPEN WEBUI ==="

# Create directory for docker-compose
mkdir -p ~/open-webui
cd ~/open-webui

# Create docker-compose.yml
cat > docker-compose.yml <<'EOF'
version: '3.8'
services:
  open-webui:
    image: ghcr.io/open-webui/open-webui:main
    container_name: open-webui
    ports:
      - "3000:8080"
    volumes:
      - open-webui:/app/backend/data
    environment:
      - OLLAMA_BASE_URL=http://host.docker.internal:11434
    extra_hosts:
      - "host.docker.internal:host-gateway"
    restart: always
volumes:
  open-webui:
EOF

echo "✅ docker-compose.yml erstellt"

# Start Open WebUI
echo ""
echo "Starte Open WebUI..."
docker-compose up -d

echo ""
echo "⏳ Warte 10 Sekunden, bis Open WebUI startet..."
sleep 10

# Check if it's running
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ Open WebUI läuft!"
    echo ""
    echo "🌐 Öffne im Browser:"
    echo "   http://localhost:3000"
    echo ""
    echo "📝 Erstelle einen Account und starte!"
else
    echo "⚠️  Open WebUI startet noch..."
    echo "   Prüfe mit: docker-compose logs"
    echo "   Oder warte ein paar Sekunden und öffne: http://localhost:3000"
fi

echo ""
echo "=== NÜTZLICHE COMMANDS ==="
echo ""
echo "Open WebUI stoppen:"
echo "  cd ~/open-webui && docker-compose down"
echo ""
echo "Open WebUI starten:"
echo "  cd ~/open-webui && docker-compose up -d"
echo ""
echo "Logs anzeigen:"
echo "  cd ~/open-webui && docker-compose logs -f"
echo ""

