#!/bin/bash
# Apply all SD card fixes
# Run with: sudo ./APPLY_SD_FIXES.sh

set -e

ROOT="/Volumes/rootfs"
BOOT="/Volumes/bootfs"

echo "=== APPLYING SD CARD FIXES ==="
echo ""

# 1. SSH file
echo "1. Creating SSH file..."
touch "$BOOT/ssh"
echo "✅ SSH file created"
echo ""

# 2. User setup
echo "2. Setting up user andre..."
if ! grep -q "^andre:" "$ROOT/etc/passwd"; then
    echo "andre:x:1000:1000:andre:/home/andre:/bin/bash" >> "$ROOT/etc/passwd"
    echo "✅ User added to passwd"
else
    echo "✅ User already in passwd"
fi

if ! grep -q "^andre:" "$ROOT/etc/group"; then
    echo "andre:x:1000:" >> "$ROOT/etc/group"
    echo "✅ User added to group"
else
    echo "✅ User already in group"
fi

# Home directory permissions
chown -R 1000:1000 "$ROOT/home/andre" 2>/dev/null || true
echo "✅ Home directory permissions set"
echo ""

# 3. Cloud-init disable
echo "3. Disabling cloud-init..."

# Create override directory
mkdir -p "$ROOT/etc/systemd/system/cloud-init.target.d"

# Create override file
cat > "$ROOT/etc/systemd/system/cloud-init.target.d/override.conf" << 'EOF'
[Unit]
After=
Wants=
Requires=
EOF
echo "✅ Cloud-init override created"

# Mask cloud-init.target
rm -f "$ROOT/etc/systemd/system/cloud-init.target"
ln -sf /dev/null "$ROOT/etc/systemd/system/cloud-init.target"
echo "✅ cloud-init.target masked"

# Mask cloud-init services
for svc in cloud-init cloud-init-local cloud-config cloud-final; do
    rm -f "$ROOT/etc/systemd/system/$svc.service"
    ln -sf /dev/null "$ROOT/etc/systemd/system/$svc.service"
done
echo "✅ Cloud-init services masked"
echo ""

echo "=== FIXES COMPLETE ==="
echo ""
echo "✅ SSH enabled"
echo "✅ User andre configured"
echo "✅ Cloud-init disabled"
echo ""
echo "SD card is ready. Eject and boot Pi."




