#!/bin/bash
# Disable all redundant SSH services - keep only standard SSH
# Run this on the Pi after boot

set -e

echo "=== DISABLING REDUNDANT SSH SERVICES ==="
echo ""

# List of custom SSH services to disable
CUSTOM_SSH_SERVICES=(
    "00-boot-network-ssh.service"
    "01-ssh-enable.service"
    "enable-ssh-early.service"
    "ssh-asap.service"
    "ssh-ultra-early.service"
    "ssh-permanent.service"
    "ssh-watchdog.service"
)

# Disable all custom SSH services
for svc in "${CUSTOM_SSH_SERVICES[@]}"; do
    echo "Disabling $svc..."
    systemctl stop "$svc" 2>/dev/null || true
    systemctl disable "$svc" 2>/dev/null || true
    systemctl mask "$svc" 2>/dev/null || true
    
    # Create override to prevent it from starting
    mkdir -p "/etc/systemd/system/$svc.d" 2>/dev/null || true
    cat > "/etc/systemd/system/$svc.d/override.conf" << 'EOF'
[Service]
ExecStart=
ExecStart=/bin/true
TimeoutStartSec=1
EOF
    
    echo "✅ $svc disabled"
done

# Ensure only standard SSH is enabled
echo ""
echo "Enabling standard SSH service..."
systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true

# Create override for standard SSH to prevent conflicts
mkdir -p /etc/systemd/system/ssh.service.d 2>/dev/null || true
cat > /etc/systemd/system/ssh.service.d/override.conf << 'EOF'
[Service]
TimeoutStartSec=10
TimeoutStopSec=5
EOF

echo "✅ Standard SSH service enabled"
echo ""
echo "=== DONE ==="
echo ""
echo "All redundant SSH services disabled"
echo "Only standard SSH service is running"
echo ""
