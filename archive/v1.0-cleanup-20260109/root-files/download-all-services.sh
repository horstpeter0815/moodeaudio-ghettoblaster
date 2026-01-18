#!/bin/bash
# 🎵 DOWNLOAD ALL SERVICES REPOSITORIES
# Lädt alle Service-Repositories herunter (Shallow Clone)

set -e

REPOS_DIR="services-repos"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Farben
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🎵 DOWNLOAD ALL SERVICES REPOSITORIES                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Erstelle Repos-Verzeichnis
mkdir -p "$REPOS_DIR"
cd "$REPOS_DIR"

# Alle Repositories
REPOS=(
    "shairport-sync|https://github.com/mikebrady/shairport-sync.git"
    "nqptp|https://github.com/mikebrady/nqptp.git"
    "spotifyd|https://github.com/hifiberry/spotifyd.git"
    "upmpdcli|https://github.com/medoc92/upmpdcli.git"
    "snapcast|https://github.com/badaix/snapcast.git"
    "squeezelite|https://github.com/ralph-irving/squeezelite.git"
    "mpd|https://github.com/MusicPlayerDaemon/MPD.git"
    "bluez|https://github.com/bluez/bluez.git"
    "mpd-mpris|https://github.com/natsukagami/mpd-mpris.git"
    "lmsmpris|https://github.com/hifiberry/lmsmpris.git"
    "camilladsp|https://github.com/HEnquist/camilladsp.git"
)

echo "📥 Lade ${#REPOS[@]} Repositories herunter (Shallow Clone)..."
echo ""

DOWNLOADED=0
SKIPPED=0
FAILED=0

for repo_entry in "${REPOS[@]}"; do
    IFS='|' read -r name url <<< "$repo_entry"
    
    echo -n "📦 $name... "
    
    if [ -d "$name" ]; then
        echo -e "${YELLOW}bereits vorhanden${NC}"
        ((SKIPPED++))
    else
        if git clone --depth 1 "$url" "$name" 2>/dev/null; then
            echo -e "${GREEN}✅${NC}"
            ((DOWNLOADED++))
        else
            echo -e "${YELLOW}❌ Fehler${NC}"
            ((FAILED++))
        fi
    fi
done

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ DOWNLOAD ABGESCHLOSSEN                                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "  ✅ Heruntergeladen: $DOWNLOADED"
echo "  ⏭️  Übersprungen: $SKIPPED"
echo "  ❌ Fehler: $FAILED"
echo ""

# Größe anzeigen
if [ $DOWNLOADED -gt 0 ] || [ $SKIPPED -gt 0 ]; then
    TOTAL_SIZE=$(du -sh . 2>/dev/null | cut -f1)
    echo "  💾 Gesamtgröße: $TOTAL_SIZE"
    echo ""
    echo "📁 Repositories in: $(pwd)"
fi

echo ""
echo "🎯 Nächste Schritte:"
echo "  - Repositories analysieren für Verständnis"
echo "  - Code-Scanning für Architektur und APIs"
echo "  - Integration in moOde verstehen"

