#!/bin/bash
# Create WireGuard client configuration file
# Usage: ./create-wireguard-client-config.sh <client-private-key>

set -e

CLIENT_PRIVATE_KEY="${1}"

if [ -z "$CLIENT_PRIVATE_KEY" ]; then
    echo "Usage: $0 <client-private-key>"
    echo ""
    echo "This script creates a WireGuard client configuration file."
    echo ""
    echo "Example:"
    echo "  $0 YOUR_PRIVATE_KEY_HERE"
    echo ""
    echo "The configuration will be saved as: moode-pi-client.conf"
    exit 1
fi

CONFIG_FILE="moode-pi-client.conf"

# Server information
SERVER_PUBLIC_KEY="MzNJlu8jKJefsADZhgr3wzEHcilx6iHE6nbjucE2VXQ="
SERVER_PUBLIC_IP="223.206.210.138"
SERVER_PORT="51820"
CLIENT_IP="10.8.0.2"

echo "Creating WireGuard client configuration..."
echo ""

cat > "$CONFIG_FILE" << EOF
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = $CLIENT_IP/24

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_PUBLIC_IP:$SERVER_PORT
AllowedIPs = 10.8.0.1/32
PersistentKeepalive = 25
EOF

echo "✅ Configuration file created: $CONFIG_FILE"
echo ""
echo "To use this configuration:"
echo "  1. Open WireGuard application on your Mac"
echo "  2. Click '+' → 'Import from file'"
echo "  3. Select: $CONFIG_FILE"
echo "  4. Click 'Save'"
echo "  5. Toggle the switch to connect"
echo ""
echo "Or copy to WireGuard directory:"
echo "  sudo cp $CONFIG_FILE /usr/local/etc/wireguard/moode-pi.conf"
echo ""
