#!/bin/bash
# Setup WireGuard for remote access
# Works from any directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Detect if running on Pi or SD card
if [ -d "/boot/firmware" ] || [ -d "/boot" ]; then
    ROOTFS="/"
    echo "=== SETTING UP WIREGUARD ON PI ==="
else
    if [ -d "/Volumes/rootfs" ]; then
        ROOTFS="/Volumes/rootfs"
        echo "=== SETTING UP WIREGUARD ON SD CARD ==="
    else
        echo "❌ Not on Pi and SD card not mounted"
        echo "   Mount SD card at /Volumes/rootfs or run on Pi"
        exit 1
    fi
fi

echo ""
echo "Root filesystem: $ROOTFS"
echo ""

# 1. Check if WireGuard is installed
echo "1. Checking WireGuard installation..."
if [ "$ROOTFS" = "/" ]; then
    if command -v wg >/dev/null 2>&1; then
        echo "✅ WireGuard is installed"
        wg --version
    else
        echo "⚠️  WireGuard not found, installing..."
        apt-get update -qq
        apt-get install -y wireguard wireguard-tools || echo "❌ Failed to install WireGuard"
    fi
else
    echo "  ⚠️  Will check/install on Pi after boot"
fi

# 2. Create WireGuard config directory
echo "2. Creating WireGuard config directory..."
mkdir -p "$ROOTFS/etc/wireguard" 2>/dev/null || true

# 3. Create example WireGuard config (user needs to customize)
echo "3. Creating WireGuard config template..."
cat > "$ROOTFS/etc/wireguard/wg0.conf.example" << 'EOF'
[Interface]
# Pi's private key (generate with: wg genkey)
PrivateKey = YOUR_PRIVATE_KEY_HERE

# Pi's IP address in VPN network
Address = 10.0.0.2/24

# Optional: Run commands when interface comes up
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

# Optional: Run commands when interface goes down
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
# Friend's public key (they generate this)
PublicKey = FRIEND_PUBLIC_KEY_HERE

# Friend's IP address in VPN network
AllowedIPs = 10.0.0.3/32

# Friend's endpoint (their public IP or domain)
Endpoint = friend.example.com:51820

# Keep connection alive
PersistentKeepalive = 25
EOF

# 4. Enable IP forwarding
echo "4. Enabling IP forwarding..."
if [ -f "$ROOTFS/etc/sysctl.conf" ]; then
    if ! grep -q "^net.ipv4.ip_forward=1" "$ROOTFS/etc/sysctl.conf"; then
        echo "" >> "$ROOTFS/etc/sysctl.conf"
        echo "# Enable IP forwarding for WireGuard" >> "$ROOTFS/etc/sysctl.conf"
        echo "net.ipv4.ip_forward=1" >> "$ROOTFS/etc/sysctl.conf"
        echo "✅ IP forwarding enabled in sysctl.conf"
    else
        echo "✅ IP forwarding already enabled"
    fi
fi

# 5. Enable WireGuard service
echo "5. Enabling WireGuard service..."
if [ "$ROOTFS" = "/" ]; then
    systemctl enable wg-quick@wg0.service 2>/dev/null || true
    echo "✅ WireGuard service enabled"
else
    echo "  ⚠️  Will enable on Pi after boot"
fi

# 6. Configure SSH to listen on WireGuard interface
echo "6. Configuring SSH for WireGuard..."
if [ -f "$ROOTFS/etc/ssh/sshd_config" ]; then
    # Add ListenAddress for WireGuard if not present
    if ! grep -q "^ListenAddress.*10.0.0" "$ROOTFS/etc/ssh/sshd_config"; then
        echo "" >> "$ROOTFS/etc/ssh/sshd_config"
        echo "# Listen on WireGuard interface" >> "$ROOTFS/etc/ssh/sshd_config"
        echo "ListenAddress 10.0.0.2" >> "$ROOTFS/etc/ssh/sshd_config"
        echo "✅ SSH configured to listen on WireGuard interface"
    else
        echo "✅ SSH already configured for WireGuard"
    fi
fi

echo ""
echo "✅ WireGuard setup complete"
echo ""
echo "NEXT STEPS (run on Pi after boot):"
echo ""
echo "1. Generate keys:"
echo "   wg genkey | tee /etc/wireguard/private.key | wg pubkey > /etc/wireguard/public.key"
echo ""
echo "2. Create config:"
echo "   cp /etc/wireguard/wg0.conf.example /etc/wireguard/wg0.conf"
echo "   nano /etc/wireguard/wg0.conf  # Edit with your keys and friend's info"
echo ""
echo "3. Start WireGuard:"
echo "   sudo systemctl start wg-quick@wg0"
echo "   sudo systemctl enable wg-quick@wg0"
echo ""
echo "4. Share your public key with friend:"
echo "   cat /etc/wireguard/public.key"
echo ""
echo "Friend connects to: ssh andre@10.0.0.2"
echo ""
