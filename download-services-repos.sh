#!/bin/bash
# 🎵 SERVICES REPOSITORY DOWNLOADER
# Lädt ausgewählte Service-Repositories herunter

set -e

REPOS_DIR="services-repos"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Farben für Output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🎵 SERVICES REPOSITORY DOWNLOADER                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Erstelle Repos-Verzeichnis
mkdir -p "$REPOS_DIR"
cd "$REPOS_DIR"

# Repository-Definitionen (als einfache Arrays für Kompatibilität)
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

# Funktion: Repository-URL abrufen
get_repo_url() {
    local repo_name=$1
    for repo_entry in "${REPOS[@]}"; do
        IFS='|' read -r name url <<< "$repo_entry"
        if [ "$name" == "$repo_name" ]; then
            echo "$url"
            return 0
        fi
    done
    return 1
}

# Service-Kategorien
CATEGORIES_AIRPLAY="shairport-sync nqptp"
CATEGORIES_STREAMING="spotifyd upmpdcli"
CATEGORIES_MULTIROOM="snapcast squeezelite"
CATEGORIES_PLAYER="mpd"
CATEGORIES_BLUETOOTH="bluez"
CATEGORIES_MPRIS="mpd-mpris lmsmpris"
CATEGORIES_AUDIO="camilladsp"

echo "📋 Verfügbare Services:"
echo ""
echo "  [1] Airplay (Shairport Sync, NQPTP)"
echo "  [2] Streaming (Spotifyd, UPnP/DLNA)"
echo "  [3] Multiroom (Snapcast, Squeezelite)"
echo "  [4] Player (MPD)"
echo "  [5] Bluetooth (BlueZ)"
echo "  [6] MPRIS (Metadata)"
echo "  [7] Audio Processing (CamillaDSP, PeppyMeter)"
echo "  [8] Alle Services"
echo "  [9] Einzelne Services auswählen"
echo ""
read -p "Wähle Kategorien (z.B. 1,3,4 für Airplay, Multiroom, Player): " SELECTION

# Parse Auswahl
SELECTED_REPOS=()

if [[ "$SELECTION" == *"8"* ]]; then
    # Alle Services
    SELECTED_REPOS=("${!REPOS[@]}")
elif [[ "$SELECTION" == *"9"* ]]; then
    # Einzelne Auswahl
    echo ""
    echo "Verfügbare Services:"
    i=1
    for repo in "${!REPOS[@]}"; do
        echo "  [$i] $repo"
        ((i++))
    done
    echo ""
    read -p "Wähle Services (z.B. 1,3,5): " INDIVIDUAL
    # TODO: Parse individual selection
else
    # Kategorien
    for cat_num in $(echo "$SELECTION" | tr ',' ' '); do
        case $cat_num in
            1) SELECTED_REPOS+=(${CATEGORIES[airplay]}) ;;
            2) SELECTED_REPOS+=(${CATEGORIES[streaming]}) ;;
            3) SELECTED_REPOS+=(${CATEGORIES[multiroom]}) ;;
            4) SELECTED_REPOS+=(${CATEGORIES[player]}) ;;
            5) SELECTED_REPOS+=(${CATEGORIES[bluetooth]}) ;;
            6) SELECTED_REPOS+=(${CATEGORIES[mpris]}) ;;
            7) SELECTED_REPOS+=(${CATEGORIES[audio]}) ;;
        esac
    done
fi

# Entferne Duplikate
SELECTED_REPOS=($(printf "%s\n" "${SELECTED_REPOS[@]}" | sort -u))

echo ""
echo "📥 Wird heruntergeladen:"
for repo in "${SELECTED_REPOS[@]}"; do
    echo "  - $repo"
done
echo ""

# Download-Modus wählen
if [ -z "$2" ]; then
    echo "Download-Modus:"
    echo "  [1] Shallow Clone (schnell, ~10-20% Größe, keine History)"
    echo "  [2] Full Clone (komplett mit History)"
    echo "  [3] ZIP Download (sehr klein, kein Git)"
    read -p "Wähle Modus [1]: " MODE
    MODE=${MODE:-1}
else
    MODE="$2"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  📥 DOWNLOAD STARTET                                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

DOWNLOADED=0
SKIPPED=0
FAILED=0

for repo in "${SELECTED_REPOS[@]}"; do
    REPO_URL=$(get_repo_url "$repo")
    if [ ! -z "$REPO_URL" ]; then
        REPO_NAME="$repo"
        
        echo -n "📦 $REPO_NAME... "
        
        if [ -d "$REPO_NAME" ]; then
            echo -e "${YELLOW}bereits vorhanden (übersprungen)${NC}"
            ((SKIPPED++))
        else
            case $MODE in
                1)
                    # Shallow Clone
                    if git clone --depth 1 "$REPO_URL" "$REPO_NAME" 2>/dev/null; then
                        echo -e "${GREEN}✅${NC}"
                        ((DOWNLOADED++))
                    else
                        echo -e "${YELLOW}❌ Fehler${NC}"
                        ((FAILED++))
                    fi
                    ;;
                2)
                    # Full Clone
                    if git clone "$REPO_URL" "$REPO_NAME" 2>/dev/null; then
                        echo -e "${GREEN}✅${NC}"
                        ((DOWNLOADED++))
                    else
                        echo -e "${YELLOW}❌ Fehler${NC}"
                        ((FAILED++))
                    fi
                    ;;
                3)
                    # ZIP Download
                    ZIP_URL="${REPO_URL%.git}/archive/refs/heads/main.zip"
                    if wget -q "$ZIP_URL" -O "${REPO_NAME}.zip" 2>/dev/null; then
                        unzip -q "${REPO_NAME}.zip" -d "$REPO_NAME" 2>/dev/null || true
                        rm "${REPO_NAME}.zip" 2>/dev/null || true
                        echo -e "${GREEN}✅${NC}"
                        ((DOWNLOADED++))
                    else
                        echo -e "${YELLOW}❌ Fehler${NC}"
                        ((FAILED++))
                    fi
                    ;;
            esac
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
    echo "📁 Repositories in: $REPOS_DIR/"
fi

echo ""
echo "🎯 Nächste Schritte:"
echo "  1. Repositories analysieren: codebase_search in services-repos/"
echo "  2. Code verstehen: Architektur, Konfiguration, APIs"
echo "  3. Integration prüfen: Wie werden Services in moOde integriert?"

