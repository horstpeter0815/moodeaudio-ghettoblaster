#!/bin/bash
# One-liner WireGuard status check - copy this entire script and run it on the Pi
# Or run directly: ssh andre@moodepi5.local 'bash -s' < tools/wireguard-status-oneliner.sh

echo "=========================================="
echo "   WIREGUARD VPN STATUS CHECK"
echo "=========================================="
echo ""

# Check if WireGuard is installed
if ! command -v wg >/dev/null 2>&1; then
    echo "❌ WireGuard is NOT installed"
    echo "   Install with: sudo apt-get install wireguard wireguard-tools"
    exit 1
fi

echo "✅ WireGuard is installed"
echo ""

# Check service status
echo "--- Service Status ---"
if systemctl is-active --quiet wg-quick@wg0.service 2>/dev/null; then
    echo "✅ WireGuard service is RUNNING"
else
    echo "❌ WireGuard service is NOT running"
    echo "   Start with: sudo systemctl start wg-quick@wg0"
fi

if systemctl is-enabled --quiet wg-quick@wg0.service 2>/dev/null; then
    echo "✅ WireGuard service is ENABLED (will start on boot)"
else
    echo "⚠️  WireGuard service is NOT enabled (won't start on boot)"
    echo "   Enable with: sudo systemctl enable wg-quick@wg0"
fi
echo ""

# Check interface status
echo "--- Interface Status ---"
if sudo wg show wg0 >/dev/null 2>&1; then
    echo "✅ WireGuard interface 'wg0' is active"
    echo ""
    echo "Active connections:"
    sudo wg show wg0
else
    echo "❌ WireGuard interface 'wg0' is NOT active"
    echo "   No peers connected or interface not started"
fi
echo ""

# Check configuration file
echo "--- Configuration ---"
if [ -f "/etc/wireguard/wg0.conf" ]; then
    echo "✅ Configuration file exists: /etc/wireguard/wg0.conf"
    PEER_COUNT=$(grep -c "^\[Peer\]" /etc/wireguard/wg0.conf 2>/dev/null || echo "0")
    echo "   Configured peers: $PEER_COUNT"
else
    echo "❌ Configuration file NOT found: /etc/wireguard/wg0.conf"
fi
echo ""

# Check IP forwarding
echo "--- Network Settings ---"
if [ "$(cat /proc/sys/net/ipv4/ip_forward 2>/dev/null)" = "1" ]; then
    echo "✅ IP forwarding is ENABLED"
else
    echo "❌ IP forwarding is DISABLED"
    echo "   Enable with: echo 'net.ipv4.ip_forward=1' | sudo tee -a /etc/sysctl.conf"
fi
echo ""

# Check firewall/port
echo "--- Port Status ---"
if command -v ufw >/dev/null 2>&1; then
    if sudo ufw status | grep -q "51820"; then
        echo "✅ Port 51820 appears in firewall rules"
    else
        echo "⚠️  Port 51820 not found in UFW rules"
        echo "   Allow with: sudo ufw allow 51820/udp"
    fi
else
    echo "ℹ️  UFW not installed (check iptables manually if needed)"
fi
echo ""

echo "=========================================="
echo "   STATUS CHECK COMPLETE"
echo "=========================================="
