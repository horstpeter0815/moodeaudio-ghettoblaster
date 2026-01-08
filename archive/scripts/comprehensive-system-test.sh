#!/bin/bash
# Comprehensive System Test Script
# Testet alle Aspekte des Systems mit Visualisierung für Fehlerfälle
# Erweitert die Wissensbasis und ermöglicht Analysen

PI5_ALIAS="pi2"
PI5_IP="192.168.178.143"
TEST_DATE=$(date +%Y%m%d_%H%M%S)
LOG_DIR="test-results"
LOG_FILE="$LOG_DIR/system-test-$TEST_DATE.log"
REPORT_FILE="$LOG_DIR/system-test-report-$TEST_DATE.md"
VISUALIZATION_FILE="$LOG_DIR/system-test-visualization-$TEST_DATE.txt"

# Farben für Terminal-Output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Test-Ergebnisse
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_WARNING=0
CRITICAL_ISSUES=0

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}" | tee -a "$LOG_FILE"
    ((TESTS_PASSED++))
}

log_error() {
    echo -e "${RED}❌ $1${NC}" | tee -a "$LOG_FILE"
    ((TESTS_FAILED++))
    ((CRITICAL_ISSUES++))
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}" | tee -a "$LOG_FILE"
    ((TESTS_WARNING++))
}

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}" | tee -a "$LOG_FILE"
}

create_visualization() {
    local section="$1"
    local status="$2"
    local details="$3"
    
    case "$status" in
        "PASS")
            echo "✅ $section: PASS" >> "$VISUALIZATION_FILE"
            ;;
        "FAIL")
            echo "❌ $section: FAIL" >> "$VISUALIZATION_FILE"
            ;;
        "WARN")
            echo "⚠️  $section: WARN" >> "$VISUALIZATION_FILE"
            ;;
    esac
    if [ -n "$details" ]; then
        echo "   $details" >> "$VISUALIZATION_FILE"
    fi
    echo "" >> "$VISUALIZATION_FILE"
}

# Erstelle Verzeichnis
mkdir -p "$LOG_DIR"

echo "╔══════════════════════════════════════════════════════════════╗" | tee -a "$LOG_FILE"
echo "║     COMPREHENSIVE SYSTEM TEST - moOde Audio Pi 5           ║" | tee -a "$LOG_FILE"
echo "║     Date: $(date)                                           ║" | tee -a "$LOG_FILE"
echo "╚══════════════════════════════════════════════════════════════╝" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Prüfe Verbindung
log "=== CONNECTION TEST ==="
if ! ping -c 1 -W 1000 "$PI5_IP" >/dev/null 2>&1; then
    log_error "Pi 5 ist offline"
    exit 1
fi
if ! ssh -o ConnectTimeout=5 "$PI5_ALIAS" "echo 'Online!'" >/dev/null 2>&1; then
    log_error "SSH-Verbindung fehlgeschlagen"
    exit 1
fi
log_success "Pi 5 ist online und erreichbar"
create_visualization "Connection" "PASS" "Pi 5 online"

log ""
log "=== HARDWARE DETECTION ==="

# Audio Hardware
log "1. Audio Hardware (HiFiBerry AMP100):"
AUDIO_CARDS=$(./pi5-ssh.sh "aplay -l 2>/dev/null | grep -i hifiberry | wc -l")
if [ "$AUDIO_CARDS" -gt 0 ]; then
    log_success "HiFiBerry AMP100 erkannt ($AUDIO_CARDS Karte(n))"
    create_visualization "Audio Hardware" "PASS" "HiFiBerry AMP100 erkannt"
    ./pi5-ssh.sh "aplay -l" | tee -a "$LOG_FILE"
else
    log_error "HiFiBerry AMP100 NICHT erkannt"
    create_visualization "Audio Hardware" "FAIL" "HiFiBerry AMP100 nicht erkannt"
    ./pi5-ssh.sh "aplay -l" | tee -a "$LOG_FILE"
fi

