#!/bin/bash
################################################################################
# COMPLETE VERIFICATION TEST SUITE
# 
# Checks EVERYTHING that could possibly go wrong:
# - All 5 Moode headers (exact match)
# - Line 1 Main Header (exact position)
# - SSH flag file
# - display_rotate setting
# - fbcon setting
# - [pi5] section
# - worker.php overwrite mechanism
# - Default config.txt comparison
# - All possible failure scenarios
#
# Usage: ./tools/test/complete-verification.sh
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[TEST]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
test_pass() { log "✅ $1"; }
test_fail() { error "❌ $1"; }
test_warn() { warn "⚠️  $1"; }

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 COMPLETE VERIFICATION TEST SUITE                        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# FIND SD CARD
################################################################################

SD_MOUNT=""
if [ -d "/Volumes/bootfs" ]; then
    SD_MOUNT="/Volumes/bootfs"
elif [ -d "/Volumes/boot" ]; then
    SD_MOUNT="/Volumes/boot"
fi

if [ -z "$SD_MOUNT" ] || [ ! -f "$SD_MOUNT/config.txt" ]; then
    error "SD-Karte nicht gefunden oder config.txt fehlt"
    exit 1
fi

info "SD-Karte: $SD_MOUNT"
echo ""

################################################################################
# TEST 1: LINE 1 MAIN HEADER (CRITICAL)
################################################################################

log "=== TEST 1: LINE 2 MAIN HEADER (CRITICAL) ==="
echo ""
echo "WICHTIG: worker.php prüft \$lines[1] = Zeile 2 (Index 1)!"
echo ""

LINE1=$(head -1 "$SD_MOUNT/config.txt")
LINE2=$(sed -n '2p' "$SD_MOUNT/config.txt")
EXPECTED_HEADER="# This file is managed by moOde"

echo "Zeile 1: '$LINE1' (sollte leer sein)"
echo "Zeile 2: '$LINE2' (sollte Main Header sein)"
echo "Erwartet in Zeile 2: '$EXPECTED_HEADER'"
echo ""

if [ -z "$LINE1" ] || [ "$LINE1" = "" ]; then
    test_pass "Zeile 1 ist leer (korrekt)"
    LINE1_EMPTY_OK=true
else
    test_warn "Zeile 1 ist nicht leer: '$LINE1'"
    LINE1_EMPTY_OK=false
fi

if [ "$LINE2" = "$EXPECTED_HEADER" ]; then
    test_pass "Zeile 2 hat exakt den Main Header (wird von worker.php erkannt)"
    LINE2_OK=true
else
    test_fail "Zeile 2 hat NICHT den Main Header"
    test_fail "  → worker.php prüft \$lines[1] = Zeile 2"
    test_fail "  → worker.php wird 'Main header missing' zurückgeben"
    test_fail "  → config.txt wird überschrieben + REBOOT!"
    LINE2_OK=false
fi
echo ""

################################################################################
# TEST 2: ALL 5 HEADERS (EXACT MATCH)
################################################################################

log "=== TEST 2: ALL 5 HEADERS (EXACT MATCH) ==="
echo ""

HEADERS=(
    "# This file is managed by moOde"
    "# Device filters"
    "# General settings"
    "# Do not alter this section"
    "# Audio overlays"
)

HEADER_COUNT=0
HEADER_DETAILS=()

for i in "${!HEADERS[@]}"; do
    HEADER="${HEADERS[$i]}"
    HEADER_NUM=$((i + 1))
    
    if grep -q "^$HEADER" "$SD_MOUNT/config.txt"; then
        COUNT=$(grep -c "^$HEADER" "$SD_MOUNT/config.txt" || echo "0")
        if [ "$COUNT" -eq 1 ]; then
            test_pass "Header $HEADER_NUM: '$HEADER' (1x vorhanden)"
            HEADER_COUNT=$((HEADER_COUNT + 1))
        else
            test_warn "Header $HEADER_NUM: '$HEADER' ($COUNT x vorhanden - doppelt!)"
            HEADER_COUNT=$((HEADER_COUNT + 1))
        fi
    else
        test_fail "Header $HEADER_NUM: '$HEADER' FEHLT"
    fi
