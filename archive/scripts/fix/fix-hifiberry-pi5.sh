#!/bin/bash
# Fix HiFiBerry Audio on Pi 5
# Based on working Pi 4 configuration

echo "=== FIXING HIFIBERRY AUDIO ON PI 5 ==="
echo ""

PI5_ALIAS="pi2"
LOG_FILE="hifiberry-fix-$(date +%Y%m%d_%H%M%S).log"

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

# Step 1: Backup current config
log "Step 1: Backing up current configuration"
ssh "$PI5_ALIAS" "sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup-$(date +%Y%m%d_%H%M%S)"
echo "   ✅ Backup created"
echo ""

# Step 2: Remove conflicting audio settings
log "Step 2: Removing conflicting audio settings"
echo "2. Cleaning up config.txt..."

# Remove duplicate/conflicting audio parameters
ssh "$PI5_ALIAS" "sudo sed -i '/^dtparam=audio=/d' /boot/firmware/config.txt"
ssh "$PI5_ALIAS" "sudo sed -i '/^dtoverlay=vc4-kms-v3d-pi5,noaudio/d' /boot/firmware/config.txt"

# Ensure vc4-kms-v3d-pi5 has noaudio to prevent HDMI audio
ssh "$PI5_ALIAS" "sudo sed -i 's/^dtoverlay=vc4-kms-v3d-pi5$/dtoverlay=vc4-kms-v3d-pi5,noaudio/' /boot/firmware/config.txt"
if ! ssh "$PI5_ALIAS" "grep -q 'dtoverlay=vc4-kms-v3d-pi5' /boot/firmware/config.txt"; then
    ssh "$PI5_ALIAS" "echo 'dtoverlay=vc4-kms-v3d-pi5,noaudio' | sudo tee -a /boot/firmware/config.txt > /dev/null"
fi

echo "   ✅ Conflicting settings removed"
echo ""

# Step 3: Ensure I2C and I2S are enabled (like Pi 4)
log "Step 3: Ensuring I2C and I2S are enabled"
echo "3. Enabling I2C and I2S..."

# Remove duplicates first
ssh "$PI5_ALIAS" "sudo sed -i '/^dtparam=i2c_arm=/d' /boot/firmware/config.txt"
ssh "$PI5_ALIAS" "sudo sed -i '/^dtparam=i2s=/d' /boot/firmware/config.txt"

# Add I2C and I2S parameters (like Pi 4)
if ! ssh "$PI5_ALIAS" "grep -q '^dtparam=i2c_arm=on' /boot/firmware/config.txt"; then
    ssh "$PI5_ALIAS" "echo 'dtparam=i2c_arm=on' | sudo tee -a /boot/firmware/config.txt > /dev/null"
fi

if ! ssh "$PI5_ALIAS" "grep -q '^dtparam=i2s=on' /boot/firmware/config.txt"; then
    ssh "$PI5_ALIAS" "echo 'dtparam=i2s=on' | sudo tee -a /boot/firmware/config.txt > /dev/null"
fi

echo "   ✅ I2C and I2S enabled"
echo ""

# Step 4: Fix HiFiBerry overlay - try different options
log "Step 4: Configuring HiFiBerry overlay"
echo "4. Configuring HiFiBerry overlay..."

# Remove existing hifiberry overlays
ssh "$PI5_ALIAS" "sudo sed -i '/^dtoverlay=hifiberry-/d' /boot/firmware/config.txt"

# Try hifiberry-dacplus first (like Pi 4), if that doesn't work, try amp100
# For now, let's try both - user can specify which hardware they have
echo "   Which HiFiBerry hardware do you have?"
echo "   1) HiFiBerry DAC+ Pro (like Pi 4)"
echo "   2) HiFiBerry AMP100"
read -p "   Enter choice (1 or 2, default 1): " choice
choice=${choice:-1}

if [ "$choice" == "1" ]; then
    echo "   Using hifiberry-dacplus (like Pi 4)"
    ssh "$PI5_ALIAS" "echo 'dtoverlay=hifiberry-dacplus' | sudo tee -a /boot/firmware/config.txt > /dev/null"
elif [ "$choice" == "2" ]; then
    echo "   Using hifiberry-amp100"
    ssh "$PI5_ALIAS" "echo 'dtoverlay=hifiberry-amp100' | sudo tee -a /boot/firmware/config.txt > /dev/null"
else
    echo "   Using hifiberry-dacplus (default)"
    ssh "$PI5_ALIAS" "echo 'dtoverlay=hifiberry-dacplus' | sudo tee -a /boot/firmware/config.txt > /dev/null"
fi

echo "   ✅ HiFiBerry overlay configured"
echo ""

# Step 5: Update ALSA config for HiFiBerry (card 2, like Pi 4)
log "Step 5: Updating ALSA configuration"
echo "5. Updating ALSA configuration..."

# Create ALSA config for HiFiBerry (card 2, like Pi 4)
ssh "$PI5_ALIAS" "sudo tee /etc/asound.conf > /dev/null << 'ALSA_CONFIG'
pcm.!default {
    type hw
    card 2
}
ctl.!default {
    type hw
    card 2
}
ALSA_CONFIG"

echo "   ✅ ALSA configuration updated for card 2"
echo ""

# Step 6: Update MPD config for HiFiBerry
log "Step 6: Updating MPD configuration"
echo "6. Updating MPD configuration..."

# Backup MPD config
ssh "$PI5_ALIAS" "sudo cp /etc/mpd.conf /etc/mpd.conf.backup-$(date +%Y%m%d_%H%M%S)"

# Update MPD to use HiFiBerry (card 2, device 0)
ssh "$PI5_ALIAS" "sudo sed -i 's/device \"_audioout\"/device \"hw:2,0\"/' /etc/mpd.conf"
ssh "$PI5_ALIAS" "sudo sed -i 's/mixer_device \"default:vc4hdmi0\"/mixer_device \"default\"/' /etc/mpd.conf"
ssh "$PI5_ALIAS" "sudo sed -i 's/mixer_control \"PCM\"/mixer_control \"Digital\"/' /etc/mpd.conf"

echo "   ✅ MPD configuration updated"
echo ""

# Step 7: Verify configuration
log "Step 7: Verifying configuration"
echo "7. Configuration summary:"
echo ""
ssh "$PI5_ALIAS" "grep -E 'dtoverlay.*hifiberry|dtparam.*i2c|dtparam.*i2s|dtoverlay.*vc4.*noaudio' /boot/firmware/config.txt" | tee -a "$LOG_FILE"
echo ""

# Step 8: Inform about reboot
log "Step 8: Reboot required"
echo "=========================================="
echo "⚠️  REBOOT REQUIRED"
echo "=========================================="
echo ""
echo "The configuration changes require a reboot to take effect."
echo ""
echo "After reboot, HiFiBerry audio should work."
echo ""
read -p "Reboot Pi 5 now? (y/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    log "Rebooting Pi 5"
    echo "Rebooting Pi 5..."
    ssh "$PI5_ALIAS" "sudo reboot"
    echo ""
    echo "Pi 5 is rebooting. Please wait 30-60 seconds, then test:"
    echo "  ssh pi2 'aplay -l'"
    echo "  ssh pi2 'mpc play'"
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