# I2C Bus
log ""
log "2. I2C Bus:"
I2C_DEVICES=$(./pi5-ssh.sh "i2cdetect -y 1 2>/dev/null | grep -v '^      ' | grep -v '^[0-9a-f]:' | wc -l")
if [ "$I2C_DEVICES" -gt 0 ]; then
    log_success "I2C Bus 1 aktiv ($I2C_DEVICES Gerät(e) erkannt)"
    create_visualization "I2C Bus" "PASS" "$I2C_DEVICES Geräte erkannt"
    ./pi5-ssh.sh "i2cdetect -y 1" | tee -a "$LOG_FILE"
else
    log_warning "I2C Bus 1: Keine Geräte erkannt (kann normal sein)"
    create_visualization "I2C Bus" "WARN" "Keine Geräte erkannt"
fi

# Display Hardware
log ""
log "3. Display Hardware:"
DISPLAY_CONNECTED=$(./pi5-ssh.sh "xrandr 2>/dev/null | grep -E 'connected|HDMI' | grep -v disconnected | wc -l")
if [ "$DISPLAY_CONNECTED" -gt 0 ]; then
    log_success "Display erkannt ($DISPLAY_CONNECTED Ausgabe(n))"
    create_visualization "Display Hardware" "PASS" "$DISPLAY_CONNECTED Ausgabe(n)"
    ./pi5-ssh.sh "xrandr 2>/dev/null | grep -E 'connected|HDMI' | grep -v disconnected" | tee -a "$LOG_FILE"
    DISPLAY_RES=$(./pi5-ssh.sh "xrandr 2>/dev/null | grep '*' | head -1")
    log_info "Auflösung: $DISPLAY_RES"
else
    log_error "Display NICHT erkannt"
    create_visualization "Display Hardware" "FAIL" "Display nicht erkannt"
fi

# Touchscreen Hardware
log ""
log "4. Touchscreen Hardware:"
TOUCHSCREEN=$(./pi5-ssh.sh "xinput list 2>/dev/null | grep -i 'WaveShare\|FT6236\|touch' | wc -l")
if [ "$TOUCHSCREEN" -gt 0 ]; then
    log_success "Touchscreen erkannt ($TOUCHSCREEN Gerät(e))"
    create_visualization "Touchscreen Hardware" "PASS" "$TOUCHSCREEN Gerät(e)"
    ./pi5-ssh.sh "xinput list | grep -i 'WaveShare\|FT6236\|touch'" | tee -a "$LOG_FILE"
else
    log_warning "Touchscreen NICHT erkannt"
    create_visualization "Touchscreen Hardware" "WARN" "Touchscreen nicht erkannt"
fi

log ""
log "=== SYSTEM SERVICES ==="

# Essentielle Services
ESSENTIAL_SERVICES=("mpd.service" "localdisplay.service" "nginx.service" "php8.4-fpm.service")
for service in "${ESSENTIAL_SERVICES[@]}"; do
    log "Prüfe: $service"
    STATUS=$(./pi5-ssh.sh "systemctl is-active $service 2>/dev/null")
    if [ "$STATUS" = "active" ]; then
        log_success "$service: AKTIV"
        create_visualization "Service: $service" "PASS" "Aktiv"
    else
        log_error "$service: NICHT AKTIV (Status: $STATUS)"
        create_visualization "Service: $service" "FAIL" "Nicht aktiv: $STATUS"
    fi
done

# Touchscreen Service
log ""
log "Prüfe: ft6236-delay.service"
STATUS=$(./pi5-ssh.sh "systemctl is-enabled ft6236-delay.service 2>/dev/null")
if [ "$STATUS" = "enabled" ]; then
    log_success "ft6236-delay.service: ENABLED"
    create_visualization "Service: ft6236-delay" "PASS" "Enabled"
else
    log_warning "ft6236-delay.service: NICHT ENABLED"
    create_visualization "Service: ft6236-delay" "WARN" "Nicht enabled"
fi

# PeppyMeter Services
log ""
log "PeppyMeter Services:"
PEPPY_SERVICES=("peppymeter.service" "peppymeter-screensaver.service" "peppymeter-position.service" "peppymeter-window-fix.service")
for service in "${PEPPY_SERVICES[@]}"; do
    STATUS=$(./pi5-ssh.sh "systemctl is-enabled $service 2>/dev/null")
    if [ "$STATUS" = "enabled" ]; then
        log_success "$service: ENABLED"
        create_visualization "Service: $service" "PASS" "Enabled"
    else
        log_warning "$service: NICHT ENABLED"
        create_visualization "Service: $service" "WARN" "Nicht enabled"
    fi
