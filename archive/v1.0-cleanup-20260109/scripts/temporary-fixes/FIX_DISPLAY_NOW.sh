#!/bin/bash
# Fix display - restore PeppyMeter, NOT wizard on display
# Run: cd ~/moodeaudio-cursor && sudo ./FIX_DISPLAY_NOW.sh

ROOTFS="/Volumes/rootfs"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted"
    exit 1
fi

echo "=== FIXING DISPLAY ==="
echo ""

# 1. Display: PeppyMeter (NOT wizard)
echo "1. Setting Display to PeppyMeter..."
sqlite3 "$ROOTFS/var/local/www/db/moode-sqlite3.db" << EOF
UPDATE cfg_system SET value='1' WHERE param='peppy_display';
UPDATE cfg_system SET value='0' WHERE param='local_display';
UPDATE cfg_system SET value='http://localhost/' WHERE param='local_display_url';
EOF
echo "✅ Display: PeppyMeter"

# 2. .xinitrc: moOde UI (NOT wizard)
echo "2. Fixing .xinitrc..."
sudo sed -i '' 's|--app="http://localhost/wizard.*"|--app="http://localhost/"|' "$ROOTFS/home/andre/.xinitrc" 2>/dev/null || true
echo "✅ .xinitrc: moOde UI"

echo ""
echo "✅✅✅ DISPLAY FIXED ✅✅✅"
echo ""
echo "After boot:"
echo "  - Display: PeppyMeter (tap for moOde UI)"
echo "  - Wizard: ONLY on iPhone (http://192.168.10.2/wizard/wizard-control.html)"
echo ""

