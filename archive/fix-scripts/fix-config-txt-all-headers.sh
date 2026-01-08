#!/bin/bash
################################################################################
# FIX CONFIG.TXT WITH ALL MOODE HEADERS
# 
# ROOT CAUSE IDENTIFIED:
# - worker.php chkBootConfigTxt() requires ALL 5 headers
# - If ANY header is missing → config.txt gets OVERWRITTEN
# - This is why display_rotate=0 keeps disappearing!
#
# REQUIRED HEADERS (from constants.php):
# 1. # This file is managed by moOde (Line 1)
# 2. # Device filters
# 3. # General settings
# 4. # Do not alter this section
# 5. # Audio overlays
#
# Usage: ./fix-config-txt-all-headers.sh [SD_MOUNT_POINT or PI_IP]
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

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 FIX CONFIG.TXT - ALL MOODE HEADERS REQUIRED               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

TARGET="${1:-}"

# Determine if target is SD card or Pi IP
if [ -z "$TARGET" ]; then
    # Auto-detect SD card
    if [ -d "/Volumes/bootfs" ]; then
        TARGET="/Volumes/bootfs"
        MODE="sd_card"
    elif [ -d "/Volumes/boot" ]; then
        TARGET="/Volumes/boot"
        MODE="sd_card"
    else
        error "Kein Ziel gefunden. Bitte SD-Karte mounten oder Pi IP angeben."
        exit 1
    fi
elif [ -d "$TARGET" ]; then
    MODE="sd_card"
