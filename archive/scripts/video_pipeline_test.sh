#!/bin/bash
# Video Pipeline Test Script für Waveshare 7.9" DSI LCD auf Raspberry Pi 4B
# Vollständiger systematischer Test der gesamten Video-Pipeline

set -euo pipefail

LOG_FILE="video_pipeline_test_$(date +%Y%m%d_%H%M%S).log"
ERROR_COUNT=0
WARNING_COUNT=0

# Farben für Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo "$1" | tee -a "$LOG_FILE"
}

log_section() {
    echo "" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
    echo "$1" | tee -a "$LOG_FILE"
    echo "========================================" | tee -a "$LOG_FILE"
}

log_test() {
    echo "" | tee -a "$LOG_FILE"
    echo "--- $1 ---" | tee -a "$LOG_FILE"
}

check_ok() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓${NC} $1" | tee -a "$LOG_FILE"
        return 0
    else
        echo -e "${RED}✗${NC} $1" | tee -a "$LOG_FILE"
        ((ERROR_COUNT++))
        return 1
    fi
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1" | tee -a "$LOG_FILE"
    ((WARNING_COUNT++))
}

# Start
log_section "VIDEO PIPELINE TEST START"
log "Date: $(date)"
log "Hostname: $(hostname)"
log "Kernel: $(uname -r)"
log "OS: $(cat /etc/os-release | grep PRETTY_NAME | cut -d'"' -f2)"

# ============================================================================
# PHASE 1: BOOT UND HARDWARE-ERKENNUNG
# ============================================================================
log_section "PHASE 1: BOOT UND HARDWARE-ERKENNUNG"

log_test "Test 1.1: Boot-Log Analyse"
dmesg | grep -iE "dsi|mipi|display|panel|vc4|drm|kms" | tee -a "$LOG_FILE" || check_warn "Keine DSI/Display Meldungen im Boot-Log"

log_test "Test 1.2: Hardware-Erkennung"
if ls -la /sys/bus/platform/devices/ | grep -qi dsi; then
    check_ok "DSI Hardware erkannt"
    ls -la /sys/bus/platform/devices/ | grep -i dsi | tee -a "$LOG_FILE"
else
    check_warn "Kein DSI Hardware gefunden"
fi

if [ -d /sys/class/mipi_dsi_host ]; then
    check_ok "MIPI DSI Host Klasse vorhanden"
    ls -la /sys/class/mipi_dsi_host/ | tee -a "$LOG_FILE"
else
    check_warn "MIPI DSI Host Klasse nicht gefunden"
fi

log_test "Test 1.3: Device Tree Erkennung"
if [ -d /proc/device-tree/soc ]; then
    find /proc/device-tree/soc -name "*dsi*" 2>/dev/null | tee -a "$LOG_FILE" || check_warn "Keine DSI Device Tree Nodes gefunden"
fi

# ============================================================================
# PHASE 2: DEVICE TREE UND OVERLAYS
# ============================================================================
log_section "PHASE 2: DEVICE TREE UND OVERLAYS"

log_test "Test 2.1: config.txt Validierung"
CONFIG_FILE="/boot/firmware/config.txt"
if [ ! -f "$CONFIG_FILE" ]; then
    CONFIG_FILE="/boot/config.txt"
fi

if [ -f "$CONFIG_FILE" ]; then
    log "Config file: $CONFIG_FILE"
    log "Relevant settings:"
    grep -E "dtoverlay|display_auto_detect|hdmi" "$CONFIG_FILE" | grep -v "^#" | tee -a "$LOG_FILE"
    
    if grep -q "dtoverlay=vc4-kms-dsi-waveshare-panel" "$CONFIG_FILE"; then
        check_ok "Waveshare DSI Overlay in config.txt"
    else
        check_warn "Waveshare DSI Overlay nicht in config.txt gefunden"
    fi
    
    if grep -q "display_auto_detect=0" "$CONFIG_FILE"; then
        check_ok "display_auto_detect=0 gesetzt"
    else
        check_warn "display_auto_detect nicht auf 0 gesetzt"
    fi
else
    check_warn "config.txt nicht gefunden"
