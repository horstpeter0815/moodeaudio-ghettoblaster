#!/bin/bash
#########################################################################
# Apply Standard Fixes Tool - Apply all moOde configuration fixes
# Usage: ./apply-fixes.sh [container-name]
# Requires: Image must be mounted first using mount-image.sh
#########################################################################

set -e

CONTAINER_NAME="${1:-pigen_work}"

echo "========================================="
echo "APPLYING MOODE CONFIGURATION FIXES"
echo "========================================="
echo ""

docker exec "$CONTAINER_NAME" bash -c '
set -e

echo "=== 1. Fixing cmdline.txt ==="
cat > /mnt/boot/cmdline.txt << "EOF"
console=tty3 root=PARTUUID=1f100fd5-02 rootfstype=ext4 fsck.repair=yes rootwait quiet loglevel=3 video=HDMI-A-1:1280x400@60 logo.nologo vt.global_cursor_default=0
EOF
echo "✅ cmdline.txt updated with video=HDMI-A-1:1280x400@60"

echo ""
echo "=== 2. Fixing config.txt mandatory settings ==="
sed -i "s/^arm_boost=0/arm_boost=1/" /mnt/boot/config.txt
sed -i "s/^hdmi_force_edid_audio=1/hdmi_force_edid_audio=0/" /mnt/boot/config.txt
echo "✅ config.txt: arm_boost=1, hdmi_force_edid_audio=0"

echo ""
echo "=== 3. Installing sqlite3 if needed ==="
if ! command -v sqlite3 &> /dev/null; then
    apt-get update -qq
    apt-get install -y sqlite3 -qq
fi

echo ""
echo "=== 4. Fixing moOde database settings ==="
sqlite3 /mnt/root/var/local/www/db/moode-sqlite3.db << "EOSQL"
UPDATE cfg_system SET value="HiFiBerry AMP100" WHERE param="adevname";
UPDATE cfg_system SET value="HiFiBerry AMP100" WHERE param="i2sdevice";
UPDATE cfg_system SET value="1" WHERE param="cardnum";
UPDATE cfg_system SET value="plughw" WHERE param="alsa_output_mode";
UPDATE cfg_system SET value="1" WHERE param="local_display";
UPDATE cfg_system SET value="bose_wave_filters.yml" WHERE param="camilladsp";
UPDATE cfg_system SET value="Yes" WHERE param="cdsp_fix_playback";
EOSQL
echo "✅ Database updated: HiFiBerry AMP100, landscape, filters enabled"

echo ""
echo "=== 5. Fixing ALSA configuration ==="
cat > /mnt/root/etc/alsa/conf.d/_audioout.conf << "EOF"
#########################################
# This file is managed by moOde
#########################################
pcm._audioout {
type copy
slave.pcm "plughw:1,0"
}
EOF
echo "✅ ALSA configured for plughw:1,0 (HiFiBerry)"

echo ""
echo "=== 6. Verifying critical settings ==="
echo "cmdline.txt:"
grep "video=" /mnt/boot/cmdline.txt
echo ""
echo "config.txt:"
grep "^arm_boost=" /mnt/boot/config.txt
grep "^hdmi_force_edid_audio=" /mnt/boot/config.txt
grep "^dtoverlay=hifiberry" /mnt/boot/config.txt
echo ""
echo "Database:"
sqlite3 /mnt/root/var/local/www/db/moode-sqlite3.db "SELECT param, value FROM cfg_system WHERE param IN (\"adevname\", \"hdmi_scn_orient\", \"local_display\");"

echo ""
echo "========================================="
echo "✅ ALL FIXES APPLIED SUCCESSFULLY!"
echo "========================================="
'
