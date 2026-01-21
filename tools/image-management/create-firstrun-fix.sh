#!/bin/bash
#########################################################################
# Create First-Run Fix Script
# When macOS can't modify ext4 rootfs, create a fix script on bootfs
# Usage: ./create-firstrun-fix.sh [sd_device]
#########################################################################

set -e

SD_DEVICE="${1:-disk4}"
BOOTFS="/Volumes/bootfs"

if [ ! -d "$BOOTFS" ]; then
    echo "Mounting bootfs..."
    diskutil mount "${SD_DEVICE}s1"
fi

echo "=== Creating First-Run Fix Script ==="
echo ""
echo "This will create /boot/firmware/firstrun-fix.sh"
echo "The script must be run after first boot via SSH"
echo ""

# Create the fix script
cat > "$BOOTFS/firstrun-fix.sh" << 'FIXSCRIPT'
#!/bin/bash
# First-run fixes for moOde
# Run after boot: sudo bash /boot/firmware/firstrun-fix.sh

echo "=== Applying First-Run Fixes ==="

# Add your fixes here
# Example:
# systemctl disable problematic.service
# sed -i 's/old/new/g' /path/to/file
# rm -f /path/to/problematic/file

echo "✅ Fixes applied"
echo "Rebooting in 5 seconds..."
sleep 5
reboot
FIXSCRIPT

chmod +x "$BOOTFS/firstrun-fix.sh"

echo "✅ Script created at: $BOOTFS/firstrun-fix.sh"
echo ""
echo "Edit the script to add your fixes, then:"
echo "1. Boot the Pi"
echo "2. SSH in: ssh user@moode.local"
echo "3. Run: sudo bash /boot/firmware/firstrun-fix.sh"
