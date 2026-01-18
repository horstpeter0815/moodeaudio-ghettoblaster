#!/bin/bash
# Apply Working Configuration to New Build
# Professional approach: Baseline comparison + application

set -e

WORKING_MOUNT="${1:-/Volumes/working-rootfs}"
NEW_MOUNT="${2:-/Volumes/rootfs}"

if [ ! -d "$WORKING_MOUNT/etc" ]; then
    echo "❌ ERROR: Working root filesystem not found at $WORKING_MOUNT"
    echo "Usage: $0 [working-mount] [new-mount]"
    echo "Example: $0 /Volumes/working-rootfs /Volumes/rootfs"
    exit 1
fi

if [ ! -d "$NEW_MOUNT/etc" ]; then
    echo "❌ ERROR: New root filesystem not found at $NEW_MOUNT"
    echo "Usage: $0 [working-mount] [new-mount]"
    echo "Example: $0 /Volumes/working-rootfs /Volumes/rootfs"
    exit 1
fi

echo "=== APPLYING WORKING CONFIGURATION ==="
echo "Working: $WORKING_MOUNT"
echo "New: $NEW_MOUNT"
echo ""
read -p "This will copy systemd configs from working to new. Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborted"
    exit 1
fi

echo ""
echo "Applying fixes..."

# 1. Copy network-online.target override
if [ -f "$WORKING_MOUNT/etc/systemd/system/network-online.target.d/override.conf" ]; then
    echo "1. Copying network-online.target override..."
    sudo mkdir -p "$NEW_MOUNT/etc/systemd/system/network-online.target.d"
    sudo cp "$WORKING_MOUNT/etc/systemd/system/network-online.target.d/override.conf" \
            "$NEW_MOUNT/etc/systemd/system/network-online.target.d/override.conf"
    echo "   ✅ Copied"
else
    echo "   ⚠️  No override in working system"
fi

# 2. Copy systemd-networkd-wait-online override
if [ -f "$WORKING_MOUNT/etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf" ]; then
    echo "2. Copying systemd-networkd-wait-online override..."
    sudo mkdir -p "$NEW_MOUNT/etc/systemd/system/systemd-networkd-wait-online.service.d"
    sudo cp "$WORKING_MOUNT/etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf" \
            "$NEW_MOUNT/etc/systemd/system/systemd-networkd-wait-online.service.d/override.conf"
    echo "   ✅ Copied"
fi

# 3. Copy multi-user.target override
if [ -f "$WORKING_MOUNT/etc/systemd/system/multi-user.target.d/override.conf" ]; then
    echo "3. Copying multi-user.target override..."
    sudo mkdir -p "$NEW_MOUNT/etc/systemd/system/multi-user.target.d"
    sudo cp "$WORKING_MOUNT/etc/systemd/system/multi-user.target.d/override.conf" \
            "$NEW_MOUNT/etc/systemd/system/multi-user.target.d/override.conf"
    echo "   ✅ Copied"
fi

# 4. Copy service masks
echo "4. Copying service masks..."
for service in systemd-networkd-wait-online NetworkManager-wait-online networkd-wait-online; do
    if [ -L "$WORKING_MOUNT/etc/systemd/system/${service}.service" ]; then
        TARGET=$(readlink "$WORKING_MOUNT/etc/systemd/system/${service}.service")
        if [ "$TARGET" = "/dev/null" ]; then
            echo "   Masking $service..."
            sudo rm -f "$NEW_MOUNT/etc/systemd/system/${service}.service"
            sudo ln -sf /dev/null "$NEW_MOUNT/etc/systemd/system/${service}.service"
            echo "   ✅ Masked"
        fi
    fi
done

# 5. Remove network-online.target.wants if it exists in new but not in working
if [ ! -d "$WORKING_MOUNT/etc/systemd/system/network-online.target.wants" ] && \
   [ -d "$NEW_MOUNT/etc/systemd/system/network-online.target.wants" ]; then
    echo "5. Removing network-online.target.wants (doesn't exist in working)..."
    sudo rm -rf "$NEW_MOUNT/etc/systemd/system/network-online.target.wants"
    echo "   ✅ Removed"
fi

# 6. Copy PeppyMeter masks
echo "6. Copying PeppyMeter service masks..."
for service in peppymeter-extended-displays localdisplay; do
    if [ -L "$WORKING_MOUNT/etc/systemd/system/${service}.service" ]; then
        TARGET=$(readlink "$WORKING_MOUNT/etc/systemd/system/${service}.service")
        if [ "$TARGET" = "/dev/null" ]; then
            echo "   Masking $service..."
            sudo rm -f "$NEW_MOUNT/etc/systemd/system/${service}.service"
            sudo ln -sf /dev/null "$NEW_MOUNT/etc/systemd/system/${service}.service"
            echo "   ✅ Masked"
        fi
    fi
done

echo ""
echo "=== SYNCING CHANGES ==="
sync
sleep 2

echo ""
echo "✅ Working configuration applied!"
echo ""
echo "Next steps:"
echo "  1. Run validation: ./tools/validate-sd-card-fixes.sh $NEW_MOUNT"
echo "  2. Test boot on Raspberry Pi"
echo "  3. If it works, document what was copied"