done

log ""
log "=== AUDIO SYSTEM ==="

# MPD Status
log "1. MPD Service:"
MPD_STATUS=$(./pi5-ssh.sh "systemctl is-active mpd.service 2>/dev/null")
if [ "$MPD_STATUS" = "active" ]; then
    log_success "MPD Service: AKTIV"
    create_visualization "MPD Service" "PASS" "Aktiv"
    
    # MPD Outputs
    log "   MPD Outputs:"
    ./pi5-ssh.sh "mpc outputs 2>/dev/null" | tee -a "$LOG_FILE"
    
    # MPD Status
    log "   MPD Status:"
    ./pi5-ssh.sh "mpc status 2>/dev/null" | tee -a "$LOG_FILE"
else
    log_error "MPD Service: NICHT AKTIV"
    create_visualization "MPD Service" "FAIL" "Nicht aktiv"
fi

# ALSA Configuration
log ""
log "2. ALSA Configuration:"
ALSA_CARD=$(./pi5-ssh.sh "cat /etc/asound.conf 2>/dev/null | grep 'card' | head -1")
if [ -n "$ALSA_CARD" ]; then
    log_success "ALSA konfiguriert: $ALSA_CARD"
    create_visualization "ALSA Config" "PASS" "$ALSA_CARD"
    ./pi5-ssh.sh "cat /etc/asound.conf" | tee -a "$LOG_FILE"
else
    log_warning "ALSA nicht konfiguriert"
    create_visualization "ALSA Config" "WARN" "Nicht konfiguriert"
fi

# Audio Mixer
log ""
log "3. Audio Mixer:"
MIXER_VOLUME=$(./pi5-ssh.sh "amixer -c 0 get 'Digital' 2>/dev/null | grep -o '[0-9]*%' | head -1")
if [ -n "$MIXER_VOLUME" ]; then
    log_success "Mixer Volume: $MIXER_VOLUME"
    create_visualization "Audio Mixer" "PASS" "Volume: $MIXER_VOLUME"
    ./pi5-ssh.sh "amixer -c 0 sget 'Digital' 2>/dev/null" | tee -a "$LOG_FILE"
else
    log_warning "Mixer nicht erreichbar"
    create_visualization "Audio Mixer" "WARN" "Nicht erreichbar"
fi

log ""
log "=== DISPLAY SYSTEM ==="

# X Server
log "1. X Server:"
X_SERVER=$(./pi5-ssh.sh "ps aux | grep -E '[X]org|[X]server' | wc -l")
if [ "$X_SERVER" -gt 0 ]; then
    log_success "X Server läuft"
    create_visualization "X Server" "PASS" "Läuft"
    ./pi5-ssh.sh "ps aux | grep -E '[X]org|[X]server' | head -2" | tee -a "$LOG_FILE"
else
    log_error "X Server läuft NICHT"
    create_visualization "X Server" "FAIL" "Läuft nicht"
fi

# Chromium
log ""
log "2. Chromium:"
CHROMIUM=$(./pi5-ssh.sh "ps aux | grep -E '[c]hromium' | wc -l")
if [ "$CHROMIUM" -gt 0 ]; then
    log_success "Chromium läuft"
    create_visualization "Chromium" "PASS" "Läuft"
    CHROMIUM_WINDOW=$(./pi5-ssh.sh "DISPLAY=:0 xdotool search --class Chromium 2>/dev/null | head -1")
    if [ -n "$CHROMIUM_WINDOW" ]; then
        log_info "Chromium Window ID: $CHROMIUM_WINDOW"
        WINDOW_SIZE=$(./pi5-ssh.sh "DISPLAY=:0 xdotool getwindowgeometry $CHROMIUM_WINDOW 2>/dev/null | grep Geometry")
        log_info "Window Size: $WINDOW_SIZE"
    fi
else
    log_error "Chromium läuft NICHT"
    create_visualization "Chromium" "FAIL" "Läuft nicht"
fi