fi

log_test "Test 2.2: Overlay Status"
if command -v vcgencmd >/dev/null 2>&1; then
    vcgencmd get_config dtoverlay | grep -i waveshare && check_ok "Waveshare Overlay geladen" || check_warn "Waveshare Overlay nicht geladen"
fi

log_test "Test 2.3: Device Tree Overlay File"
if [ -f /boot/firmware/overlays/vc4-kms-dsi-waveshare-panel.dtbo ]; then
    check_ok "Overlay .dtbo Datei vorhanden"
    ls -lh /boot/firmware/overlays/vc4-kms-dsi-waveshare-panel.dtbo | tee -a "$LOG_FILE"
elif [ -f /boot/overlays/vc4-kms-dsi-waveshare-panel.dtbo ]; then
    check_ok "Overlay .dtbo Datei vorhanden (altes Verzeichnis)"
    ls -lh /boot/overlays/vc4-kms-dsi-waveshare-panel.dtbo | tee -a "$LOG_FILE"
else
    check_warn "Overlay .dtbo Datei nicht gefunden"
fi

# ============================================================================
# PHASE 3: DSI HOST INITIALISIERUNG
# ============================================================================
log_section "PHASE 3: DSI HOST INITIALISIERUNG"

log_test "Test 3.1: DSI Host Device"
DSI_DEVICES=$(find /sys/devices -name "*dsi*" -type d 2>/dev/null | wc -l)
if [ "$DSI_DEVICES" -gt 0 ]; then
    check_ok "$DSI_DEVICES DSI Device(s) gefunden"
    find /sys/devices -name "*dsi*" -type d 2>/dev/null | tee -a "$LOG_FILE"
else
    check_warn "Keine DSI Devices gefunden"
fi

