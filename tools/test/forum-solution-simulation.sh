#!/bin/bash
################################################################################
#
# Forum Solution Simulation - Waveshare 7.9" Display
# Simuliert die Forum-Lösung für das Waveshare 7.9" Display
# Quelle: https://moodeaudio.org/forum/showthread.php?tid=6416
#
################################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test counters
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARN=0

test_pass() {
    echo -e "${GREEN}✅ PASS:${NC} $1"
    ((TESTS_PASSED++))
}

test_fail() {
    echo -e "${RED}❌ FAIL:${NC} $1"
    ((TESTS_FAILED++))
}

test_warn() {
    echo -e "${YELLOW}⚠️  WARN:${NC} $1"
    ((TESTS_WARN++))
}

test_info() {
    echo -e "${BLUE}ℹ️  INFO:${NC} $1"
}

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  FORUM SOLUTION SIMULATION - WAVESHARE 7.9\" DISPLAY        ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Quelle: Moode Audio Forum Thread 6416"
echo "Link: https://moodeaudio.org/forum/showthread.php?tid=6416"
echo ""

# Find SD card mount point
if [ -d "/Volumes/bootfs" ]; then
    SD_MOUNT="/Volumes/bootfs"
elif [ -d "/Volumes/boot" ]; then
    SD_MOUNT="/Volumes/boot"
else
    test_fail "SD-Karte nicht gefunden"
    echo ""
    echo "Bitte SD-Karte in Mac einlegen"
    exit 1
fi

test_info "SD-Karte gefunden: $SD_MOUNT"
echo ""

################################################################################
# TEST 1: cmdline.txt - video= Parameter (Forum-Lösung)
################################################################################

echo "=== TEST 1: cmdline.txt - video= Parameter (Forum-Lösung) ==="
echo ""

CMDLINE_FILE="$SD_MOUNT/cmdline.txt"
if [ ! -f "$CMDLINE_FILE" ]; then
    test_fail "cmdline.txt nicht gefunden"
else
    CMDLINE_CONTENT=$(cat "$CMDLINE_FILE")
    
    # Prüfe video= Parameter für Pi 5
    if echo "$CMDLINE_CONTENT" | grep -q "video=HDMI-A-2:400x1280M@60,rotate=90"; then
        test_pass "video=HDMI-A-2:400x1280M@60,rotate=90 gefunden (Pi 5 - Forum-Lösung)"
        VIDEO_PARAM_OK=true
    elif echo "$CMDLINE_CONTENT" | grep -q "video=HDMI-A-1:400x1280M@60,rotate=90"; then
        test_warn "video=HDMI-A-1:400x1280M@60,rotate=90 gefunden (Pi 4 - Forum-Lösung)"
        test_info "Für Pi 5 sollte HDMI-A-2 verwendet werden"
        VIDEO_PARAM_OK=true
    elif echo "$CMDLINE_CONTENT" | grep -q "video="; then
        VIDEO_PARAM=$(echo "$CMDLINE_CONTENT" | grep -o "video=[^ ]*")
        test_fail "video= Parameter gefunden, aber nicht Forum-Lösung: $VIDEO_PARAM"
        test_info "Erwartet: video=HDMI-A-2:400x1280M@60,rotate=90"
        VIDEO_PARAM_OK=false
    else
        test_fail "Kein video= Parameter gefunden"
        test_info "Forum-Lösung erfordert: video=HDMI-A-2:400x1280M@60,rotate=90"
        VIDEO_PARAM_OK=false
    fi
    
    # Prüfe fbcon=rotate:3 (Console Rotation)
    if echo "$CMDLINE_CONTENT" | grep -q "fbcon=rotate:3"; then
        test_pass "fbcon=rotate:3 gefunden (Console Rotation 180°)"
        FBCON_OK=true
    else
        test_warn "fbcon=rotate:3 nicht gefunden"
        FBCON_OK=false
    fi
    
    echo ""
    echo "cmdline.txt Inhalt:"
    echo "$CMDLINE_CONTENT"
    echo ""
