#!/bin/bash
# Verify config.txt is saved and reboot

log() { echo -e "\033[0;32m[REBOOT]\033[0m $1"; }

log "Verifying config.txt..."
if [ -f /boot/firmware/config.txt ]; then
    log "✅ config.txt exists"
    echo ""
    log "Key audio settings:"
    grep -E "noaudio|audio=off|hifiberry-amp100|i2s=on" /boot/firmware/config.txt | head -5
    echo ""
else
    echo "⚠️  config.txt not found at /boot/firmware/config.txt"
fi

log "Config is saved (on boot partition, persists across reboots)"
echo ""
read -p "Reboot now? (y/n): " confirm
if [[ "$confirm" =~ ^[Yy] ]]; then
    log "Rebooting in 3 seconds..."
    sleep 3
    sudo reboot
else
    log "Reboot cancelled"
fi
