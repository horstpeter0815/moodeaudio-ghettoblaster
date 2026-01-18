#!/bin/bash
# Disable services that might be blocking after basic.target

ROOTFS="/Volumes/rootfs"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted at $ROOTFS"
    exit 1
fi

cd "$ROOTFS/etc/systemd/system" || exit 1

echo "=== Disabling Services Blocking After basic.target ==="
echo ""

# Services that commonly block after basic.target:
# 1. systemd-hostnamed.service (socket-activated, might hang)
# 2. systemd-timedated.service (already has fixes, but might need disabling)
# 3. systemd-resolved.service (if it exists)
# 4. systemd-logind.service (if it exists)

# Mask systemd-hostnamed.service (socket activation will still work, but service won't start)
echo "1. Masking systemd-hostnamed.service..."
rm -f systemd-hostnamed.service
ln -s /dev/null systemd-hostnamed.service 2>/dev/null
echo "   ✅ systemd-hostnamed.service masked"

# Mask systemd-timedated.service (already disabled, but ensure it's masked)
echo ""
echo "2. Ensuring systemd-timedated.service is masked..."
rm -f systemd-timedated.service
ln -s /dev/null systemd-timedated.service 2>/dev/null
echo "   ✅ systemd-timedated.service masked"

# Mask systemd-resolved.service if it exists
if [ -f "$ROOTFS/lib/systemd/system/systemd-resolved.service" ] || [ -L "$ROOTFS/etc/systemd/system/systemd-resolved.service" ]; then
    echo ""
    echo "3. Masking systemd-resolved.service..."
    rm -f systemd-resolved.service
    ln -s /dev/null systemd-resolved.service 2>/dev/null
    echo "   ✅ systemd-resolved.service masked"
fi

# Mask systemd-logind.service if it exists
if [ -f "$ROOTFS/lib/systemd/system/systemd-logind.service" ] || [ -L "$ROOTFS/etc/systemd/system/systemd-logind.service" ]; then
    echo ""
    echo "4. Masking systemd-logind.service..."
    rm -f systemd-logind.service
    ln -s /dev/null systemd-logind.service 2>/dev/null
    echo "   ✅ systemd-logind.service masked"
fi

echo ""
echo "=== Fix Complete ==="
echo "✅ Services that might block after basic.target are now masked"
echo ""
echo "Masked services:"
echo "  - systemd-hostnamed.service"
echo "  - systemd-timedated.service"
if [ -L "$ROOTFS/etc/systemd/system/systemd-resolved.service" ]; then
    echo "  - systemd-resolved.service"
fi
if [ -L "$ROOTFS/etc/systemd/system/systemd-logind.service" ]; then
    echo "  - systemd-logind.service"
fi