# Display Resolution
log ""
log "3. Display Resolution:"
DISPLAY_RES=$(./pi5-ssh.sh "xrandr 2>/dev/null | grep '*' | head -1")
if [ -n "$DISPLAY_RES" ]; then
    if echo "$DISPLAY_RES" | grep -q "1280x400"; then
        log_success "Display Resolution: 1280x400 (korrekt)"
        create_visualization "Display Resolution" "PASS" "1280x400"
    else
        log_warning "Display Resolution: $DISPLAY_RES (nicht 1280x400)"
        create_visualization "Display Resolution" "WARN" "$DISPLAY_RES"
    fi
    log_info "Details: $DISPLAY_RES"
else
    log_error "Display Resolution nicht ermittelbar"
    create_visualization "Display Resolution" "FAIL" "Nicht ermittelbar"
fi

log ""
log "=== TOUCHSCREEN SYSTEM ==="

# Touchscreen Device
log "1. Touchscreen Device:"
TOUCH_ID=$(./pi5-ssh.sh "DISPLAY=:0 xinput list | grep -i 'WaveShare\|FT6236' | grep -oP 'id=\K[0-9]+' | head -1")
if [ -n "$TOUCH_ID" ]; then
    log_success "Touchscreen ID: $TOUCH_ID"
    create_visualization "Touchscreen Device" "PASS" "ID: $TOUCH_ID"
    
    # Touchscreen Properties
    log "   Touchscreen Properties:"
    ./pi5-ssh.sh "DISPLAY=:0 xinput list-props $TOUCH_ID 2>/dev/null | grep -E 'Send Events|Coordinate Transformation'" | tee -a "$LOG_FILE"
    
    # Send Events Mode
    SEND_EVENTS=$(./pi5-ssh.sh "DISPLAY=:0 xinput list-props $TOUCH_ID 2>/dev/null | grep 'Send Events Mode Enabled' | grep -oP '\\([0-9]+\\):\\s+\\K[0-9,]+'")
    if echo "$SEND_EVENTS" | grep -q "1,0"; then
        log_success "Send Events Mode: Enabled (1,0)"
        create_visualization "Touchscreen Events" "PASS" "Enabled"
    else
        log_warning "Send Events Mode: $SEND_EVENTS (sollte 1,0 sein)"
        create_visualization "Touchscreen Events" "WARN" "$SEND_EVENTS"
    fi
else
    log_error "Touchscreen NICHT erkannt"
    create_visualization "Touchscreen Device" "FAIL" "Nicht erkannt"
fi

log ""
log "=== PEPPYMETER SYSTEM ==="

# PeppyMeter Service
log "1. PeppyMeter Service:"
PEPPY_STATUS=$(./pi5-ssh.sh "systemctl is-active peppymeter.service 2>/dev/null")
if [ "$PEPPY_STATUS" = "active" ]; then
    log_success "PeppyMeter Service: AKTIV"
    create_visualization "PeppyMeter Service" "PASS" "Aktiv"
    
    # PeppyMeter Process
    PEPPY_PROCESS=$(./pi5-ssh.sh "ps aux | grep -E '[p]eppymeter' | wc -l")
    if [ "$PEPPY_PROCESS" -gt 0 ]; then
        log_success "PeppyMeter Process läuft"
        create_visualization "PeppyMeter Process" "PASS" "Läuft"
    else
        log_warning "PeppyMeter Process läuft NICHT"
        create_visualization "PeppyMeter Process" "WARN" "Läuft nicht"
    fi
    
    # PeppyMeter Window
    PEPPY_WINDOW=$(./pi5-ssh.sh "DISPLAY=:0 xdotool search --classname PeppyMeter 2>/dev/null | head -1")
    if [ -n "$PEPPY_WINDOW" ]; then
        log_success "PeppyMeter Window gefunden: $PEPPY_WINDOW"
        create_visualization "PeppyMeter Window" "PASS" "ID: $PEPPY_WINDOW"
        WINDOW_SIZE=$(./pi5-ssh.sh "DISPLAY=:0 xdotool getwindowgeometry $PEPPY_WINDOW 2>/dev/null | grep Geometry")
        log_info "Window Size: $WINDOW_SIZE"
    else
        log_warning "PeppyMeter Window NICHT gefunden"
        create_visualization "PeppyMeter Window" "WARN" "Nicht gefunden"
    fi
