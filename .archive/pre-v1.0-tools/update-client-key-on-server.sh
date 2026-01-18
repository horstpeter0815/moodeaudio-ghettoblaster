#!/bin/bash
# Update client public key on server
# Usage: ./update-client-key-on-server.sh <CLIENT_ACTUAL_PUBLIC_KEY>

NEW_CLIENT_KEY="${1}"
PI_HOST="${2:-moodepi5.local}"
PI_USER="andre"
PI_PASS="${3:-0815}"

if [ -z "$NEW_CLIENT_KEY" ]; then
    echo "Usage: $0 <CLIENT_ACTUAL_PUBLIC_KEY> [PI_HOST] [PI_PASS]"
    echo ""
    echo "Example:"
    echo "  $0 '0hM5yODbCJqe8wH+Rau419/NFTID1f7DE8+6UYixx0w='"
    echo ""
    echo "Get the client's actual public key from their WireGuard GUI"
    exit 1
fi

echo "=========================================="
echo "   UPDATING CLIENT KEY ON SERVER"
echo "=========================================="
echo ""
echo "New client public key: $NEW_CLIENT_KEY"
echo ""

sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=accept-new "$PI_USER@$PI_HOST" << EOF
# Backup config
sudo cp /etc/wireguard/wg0.conf /etc/wireguard/wg0.conf.backup.\$(date +%Y%m%d_%H%M%S)

# Update client key in config
sudo sed -i "s/PublicKey = .*/PublicKey = $NEW_CLIENT_KEY/" /etc/wireguard/wg0.conf

echo "✅ Config updated"
echo ""
echo "Updated config:"
sudo grep -A 2 "\[Peer\]" /etc/wireguard/wg0.conf
echo ""

# Restart WireGuard
echo "Restarting WireGuard..."
sudo systemctl restart wg-quick@wg0.service
sleep 2

# Check status
echo "=== NEW STATUS ==="
sudo wg show wg0
echo ""

echo "✅ Done! Check if handshake appears now."
EOF

echo ""
echo "Update complete!"
