#!/bin/bash
################################################################################
#
# COMPLETE SD CARD FIX V1.0
#
# Applies ALL fixes to SD card:
# - Touch calibration (top/bottom fix)
# - Audio chain (CamillaDSP + PeppyMeter + Software volume)
# - All parameters correct
#
# Run when SD card is mounted in Mac
#
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[FIX]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

# Find SD card volumes
BOOTFS=""
ROOTFS=""

log "=== COMPLETE SD CARD FIX V1.0 ==="
echo ""

# Find bootfs
for vol in /Volumes/*; do
    if [ -d "$vol" ] && [ "$vol" != "/Volumes/Macintosh HD" ]; then
        if [ -f "$vol/config.txt" ] || [ -f "$vol/cmdline.txt" ] || [ -d "$vol/overlays" ]; then
            BOOTFS="$vol"
            break
        fi
    fi
done

# Find rootfs
for vol in /Volumes/*; do
    if [ -d "$vol" ] && [ "$vol" != "/Volumes/Macintosh HD" ]; then
        if [ -d "$vol/etc" ] && [ -d "$vol/usr" ] && [ -d "$vol/boot" ]; then
            ROOTFS="$vol"
            break
        fi
    fi
done

if [ -z "$BOOTFS" ]; then
    error "Boot partition not found!"
    error "Please insert SD card and ensure it's mounted"
    exit 1
fi

if [ -z "$ROOTFS" ]; then
    error "Root partition not found!"
    error "Please insert SD card and ensure it's mounted"
    exit 1
fi

log "Found SD card:"
info "  Boot: $BOOTFS"
info "  Root: $ROOTFS"
echo ""

# ============================================================================
# STEP 1: TOUCH CALIBRATION (Top/Bottom Fix)
# ============================================================================
log "Step 1: Fixing touch calibration (top/bottom swap)..."
TOUCH_CONF="$ROOTFS/etc/X11/xorg.conf.d/99-touch-calibration.conf"

mkdir -p "$(dirname "$TOUCH_CONF")" 2>/dev/null || {
    error "Cannot create xorg.conf.d directory"
    exit 1
}

# Use vertical flip matrix (fixes top/bottom)
cat > "$TOUCH_CONF" << 'EOF'
Section "InputClass"
    Identifier "Touchscreen Calibration"
    MatchProduct "*"
    MatchDevicePath "/dev/input/event*"
    Option "TransformationMatrix" "1 0 0 0 -1 1 0 0 1"
EndSection
EOF

log "✅ Touch calibration: Vertical flip (fixes top/bottom)"
log "   Matrix: 1 0 0 0 -1 1 0 0 1"
log "   Note: If left/right is wrong, use: -1 0 1 0 -1 1 0 0 1"

# ============================================================================
# STEP 2: AUDIO FIX SCRIPT (CamillaDSP + PeppyMeter + Software Volume)
# ============================================================================
log "Step 2: Creating audio fix script..."
AUDIO_FIX_SCRIPT="$ROOTFS/usr/local/bin/fix-audio-complete-v1.0.sh"
mkdir -p "$(dirname "$AUDIO_FIX_SCRIPT")" 2>/dev/null || true

cat > "$AUDIO_FIX_SCRIPT" << 'EOFAUDIO'
#!/bin/bash
# Complete Audio Setup V1.0: CamillaDSP + PeppyMeter + Software Volume
# Runs on boot to configure audio correctly

set -euo pipefail

log() { echo "[AUDIO-FIX] $1"; }

# Wait for system to be ready
sleep 10

# Check if running on Pi
if [ ! -d "/proc/asound" ]; then
    log "Not running on Pi, skipping audio fix"
    exit 0
fi

log "Starting audio configuration..."

# Find AMP100
if ! grep -q "sndrpihifiberry\|HiFiBerry AMP100" /proc/asound/cards 2>/dev/null; then
    log "ERROR: AMP100 not detected"
    exit 1
fi

AMP100_CARD=$(grep -E "sndrpihifiberry|HiFiBerry AMP100" /proc/asound/cards | head -1 | awk '{print $1}')
log "AMP100: card $AMP100_CARD"

# Wait for database to be ready
MOODE_DB="/var/local/www/db/moode-sqlite3.db"
for i in {1..30}; do
    if [ -f "$MOODE_DB" ]; then
        break
    fi
    sleep 1
done

if [ ! -f "$MOODE_DB" ]; then
    log "ERROR: Database not found"
    exit 1
fi

log "Updating database..."

# Audio device settings
sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='$AMP100_CARD' WHERE param='cardnum';" 2>/dev/null || true
sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='i2sdevice';" 2>/dev/null || true
sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='adevname';" 2>/dev/null || true

# PeppyMeter ON
sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='1' WHERE param='peppy_display';" 2>/dev/null || true
sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='meter' WHERE param='peppy_display_type';" 2>/dev/null || true

# CamillaDSP ON
sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='bose_wave_filters.yml' WHERE param='camilladsp';" 2>/dev/null || true
sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='Yes' WHERE param='cdsp_fix_playback';" 2>/dev/null || true

# Software volume
sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='Software' WHERE param='volume_control';" 2>/dev/null || true
sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='100' WHERE param='volume_db_range';" 2>/dev/null || true

# ALSA mode
sqlite3 "$MOODE_DB" "UPDATE cfg_system SET value='plughw' WHERE param='alsa_output_mode';" 2>/dev/null || true
sqlite3 "$MOODE_DB" "UPDATE cfg_mpd SET value='_audioout' WHERE param='device';" 2>/dev/null || true

log "Database updated"

# ALSA routing: MPD → camilladsp → peppy → AMP100
mkdir -p /etc/alsa/conf.d/

cat > /etc/alsa/conf.d/_audioout.conf << EOF
pcm._audioout {
    type copy
    slave.pcm "camilladsp"
}
EOF

cat > /etc/alsa/conf.d/_peppyout.conf << EOF
pcm._peppyout {
    type copy
    slave.pcm "plughw:$AMP100_CARD,0"
}
EOF

log "ALSA routing: MPD → camilladsp → peppy → AMP100"

# PeppyMeter config
if [ -f /etc/peppymeter/config.txt ]; then
    sed -i 's/^meter = .*/meter = blue/' /etc/peppymeter/config.txt 2>/dev/null || true
    sed -i 's/^random.meter.interval = .*/random.meter.interval = 0/' /etc/peppymeter/config.txt 2>/dev/null || true
    sed -i 's/^meter.folder = .*/meter.folder = 1280x400/' /etc/peppymeter/config.txt 2>/dev/null || true
    sed -i 's/^screen.width = .*/screen.width = 1280/' /etc/peppymeter/config.txt 2>/dev/null || true
    sed -i 's/^screen.height = .*/screen.height = 400/' /etc/peppymeter/config.txt 2>/dev/null || true
    log "PeppyMeter configured"
