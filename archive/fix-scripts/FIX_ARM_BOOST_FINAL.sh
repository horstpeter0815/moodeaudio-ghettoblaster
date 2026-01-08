#!/bin/bash
# FIX arm_boost - remove arm_boost=0 - RUN WITH SUDO
# sudo /Users/andrevollmer/moodeaudio-cursor/FIX_ARM_BOOST_FINAL.sh

SD_MOUNT="/Volumes/bootfs"
[ ! -d "$SD_MOUNT" ] && SD_MOUNT="/Volumes/boot"
CONFIG_FILE="$SD_MOUNT/config.txt"

echo "=== Entferne arm_boost=0 ==="

# Remove arm_boost=0, keep only arm_boost=1
awk '/arm_boost=0/ {next} {print}' "$CONFIG_FILE" > "$CONFIG_FILE.tmp"
mv "$CONFIG_FILE.tmp" "$CONFIG_FILE"
sync

echo ""
echo "arm_boost Einträge:"
grep "arm_boost" "$CONFIG_FILE"
echo ""
echo "✅ Fertig"

