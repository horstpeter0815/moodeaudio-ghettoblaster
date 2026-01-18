#!/bin/bash
# Run WireGuard diagnostic via SSH
# Usage: ./run-wg-diagnostic-ssh.sh [PI_HOST]

PI_HOST="${1:-moodepi5.local}"
PI_USER="andre"

echo "Connecting to $PI_USER@$PI_HOST..."
echo "Running WireGuard diagnostic..."
echo ""

ssh "$PI_USER@$PI_HOST" 'bash -s' << 'DIAGNOSTIC_SCRIPT'
echo "=========================================="
echo "   WIREGUARD HANDSHAKE DIAGNOSTIC"
echo "=========================================="
echo ""

PEER_KEY="0hM5yODbCJqe8wH+Rau419/NFTlD1f7DE8+6UYixx0w="

# Check if peer is in config file
echo "--- Step 1: Check Config File ---"
if [ -f "/etc/wireguard/wg0.conf" ]; then
    echo "✅ Config file exists"
    if sudo grep -q "$PEER_KEY" /etc/wireguard/wg0.conf; then
        echo "✅ Peer found in config"
        echo "Peer section:"
        sudo grep -A 3 "$PEER_KEY" /etc/wireguard/wg0.conf
    else
        echo "❌ Peer NOT in config file!"
        echo ""
        echo "Current config file contents:"
        sudo cat /etc/wireguard/wg0.conf
    fi
else
    echo "❌ Config file NOT found at /etc/wireguard/wg0.conf"
    echo "   This may be why there's no handshake!"
    echo ""
    echo "Checking if WireGuard is using runtime config only..."
    sudo wg show wg0
fi
echo ""

# Check port listening
echo "--- Step 2: Check Server Port ---"
echo "Checking if port 51820 is listening:"
if command -v ss >/dev/null 2>&1; then
    sudo ss -ulnp | grep 51820 || echo "⚠️  Port 51820 not found in listening ports"
else
    sudo netstat -ulnp 2>/dev/null | grep 51820 || echo "⚠️  Port 51820 not found"
fi
echo ""

# Check logs
echo "--- Step 3: Check WireGuard Logs ---"
echo "Recent logs (last 30 lines):"
sudo journalctl -u wg-quick@wg0 -n 30 --no-pager 2>/dev/null | tail -20 || echo "Could not read logs"
echo ""

# Try to set keepalive
echo "--- Step 4: Set Persistent Keepalive ---"
if sudo wg show wg0 | grep -q "$PEER_KEY"; then
    sudo wg set wg0 peer "$PEER_KEY" persistent-keepalive 25
    echo "✅ Set persistent-keepalive to 25 seconds"
else
    echo "⚠️  Peer not found in runtime config, cannot set keepalive"
fi
echo ""

# Show current status
echo "--- Step 5: Current Status ---"
sudo wg show wg0
echo ""

# Check ICMP rules
echo "--- Step 6: Check ICMP Rules ---"
echo "INPUT chain policy:"
sudo iptables -L INPUT -n | head -2
echo ""
echo "Rules for wg0 interface:"
sudo iptables -L INPUT -n -v | grep wg0 || echo "No wg0-specific rules (using default ACCEPT policy)"
echo ""
echo "ICMP-related rules:"
sudo iptables -L INPUT -n -v | grep -i "icmp" || echo "No explicit ICMP rules (default should allow)"
echo ""

# Test ping from server
echo "--- Step 7: Test Server → Client Ping ---"
if ping -c 2 -W 2 10.8.0.2 >/dev/null 2>&1; then
    echo "✅ Server CAN ping client (10.8.0.2)"
else
    echo "❌ Server CANNOT ping client (10.8.0.2)"
    echo "   This is expected if no handshake has occurred"
fi
echo ""

echo "=========================================="
echo "   SUMMARY"
echo "=========================================="
echo ""
echo "Key findings:"
echo "1. Check if config file exists and contains peer"
echo "2. Check if port 51820 is listening"
echo "3. Check logs for connection attempts"
echo "4. Verify handshake appears after setting keepalive"
echo ""
DIAGNOSTIC_SCRIPT

echo ""
echo "Diagnostic complete!"
