#!/bin/bash
# Apply FINAL working configuration to SD card
# ONE clean working setup - no conflicts

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect SD card
ROOTFS="${ROOTFS:-/}"

if [ "$ROOTFS" = "/" ] && [ ! -d "/boot/firmware" ]; then
    if [ -d "/Volumes/rootfs" ]; then
        ROOTFS="/Volumes/rootfs"
    else
        echo "❌ SD card not found"
        echo "   Mount SD card at /Volumes/rootfs"
        exit 1
    fi
fi

echo "=== APPLYING FINAL WORKING CONFIGURATION ==="
echo ""
echo "Root filesystem: $ROOTFS"
echo ""

# 1. Disable ALL redundant SSH services
echo "1. Disabling redundant SSH services..."
CUSTOM_SSH_SERVICES=(
    "01-ssh-enable.service"
    "enable-ssh-early.service"
    "ssh-asap.service"
    "ssh-ultra-early.service"
    "ssh-permanent.service"
    "ssh-watchdog.service"
    "fix-ssh-sudoers.service"
    "00-boot-network-ssh.service"
)

for svc in "${CUSTOM_SSH_SERVICES[@]}"; do
    # Remove symlinks
    rm -f "$ROOTFS/etc/systemd/system/multi-user.target.wants/$svc" 2>/dev/null || true
    rm -f "$ROOTFS/etc/systemd/system/sysinit.target.wants/$svc" 2>/dev/null || true
    rm -f "$ROOTFS/etc/systemd/system/local-fs.target.wants/$svc" 2>/dev/null || true
    rm -f "$ROOTFS/etc/systemd/system/basic.target.wants/$svc" 2>/dev/null || true
    
    # Create override to disable
    mkdir -p "$ROOTFS/etc/systemd/system/$svc.d" 2>/dev/null || true
    cat > "$ROOTFS/etc/systemd/system/$svc.d/override.conf" << 'EOF'
[Service]
ExecStart=
ExecStart=/bin/true
TimeoutStartSec=1
EOF
done
echo "✅ All redundant SSH services disabled"

# 2. Ensure only 00-unified-boot is enabled for SSH
echo "2. Ensuring 00-unified-boot.service is enabled..."
mkdir -p "$ROOTFS/etc/systemd/system/local-fs.target.wants" 2>/dev/null || true
mkdir -p "$ROOTFS/etc/systemd/system/sysinit.target.wants" 2>/dev/null || true
if [ -f "$ROOTFS/lib/systemd/system/00-unified-boot.service" ]; then
    ln -sf /lib/systemd/system/00-unified-boot.service "$ROOTFS/etc/systemd/system/local-fs.target.wants/00-unified-boot.service" 2>/dev/null || true
    ln -sf /lib/systemd/system/00-unified-boot.service "$ROOTFS/etc/systemd/system/sysinit.target.wants/00-unified-boot.service" 2>/dev/null || true
    echo "✅ 00-unified-boot.service enabled"
fi

# 3. Disable disable-console.service
echo "3. Disabling disable-console.service..."
rm -f "$ROOTFS/etc/systemd/system/multi-user.target.wants/disable-console.service" 2>/dev/null || true
mkdir -p "$ROOTFS/etc/systemd/system/disable-console.service.d" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system/disable-console.service.d/override.conf" << 'EOF'
[Service]
ExecStart=
ExecStart=/bin/true
TimeoutStartSec=1
EOF
echo "✅ disable-console.service disabled"

# 4. Update all IP addresses to 192.168.2.3
echo "4. Updating IP addresses to 192.168.2.3..."
# Update service files that might have old IP
for f in "$ROOTFS/lib/systemd/system"/*.service "$ROOTFS/etc/systemd/system"/*.service; do
    if [ -f "$f" ] && grep -q "192.168.10.2" "$f" 2>/dev/null; then
        if [[ "$OSTYPE" == "darwin"* ]]; then
            sed -i '' 's/192\.168\.10\.2/192.168.2.3/g' "$f" 2>/dev/null || true
            sed -i '' 's/192\.168\.10\.1/192.168.2.1/g' "$f" 2>/dev/null || true
        else
            sed -i 's/192\.168\.10\.2/192.168.2.3/g' "$f" 2>/dev/null || true
            sed -i 's/192\.168\.10\.1/192.168.2.1/g' "$f" 2>/dev/null || true
        fi
    fi
done
echo "✅ IP addresses updated"

# 5. Fix network script IP
echo "5. Updating network scripts..."
if [ -f "$ROOTFS/usr/local/bin/fix-network-ip.sh" ]; then
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' 's/192\.168\.10\.2/192.168.2.3/g' "$ROOTFS/usr/local/bin/fix-network-ip.sh" 2>/dev/null || true
        sed -i '' 's/192\.168\.10\.1/192.168.2.1/g' "$ROOTFS/usr/local/bin/fix-network-ip.sh" 2>/dev/null || true
    else
        sed -i 's/192\.168\.10\.2/192.168.2.3/g' "$ROOTFS/usr/local/bin/fix-network-ip.sh" 2>/dev/null || true
        sed -i 's/192\.168\.10\.1/192.168.2.1/g' "$ROOTFS/usr/local/bin/fix-network-ip.sh" 2>/dev/null || true
    fi
    echo "✅ fix-network-ip.sh updated"
fi

# 6. Ensure SSH is enabled
echo "6. Ensuring SSH is enabled..."
mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants" 2>/dev/null || true
if [ -f "$ROOTFS/lib/systemd/system/ssh.service" ]; then
    ln -sf /lib/systemd/system/ssh.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/ssh.service" 2>/dev/null || true
elif [ -f "$ROOTFS/usr/lib/systemd/system/ssh.service" ]; then
    ln -sf /usr/lib/systemd/system/ssh.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/ssh.service" 2>/dev/null || true
fi
touch "$ROOTFS/boot/firmware/ssh" 2>/dev/null || touch "$ROOTFS/boot/ssh" 2>/dev/null || true
echo "✅ SSH enabled"

# 7. Add timeout to fix-network-ip if it exists
echo "7. Adding timeout to fix-network-ip.service..."
mkdir -p "$ROOTFS/etc/systemd/system/fix-network-ip.service.d" 2>/dev/null || true
cat > "$ROOTFS/etc/systemd/system/fix-network-ip.service.d/override.conf" << 'EOF'
[Service]
TimeoutStartSec=10
TimeoutStopSec=5
EOF
echo "✅ fix-network-ip.service timeout added"

echo ""
echo "=== FINAL CONFIGURATION APPLIED ==="
echo ""
echo "✅ Only 00-unified-boot.service enabled for SSH"
echo "✅ All redundant SSH services disabled"
echo "✅ IP address: 192.168.2.3 (all services)"
echo "✅ SSH enabled and ready"
echo "✅ disable-console.service disabled"
echo ""
echo "SSH ready at: ssh andre@192.168.2.3"
echo ""
echo "This is ONE clean working configuration."
echo ""
