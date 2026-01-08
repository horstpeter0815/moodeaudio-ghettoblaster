#!/bin/bash
# 🔧 DOWNLOAD MISSING DRIVER REPOSITORIES
# Lädt alle fehlenden Treiber-Repositories herunter

set -e

DRIVERS_DIR="drivers-repos"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Farben
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 DOWNLOAD MISSING DRIVER REPOSITORIES                      ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Erstelle Drivers-Verzeichnis
mkdir -p "$DRIVERS_DIR"
cd "$DRIVERS_DIR"

# Fehlende Treiber-Repositories mit korrekten URLs
MISSING_DRIVERS=(
    # HiFiBerry Treiber
    "hifiberry-dsp|https://github.com/hifiberry/hifiberry-dsp.git"
    "hifiberry-amp|https://github.com/hifiberry/hifiberry-amp.git"
    "hifiberry-dac|https://github.com/hifiberry/hifiberry-dac.git"
    
    # ALSA Treiber
    "alsa-driver|https://github.com/alsa-project/alsa-driver.git"
    "alsa-utils|https://github.com/alsa-project/alsa-utils.git"
    "alsa-plugins|https://github.com/alsa-project/alsa-plugins.git"
    
    # I2C Tools (alternative URLs)
    "i2c-tools|https://git.kernel.org/pub/scm/utils/i2c-tools/i2c-tools.git"
    
    # Audio Processing Tools
    "brutefir|https://github.com/woodywoodham/brutefir.git"
    
    # Audio Control
    "audiocontrol2|https://github.com/hifiberry/audiocontrol2.git"
    
    # ALSA Loop (HiFiBerry)
    "alsaloop|https://github.com/hifiberry/alsaloop.git"
)

echo "📥 Lade fehlende Treiber-Repositories herunter (Shallow Clone)..."
echo ""

DOWNLOADED=0
SKIPPED=0
FAILED=0

for driver_entry in "${MISSING_DRIVERS[@]}"; do
    IFS='|' read -r name url extra <<< "$driver_entry"
    
    echo -n "🔧 $name... "
    
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
echo "ℹ️  Hinweis zu Room EQ Wizard (REW):"
echo "  REW ist eine Java-Anwendung (kein Treiber-Repository)"
echo "  Download: https://www.roomeqwizard.com/"
echo "  Für Messungen wird ein kalibriertes Mikrofon benötigt"
echo ""

