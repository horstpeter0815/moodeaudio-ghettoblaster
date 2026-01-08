#!/bin/bash
# Fix Audio Hardware on Pi 5
# Attempts to fix audio hardware detection issues

echo "=== FIXING AUDIO HARDWARE ON PI 5 ==="
echo ""

PI5_ALIAS="pi2"
LOG_FILE="audio-fix-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

# Check if Pi 5 is online
if ! ssh -o ConnectTimeout=5 "$PI5_ALIAS" "echo 'Online'" >/dev/null 2>&1; then
    echo "❌ Pi 5 is not online. Please ensure it's running."
    exit 1
fi

echo "✅ Pi 5 is online"
echo ""

# Step 1: Check current audio status
log "Step 1: Checking current audio status"
echo "1. Current audio status:"
ssh "$PI5_ALIAS" "aplay -l 2>&1" | tee -a "$LOG_FILE"
echo ""

# Step 2: Check I2C bus status
log "Step 2: Checking I2C bus"
echo "2. I2C bus status:"
ssh "$PI5_ALIAS" "dmesg | grep -i 'i2c.*timeout' | tail -5" | tee -a "$LOG_FILE"
echo ""

# Step 3: Try enabling HDMI audio as fallback
log "Step 3: Attempting to enable HDMI audio"
echo "3. Enabling HDMI audio as fallback..."

# Backup current config
ssh "$PI5_ALIAS" "sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup-$(date +%Y%m%d_%H%M%S)"

# Remove noaudio from vc4-kms-v3d-pi5 overlay
ssh "$PI5_ALIAS" "sudo sed -i 's/dtoverlay=vc4-kms-v3d-pi5,noaudio/dtoverlay=vc4-kms-v3d-pi5/' /boot/firmware/config.txt"

# Enable audio parameter
ssh "$PI5_ALIAS" "sudo sed -i 's/^dtparam=audio=off/dtparam=audio=on/' /boot/firmware/config.txt"

# If audio=on doesn't exist, add it
if ! ssh "$PI5_ALIAS" "grep -q '^dtparam=audio=on' /boot/firmware/config.txt"; then
    ssh "$PI5_ALIAS" "echo 'dtparam=audio=on' | sudo tee -a /boot/firmware/config.txt > /dev/null"
fi

echo "   ✅ Configuration updated"
echo ""

# Step 4: Verify changes
log "Step 4: Verifying configuration changes"
echo "4. Configuration changes:"
ssh "$PI5_ALIAS" "grep -E 'dtoverlay=vc4-kms-v3d-pi5|dtparam=audio' /boot/firmware/config.txt" | tee -a "$LOG_FILE"
echo ""

# Step 5: Update ALSA config for HDMI
log "Step 5: Updating ALSA configuration"
echo "5. Updating ALSA configuration for HDMI..."

# Create ALSA config for HDMI
ssh "$PI5_ALIAS" "sudo tee /etc/asound.conf > /dev/null << 'ALSA_CONFIG'
pcm.!default {
    type hw
    card 1
}
ctl.!default {
    type hw
    card 1
}
ALSA_CONFIG"

echo "   ✅ ALSA configuration updated"
echo ""

# Step 6: Update MPD config for HDMI
log "Step 6: Updating MPD configuration"
echo "6. Updating MPD configuration..."

# Backup MPD config
ssh "$PI5_ALIAS" "sudo cp /etc/mpd.conf /etc/mpd.conf.backup-$(date +%Y%m%d_%H%M%S)"

# Update MPD audio output to use HDMI
ssh "$PI5_ALIAS" "sudo sed -i 's/device \"_audioout\"/device \"hw:1,0\"/' /etc/mpd.conf"
ssh "$PI5_ALIAS" "sudo sed -i 's/mixer_device \"default:vc4hdmi0\"/mixer_device \"default\"/' /etc/mpd.conf"

echo "   ✅ MPD configuration updated"
echo ""

# Step 7: Restart MPD
log "Step 7: Restarting MPD"
echo "7. Restarting MPD service..."
ssh "$PI5_ALIAS" "sudo systemctl restart mpd"
sleep 2

if ssh "$PI5_ALIAS" "systemctl is-active --quiet mpd"; then
    echo "   ✅ MPD restarted successfully"
else
    echo "   ⚠️  MPD restart had issues"
fi
echo ""

# Step 8: Inform about reboot
log "Step 8: Reboot required"
echo "=========================================="
echo "⚠️  REBOOT REQUIRED"
echo "=========================================="
echo ""
echo "The configuration changes require a reboot to take effect."
echo ""
echo "After reboot, audio should work via HDMI."
echo ""
read -p "Reboot Pi 5 now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Rebooting Pi 5"
    echo "Rebooting Pi 5..."
    ssh "$PI5_ALIAS" "sudo reboot"
    echo "Pi 5 is rebooting. Please wait 30-60 seconds, then run:"
    echo "  ./test-complete-audio-system.sh"
else
    echo "Please reboot manually when ready:"
    echo "  ssh pi2 'sudo reboot'"
fi

echo ""
echo "=========================================="
echo "FIX COMPLETE"
echo "=========================================="
echo "Log file: $LOG_FILE"
echo ""

