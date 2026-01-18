#!/bin/bash
# Generate complete client config for friend
# This ensures all settings are correct

SERVER_PUBLIC_KEY="NXvSV5Vuo715zIPtBKrSPaj3GLcUnbJ3d9UJbkZqdyU="
SERVER_ENDPOINT="223.206.210.138:51820"
CLIENT_VPN_IP="10.8.0.2/24"
CLIENT_PUBLIC_KEY="0hM5yODbCJqe8wH+Rau419/NFTlD1f7DE8+6UYixx0w="

echo "=========================================="
echo "   CLIENT CONFIGURATION FOR YOUR FRIEND"
echo "=========================================="
echo ""
echo "⚠️  IMPORTANT: Your friend needs to provide their PRIVATE KEY"
echo "   (The one that generates public key: $CLIENT_PUBLIC_KEY)"
echo ""
echo "=========================================="
echo "   COMPLETE CLIENT CONFIG"
echo "=========================================="
echo ""
cat << EOF
[Interface]
# Friend's PRIVATE KEY goes here (NOT the public key!)
# This must be the private key that generates: $CLIENT_PUBLIC_KEY
PrivateKey = YOUR_FRIEND_PRIVATE_KEY_HERE
Address = $CLIENT_VPN_IP

[Peer]
# Server public key (this is correct)
PublicKey = $SERVER_PUBLIC_KEY
# Server endpoint (this is correct)
Endpoint = $SERVER_ENDPOINT
# Only route traffic to server through VPN
AllowedIPs = 10.8.0.1/32
# Keep connection alive
PersistentKeepalive = 25
EOF
echo ""
echo "=========================================="
echo "   VERIFICATION CHECKLIST"
echo "=========================================="
echo ""
echo "For your friend to check:"
echo ""
echo "1. ✅ Server Public Key: $SERVER_PUBLIC_KEY"
echo "2. ✅ Server Endpoint: $SERVER_ENDPOINT"
echo "3. ✅ Client VPN IP: $CLIENT_VPN_IP"
echo "4. ⚠️  Client Private Key: Must match public key $CLIENT_PUBLIC_KEY"
echo ""
echo "=========================================="
echo "   TROUBLESHOOTING STEPS"
echo "=========================================="
echo ""
echo "If connection still doesn't work:"
echo ""
echo "1. Verify client's private key generates the correct public key:"
echo "   wg pubkey < private.key"
echo "   Should output: $CLIENT_PUBLIC_KEY"
echo ""
echo "2. Check WireGuard logs on client side for errors"
echo ""
echo "3. Verify router/firewall allows outbound UDP 51820"
echo ""
echo "4. Try connecting from different network (mobile hotspot)"
echo ""
echo "5. Check if client can reach server:"
echo "   ping 223.206.210.138"
echo "   nc -zv -u 223.206.210.138 51820"
echo ""
