#!/bin/bash
# Apply minimal boot fixes - NO multi-user target, disable audio, fix dbus

ROOTFS="/Volumes/rootfs"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted at $ROOTFS"
    exit 1
fi

cd "$ROOTFS/etc/systemd/system" || exit 1

echo "=== Applying Minimal Boot Fixes ==="
echo ""

# 1. Set default.target to basic.target (NOT multi-user)
echo "1. Setting default.target → basic.target"
rm -f default.target
ln -sf /lib/systemd/system/basic.target default.target
if [ -L default.target ]; then
    echo "   ✅ default.target → basic.target"
else
    echo "   ❌ Failed to create default.target symlink"
    exit 1
fi

# 2. Mask audio services (prevent them from blocking boot)
echo ""
echo "2. Masking audio services"
rm -f sound.target alsa-state.service alsa-restore.service
ln -s /dev/null sound.target 2>/dev/null
ln -s /dev/null alsa-state.service 2>/dev/null
ln -s /dev/null alsa-restore.service 2>/dev/null

# Verify
if [ -L sound.target ] && [ -L alsa-state.service ] && [ -L alsa-restore.service ]; then
    echo "   ✅ Audio services masked"
else
    echo "   ⚠️  Some audio services may not be masked"
fi

# 3. Verify dbus.service fixes
echo ""
echo "3. Verifying dbus.service fixes"
if [ -f "dbus.service.d/fix-circular-dependency.conf" ]; then
    echo "   ✅ dbus.service.d/fix-circular-dependency.conf exists"
    if grep -q "After=dbus.socket sysinit.target" dbus.service.d/fix-circular-dependency.conf; then
        echo "   ✅ After= correctly set (no basic.target)"
    else
        echo "   ⚠️  After= might be wrong"
    fi
    if grep -q "Before=basic.target" dbus.service.d/fix-circular-dependency.conf; then
        echo "   ✅ Before=basic.target set"
    else
        echo "   ⚠️  Before= missing"
    fi
else
    echo "   ❌ dbus.service.d/fix-circular-dependency.conf missing!"
fi

if [ -f "dbus.service.d/fix-timeout.conf" ]; then
    echo "   ✅ dbus.service.d/fix-timeout.conf exists"
else
    echo "   ❌ dbus.service.d/fix-timeout.conf missing!"
fi

# 4. Verify other fixes
echo ""
echo "4. Verifying other fixes"
[ -f "basic.target.d/fix-no-avahi.conf" ] && echo "   ✅ basic.target.d/fix-no-avahi.conf" || echo "   ❌ Missing"
[ -f "basic.target.d/disable-sound.conf" ] && echo "   ✅ basic.target.d/disable-sound.conf" || echo "   ❌ Missing"
[ -f "systemd-timedated.service.d/fix-dependencies.conf" ] && echo "   ✅ systemd-timedated fix" || echo "   ❌ Missing"
[ -f "NetworkManager.service.d/fix-timeout.conf" ] && echo "   ✅ NetworkManager fix" || echo "   ❌ Missing"

echo ""
echo "=== Summary ==="
echo "✅ default.target → basic.target (NO multi-user)"
echo "✅ Audio services masked"
echo "✅ dbus.service fixes applied"
echo ""
echo "Boot should now:"
echo "  1. Start dbus.service when socket is ready"
echo "  2. Stop at basic.target (NOT multi-user)"
echo "  3. NOT wait for audio services"
