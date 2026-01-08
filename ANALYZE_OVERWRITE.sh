#!/bin/bash
# ANALYZE OVERWRITE MECHANISM
# Analyzes how worker.php overwrites config.txt

PROJECT_ROOT="/Users/andrevollmer/moodeaudio-cursor"
SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 ANALYZE OVERWRITE MECHANISM                              ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# STEP 1: CHECK REQUIRED HEADERS
################################################################################

echo "=== STEP 1: REQUIRED HEADERS ==="
echo ""

CONSTANTS_FILE="$PROJECT_ROOT/moode-source/www/inc/constants.php"
if [ -f "$CONSTANTS_FILE" ]; then
    echo "Header-Definitionen:"
    grep -E "CFG_MAIN_FILE_HEADER|CFG_DEVICE_FILTERS_HEADER|CFG_GENERAL_SETTINGS_HEADER|CFG_DO_NOT_ALTER_HEADER|CFG_AUDIO_OVERLAYS_HEADER|CFG_HEADERS_REQUIRED" "$CONSTANTS_FILE" | head -10
    echo ""
    
    # Extract header values
    MAIN_HEADER=$(grep "CFG_MAIN_FILE_HEADER" "$CONSTANTS_FILE" | grep -oP "'.*?'" | head -1 | tr -d "'")
    DEVICE_HEADER=$(grep "CFG_DEVICE_FILTERS_HEADER" "$CONSTANTS_FILE" | grep -oP "'.*?'" | head -1 | tr -d "'")
    GENERAL_HEADER=$(grep "CFG_GENERAL_SETTINGS_HEADER" "$CONSTANTS_FILE" | grep -oP "'.*?'" | head -1 | tr -d "'")
    DO_NOT_ALTER_HEADER=$(grep "CFG_DO_NOT_ALTER_HEADER" "$CONSTANTS_FILE" | grep -oP "'.*?'" | head -1 | tr -d "'")
    AUDIO_HEADER=$(grep "CFG_AUDIO_OVERLAYS_HEADER" "$CONSTANTS_FILE" | grep -oP "'.*?'" | head -1 | tr -d "'")
    REQUIRED_COUNT=$(grep "CFG_HEADERS_REQUIRED" "$CONSTANTS_FILE" | grep -oP "= \K[0-9]+")
    
    echo "Erforderliche Headers ($REQUIRED_COUNT):"
    echo "  1. $MAIN_HEADER"
    echo "  2. $DEVICE_HEADER"
    echo "  3. $GENERAL_HEADER"
    echo "  4. $DO_NOT_ALTER_HEADER"
    echo "  5. $AUDIO_HEADER"
    echo ""
else
    echo "❌ constants.php nicht gefunden"
fi

################################################################################
# STEP 2: CHECK chkBootConfigTxt() LOGIC
################################################################################

echo "=== STEP 2: chkBootConfigTxt() LOGIC ==="
echo ""

COMMON_FILE="$PROJECT_ROOT/moode-source/www/inc/common.php"
if [ -f "$COMMON_FILE" ]; then
    echo "chkBootConfigTxt() Funktion:"
    sed -n '559,594p' "$COMMON_FILE"
    echo ""
    
    echo "Logik:"
    echo "  1. Liest config.txt Zeile für Zeile"
    echo "  2. Prüft Zeile 1 auf Main Header"
    echo "  3. Zählt alle 5 Headers"
    echo "  4. Wenn < 5 Headers → 'Required header missing'"
    echo "  5. Wenn Zeile 1 falsch → 'Main header missing'"
    echo ""
fi

################################################################################
# STEP 3: CHECK worker.php OVERWRITE
################################################################################

echo "=== STEP 3: worker.php OVERWRITE ==="
echo ""

WORKER_FILE="$PROJECT_ROOT/moode-source/www/daemon/worker.php"
if [ -f "$WORKER_FILE" ]; then
    echo "worker.php Zeilen 105-118:"
    sed -n '105,118p' "$WORKER_FILE"
    echo ""
    
    echo "Überschreib-Logik:"
    echo "  Zeile 106: \$status = chkBootConfigTxt();"
    echo "  Zeile 107-108: Wenn 'Required headers present' → OK"
    echo "  Zeile 109-113: Wenn 'Required header missing' → ÜBERSCHREIBT!"
    echo "    sysCmd('cp /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');"
    echo "  Zeile 114-118: Wenn 'Main header missing' → ÜBERSCHREIBT + REBOOT!"
    echo "    sysCmd('cp -f /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');"
    echo "    sysCmd('reboot');"
    echo ""
fi

################################################################################
# STEP 4: CHECK SD CARD CONFIG.TXT
################################################################################

echo "=== STEP 4: CHECK SD CARD CONFIG.TXT ==="
echo ""

if [ -d "$SD_MOUNT" ] && [ -f "$SD_MOUNT/config.txt" ]; then
    echo "SD-Karte: $SD_MOUNT"
    echo ""
    
    # Check each header
    HEADER_COUNT=0
    
    if grep -q "^# This file is managed by moOde" "$SD_MOUNT/config.txt"; then
        echo "✅ Header 1: Main Header vorhanden"
        HEADER_COUNT=$((HEADER_COUNT + 1))
    else
        echo "❌ Header 1: Main Header FEHLT"
    fi
    
    if grep -q "^# Device filters" "$SD_MOUNT/config.txt"; then
        echo "✅ Header 2: Device filters vorhanden"
        HEADER_COUNT=$((HEADER_COUNT + 1))
    else
        echo "❌ Header 2: Device filters FEHLT"
    fi
    
    if grep -q "^# General settings" "$SD_MOUNT/config.txt"; then
        echo "✅ Header 3: General settings vorhanden"
        HEADER_COUNT=$((HEADER_COUNT + 1))
    else
        echo "❌ Header 3: General settings FEHLT"
    fi
    
    if grep -q "^# Do not alter this section" "$SD_MOUNT/config.txt"; then
        echo "✅ Header 4: Do not alter vorhanden"
        HEADER_COUNT=$((HEADER_COUNT + 1))
    else
        echo "❌ Header 4: Do not alter FEHLT"
    fi
    
    if grep -q "^# Audio overlays" "$SD_MOUNT/config.txt"; then
        echo "✅ Header 5: Audio overlays vorhanden"
        HEADER_COUNT=$((HEADER_COUNT + 1))
    else
        echo "❌ Header 5: Audio overlays FEHLT"
    fi
    
    echo ""
    echo "Header-Count: $HEADER_COUNT/5"
    echo ""
    
    if [ "$HEADER_COUNT" -eq 5 ]; then
        echo "✅ ALLE HEADERS VORHANDEN"
        echo "   → worker.php wird config.txt NICHT überschreiben"
    else
        echo "❌ HEADERS FEHLEN"
        echo "   → worker.php WIRD config.txt ÜBERSCHREIBEN beim Boot!"
        echo "   → Alle Einstellungen (display_rotate, etc.) werden verloren!"
    fi
    echo ""
    
    # Check line 1
    LINE1=$(head -1 "$SD_MOUNT/config.txt")
    echo "Zeile 1: $LINE1"
    if echo "$LINE1" | grep -q "managed by moOde"; then
        echo "✅ Zeile 1 hat Main Header (korrekt)"
    else
        echo "❌ Zeile 1 hat KEINEN Main Header"
        echo "   → worker.php wird 'Main header missing' zurückgeben"
        echo "   → config.txt wird überschrieben + REBOOT!"
    fi
else
    echo "❌ SD-Karte oder config.txt nicht gefunden"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ ANALYSE ABGESCHLOSSEN                                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

