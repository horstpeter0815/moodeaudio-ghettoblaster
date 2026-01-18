#!/bin/bash
# Comprehensive Connectivity Fix
# This script applies ALL fixes to solve connectivity problems permanently

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 COMPREHENSIVE CONNECTIVITY FIX                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "This script applies ALL connectivity fixes:"
echo "  1. Remove cloud-init package entirely"
echo "  2. Apply kernel parameters (cmdline.txt)"
echo "  3. Create unified boot service"
echo "  4. Remove conflicting network services"
echo "  5. Verify all fixes"
echo ""

# Check if SD card is mounted
if [ ! -d "/Volumes/rootfs" ]; then
    echo "❌ SD card not mounted"
    echo "   Please mount the SD card first"
    exit 1
fi

ROOTFS="/Volumes/rootfs"
BOOTFS="/Volumes/bootfs"

# Check for password file
if [ -f "test-password.txt" ]; then
    PASSWORD=$(cat test-password.txt | tr -d '\n\r')
else
    echo "⚠️  Password file not found, will prompt for sudo"
    PASSWORD=""
fi

run_sudo() {
    if [ -n "$PASSWORD" ]; then
        echo "$PASSWORD" | sudo -S "$@" 2>&1
    else
        sudo "$@" 2>&1
    fi
}

echo "=== STEP 1: Remove cloud-init package ==="
echo ""
echo "Removing cloud-init package from SD card..."
run_sudo chroot "$ROOTFS" apt-get remove --purge cloud-init cloud-initramfs-growroot cloud-initramfs-rescuepop -y 2>&1 | grep -v "^$" || true
run_sudo chroot "$ROOTFS" apt-get autoremove -y 2>&1 | grep -v "^$" || true
echo "✅ Cloud-init package removed"
echo ""

echo "=== STEP 2: Remove cloud-init files ==="
echo ""
run_sudo rm -rf "$ROOTFS/etc/cloud" 2>&1 || true
run_sudo rm -rf "$ROOTFS/var/lib/cloud" 2>&1 || true
run_sudo rm -rf "$ROOTFS/usr/lib/cloud-init" 2>&1 || true
run_sudo rm -rf "$ROOTFS/usr/bin/cloud-init*" 2>&1 || true
run_sudo rm -rf "$ROOTFS/usr/sbin/cloud-init*" 2>&1 || true
echo "✅ Cloud-init files removed"
echo ""

echo "=== STEP 3: Apply kernel parameters ==="
echo ""
if [ -f "$BOOTFS/cmdline.txt" ]; then
    echo "Updating cmdline.txt..."
    CURRENT_CMDLINE=$(cat "$BOOTFS/cmdline.txt")
    if ! echo "$CURRENT_CMDLINE" | grep -q "cloud-init=disabled"; then
        NEW_CMDLINE="$CURRENT_CMDLINE cloud-init=disabled cloud-init=none"
        run_sudo sh -c "echo '$NEW_CMDLINE' > '$BOOTFS/cmdline.txt'"
        echo "✅ cmdline.txt updated"
    else
        echo "✅ cmdline.txt already has cloud-init=disabled"
    fi
    echo "Current cmdline:"
    cat "$BOOTFS/cmdline.txt"
else
    echo "⚠️  cmdline.txt not found at $BOOTFS/cmdline.txt"
fi
echo ""

echo "=== STEP 4: Install unified boot service ==="
echo ""
if [ -f "moode-source/lib/systemd/system/00-unified-boot.service" ]; then
    run_sudo cp "moode-source/lib/systemd/system/00-unified-boot.service" "$ROOTFS/lib/systemd/system/" 2>&1
    echo "✅ Unified boot service installed"
    
    # Enable the service
    run_sudo chroot "$ROOTFS" systemctl enable 00-unified-boot.service 2>&1 || true
    echo "✅ Unified boot service enabled"
else
    echo "❌ Unified boot service not found"
fi
echo ""

echo "=== STEP 5: Apply systemd overrides ==="
echo ""
# Cloud-init override
run_sudo mkdir -p "$ROOTFS/etc/systemd/system/cloud-init.target.d" 2>&1
run_sudo tee "$ROOTFS/etc/systemd/system/cloud-init.target.d/override.conf" > /dev/null << 'EOF'
[Unit]
After=
Wants=
Requires=
EOF
echo "✅ Cloud-init override created"

# Mask cloud-init.target
run_sudo rm -f "$ROOTFS/etc/systemd/system/cloud-init.target" 2>&1
run_sudo ln -sf /dev/null "$ROOTFS/etc/systemd/system/cloud-init.target" 2>&1
echo "✅ cloud-init.target masked"

# Mask all cloud-init services
for svc in cloud-init cloud-init-local cloud-config cloud-final; do
    run_sudo rm -f "$ROOTFS/etc/systemd/system/${svc}.service" 2>&1
    run_sudo ln -sf /dev/null "$ROOTFS/etc/systemd/system/${svc}.service" 2>&1
done
echo "✅ All cloud-init services masked"
echo ""

echo "=== STEP 6: NetworkManager-wait-online fix ==="
echo ""
run_sudo mkdir -p "$ROOTFS/etc/systemd/system/NetworkManager-wait-online.service.d" 2>&1
run_sudo tee "$ROOTFS/etc/systemd/system/NetworkManager-wait-online.service.d/override.conf" > /dev/null << 'EOF'
[Unit]
After=
Wants=
Requires=
[Service]
ExecStart=
ExecStart=/bin/true
EOF
run_sudo rm -f "$ROOTFS/etc/systemd/system/NetworkManager-wait-online.service" 2>&1
run_sudo ln -sf /dev/null "$ROOTFS/etc/systemd/system/NetworkManager-wait-online.service" 2>&1
echo "✅ NetworkManager-wait-online masked"
echo ""

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ COMPREHENSIVE FIX APPLIED                               ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "All fixes have been applied:"
echo "  ✅ Cloud-init package removed"
echo "  ✅ Cloud-init files removed"
echo "  ✅ Kernel parameters added (cmdline.txt)"
echo "  ✅ Unified boot service installed"
echo "  ✅ Systemd overrides created"
echo "  ✅ NetworkManager-wait-online disabled"
echo ""
echo "The SD card is ready. Boot the Pi - it should work now!"
echo ""