done

echo ""
echo "Header-Count: $HEADER_COUNT/5"

if [ "$HEADER_COUNT" -eq 5 ]; then
    test_pass "Alle 5 Headers vorhanden"
    HEADERS_OK=true
else
    test_fail "Nur $HEADER_COUNT/5 Headers vorhanden"
    test_fail "  → worker.php wird 'Required header missing' zurückgeben"
    test_fail "  → config.txt wird überschrieben!"
    HEADERS_OK=false
fi
echo ""

################################################################################
# TEST 3: SSH FLAG FILE
################################################################################

log "=== TEST 3: SSH FLAG FILE ==="
echo ""

SSH_FLAG_BOOT="$SD_MOUNT/ssh"
SSH_FLAG_FIRMWARE="$SD_MOUNT/firmware/ssh"

if [ -f "$SSH_FLAG_BOOT" ]; then
    SIZE=$(stat -f%z "$SSH_FLAG_BOOT" 2>/dev/null || echo "0")
    if [ "$SIZE" -eq 0 ]; then
        test_pass "SSH-Flag vorhanden: $SSH_FLAG_BOOT (leer, korrekt)"
        ls -lh "$SSH_FLAG_BOOT"
        SSH_OK=true
    else
        test_warn "SSH-Flag vorhanden, aber hat Inhalt ($SIZE bytes)"
        SSH_OK=true
    fi
elif [ -f "$SSH_FLAG_FIRMWARE" ]; then
    SIZE=$(stat -f%z "$SSH_FLAG_FIRMWARE" 2>/dev/null || echo "0")
    if [ "$SIZE" -eq 0 ]; then
        test_pass "SSH-Flag vorhanden: $SSH_FLAG_FIRMWARE (leer, korrekt)"
        ls -lh "$SSH_FLAG_FIRMWARE"
        SSH_OK=true
    else
        test_warn "SSH-Flag vorhanden, aber hat Inhalt ($SIZE bytes)"
        SSH_OK=true
    fi
else
    test_fail "SSH-Flag fehlt: $SSH_FLAG_BOOT"
    test_fail "SSH-Flag fehlt: $SSH_FLAG_FIRMWARE"
    test_fail "  → SSH wird beim Boot NICHT aktiviert!"
    SSH_OK=false
fi
echo ""

################################################################################
# TEST 4: DISPLAY ROTATION
################################################################################

log "=== TEST 4: DISPLAY ROTATION ==="
echo ""

if grep -q "^\[pi5\]" "$SD_MOUNT/config.txt"; then
    test_pass "[pi5] Section vorhanden"
    
    # Check display_rotate in [pi5] section (works even if [pi5] is at end of file)
    DISPLAY_ROTATE=$(awk '/^\[pi5\]/ {in_pi5=1; next} /^\[/ && in_pi5 {in_pi5=0} in_pi5 && /^display_rotate=/ {print; exit}' "$SD_MOUNT/config.txt" | head -1)
    
    if [ -n "$DISPLAY_ROTATE" ]; then
        if echo "$DISPLAY_ROTATE" | grep -q "display_rotate=2"; then
            test_pass "display_rotate=2 in [pi5] Section: $DISPLAY_ROTATE"
            DISPLAY_OK=true
        else
            test_fail "display_rotate in [pi5] Section ist NICHT 2: $DISPLAY_ROTATE"
            test_fail "  → Display wird NICHT um 180° rotiert!"
            DISPLAY_OK=false
        fi
    else
        test_fail "display_rotate fehlt in [pi5] Section"
        test_fail "  → Display wird NICHT rotiert!"
        DISPLAY_OK=false
    fi