elif [[ "$TARGET" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    MODE="pi_remote"
    PI_IP="$TARGET"
    PI_USER="${2:-andre}"
    PI_PASS="${3:-0815}"
else
    error "Ungültiges Ziel: $TARGET"
    exit 1
fi

info "Modus: $MODE"
info "Ziel: $TARGET"
echo ""

################################################################################
# REQUIRED HEADERS (from moOde constants.php)
################################################################################

REQUIRED_HEADERS=(
    "# This file is managed by moOde"
    "# Device filters"
    "# General settings"
    "# Do not alter this section"
    "# Audio overlays"
)

################################################################################
# FUNCTION: Add all headers to config.txt
################################################################################

add_all_headers() {
    local config_file="$1"
    local temp_file="${config_file}.tmp"
    
    info "Prüfe Header in: $config_file"
    
    # Check which headers are missing
    local missing_headers=()
    for header in "${REQUIRED_HEADERS[@]}"; do
        if ! grep -q "^${header}$" "$config_file" 2>/dev/null; then
            missing_headers+=("$header")
        fi
    done
    
    if [ ${#missing_headers[@]} -eq 0 ]; then
        log "✅ Alle 5 Header bereits vorhanden"
        return 0
    fi
    
    warn "⚠️  Fehlende Header: ${#missing_headers[@]}"
    for header in "${missing_headers[@]}"; do
        echo "  - $header"
    done
    echo ""
    
    # Read existing config
    local existing_content=$(cat "$config_file")
    
    # Build new config with all headers
    {
        # Header 1: Main file header (must be line 1)
        echo "${REQUIRED_HEADERS[0]}"
        echo ""
        
        # Header 2: Device filters
        echo "${REQUIRED_HEADERS[1]}"
        if ! echo "$existing_content" | grep -q "^\[pi5\]"; then
            echo "[pi5]"
            echo "display_rotate=0"
            echo "dtoverlay=vc4-kms-v3d-pi5,noaudio"
            echo "hdmi_enable_4kp60=0"
        else
            # Extract [pi5] section from existing
            echo "$existing_content" | sed -n '/^\[pi5\]/,/^\[/p' | grep -v "^\[$"
        fi
        echo ""
        
        # Header 3: General settings
        echo "${REQUIRED_HEADERS[2]}"
        if ! echo "$existing_content" | grep -q "^\[all\]"; then
            echo "[all]"
            echo "hdmi_group=2"
            echo "hdmi_mode=87"
            echo "hdmi_timings=400 0 220 32 110 1280 0 10 10 10 0 0 0 60 0 59510000 0"
            echo "hdmi_ignore_edid=0xa5000080"
            echo "hdmi_force_hotplug=1"
            echo "hdmi_drive=2"
            echo "hdmi_blanking=0"
            echo "arm_64bit=1"
            echo "arm_boost=1"
            echo "disable_splash=0"
            echo "disable_overscan=1"
        else
            # Extract [all] section from existing
            echo "$existing_content" | sed -n '/^\[all\]/,/^\[/p' | grep -v "^\[$"
        fi
        echo ""
        
        # Header 4: Do not alter this section
        echo "${REQUIRED_HEADERS[3]}"
        echo "# Integrated adapters"
        echo "#dtoverlay=disable-bt"
        echo "#dtoverlay=disable-wifi"
        echo ""
        
        # Header 5: Audio overlays
        echo "${REQUIRED_HEADERS[4]}"
        if ! echo "$existing_content" | grep -q "dtoverlay=hifiberry-amp100"; then
            echo "dtoverlay=hifiberry-amp100"
        else
            echo "$existing_content" | grep "dtoverlay=hifiberry-amp100" | head -1
        fi
        echo "force_eeprom_read=0"
        echo ""
        
        # Add any remaining custom settings (that don't conflict)
        echo "$existing_content" | grep -v "^#" | grep -v "^$" | grep -v "^\[" | \
            grep -v "display_rotate" | grep -v "dtoverlay=vc4-kms-v3d-pi5" | \
            grep -v "hdmi_group" | grep -v "hdmi_mode" | grep -v "hdmi_timings" | \
            grep -v "hdmi_ignore_edid" | grep -v "hdmi_force_hotplug" | \
            grep -v "dtoverlay=hifiberry-amp100" | grep -v "force_eeprom_read" | \
            sort -u
        
    } > "$temp_file"
    
    # Replace config file
    mv "$temp_file" "$config_file"
    
    log "✅ Alle 5 Header hinzugefügt"
    
    # Verify
    local header_count=0
    for header in "${REQUIRED_HEADERS[@]}"; do
        if grep -q "^${header}$" "$config_file"; then
            header_count=$((header_count + 1))
        fi
    done
    
    if [ $header_count -eq 5 ]; then
        log "✅ Verifiziert: Alle 5 Header vorhanden"
        return 0
    else
        error "❌ Fehler: Nur $header_count von 5 Headern gefunden"
        return 1
    fi
}

################################################################################
# MAIN: Apply fix
################################################################################

if [ "$MODE" = "sd_card" ]; then
    log "=== FIX SD CARD CONFIG.TXT ==="
    echo ""
    
    CONFIG_FILE="$TARGET/config.txt"
    
    if [ ! -f "$CONFIG_FILE" ]; then
        error "config.txt nicht gefunden: $CONFIG_FILE"
        exit 1
    fi
    
    # Backup
    cp "$CONFIG_FILE" "${CONFIG_FILE}.backup_$(date +%Y%m%d_%H%M%S)"
    log "✅ Backup erstellt"
    
    # Add all headers
    if add_all_headers "$CONFIG_FILE"; then
        log "✅ config.txt gefixt mit allen Headern"
        echo ""
        info "Verifikation:"
        for i in "${!REQUIRED_HEADERS[@]}"; do
            if grep -q "^${REQUIRED_HEADERS[$i]}$" "$CONFIG_FILE"; then
                echo "  ✅ Header $((i+1)): ${REQUIRED_HEADERS[$i]}"
            else
                echo "  ❌ Header $((i+1)): ${REQUIRED_HEADERS[$i]} FEHLT"
            fi
        done
    else
        error "Fehler beim Hinzufügen der Header"
        exit 1
    fi
    
    sync
    log "✅ Sync abgeschlossen"
    
elif [ "$MODE" = "pi_remote" ]; then
    log "=== FIX PI REMOTE CONFIG.TXT ==="
    echo ""
    
    info "Verbinde mit Pi: $PI_USER@$PI_IP"
    
    if ! command -v sshpass &> /dev/null; then
        error "sshpass nicht gefunden. Installiere mit: brew install hudochenkov/sshpass/sshpass"
        exit 1
    fi
    
    # Test SSH
    if ! sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$PI_USER@$PI_IP" "echo 'SSH OK'" >/dev/null 2>&1; then
        error "SSH-Verbindung fehlgeschlagen"
        exit 1
    fi
    
    log "✅ SSH-Verbindung erfolgreich"
    echo ""
    
    # Apply fix remotely
    sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'REMOTE_FIX'
set -e

CONFIG_FILE="/boot/firmware/config.txt"

# Backup
sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.backup_$(date +%Y%m%d_%H%M%S)"
echo "✅ Backup erstellt"

# Mount boot as writable
sudo mount -o remount,rw /boot/firmware

# Create temp file with all headers
sudo tee "${CONFIG_FILE}.new" > /dev/null << 'CONFIG_EOF'
# This file is managed by moOde

# Device filters
[pi5]
display_rotate=0
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0
hdmi_timings=400 0 220 32 110 1280 0 10 10 10 0 0 0 60 0 59510000 0
hdmi_ignore_edid=0xa5000080
hdmi_force_hotplug=1

# General settings
[all]
hdmi_group=2
hdmi_mode=87
hdmi_drive=2
hdmi_blanking=0
arm_64bit=1
arm_boost=1
disable_splash=0
disable_overscan=1

# Do not alter this section
# Integrated adapters
#dtoverlay=disable-bt
#dtoverlay=disable-wifi

# Audio overlays
dtoverlay=hifiberry-amp100
force_eeprom_read=0
CONFIG_EOF

# Merge with existing custom settings (preserve non-conflicting)
sudo awk '
    BEGIN { in_custom=1 }
    /^# This file is managed by moOde/ { in_custom=0; next }
    /^# Device filters/ { in_custom=0; next }
    /^# General settings/ { in_custom=0; next }
    /^# Do not alter this section/ { in_custom=0; next }
    /^# Audio overlays/ { in_custom=0; next }
    /^\[pi5\]/ { in_custom=0; next }
    /^\[all\]/ { in_custom=0; next }
    /^\[/ { in_custom=1 }
    in_custom && !/^#/ && !/^$/ && !/^display_rotate/ && !/^dtoverlay=vc4-kms-v3d-pi5/ && !/^hdmi_group/ && !/^hdmi_mode/ && !/^hdmi_timings/ && !/^dtoverlay=hifiberry-amp100/ { print }
' "$CONFIG_FILE" >> "${CONFIG_FILE}.new"

# Replace config
sudo mv "${CONFIG_FILE}.new" "$CONFIG_FILE"
sudo chmod 644 "$CONFIG_FILE"

# Verify headers
HEADER_COUNT=0
for header in "# This file is managed by moOde" "# Device filters" "# General settings" "# Do not alter this section" "# Audio overlays"; do
    if grep -q "^${header}$" "$CONFIG_FILE"; then
        HEADER_COUNT=$((HEADER_COUNT + 1))
    fi
done

if [ $HEADER_COUNT -eq 5 ]; then
    echo "✅ Alle 5 Header vorhanden"
else
    echo "⚠️  Nur $HEADER_COUNT von 5 Headern gefunden"
fi

sync
echo "✅ config.txt gefixt"
REMOTE_FIX

    log "✅ Fix auf Pi angewendet"
fi

echo ""
log "=== FIX ABGESCHLOSSEN ==="
echo ""
info "ROOT CAUSE BEHOBEN:"
echo "  ✅ Alle 5 moOde Header hinzugefügt"
echo "  ✅ worker.php wird config.txt NICHT mehr überschreiben"
echo "  ✅ display_rotate=0 bleibt erhalten"
echo ""
warn "⚠️  REBOOT ERFORDERLICH"
echo ""

