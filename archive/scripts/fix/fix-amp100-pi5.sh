#!/bin/bash
# Fix HiFiBerry AMP100 on Pi 5
# AMP100 consists of DAC 2 Plus Pro

echo "=== FIXING HIFIBERRY AMP100 ON PI 5 ==="
echo ""

PI5_ALIAS="pi2"
LOG_FILE="amp100-fix-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

# Check if Pi 5 is online
if ! ssh -o ConnectTimeout=5 "$PI5_ALIAS" "echo 'Online'" >/dev/null 2>&1; then
    echo "❌ Pi 5 is not online."
    exit 1
fi

echo "✅ Pi 5 is online"
echo ""

# Step 1: Backup
log "Step 1: Backing up configuration"
ssh "$PI5_ALIAS" "sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup-$(date +%Y%m%d_%H%M%S)"
echo "   ✅ Backup created"
echo ""

# Step 2: Clean up - remove all hifiberry and duplicate settings
log "Step 2: Cleaning up config.txt"
ssh "$PI5_ALIAS" "sudo sed -i '/^dtoverlay=hifiberry-/d' /boot/firmware/config.txt"
ssh "$PI5_ALIAS" "sudo sed -i '/^dtparam=i2c_arm=/d' /boot/firmware/config.txt"
ssh "$PI5_ALIAS" "sudo sed -i '/^dtparam=i2s=/d' /boot/firmware/config.txt"
ssh "$PI5_ALIAS" "sudo sed -i '/^dtparam=i2c_arm_baudrate=/d' /boot/firmware/config.txt"
ssh "$PI5_ALIAS" "sudo sed -i '/^dtoverlay=vc4-kms-v3d-pi5/d' /boot/firmware/config.txt"
echo "   ✅ Cleaned up"
echo ""

# Step 3: Add correct AMP100 configuration
log "Step 3: Adding AMP100 configuration"
echo "3. Configuring for HiFiBerry AMP100 (DAC 2 Plus Pro)..."

# I2C and I2S (single entries, no duplicates)
ssh "$PI5_ALIAS" "echo 'dtparam=i2c_arm=on' | sudo tee -a /boot/firmware/config.txt > /dev/null"
ssh "$PI5_ALIAS" "echo 'dtparam=i2s=on' | sudo tee -a /boot/firmware/config.txt > /dev/null"

# VC4 KMS with noaudio (HDMI audio disabled)
ssh "$PI5_ALIAS" "echo 'dtoverlay=vc4-kms-v3d-pi5,noaudio' | sudo tee -a /boot/firmware/config.txt > /dev/null"

# AMP100 overlay (this is the correct one for AMP100)
ssh "$PI5_ALIAS" "echo 'dtoverlay=hifiberry-amp100' | sudo tee -a /boot/firmware/config.txt > /dev/null"

# I2C baudrate - try higher value for Pi 5 (AMP100 might need it)
ssh "$PI5_ALIAS" "echo 'dtparam=i2c_arm_baudrate=100000' | sudo tee -a /boot/firmware/config.txt > /dev/null"

echo "   ✅ AMP100 configuration added"
echo ""

# Step 4: Update ALSA config
log "Step 4: Updating ALSA configuration"
ssh "$PI5_ALIAS" "sudo tee /etc/asound.conf > /dev/null << 'ALSA_CONFIG'
pcm.!default {
    type hw
    card 0
}
ctl.!default {
    type hw
    card 0
}
ALSA_CONFIG"
echo "   ✅ ALSA configured for card 0"
echo ""

# Step 5: Update MPD config
log "Step 5: Updating MPD configuration"
ssh "$PI5_ALIAS" "sudo cp /etc/mpd.conf /etc/mpd.conf.backup-$(date +%Y%m%d_%H%M%S)"
ssh "$PI5_ALIAS" "sudo sed -i 's/device \"hw:2,0\"/device \"hw:0,0\"/' /etc/mpd.conf"
ssh "$PI5_ALIAS" "sudo sed -i 's/device \"_audioout\"/device \"hw:0,0\"/' /etc/mpd.conf"
ssh "$PI5_ALIAS" "sudo sed -i 's/mixer_device \"default:vc4hdmi0\"/mixer_device \"default\"/' /etc/mpd.conf"
ssh "$PI5_ALIAS" "sudo sed -i 's/mixer_control \"PCM\"/mixer_control \"Digital\"/' /etc/mpd.conf"
echo "   ✅ MPD configured for card 0"
echo ""

# Step 6: Verify
log "Step 6: Verifying configuration"
echo "6. Final configuration:"
ssh "$PI5_ALIAS" "grep -E 'hifiberry|i2c|i2s|vc4.*noaudio' /boot/firmware/config.txt" | tee -a "$LOG_FILE"
echo ""

# Step 7: Reboot
log "Step 7: Rebooting"
echo "=========================================="
echo "⚠️  REBOOTING PI 5"
echo "=========================================="
echo ""
echo "Rebooting to apply AMP100 configuration..."
ssh "$PI5_ALIAS" "sudo reboot"
echo ""
echo "Pi 5 rebooting. Wait 60 seconds, then test:"
echo "  ssh pi2 'aplay -l'"
echo "  ssh pi2 'cat /proc/asound/cards'"
echo "  ssh pi2 'mpc play'"
echo ""
echo "=========================================="
echo "AMP100 FIX APPLIED - REBOOTING"
echo "=========================================="
echo "Log: $LOG_FILE"
echo ""