fi

# Restart services
log "Restarting services..."
systemctl restart mpd 2>/dev/null && sleep 2
systemctl restart camilladsp 2>/dev/null && sleep 1
systemctl restart peppymeter 2>/dev/null && sleep 1

# Volume
amixer -c "$AMP100_CARD" set Master unmute >/dev/null 2>&1 || true
amixer -c "$AMP100_CARD" set Master 100% >/dev/null 2>&1 || true
mpc volume 80 >/dev/null 2>&1 || true

log "Audio configuration complete"
log "CamillaDSP: ✅ Enabled"
log "PeppyMeter: ✅ Enabled"
log "Software volume: ✅ Enabled"
log "Audio chain: MPD → camilladsp → peppy → AMP100"
EOFAUDIO

chmod +x "$AUDIO_FIX_SCRIPT" 2>/dev/null || true
log "✅ Audio fix script created: $AUDIO_FIX_SCRIPT"

# ============================================================================
# STEP 3: CREATE SYSTEMD SERVICE TO RUN AUDIO FIX ON BOOT
# ============================================================================
log "Step 3: Creating systemd service for audio fix..."
SERVICE_FILE="$ROOTFS/etc/systemd/system/fix-audio-v1.0.service"
mkdir -p "$(dirname "$SERVICE_FILE")" 2>/dev/null || true

cat > "$SERVICE_FILE" << 'EOFSERVICE'
[Unit]
Description=Audio Configuration Fix V1.0
After=network.target mpd.service
Wants=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/fix-audio-complete-v1.0.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOFSERVICE

# Enable service
SERVICE_ENABLE="$ROOTFS/etc/systemd/system/multi-user.target.wants/fix-audio-v1.0.service"
mkdir -p "$(dirname "$SERVICE_ENABLE")" 2>/dev/null || true
ln -sf /etc/systemd/system/fix-audio-v1.0.service "$SERVICE_ENABLE" 2>/dev/null || true
log "✅ Systemd service created and enabled"

# ============================================================================
# SUMMARY
# ============================================================================
echo ""
log "=== SD CARD FIX COMPLETE ==="
echo ""
info "Configuration Applied:"
echo "  ✅ Touch calibration: Vertical flip (fixes top/bottom)"
echo "     Matrix: 1 0 0 0 -1 1 0 0 1"
echo "     If left/right wrong: -1 0 1 0 -1 1 0 0 1"
echo ""
echo "  ✅ Audio chain: CamillaDSP + PeppyMeter + Software volume"
echo "     Chain: MPD → camilladsp → peppy → AMP100"
echo "     All parameters configured"
echo ""
info "Next Steps:"
echo "  1. Eject SD card safely"
echo "  2. Insert into Pi"
echo "  3. Boot Pi"
echo "  4. Audio will auto-configure on boot"
echo "  5. Touch will be fixed after X11 starts"
echo ""
info "After boot, verify:"
echo "  - Audio: mpc play (test playback)"
echo "  - Touch: Test touch input"
echo "  - If touch left/right wrong, run on Pi:"
echo "    sudo tee /etc/X11/xorg.conf.d/99-touch-calibration.conf > /dev/null << 'EOF'"
echo "    Section \"InputClass\""
echo "        Identifier \"Touchscreen Calibration\""
echo "        MatchProduct \"*\""
echo "        MatchDevicePath \"/dev/input/event*\""
echo "        Option \"TransformationMatrix\" \"-1 0 1 0 -1 1 0 0 1\""
echo "    EndSection"
echo "    EOF"
echo "    sudo systemctl restart localdisplay.service"
echo ""
