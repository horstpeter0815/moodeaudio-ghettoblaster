#!/bin/bash
# Add a WireGuard peer (friend) to the server
# Usage: ./add-wireguard-peer.sh <friend-public-key> [friend-ip]

set -e

FRIEND_PUBLIC_KEY="${1}"
FRIEND_IP="${2:-10.8.0.2}"

if [ -z "$FRIEND_PUBLIC_KEY" ]; then
    echo "Usage: $0 <friend-public-key> [friend-ip]"
    echo ""
    echo "Example:"
    echo "  $0 abc123def456... 10.8.0.2"
    echo ""
    echo "To get friend's public key, have them run:"
    echo "  wg genkey | tee private.key | wg pubkey > public.key"
    echo "  cat public.key"
    exit 1
fi

WG_CONFIG="/etc/wireguard/wg0.conf"
SERVER_PUBLIC_KEY=$(sudo cat /etc/wireguard/public.key 2>/dev/null || echo "")

if [ -z "$SERVER_PUBLIC_KEY" ]; then
    echo "❌ Server public key not found. Is WireGuard set up?"
    exit 1
fi

echo "=== ADDING WIREGUARD PEER ==="
echo ""
echo "Friend's Public Key: $FRIEND_PUBLIC_KEY"
echo "Friend's IP: $FRIEND_IP/32"
echo ""

# Backup config
sudo cp "$WG_CONFIG" "${WG_CONFIG}.backup.$(date +%Y%m%d_%H%M%S)"

# Add peer to config
echo "" | sudo tee -a "$WG_CONFIG" >/dev/null
echo "# Peer added $(date)" | sudo tee -a "$WG_CONFIG" >/dev/null
echo "[Peer]" | sudo tee -a "$WG_CONFIG" >/dev/null
echo "PublicKey = $FRIEND_PUBLIC_KEY" | sudo tee -a "$WG_CONFIG" >/dev/null
echo "AllowedIPs = $FRIEND_IP/32" | sudo tee -a "$WG_CONFIG" >/dev/null
echo "" | sudo tee -a "$WG_CONFIG" >/dev/null

echo "✅ Peer added to configuration"
echo ""

# Restart WireGuard
echo "Restarting WireGuard..."
sudo systemctl restart wg-quick@wg0.service
sleep 2

if sudo systemctl is-active --quiet wg-quick@wg0.service; then
    echo "✅ WireGuard restarted successfully"
else
    echo "⚠️  WireGuard restart had issues. Check status:"
    sudo systemctl status wg-quick@wg0.service --no-pager | head -10
fi

echo ""
echo "=== FRIEND'S CLIENT CONFIGURATION ==="
echo ""
echo "Share this configuration with your friend:"
echo ""
echo "--- START CONFIG ---"
cat << EOF
[Interface]
PrivateKey = FRIEND_PRIVATE_KEY_HERE
Address = $FRIEND_IP/24

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = YOUR_SERVER_PUBLIC_IP:51820
AllowedIPs = 10.8.0.1/32
PersistentKeepalive = 25
EOF
echo "--- END CONFIG ---"
echo ""
echo "⚠️  IMPORTANT: Friend must replace:"
echo "   1. FRIEND_PRIVATE_KEY_HERE with their private key"
echo "   2. YOUR_SERVER_PUBLIC_IP with the server's public IP address"
echo ""
echo "Current WireGuard status:"
sudo wg show
echo ""
