#!/bin/bash
# Fix HiFiBerry Audio on Pi 5 - Automatic
# Based on working Pi 4 configuration, fixes I2C issues

echo "=== FIXING HIFIBERRY AUDIO ON PI 5 (AUTOMATIC) ==="
echo ""

PI5_ALIAS="pi2"
LOG_FILE="hifiberry-fix-auto-$(date +%Y%m%d_%H%M%S).log"

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

# Step 2: Clean up config.txt - remove all audio/hifiberry related lines
log "Step 2: Cleaning up config.txt"
echo "2. Removing old audio/HiFiBerry settings..."

# Remove all audio and hifiberry related lines
ssh "$PI5_ALIAS" "sudo sed -i '/^dtparam=audio=/d' /boot/firmware/config.txt"
ssh "$PI5_ALIAS" "sudo sed -i '/^dtoverlay=hifiberry-/d' /boot/firmware/config.txt"
ssh "$PI5_ALIAS" "sudo sed -i '/^dtoverlay=vc4-kms-v3d-pi5/d' /boot/firmware/config.txt"

echo "   ✅ Old settings removed"
echo ""

# Step 3: Add correct configuration (like Pi 4)
log "Step 3: Adding correct configuration"
echo "3. Adding HiFiBerry configuration (like Pi 4)..."

# Add I2C and I2S first (before overlays)
ssh "$PI5_ALIAS" "echo 'dtparam=i2c_arm=on' | sudo tee -a /boot/firmware/config.txt > /dev/null"
ssh "$PI5_ALIAS" "echo 'dtparam=i2s=on' | sudo tee -a /boot/firmware/config.txt > /dev/null"

# Add VC4 KMS with noaudio (to prevent HDMI audio)
ssh "$PI5_ALIAS" "echo 'dtoverlay=vc4-kms-v3d-pi5,noaudio' | sudo tee -a /boot/firmware/config.txt > /dev/null"

# Add HiFiBerry DAC+ overlay (like Pi 4 - this is the standard that works)
ssh "$PI5_ALIAS" "echo 'dtoverlay=hifiberry-dacplus' | sudo tee -a /boot/firmware/config.txt > /dev/null"

echo "   ✅ Configuration added"
echo ""

# Step 4: Fix I2C baudrate (Pi 5 might need different settings)
log "Step 4: Configuring I2C for Pi 5"
echo "4. Configuring I2C..."

# Remove old I2C baudrate settings
ssh "$PI5_ALIAS" "sudo sed -i '/^dtparam=i2c_arm_baudrate=/d' /boot/firmware/config.txt"

# Add I2C baudrate (lower might help with timeouts)
ssh "$PI5_ALIAS" "echo 'dtparam=i2c_arm_baudrate=50000' | sudo tee -a /boot/firmware/config.txt > /dev/null"

echo "   ✅ I2C configured (lower baudrate to avoid timeouts)"
echo ""

# Step 5: Update ALSA config for HiFiBerry (card 2, like Pi 4)
log "Step 5: Updating ALSA configuration"
echo "5. Updating ALSA configuration..."

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
echo "7. Final configuration:"
echo ""
ssh "$PI5_ALIAS" "grep -E 'dtoverlay.*hifiberry|dtparam.*i2c|dtparam.*i2s|dtoverlay.*vc4.*noaudio' /boot/firmware/config.txt" | tee -a "$LOG_FILE"
echo ""

# Step 8: Reboot
log "Step 8: Rebooting Pi 5"
echo "=========================================="
echo "⚠️  REBOOTING PI 5"
echo "=========================================="
echo ""
echo "Rebooting now to apply changes..."
ssh "$PI5_ALIAS" "sudo reboot"
echo ""
echo "Pi 5 is rebooting. Please wait 60 seconds, then test:"
echo "  ssh pi2 'aplay -l'"
echo "  ssh pi2 'cat /proc/asound/cards'"
echo "  ssh pi2 'mpc play'"
echo ""
echo "=========================================="
echo "FIX APPLIED - REBOOTING"
echo "=========================================="
echo "Log file: $LOG_FILE"
echo ""