fi

################################################################################
# TEST 2: config.txt - Display Settings
################################################################################

echo "=== TEST 2: config.txt - Display Settings ==="
echo ""

CONFIG_FILE="$SD_MOUNT/config.txt"
if [ ! -f "$CONFIG_FILE" ]; then
    test_fail "config.txt nicht gefunden"
else
    # Prüfe display_rotate in [pi5] Section
    if grep -A 10 "\[pi5\]" "$CONFIG_FILE" | grep -q "display_rotate=2"; then
        test_pass "display_rotate=2 in [pi5] Section gefunden (180° Rotation)"
        DISPLAY_ROTATE_OK=true
    elif grep -A 10 "\[pi5\]" "$CONFIG_FILE" | grep -q "display_rotate=0"; then
        test_warn "display_rotate=0 in [pi5] Section gefunden"
        test_info "Forum-Lösung verwendet Portrait-Start, dann Rotation"
        DISPLAY_ROTATE_OK=true
    else
        test_warn "display_rotate nicht in [pi5] Section gefunden"
        DISPLAY_ROTATE_OK=false
    fi
    
    # Prüfe hdmi_timings
    if grep -A 10 "\[pi5\]" "$CONFIG_FILE" | grep -q "hdmi_timings.*1280.*400"; then
        test_pass "hdmi_timings für 1280x400 gefunden"
        HDMI_TIMINGS_OK=true
    else
        test_warn "hdmi_timings für 1280x400 nicht gefunden"
        HDMI_TIMINGS_OK=false
    fi
    
    # Prüfe disable_splash
    if grep -q "disable_splash=1" "$CONFIG_FILE"; then
        test_pass "disable_splash=1 gefunden (kein Splash Screen)"
    else
        test_warn "disable_splash=1 nicht gefunden"
    fi
    
    echo ""
fi

################################################################################
# TEST 3: fix-xinitrc-display.sh Script
################################################################################

echo "=== TEST 3: fix-xinitrc-display.sh Script ==="
echo ""

FIX_SCRIPT="$SD_MOUNT/fix-xinitrc-display.sh"
if [ -f "$FIX_SCRIPT" ]; then
    test_pass "fix-xinitrc-display.sh Script gefunden"
    
    # Prüfe Script-Inhalt
    if grep -q "xrandr --output HDMI" "$FIX_SCRIPT"; then
        test_pass "Script enthält xrandr Rotation"
    else
        test_warn "Script enthält keine xrandr Rotation"
    fi
    
    if grep -q "SCREENSIZE.*\$3.*\$2" "$FIX_SCRIPT"; then
        test_pass "Script enthält SCREENSIZE Swap (Portrait → Landscape)"
    else
        test_warn "Script enthält keinen SCREENSIZE Swap"
    fi
    
    if grep -q "hdmi_scn_orient.*portrait" "$FIX_SCRIPT"; then
        test_pass "Script setzt hdmi_scn_orient auf 'portrait'"
    else
        test_warn "Script setzt hdmi_scn_orient nicht auf 'portrait'"
    fi
    
    if [ -x "$FIX_SCRIPT" ]; then
        test_pass "Script ist ausführbar"
    else
        test_warn "Script ist nicht ausführbar (chmod +x fehlt)"
    fi
    
    echo ""
else
    test_fail "fix-xinitrc-display.sh Script nicht gefunden"
    test_info "Script sollte auf SD-Karte erstellt werden"
    echo ""
fi

################################################################################
# TEST 4: Forum-Lösung Simulation - Erwartetes Verhalten
################################################################################

echo "=== TEST 4: Forum-Lösung Simulation - Erwartetes Verhalten ==="
echo ""

test_info "Forum-Lösung Funktionsweise:"
echo "  1. Display startet im Portrait-Modus (400x1280)"
echo "  2. video= Parameter rotiert zu Landscape (1280x400)"
echo "  3. .xinitrc rotiert X11 Display weiter"
echo "  4. SCREENSIZE wird getauscht (Portrait → Landscape)"
echo "  5. Moode hdmi_scn_orient wird auf 'landscape' gesetzt"
echo ""