log_test "Test 3.2: DSI Host Binding"
for dsi in /sys/bus/platform/devices/*dsi*; do
    if [ -d "$dsi" ]; then
        DEV_NAME=$(basename "$dsi")
        log "Device: $DEV_NAME"
        if [ -L "$dsi/driver" ]; then
            DRIVER=$(basename $(readlink "$dsi/driver"))
            check_ok "  -> Bound to: $DRIVER"
        else
            check_warn "  -> No driver bound"
        fi
    fi
done

log_test "Test 3.3: DSI Host Status in dmesg"
dmesg | grep -iE "dsi.*host|mipi.*dsi" | tail -20 | tee -a "$LOG_FILE" || check_warn "Keine DSI Host Meldungen in dmesg"

# ============================================================================
# PHASE 4: PANEL DRIVER UND BINDING
# ============================================================================
log_section "PHASE 4: PANEL DRIVER UND BINDING"

log_test "Test 4.1: Panel Device Erkennung"
PANEL_DEV="/sys/bus/i2c/devices/10-0045"
if [ -d "$PANEL_DEV" ]; then
    check_ok "Panel device 10-0045 gefunden"
    ls -la "$PANEL_DEV/" | tee -a "$LOG_FILE"
else
    check_warn "Panel device 10-0045 nicht gefunden"
    log "Verfügbare I2C-10 Devices:"
    ls -la /sys/bus/i2c/devices/10-* 2>/dev/null | tee -a "$LOG_FILE" || log "Keine Devices auf I2C-10"
fi

log_test "Test 4.2: Panel Driver Binding"
if [ -d "$PANEL_DEV" ]; then
    if [ -L "$PANEL_DEV/driver" ]; then
        DRIVER=$(basename $(readlink "$PANEL_DEV/driver"))
        log "Panel bound to: $DRIVER"
        if [ "$DRIVER" = "ws_touchscreen" ]; then
            check_warn "ws_touchscreen bound (sollte panel_waveshare_dsi sein)"
        else
            check_ok "Panel bound to: $DRIVER"
        fi
        ls -la "/sys/bus/i2c/drivers/$DRIVER/" 2>/dev/null | head -5 | tee -a "$LOG_FILE"
    else
        check_warn "Panel not bound to any driver!"
    fi
fi

log_test "Test 4.3: Panel Driver Module"
PANEL_MODULES=$(lsmod | grep -iE "panel|waveshare|dsi" | wc -l)
if [ "$PANEL_MODULES" -gt 0 ]; then
    check_ok "Panel Driver Module geladen"
    lsmod | grep -iE "panel|waveshare|dsi" | tee -a "$LOG_FILE"
else
    check_warn "Keine Panel Driver Module geladen"
fi

log_test "Test 4.4: Panel Probe Status"
dmesg | grep -iE "panel.*probe|waveshare.*probe|panel.*init" | tail -20 | tee -a "$LOG_FILE" || check_warn "Keine Panel Probe Meldungen"

# ============================================================================
# PHASE 5: DRM/KMS STACK
# ============================================================================
log_section "PHASE 5: DRM/KMS STACK"

log_test "Test 5.1: DRM Device Erkennung"
DRM_DEVICES=$(ls -1 /sys/class/drm/ 2>/dev/null | grep -E "^card" | wc -l)
if [ "$DRM_DEVICES" -gt 0 ]; then
    check_ok "$DRM_DEVICES DRM Card(s) gefunden"
    ls -la /sys/class/drm/ | tee -a "$LOG_FILE"
else
    check_warn "Keine DRM Cards gefunden"
fi

log_test "Test 5.2: DRM Card Status"
for card in /sys/class/drm/card*; do
    if [ -d "$card" ]; then
        CARD_NAME=$(basename "$card")
        log "=== $CARD_NAME ==="
        
        for conn in "$card"/*-*; do
            if [ -d "$conn" ]; then
                CONN_NAME=$(basename "$conn")
                log "  Connector: $CONN_NAME"
                [ -f "$conn/status" ] && log "    Status: $(cat $conn/status)"
                [ -f "$conn/enabled" ] && log "    Enabled: $(cat $conn/enabled)"
                [ -f "$conn/dpms" ] && log "    DPMS: $(cat $conn/dpms)"
                [ -f "$conn/mode" ] && log "    Mode: $(cat $conn/mode)" || log "    Mode: Not set"
            fi
        done
    fi
done | tee -a "$LOG_FILE"

log_test "Test 5.3: VC4 KMS Driver"
dmesg | grep -iE "vc4|kms" | tail -20 | tee -a "$LOG_FILE" || check_warn "Keine VC4/KMS Meldungen"

log_test "Test 5.4: DRM/KMS Module Status"
DRM_MODULES=$(lsmod | grep -iE "drm|vc4|kms" | wc -l)
if [ "$DRM_MODULES" -gt 0 ]; then
    check_ok "DRM/KMS Module geladen"
    lsmod | grep -iE "drm|vc4|kms" | tee -a "$LOG_FILE"
else
    check_warn "Keine DRM/KMS Module geladen"
fi

# ============================================================================
# PHASE 6: FRAMEBUFFER
# ============================================================================
log_section "PHASE 6: FRAMEBUFFER"

log_test "Test 6.1: Framebuffer Devices"
FB_COUNT=$(ls -1 /sys/class/graphics/ 2>/dev/null | grep -E "^fb" | wc -l)
if [ "$FB_COUNT" -gt 0 ]; then
    check_ok "$FB_COUNT Framebuffer Device(s) gefunden"
    for fb in /sys/class/graphics/fb*; do
        if [ -d "$fb" ]; then
            FB_NAME=$(basename "$fb")
            log "=== $FB_NAME ==="
            [ -f "$fb/name" ] && log "  Name: $(cat $fb/name)"
            [ -f "$fb/virtual_size" ] && log "  Virtual Size: $(cat $fb/virtual_size)"
        fi
    done | tee -a "$LOG_FILE"
else
    check_warn "Keine Framebuffer Devices gefunden"
fi

log_test "Test 6.2: Framebuffer Resolution"
FB0="/sys/class/graphics/fb0"
if [ -d "$FB0" ] && [ -f "$FB0/virtual_size" ]; then
    VIRT_SIZE=$(cat "$FB0/virtual_size")
    log "Framebuffer Resolution: $VIRT_SIZE"
    if echo "$VIRT_SIZE" | grep -q "1280,400"; then
        check_ok "Korrekte Resolution für Waveshare 7.9\" (1280x400)"
    else
        check_warn "Falsche Resolution! Erwartet: 1280,400, Gefunden: $VIRT_SIZE"
    fi
else
    check_warn "Framebuffer fb0 nicht verfügbar"
fi

# ============================================================================
# PHASE 7: DISPLAY INITIALISIERUNG
# ============================================================================
log_section "PHASE 7: DISPLAY INITIALISIERUNG"

log_test "Test 7.1: DSI-1 Connector Status"
DSI_CONN="/sys/class/drm/card1-DSI-1"
if [ -d "$DSI_CONN" ]; then
    check_ok "DSI-1 Connector gefunden"
    [ -f "$DSI_CONN/status" ] && log "  Status: $(cat $DSI_CONN/status)"
    [ -f "$DSI_CONN/enabled" ] && log "  Enabled: $(cat $DSI_CONN/enabled)"
    [ -f "$DSI_CONN/dpms" ] && log "  DPMS: $(cat $DSI_CONN/dpms)"
    [ -f "$DSI_CONN/mode" ] && log "  Mode: $(cat $DSI_CONN/mode)" || log "  Mode: Not set"
else
    check_warn "DSI-1 Connector nicht gefunden"
    log "Verfügbare Connectors:"
    ls -la /sys/class/drm/card*/ 2>/dev/null | grep -E "^-.*DSI" | tee -a "$LOG_FILE" || log "Keine DSI Connectors gefunden"
