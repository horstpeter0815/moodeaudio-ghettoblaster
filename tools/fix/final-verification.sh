#!/bin/bash
# Final verification - check ALL critical fixes

ROOTFS="/Volumes/rootfs"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted"
    exit 1
fi

cd "$ROOTFS/etc/systemd/system"

echo "=== Final Verification of All Fixes ==="
echo ""

ALL_OK=true

# Check 1: D-Bus circular dependency fix
if [ -f "dbus.service.d/fix-circular-dependency.conf" ]; then
    echo "✅ dbus.service.d/fix-circular-dependency.conf"
else
    echo "❌ MISSING: dbus.service.d/fix-circular-dependency.conf"
    ALL_OK=false
fi

# Check 2: basic.target fix
if [ -f "basic.target.d/fix-no-dbus-wait.conf" ]; then
    echo "✅ basic.target.d/fix-no-dbus-wait.conf"
else
    echo "❌ MISSING: basic.target.d/fix-no-dbus-wait.conf"
    ALL_OK=false
fi

# Check 3: start-ssh-nginx service
if [ -f "start-ssh-nginx.service" ]; then
    echo "✅ start-ssh-nginx.service"
else
    echo "❌ MISSING: start-ssh-nginx.service"
    ALL_OK=false
fi

# Check 4: Symlink
if [ -L "basic.target.wants/start-ssh-nginx.service" ]; then
    TARGET=$(readlink basic.target.wants/start-ssh-nginx.service)
    echo "✅ Symlink: basic.target.wants/start-ssh-nginx.service -> $TARGET"
else
    echo "❌ MISSING: basic.target.wants/start-ssh-nginx.service symlink"
    ALL_OK=false
fi

# Check 5: default.target
if [ -L "default.target" ]; then
    TARGET=$(readlink default.target)
    if [[ "$TARGET" == *"basic.target"* ]]; then
        echo "✅ default.target -> $TARGET"
    else
        echo "❌ default.target points to wrong target: $TARGET"
        ALL_OK=false
    fi
else
    echo "❌ MISSING: default.target"
    ALL_OK=false
fi

# Check 6: Masked services
if [ -L "systemd-hostnamed.socket" ] && [ "$(readlink systemd-hostnamed.socket)" = "/dev/null" ]; then
    echo "✅ systemd-hostnamed.socket masked"
else
    echo "⚠️  systemd-hostnamed.socket not masked (may cause errors but won't block)"
fi

if [ -L "systemd-hostnamed.service" ] && [ "$(readlink systemd-hostnamed.service)" = "/dev/null" ]; then
    echo "✅ systemd-hostnamed.service masked"
else
    echo "⚠️  systemd-hostnamed.service not masked"
fi

if [ -L "systemd-timedated.service" ] && [ "$(readlink systemd-timedated.service)" = "/dev/null" ]; then
    echo "✅ systemd-timedated.service masked"
else
    echo "⚠️  systemd-timedated.service not masked"
fi

echo ""
if [ "$ALL_OK" = true ]; then
    echo "✅ ALL CRITICAL FIXES ARE IN PLACE!"
    echo ""
    echo "Ready to boot. Expected behavior:"
    echo "  1. Boot reaches basic.target"
    echo "  2. start-ssh-nginx.service runs"
    echo "  3. SSH and nginx start"
    echo "  4. System accessible via SSH/web within 30-60 seconds"
else
    echo "❌ Some fixes are missing. Please check above."
    exit 1
fi