# Simuliere erwartetes Verhalten
EXPECTED_BEHAVIOR_OK=true

if [ "$VIDEO_PARAM_OK" = true ]; then
    test_pass "✅ video= Parameter korrekt (Display startet Portrait, wird rotiert)"
else
    test_fail "❌ video= Parameter fehlt oder falsch"
    EXPECTED_BEHAVIOR_OK=false
fi

if [ -f "$FIX_SCRIPT" ]; then
    test_pass "✅ .xinitrc Fix-Script vorhanden"
else
    test_warn "⚠️  .xinitrc Fix-Script fehlt (muss nach Boot ausgeführt werden)"
fi

echo ""

################################################################################
# TEST 5: Vergleich mit Standard-Konfiguration
################################################################################

echo "=== TEST 5: Vergleich mit Standard-Konfiguration ==="
echo ""

test_info "Standard-Konfiguration (NICHT Forum-Lösung):"
echo "  - video=HDMI-A-2:1280x400@60 (direkt Landscape)"
echo "  - display_rotate=2 (180° Rotation)"
echo ""

test_info "Forum-Lösung (WAVESHARE 7.9\"):"
echo "  - video=HDMI-A-2:400x1280M@60,rotate=90 (Portrait → Landscape)"
echo "  - .xinitrc rotiert zusätzlich"
echo "  - SCREENSIZE Swap notwendig"
echo ""

if [ "$VIDEO_PARAM_OK" = true ]; then
    if echo "$CMDLINE_CONTENT" | grep -q "400x1280M@60,rotate=90"; then
        test_pass "✅ Forum-Lösung aktiv (Portrait-Start mit Rotation)"
    else
        test_warn "⚠️  Standard-Konfiguration aktiv (direkt Landscape)"
    fi
fi

echo ""

################################################################################
# FINAL SUMMARY
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  TEST SUMMARY                                                ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "Tests passed:  $TESTS_PASSED"
echo "Tests failed:  $TESTS_FAILED"
echo "Tests warning: $TESTS_WARN"
echo ""

if [ $TESTS_FAILED -eq 0 ]; then
    if [ "$VIDEO_PARAM_OK" = true ] && [ -f "$FIX_SCRIPT" ]; then
        echo -e "${GREEN}✅ FORUM-LÖSUNG KORREKT KONFIGURIERT${NC}"
        echo ""
        echo "Erwartetes Verhalten nach Boot:"
        echo "  ✅ Display startet Portrait (400x1280)"
        echo "  ✅ Wird zu Landscape (1280x400) rotiert"
        echo "  ✅ Nach Reboot bleibt Orientierung korrekt"
        echo ""
        echo "Nächste Schritte:"
        echo "  1. SD-Karte in Pi einlegen"
        echo "  2. Boot durchführen"
        echo "  3. SSH zum Pi: sudo /boot/firmware/fix-xinitrc-display.sh"
        echo "  4. Reboot testen"
    else
        echo -e "${YELLOW}⚠️  FORUM-LÖSUNG TEILWEISE KONFIGURIERT${NC}"
        echo ""
        if [ "$VIDEO_PARAM_OK" != true ]; then
            echo "❌ video= Parameter fehlt oder falsch"
        fi
        if [ ! -f "$FIX_SCRIPT" ]; then
            echo "❌ fix-xinitrc-display.sh Script fehlt"
        fi
    fi
else
    echo -e "${RED}❌ FORUM-LÖSUNG NICHT KORREKT KONFIGURIERT${NC}"
    echo ""
    echo "Bitte korrigieren:"
    if [ "$VIDEO_PARAM_OK" != true ]; then
        echo "  - cmdline.txt: video=HDMI-A-2:400x1280M@60,rotate=90 hinzufügen"
    fi
    if [ ! -f "$FIX_SCRIPT" ]; then
        echo "  - fix-xinitrc-display.sh Script erstellen"
    fi
fi

echo ""
exit $TESTS_FAILED