else
    test_fail "[pi5] Section fehlt"
    test_fail "  → display_rotate kann nicht gesetzt werden!"
    DISPLAY_OK=false
fi
echo ""

################################################################################
# TEST 5: FBCON CONSOLE ROTATION
################################################################################

log "=== TEST 5: FBCON CONSOLE ROTATION ==="
echo ""

if [ -f "$SD_MOUNT/cmdline.txt" ]; then
    CMDLINE=$(cat "$SD_MOUNT/cmdline.txt")
    
    if echo "$CMDLINE" | grep -q "fbcon=rotate:3"; then
        test_pass "fbcon=rotate:3 in cmdline.txt vorhanden"
        FBCON_OK=true
    else
        test_fail "fbcon=rotate:3 fehlt in cmdline.txt"
        test_fail "  → Console wird NICHT rotiert!"
        FBCON_OK=false
    fi
    
    # Check for conflicting video= parameter
    if echo "$CMDLINE" | grep -q "video=.*rotate"; then
        test_fail "cmdline.txt hat video= rotate Parameter (KONFLIKT!)"
        VIDEO_CONFLICT=true
    else
        test_pass "Kein video= rotate Parameter (gut)"
        VIDEO_CONFLICT=false
    fi
else
    test_fail "cmdline.txt nicht gefunden"
    FBCON_OK=false
    VIDEO_CONFLICT=false
fi
echo ""

################################################################################
# TEST 6: WORKER.PHP OVERWRITE SIMULATION
################################################################################

log "=== TEST 6: WORKER.PHP OVERWRITE SIMULATION ==="
echo ""

# Simulate chkBootConfigTxt() logic
# worker.php prüft $lines[1] = Zeile 2 (Index 1)
OVERWRITE_WOULD_HAPPEN=false
OVERWRITE_REASON=""

if [ "$LINE2_OK" != true ]; then
    OVERWRITE_WOULD_HAPPEN=true
    OVERWRITE_REASON="Main header missing (Zeile 2 falsch - worker.php prüft \$lines[1])"
elif [ "$HEADERS_OK" != true ]; then
    OVERWRITE_WOULD_HAPPEN=true
    OVERWRITE_REASON="Required header missing (nur $HEADER_COUNT/5 Headers)"
fi

if [ "$OVERWRITE_WOULD_HAPPEN" = true ]; then
    test_fail "worker.php WÜRDE config.txt überschreiben!"
    test_fail "  Grund: $OVERWRITE_REASON"
    test_fail "  → Alle Einstellungen würden verloren gehen!"
    test_fail "  → display_rotate, SSH-Flag, etc. würden überschrieben!"
else
    test_pass "worker.php wird config.txt NICHT überschreiben"
    test_pass "  → Alle Einstellungen bleiben erhalten"
fi
echo ""

################################################################################
# TEST 7: DEFAULT CONFIG.TXT COMPARISON
################################################################################

log "=== TEST 7: DEFAULT CONFIG.TXT COMPARISON ==="
echo ""

DEFAULT_CONFIG="$PROJECT_ROOT/moode-source/usr/share/moode-player/boot/firmware/config.txt"

if [ -f "$DEFAULT_CONFIG" ]; then
    info "Vergleiche mit moOde Default config.txt..."
    
    DEFAULT_DISPLAY_ROTATE=$(grep "^display_rotate=" "$DEFAULT_CONFIG" | head -1 || echo "")
    CURRENT_DISPLAY_ROTATE=$(grep "^display_rotate=" "$SD_MOUNT/config.txt" | head -1 || echo "")
    
    if [ -n "$DEFAULT_DISPLAY_ROTATE" ]; then
        echo "Default config.txt: $DEFAULT_DISPLAY_ROTATE"
    fi
    if [ -n "$CURRENT_DISPLAY_ROTATE" ]; then
        echo "Aktuelle config.txt: $CURRENT_DISPLAY_ROTATE"
    fi
    
    if [ "$DEFAULT_DISPLAY_ROTATE" = "$CURRENT_DISPLAY_ROTATE" ] && [ -n "$DEFAULT_DISPLAY_ROTATE" ]; then
        test_warn "display_rotate ist gleich wie Default (könnte überschrieben werden)"
    else
        test_pass "display_rotate ist anders als Default (gut)"
    fi