else
    log_warning "PeppyMeter Service: NICHT AKTIV"
    create_visualization "PeppyMeter Service" "WARN" "Nicht aktiv"
fi

# PeppyMeter Screensaver
log ""
log "2. PeppyMeter Screensaver:"
SCREENSAVER_STATUS=$(./pi5-ssh.sh "systemctl is-active peppymeter-screensaver.service 2>/dev/null")
if [ "$SCREENSAVER_STATUS" = "active" ]; then
    log_success "PeppyMeter Screensaver: AKTIV"
    create_visualization "PeppyMeter Screensaver" "PASS" "Aktiv"
    
    # Screensaver Timeout
    TIMEOUT=$(./pi5-ssh.sh "grep 'INACTIVITY_TIMEOUT=' /usr/local/bin/peppymeter-screensaver.sh 2>/dev/null | grep -oP '=\\K[0-9]+'")
    if [ -n "$TIMEOUT" ]; then
        TIMEOUT_MIN=$((TIMEOUT / 60))
        log_info "Screensaver Timeout: $TIMEOUT Sekunden ($TIMEOUT_MIN Minuten)"
        create_visualization "Screensaver Timeout" "PASS" "$TIMEOUT_MIN Minuten"
    fi
else
    log_warning "PeppyMeter Screensaver: NICHT AKTIV"
    create_visualization "PeppyMeter Screensaver" "WARN" "Nicht aktiv"
fi

log ""
log "=== CONFIGURATION FILES ==="

# config.txt
log "1. /boot/firmware/config.txt:"
CONFIG_ROTATE=$(./pi5-ssh.sh "grep 'display_rotate=' /boot/firmware/config.txt 2>/dev/null | head -1")
if [ -n "$CONFIG_ROTATE" ]; then
    if echo "$CONFIG_ROTATE" | grep -q "display_rotate=3"; then
        log_success "display_rotate=3 (korrekt)"
        create_visualization "config.txt: display_rotate" "PASS" "3 (korrekt)"
    else
        log_warning "display_rotate: $CONFIG_ROTATE (sollte 3 sein)"
        create_visualization "config.txt: display_rotate" "WARN" "$CONFIG_ROTATE"
    fi
else
    log_error "display_rotate nicht gefunden"
    create_visualization "config.txt: display_rotate" "FAIL" "Nicht gefunden"
fi

# cmdline.txt
log ""
log "2. /boot/firmware/cmdline.txt:"
CMDLINE_FBCON=$(./pi5-ssh.sh "grep 'fbcon=rotate' /boot/firmware/cmdline.txt 2>/dev/null")
if [ -n "$CMDLINE_FBCON" ]; then
    log_success "fbcon=rotate gefunden"
    create_visualization "cmdline.txt: fbcon" "PASS" "Gefunden"
else
    log_warning "fbcon=rotate NICHT gefunden"
    create_visualization "cmdline.txt: fbcon" "WARN" "Nicht gefunden"
fi

log ""
log "=== REMOTE ACCESS (RASPI-CONNECT) ==="

# Raspberry Pi Connect
log "1. Raspberry Pi Connect:"
RPI_CONNECT=$(./pi5-ssh.sh "which rpi-connect 2>/dev/null || which raspi-connect 2>/dev/null")
if [ -n "$RPI_CONNECT" ]; then
    log_success "rpi-connect gefunden: $RPI_CONNECT"
    create_visualization "rpi-connect" "PASS" "Installiert"
    
    # Connect Status
    CONNECT_STATUS=$(./pi5-ssh.sh "rpi-connect status 2>/dev/null || echo 'UNKNOWN'")
    log_info "Connect Status: $CONNECT_STATUS"
    
    # Connect Service
    CONNECT_SERVICE=$(./pi5-ssh.sh "systemctl is-enabled rpi-connect.service 2>/dev/null || systemctl is-enabled rpi-connect-lite.service 2>/dev/null || echo 'NOT FOUND'")
    if [ "$CONNECT_SERVICE" != "NOT FOUND" ]; then
        if [ "$CONNECT_SERVICE" = "enabled" ]; then
            log_success "rpi-connect Service: ENABLED"
            create_visualization "rpi-connect Service" "PASS" "Enabled"
        else
            log_warning "rpi-connect Service: $CONNECT_SERVICE"
            create_visualization "rpi-connect Service" "WARN" "$CONNECT_SERVICE"
        fi
    else
        log_warning "rpi-connect Service nicht gefunden"
        create_visualization "rpi-connect Service" "WARN" "Nicht gefunden"
    fi
