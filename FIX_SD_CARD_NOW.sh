#!/bin/bash
# Fix SD card - Run with sudo
# Usage: sudo ./FIX_SD_CARD_NOW.sh

ROOT="/Volumes/rootfs"
BOOT="/Volumes/bootfs"

echo "Fixing SD card..."

# SSH file
if [ -d "$BOOT" ]; then
    touch "$BOOT/ssh"
    echo "✅ SSH file created"
fi

# User setup
if [ -d "$ROOT" ]; then
    # Add user to passwd
    if ! grep -q "^andre:" "$ROOT/etc/passwd"; then
        echo "andre:x:1000:1000:andre:/home/andre:/bin/bash" >> "$ROOT/etc/passwd"
        echo "✅ User added to passwd"
    fi
    
    # Add to group
    if ! grep -q "^andre:" "$ROOT/etc/group"; then
        echo "andre:x:1000:" >> "$ROOT/etc/group"
        echo "✅ User added to group"
    fi
    
    # Set permissions
    chown -R 1000:1000 "$ROOT/home/andre" 2>/dev/null || true
    
    echo "✅ User setup complete"
fi

echo ""
echo "Done. Eject SD card and boot Pi."
echo "User: andre"
echo "Password: 0815 (will be set on first boot, or use default)"