else
    test_warn "Default config.txt nicht gefunden (überspringe Vergleich)"
fi
echo ""

################################################################################
# TEST 8: COMPLETE CONFIG.TXT STRUCTURE
################################################################################

log "=== TEST 8: COMPLETE CONFIG.TXT STRUCTURE ==="
echo ""

# Check if config.txt has proper structure
TOTAL_LINES=$(wc -l < "$SD_MOUNT/config.txt" | tr -d ' ')
echo "config.txt hat $TOTAL_LINES Zeilen"

# Check for critical sections
SECTIONS=("[pi5]" "[all]" "[cm4]" "[pi4]")
SECTION_COUNT=0

for section in "${SECTIONS[@]}"; do
    if grep -q "^$section" "$SD_MOUNT/config.txt"; then
        test_pass "Section vorhanden: $section"
        SECTION_COUNT=$((SECTION_COUNT + 1))
    fi
done

echo ""
echo "Sections gefunden: $SECTION_COUNT/${#SECTIONS[@]}"
echo ""

################################################################################
# FINAL SUMMARY
################################################################################

log "=== FINAL SUMMARY ==="
echo ""

ALL_OK=true

echo "Ergebnisse:"
[ "$LINE1_EMPTY_OK" = true ] && echo "  ✅ Zeile 1 leer" || { echo "  ⚠️  Zeile 1 nicht leer"; }
[ "$LINE2_OK" = true ] && echo "  ✅ Zeile 2 Main Header" || { echo "  ❌ Zeile 2 Main Header"; ALL_OK=false; }
[ "$HEADERS_OK" = true ] && echo "  ✅ Alle 5 Headers" || { echo "  ❌ Alle 5 Headers"; ALL_OK=false; }
[ "$SSH_OK" = true ] && echo "  ✅ SSH-Flag" || { echo "  ❌ SSH-Flag"; ALL_OK=false; }
[ "$DISPLAY_OK" = true ] && echo "  ✅ display_rotate=2" || { echo "  ❌ display_rotate=2"; ALL_OK=false; }
[ "$FBCON_OK" = true ] && echo "  ✅ fbcon=rotate:3" || { echo "  ❌ fbcon=rotate:3"; ALL_OK=false; }
[ "$OVERWRITE_WOULD_HAPPEN" = false ] && echo "  ✅ Kein Overwrite" || { echo "  ❌ Overwrite würde passieren"; ALL_OK=false; }
[ "$VIDEO_CONFLICT" = false ] && echo "  ✅ Kein video= Konflikt" || { echo "  ❌ video= Konflikt"; ALL_OK=false; }

echo ""

if [ "$ALL_OK" = true ]; then
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ✅ ALLE TESTS BESTANDEN                                     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Die SD-Karte ist bereit:"
    echo "  ✅ worker.php wird config.txt NICHT überschreiben"
    echo "  ✅ Display wird korrekt rotiert (180°)"
    echo "  ✅ SSH wird aktiviert"
    echo "  ✅ Console wird rotiert"
    echo ""
    echo "Nächste Schritte:"
    echo "  1. SD-Karte sicher auswerfen"
    echo "  2. SD-Karte in Pi einstecken"
    echo "  3. Pi booten"
    echo "  4. Alles sollte funktionieren!"
else
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ❌ TESTS FEHLGESCHLAGEN                                     ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Es gibt noch Probleme, die behoben werden müssen!"
    echo ""
    exit 1
fi

echo ""

