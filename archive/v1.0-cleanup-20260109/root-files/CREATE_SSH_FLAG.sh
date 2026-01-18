#!/bin/bash
# Create SSH flag on boot partition
# Run: sudo ./CREATE_SSH_FLAG.sh

BOOTFS=""
for vol in "/Volumes/bootfs" "/Volumes/boot" "/Volumes/firmware"; do
    if [ -d "$vol" ]; then
        BOOTFS="$vol"
        break
    fi
done

if [ -z "$BOOTFS" ]; then
    echo "❌ Boot partition not found"
    echo "Please mount boot partition first"
    exit 1
fi

echo "=== CREATING SSH FLAG ==="
echo "Boot partition: $BOOTFS"
echo ""

# Try different locations
if touch "$BOOTFS/ssh" 2>/dev/null; then
    echo "✅ Created: $BOOTFS/ssh"
elif touch "$BOOTFS/firmware/ssh" 2>/dev/null; then
    echo "✅ Created: $BOOTFS/firmware/ssh"
else
    echo "❌ Could not create SSH flag (may need sudo)"
    echo "Run manually: sudo touch $BOOTFS/ssh"
    exit 1
fi

echo ""
echo "✅✅✅ SSH FLAG CREATED ✅✅✅"
echo ""

