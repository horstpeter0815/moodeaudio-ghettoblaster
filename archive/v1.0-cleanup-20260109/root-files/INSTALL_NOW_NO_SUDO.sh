#!/bin/bash
# Install without sudo (for files we can write)

cd /Users/andrevollmer/moodeaudio-cursor

echo "=== Installing Bulletproof Fix (no sudo parts) ==="

# Copy service file (if we can)
cp BULLETPROOF_ETH0_FIX.service /Volumes/rootfs/lib/systemd/system/eth0-direct-static.service 2>/dev/null && echo "✅ Service file copied" || echo "Need sudo for service file"

# Create directories (if we can)
mkdir -p /Volumes/rootfs/etc/systemd/system/local-fs.target.wants 2>/dev/null || echo "Need sudo for directories"

# Create SSH flag (if bootfs is writable)
if [ -d /Volumes/bootfs ]; then
    touch /Volumes/bootfs/ssh 2>/dev/null && echo "✅ SSH flag created" || echo "Need sudo for SSH flag"
fi

echo ""
echo "Some operations need sudo. Run: sudo ./COMPLETE_BULLETPROOF_FIX.sh"

