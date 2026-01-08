#!/bin/bash
################################################################################
#
# START COCKPIT
# Startet das Smart AI Manager Cockpit
#
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "🎯 Starting Smart AI Manager Cockpit..."
echo ""

# Prüfe ob Python installiert ist
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 nicht gefunden. Bitte installieren Sie Python3."
    exit 1
fi

# Prüfe ob Flask installiert ist
if ! python3 -c "import flask" 2>/dev/null; then
    echo "📦 Installiere Flask..."
    pip3 install -r requirements.txt
fi

# Prüfe ob psutil installiert ist
if ! python3 -c "import psutil" 2>/dev/null; then
    echo "📦 Installiere psutil..."
    pip3 install psutil
fi

# Starte Cockpit
echo "🚀 Starte Cockpit..."
echo ""
echo "📊 Dashboard wird auf freiem Port gestartet (5001-5009)"
echo "🛑 Stoppen mit: Ctrl+C"
echo ""

python3 app.py