fi

log_test "Test 7.2: Display Mode Setting"
if [ -d "$DSI_CONN" ]; then
    if [ -f "$DSI_CONN/mode" ]; then
        MODE=$(cat "$DSI_CONN/mode")
        if [ -n "$MODE" ]; then
            check_ok "Display Mode gesetzt: $MODE"
        else
            check_warn "Display Mode leer"
        fi
    else
        check_warn "Display Mode Datei nicht vorhanden"
    fi
    
    if [ -f "$DSI_CONN/modes" ]; then
        log "Verfügbare Modes:"
        cat "$DSI_CONN/modes" | head -5 | tee -a "$LOG_FILE"
    fi
fi

log_test "Test 7.3: Panel Initialisierung"
dmesg | grep -iE "panel.*init|panel.*enable|panel.*power" | tail -20 | tee -a "$LOG_FILE" || check_warn "Keine Panel Initialisierung Meldungen"

# ============================================================================
# PHASE 8: I2C KOMMUNIKATION
# ============================================================================
log_section "PHASE 8: I2C KOMMUNIKATION"

log_test "Test 8.1: I2C Bus Verfügbarkeit"
if [ -c /dev/i2c-10 ]; then
    check_ok "I2C-10 device vorhanden"
    if command -v i2cdetect >/dev/null 2>&1; then
        log "Scanning I2C-10:"
        i2cdetect -y 10 2>&1 | tee -a "$LOG_FILE"
    else
        log "i2cdetect nicht verfügbar, prüfe sysfs:"
        ls -la /sys/bus/i2c/devices/10-* 2>/dev/null | tee -a "$LOG_FILE" || log "Keine Devices auf I2C-10"
    fi
else
    check_warn "I2C-10 device nicht gefunden"
fi

log_test "Test 8.2: Panel I2C Kommunikation"
PANEL_ADDR="0x45"
I2C_BUS="10"

if [ -c /dev/i2c-$I2C_BUS ]; then
    if command -v i2cget >/dev/null 2>&1; then
        log "Versuche I2C Read von $PANEL_ADDR..."
        if i2cget -y $I2C_BUS $PANEL_ADDR 0x00 2>/dev/null >/dev/null; then
            check_ok "I2C Kommunikation erfolgreich"
        else
            check_warn "I2C Kommunikation fehlgeschlagen"
        fi
    else
        check_warn "i2cget nicht verfügbar"
    fi
    
    log "I2C Fehler in dmesg:"
    dmesg | grep -iE "i2c.*$PANEL_ADDR|i2c.*timeout|i2c.*error" | tail -10 | tee -a "$LOG_FILE" || log "Keine I2C Fehler gefunden"