else
    log_warning "rpi-connect NICHT installiert"
    create_visualization "rpi-connect" "WARN" "Nicht installiert"
fi

log ""
log "=== SYSTEM RESOURCES ==="

# CPU Load
log "1. CPU Load:"
CPU_LOAD=$(./pi5-ssh.sh "uptime | awk -F'load average:' '{print \$2}'")
log_info "CPU Load: $CPU_LOAD"
create_visualization "CPU Load" "PASS" "$CPU_LOAD"

# Memory
log ""
log "2. Memory:"
MEMORY=$(./pi5-ssh.sh "free -h | grep '^Mem:' | awk '{print \"Used: \" \$3 \"/\" \$2}'")
log_info "Memory: $MEMORY"
create_visualization "Memory" "PASS" "$MEMORY"

# Disk Space
log ""
log "3. Disk Space:"
DISK=$(./pi5-ssh.sh "df -h / | tail -1 | awk '{print \"Used: \" \$3 \"/\" \$2 \" (\" \$5 \")\"}'")
log_info "Disk: $DISK"
create_visualization "Disk Space" "PASS" "$DISK"

log ""
log "=== FINAL SUMMARY ==="

echo "" | tee -a "$LOG_FILE"
echo "╔══════════════════════════════════════════════════════════════╗" | tee -a "$LOG_FILE"
echo "║                    TEST SUMMARY                             ║" | tee -a "$LOG_FILE"
echo "╚══════════════════════════════════════════════════════════════╝" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Tests Passed:  $TESTS_PASSED" | tee -a "$LOG_FILE"
echo "Tests Failed:  $TESTS_FAILED" | tee -a "$LOG_FILE"
echo "Tests Warning: $TESTS_WARNING" | tee -a "$LOG_FILE"
echo "Critical Issues: $CRITICAL_ISSUES" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"

# Erstelle Report
cat > "$REPORT_FILE" << EOF
# System Test Report

**Date:** $(date)  
**System:** moOde Audio Pi 5  
**Test ID:** $TEST_DATE

## Summary

- **Tests Passed:** $TESTS_PASSED
- **Tests Failed:** $TESTS_FAILED
- **Tests Warning:** $TESTS_WARNING
- **Critical Issues:** $CRITICAL_ISSUES

## Visualization

\`\`\`
$(cat "$VISUALIZATION_FILE")
\`\`\`

## Detailed Log

See: \`$LOG_FILE\`

## Next Steps

$(if [ $CRITICAL_ISSUES -gt 0 ]; then
    echo "- ⚠️  **CRITICAL ISSUES FOUND** - System needs attention"
    echo "- Review failed tests and fix issues"
else
    echo "- ✅ No critical issues found"
    echo "- System appears to be functioning correctly"
fi)

EOF

log "Report erstellt: $REPORT_FILE"
log "Visualization erstellt: $VISUALIZATION_FILE"
log "Log erstellt: $LOG_FILE"

echo "" | tee -a "$LOG_FILE"
echo "📊 Reports erstellt in: $LOG_DIR/" | tee -a "$LOG_FILE"
echo "   - Report: $REPORT_FILE" | tee -a "$LOG_FILE"
echo "   - Visualization: $VISUALIZATION_FILE" | tee -a "$LOG_FILE"
echo "   - Log: $LOG_FILE" | tee -a "$LOG_FILE"

if [ $CRITICAL_ISSUES -gt 0 ]; then
    echo "" | tee -a "$LOG_FILE"
    echo "⚠️  CRITICAL ISSUES FOUND - System needs attention!" | tee -a "$LOG_FILE"
    exit 1
else
    echo "" | tee -a "$LOG_FILE"
    echo "✅ All tests completed successfully!" | tee -a "$LOG_FILE"
    exit 0
fi

