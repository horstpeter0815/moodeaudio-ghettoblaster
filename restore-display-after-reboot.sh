#!/bin/bash
################################################################################
# RESTORE DISPLAY AFTER REBOOT - 180° ROTATION
# 
# Fixes display that got reset after reboot:
# 1. Ensures all 5 Moode headers are present (prevents worker.php overwrite)
# 2. Sets display_rotate=2 (180° rotation)
# 3. Sets fbcon=rotate:3 in cmdline.txt (180° console rotation)
# 4. Ensures [pi5] section is correctly placed
# 5. Restores all display settings
#
# Usage: ./restore-display-after-reboot.sh [PI_IP] [USER] [PASS]
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[FIX]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Configuration
PI_IP="${1:-}"
PI_USER="${2:-andre}"
PI_PASS="${3:-0815}"

# Try to find Pi IP
if [ -z "$PI_IP" ]; then
    info "Suche Pi IP..."
    for ip in "moodepi5.local" "192.168.1.100" "192.168.1.101" "192.168.1.102"; do
        if ping -c 1 -W 1 "$ip" >/dev/null 2>&1; then
            PI_IP=$(ping -c 1 -W 1 "$ip" 2>/dev/null | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
            if [ -z "$PI_IP" ]; then
                PI_IP="$ip"
            fi
            log "✅ Pi gefunden: $PI_IP"
            break
        fi
    done
fi

if [ -z "$PI_IP" ]; then
    error "Pi IP nicht gefunden. Bitte manuell angeben: $0 [PI_IP]"
    exit 1
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 RESTORE DISPLAY AFTER REBOOT (180° ROTATION)             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
info "Pi: $PI_USER@$PI_IP"
echo ""

# Check sshpass
if ! command -v sshpass &> /dev/null; then
    error "sshpass nicht gefunden. Installiere mit: brew install hudochenkov/sshpass/sshpass"
    exit 1
fi

# Test SSH connection
info "Teste SSH-Verbindung..."
if ! sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=10 "$PI_USER@$PI_IP" "echo 'SSH OK'" >/dev/null 2>&1; then
    error "SSH-Verbindung fehlgeschlagen. Prüfe IP, User und Passwort."
    exit 1
fi
log "✅ SSH-Verbindung erfolgreich"
echo ""

################################################################################
# STEP 1: CHECK CURRENT STATE
################################################################################

log "=== STEP 1: CHECK CURRENT STATE ==="
echo ""

sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'CHECK_STATE'
echo "=== config.txt ==="
echo "display_rotate:"
grep -E '^display_rotate=' /boot/firmware/config.txt || echo "  Nicht gefunden"
echo ""
echo "Moode Headers:"
head -30 /boot/firmware/config.txt | grep -E 'managed by moOde|Device filters|General settings|Do not alter|Audio overlays' || echo "  Headers fehlen!"
echo ""
echo "[pi5] Section:"
grep -A 5 '^\[pi5\]' /boot/firmware/config.txt | head -10 || echo "  [pi5] Section nicht gefunden"
echo ""
echo "=== cmdline.txt ==="
echo "fbcon:"
grep -E 'fbcon|video' /boot/firmware/cmdline.txt || echo "  Kein fbcon/video gefunden"
echo ""
CHECK_STATE

echo ""

################################################################################
# STEP 2: FIX CONFIG.TXT - ALL HEADERS + DISPLAY_ROTATE=2
################################################################################

log "=== STEP 2: FIX CONFIG.TXT ==="
echo ""

info "Stelle alle 5 Moode Headers sicher und setze display_rotate=2..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'FIX_CONFIG'
sudo mount -o remount,rw /boot/firmware

CONFIG_FILE="/boot/firmware/config.txt"

# Backup
cp "$CONFIG_FILE" "${CONFIG_FILE}.backup_$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true

# Read current config
CURRENT_CONFIG=$(cat "$CONFIG_FILE")

# Check if all 5 headers are present
HAS_MAIN_HEADER=$(echo "$CURRENT_CONFIG" | grep -q "^# This file is managed by moOde" && echo "yes" || echo "no")
HAS_DEVICE_FILTERS=$(echo "$CURRENT_CONFIG" | grep -q "^# Device filters" && echo "yes" || echo "no")
HAS_GENERAL_SETTINGS=$(echo "$CURRENT_CONFIG" | grep -q "^# General settings" && echo "yes" || echo "no")
HAS_DO_NOT_ALTER=$(echo "$CURRENT_CONFIG" | grep -q "^# Do not alter this section" && echo "yes" || echo "no")
HAS_AUDIO_OVERLAYS=$(echo "$CURRENT_CONFIG" | grep -q "^# Audio overlays" && echo "yes" || echo "no")

echo "Header Status:"
echo "  Main header: $HAS_MAIN_HEADER"
echo "  Device filters: $HAS_DEVICE_FILTERS"
echo "  General settings: $HAS_GENERAL_SETTINGS"
echo "  Do not alter: $HAS_DO_NOT_ALTER"
echo "  Audio overlays: $HAS_AUDIO_OVERLAYS"
echo ""

# If headers are missing, we need to add them
if [ "$HAS_MAIN_HEADER" = "no" ] || [ "$HAS_DEVICE_FILTERS" = "no" ] || [ "$HAS_GENERAL_SETTINGS" = "no" ] || [ "$HAS_DO_NOT_ALTER" = "no" ] || [ "$HAS_AUDIO_OVERLAYS" = "no" ]; then
    echo "⚠️  Headers fehlen - erstelle vollständige config.txt Struktur..."
    
    # Create properly structured config.txt with all headers
    cat > "${CONFIG_FILE}.new" << 'CONFIG_EOF'
# This file is managed by moOde

# Device filters
[cm4]
otg_mode=1

[pi4]
hdmi_force_hotplug:0=1
hdmi_force_hotplug:1=1
hdmi_enable_4kp60=0

[pi5]
display_rotate=2
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0
hdmi_timings=400 0 220 32 110 1280 0 10 10 10 0 0 0 60 0 59510000 0
hdmi_ignore_edid=0xa5000080
hdmi_force_hotplug=1
disable_splash=1

# General settings
[all]
hdmi_group=2
hdmi_mode=87
hdmi_drive=2
hdmi_blanking=0
dtoverlay=vc4-kms-v3d
max_framebuffers=2
display_auto_detect=1
arm_64bit=1
arm_boost=1
disable_overscan=1
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=100000
dtparam=i2c_vc=on
dtparam=i2s=on
dtparam=audio=off

# Do not alter this section
# Integrated adapters
#dtoverlay=disable-bt
#dtoverlay=disable-wifi
# PCI Express
#dtparam=pciex1
#dtparam=pciex1_gen=3
# Pi Touch1
#dtoverlay=vc4-kms-dsi-7inch,invx,invy
# Fan speed
#dtparam=fan_temp0=50000,fan_temp0_hyst=5000,fan_temp0_speed=75

# Audio overlays
dtoverlay=hifiberry-amp100
force_eeprom_read=0
CONFIG_EOF
    
    mv "${CONFIG_FILE}.new" "$CONFIG_FILE"
    echo "✅ config.txt mit allen Headers neu erstellt"
else
    echo "✅ Alle Headers vorhanden"
    
    # Just fix display_rotate=2 in [pi5] section
    if grep -q "^\[pi5\]" "$CONFIG_FILE"; then
        # Remove existing display_rotate from [pi5] section
        awk '
            /^\[pi5\]/ { in_pi5=1; print; next }
            /^\[/ && in_pi5 { in_pi5=0 }
            in_pi5 && /^display_rotate=/ { next }
            { print }
        ' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
        mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
        
        # Add display_rotate=2 after [pi5]
        sed -i '/^\[pi5\]/a display_rotate=2' "$CONFIG_FILE"
        echo "✅ display_rotate=2 in [pi5] Section gesetzt"
    else
        # Add [pi5] section after # Device filters
        sed -i '/^# Device filters$/a\
[pi5]\
display_rotate=2\
dtoverlay=vc4-kms-v3d-pi5,noaudio\
hdmi_enable_4kp60=0\
hdmi_timings=400 0 220 32 110 1280 0 10 10 10 0 0 0 60 0 59510000 0\
hdmi_ignore_edid=0xa5000080\
hdmi_force_hotplug=1\
disable_splash=1
' "$CONFIG_FILE"
        echo "✅ [pi5] Section mit display_rotate=2 hinzugefügt"
    fi
    
    # Ensure disable_splash=1
    if ! grep -q "^disable_splash=1" "$CONFIG_FILE"; then
        sed -i '/^\[pi5\]/a disable_splash=1' "$CONFIG_FILE"
        echo "✅ disable_splash=1 hinzugefügt"
    fi
fi

sync
echo "✅ config.txt gefixt"
FIX_CONFIG

echo ""

################################################################################
# STEP 3: FIX CMDLINE.TXT - FBCON=ROTATE:3
################################################################################

log "=== STEP 3: FIX CMDLINE.TXT ==="
echo ""

info "Setze fbcon=rotate:3 in cmdline.txt (180° Console-Rotation)..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'FIX_CMDLINE'
sudo mount -o remount,rw /boot/firmware

CMDLINE_FILE="/boot/firmware/cmdline.txt"

# Backup
cp "$CMDLINE_FILE" "${CMDLINE_FILE}.backup_$(date +%Y%m%d_%H%M%S)" 2>/dev/null || true

# Remove existing fbcon=rotate parameter
sed -i 's/ fbcon=rotate:[0-9]//g' "$CMDLINE_FILE"
sed -i 's/ fbcon=rotate//g' "$CMDLINE_FILE"

# Remove conflicting video= rotate parameter
sed -i 's/ video=[^ ]*rotate[^ ]*//g' "$CMDLINE_FILE"

# Clean up double spaces
sed -i 's/  / /g' "$CMDLINE_FILE"

# Add fbcon=rotate:3 at the end (for 180° console rotation)
if ! grep -q "fbcon=rotate:3" "$CMDLINE_FILE"; then
    # Add at the end
    sed -i 's/$/ fbcon=rotate:3/' "$CMDLINE_FILE"
    echo "✅ fbcon=rotate:3 hinzugefügt"
else
    echo "✅ fbcon=rotate:3 bereits vorhanden"
fi

sync
echo "✅ cmdline.txt gefixt"
FIX_CMDLINE

echo ""

################################################################################
# STEP 4: VERIFICATION
################################################################################

log "=== STEP 4: VERIFICATION ==="
echo ""

info "Prüfe finale Einstellungen..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'VERIFY'
echo "=== Finale Einstellungen ==="
echo ""
echo "1. config.txt display_rotate:"
grep -E '^display_rotate=' /boot/firmware/config.txt || echo "  ❌ Nicht gefunden"
echo ""
echo "2. config.txt Moode Headers:"
HEADER_COUNT=$(head -30 /boot/firmware/config.txt | grep -cE 'managed by moOde|Device filters|General settings|Do not alter|Audio overlays' || echo "0")
echo "  Gefundene Headers: $HEADER_COUNT/5"
if [ "$HEADER_COUNT" -eq 5 ]; then
    echo "  ✅ Alle Headers vorhanden"
else
    echo "  ⚠️  Headers fehlen!"
fi
echo ""
echo "3. config.txt [pi5] Section:"
grep -A 5 '^\[pi5\]' /boot/firmware/config.txt | head -10 || echo "  ❌ [pi5] Section nicht gefunden"
echo ""
echo "4. cmdline.txt fbcon:"
grep -E 'fbcon=rotate:3' /boot/firmware/cmdline.txt && echo "  ✅ fbcon=rotate:3 vorhanden" || echo "  ❌ fbcon=rotate:3 fehlt"
echo ""
VERIFY

echo ""

################################################################################
# SUMMARY
################################################################################

log "=== FIX ABGESCHLOSSEN ==="
echo ""
info "Änderungen:"
echo "  ✅ Alle 5 Moode Headers sichergestellt (verhindert worker.php Überschreibung)"
echo "  ✅ display_rotate=2 in [pi5] Section (180° Rotation)"
echo "  ✅ fbcon=rotate:3 in cmdline.txt (180° Console-Rotation)"
echo "  ✅ disable_splash=1 (kein Splash-Screen)"
echo ""
warn "⚠️  REBOOT ERFORDERLICH, damit alle Änderungen aktiv werden!"
echo ""