fi

log_test "Test 8.3: I2C Driver Status"
if [ -d "$PANEL_DEV" ]; then
    if [ -L "$PANEL_DEV/driver" ]; then
        DRIVER=$(basename $(readlink "$PANEL_DEV/driver"))
        log "Driver: $DRIVER"
        [ -f "$PANEL_DEV/power/control" ] && log "Power Control: $(cat $PANEL_DEV/power/control)"
    fi
fi

# ============================================================================
# PHASE 9: BACKLIGHT CONTROL
# ============================================================================
log_section "PHASE 9: BACKLIGHT CONTROL"

log_test "Test 9.1: Backlight Device"
BL_COUNT=$(ls -1 /sys/class/backlight/ 2>/dev/null | wc -l)
if [ "$BL_COUNT" -gt 0 ]; then
    check_ok "$BL_COUNT Backlight Device(s) gefunden"
    for bl in /sys/class/backlight/*; do
        if [ -d "$bl" ]; then
            BL_NAME=$(basename "$bl")
            log "=== $BL_NAME ==="
            [ -f "$bl/brightness" ] && log "  Brightness: $(cat $bl/brightness)"
            [ -f "$bl/max_brightness" ] && log "  Max Brightness: $(cat $bl/max_brightness)"
        fi
    done | tee -a "$LOG_FILE"
else
    check_warn "Keine Backlight Devices gefunden"
fi

# ============================================================================
# PHASE 10: VIDEO SIGNAL OUTPUT
# ============================================================================
log_section "PHASE 10: VIDEO SIGNAL OUTPUT"

log_test "Test 10.1: Display Signal Test"
if [ -d "$DSI_CONN" ]; then
    STATUS=$(cat "$DSI_CONN/status" 2>/dev/null || echo "unknown")
    DPMS=$(cat "$DSI_CONN/dpms" 2>/dev/null || echo "unknown")
    MODE=$(cat "$DSI_CONN/mode" 2>/dev/null || echo "")
    
    log "DSI-1 Status: $STATUS"
    log "DSI-1 DPMS: $DPMS"
    log "DSI-1 Mode: ${MODE:-Not set}"
    
    if [ "$STATUS" = "connected" ] && [ "$DPMS" = "On" ] && [ -n "$MODE" ]; then
        check_ok "Display Signal sollte aktiv sein"
    else
        check_warn "Display Signal möglicherweise nicht aktiv"
    fi
fi

log_test "Test 10.2: Framebuffer Output Test"
if [ -c /dev/fb0 ]; then
    check_ok "Framebuffer Device /dev/fb0 vorhanden"
    if command -v fbset >/dev/null 2>&1; then
        log "Framebuffer Info:"
        fbset -i 2>&1 | tee -a "$LOG_FILE"
    fi
else
    check_warn "Framebuffer Device /dev/fb0 nicht vorhanden"
fi

log_test "Test 10.3: Visual Display Check"
log "Bitte prüfen Sie visuell:"
log "1. Ist die grüne LED am Display an/blinkend?"
log "2. Zeigt das Display ein Bild?"
log "3. Ist das Bild korrekt (nicht verzerrt/verschoben)?"
log "4. Funktioniert der Touchscreen (falls aktiviert)?"

# ============================================================================
# ZUSAMMENFASSUNG
# ============================================================================
log_section "TEST ZUSAMMENFASSUNG"
log "Fehler: $ERROR_COUNT"
log "Warnungen: $WARNING_COUNT"
log "Test abgeschlossen: $(date)"
log ""
log "Log-Datei: $LOG_FILE"

if [ $ERROR_COUNT -eq 0 ] && [ $WARNING_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ Alle Tests erfolgreich!${NC}"
    exit 0
elif [ $ERROR_COUNT -eq 0 ]; then
    echo -e "${YELLOW}⚠ Tests mit Warnungen abgeschlossen${NC}"
    exit 0
else
    echo -e "${RED}✗ Tests mit Fehlern abgeschlossen${NC}"
    exit 1
fi

