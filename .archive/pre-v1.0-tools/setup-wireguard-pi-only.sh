#!/bin/bash
# Setup WireGuard server on Pi only
# Run this script on the Pi via SSH
# Works from any directory

set -e

echo "=== SETTING UP WIREGUARD SERVER ON PI ==="
echo ""

# 1. Install WireGuard
echo "1. Installing WireGuard..."
if command -v wg >/dev/null 2>&1; then
    echo "✅ WireGuard already installed"
    wg --version
else
    echo "Installing WireGuard..."
    sudo apt-get update -qq
    sudo apt-get install -y wireguard wireguard-tools
    echo "✅ WireGuard installed"
fi

# 2. Enable IP forwarding
echo ""
echo "2. Enabling IP forwarding..."
if ! grep -q "^net.ipv4.ip_forward=1" /etc/sysctl.conf; then
    echo "" | sudo tee -a /etc/sysctl.conf >/dev/null
    echo "# Enable IP forwarding for WireGuard" | sudo tee -a /etc/sysctl.conf >/dev/null
    echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf >/dev/null
    echo "✅ IP forwarding enabled"
else
    echo "✅ IP forwarding already enabled"
fi

# Apply immediately
sudo sysctl -p >/dev/null 2>&1 || true

# 3. Generate keys if they don't exist
echo ""
echo "3. Generating WireGuard keys..."
WG_DIR="/etc/wireguard"
sudo mkdir -p "$WG_DIR"

if [ ! -f "$WG_DIR/private.key" ]; then
    echo "Generating server private key..."
    sudo wg genkey | sudo tee "$WG_DIR/private.key" >/dev/null
    sudo chmod 600 "$WG_DIR/private.key"
    echo "✅ Private key generated"
else
    echo "✅ Private key already exists"
fi

if [ ! -f "$WG_DIR/public.key" ]; then
    echo "Generating server public key..."
    sudo cat "$WG_DIR/private.key" | sudo wg pubkey | sudo tee "$WG_DIR/public.key" >/dev/null
    echo "✅ Public key generated"
else
    echo "✅ Public key already exists"
fi

# 4. Create WireGuard config
echo ""
echo "4. Creating WireGuard configuration..."
SERVER_PRIVATE_KEY=$(sudo cat "$WG_DIR/private.key")
SERVER_PUBLIC_KEY=$(sudo cat "$WG_DIR/public.key")

# Use 10.8.0.1 for server (common WireGuard convention)
# Friend will get 10.8.0.2
cat << EOF | sudo tee "$WG_DIR/wg0.conf" >/dev/null
[Interface]
# Pi's private key
PrivateKey = $SERVER_PRIVATE_KEY

# Pi's IP in VPN network
Address = 10.8.0.1/24

# Listen on port 51820 (standard WireGuard port)
ListenPort = 51820

# Forward traffic
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

# Add peers here (friend's config will be added later)
# [Peer]
# PublicKey = FRIEND_PUBLIC_KEY_HERE
# AllowedIPs = 10.8.0.2/32
EOF

sudo chmod 600 "$WG_DIR/wg0.conf"
echo "✅ WireGuard config created"

# 5. Enable and start WireGuard
echo ""
echo "5. Starting WireGuard service..."
sudo systemctl enable wg-quick@wg0.service
sudo systemctl start wg-quick@wg0.service

if sudo systemctl is-active --quiet wg-quick@wg0.service; then
    echo "✅ WireGuard is running"
else
    echo "⚠️  WireGuard service started but may need peer config"
fi

# 6. Configure SSH to listen on WireGuard interface
echo ""
echo "6. Configuring SSH for WireGuard..."
if ! grep -q "^ListenAddress.*10.8.0.1" /etc/ssh/sshd_config; then
    echo "" | sudo tee -a /etc/ssh/sshd_config >/dev/null
    echo "# Listen on WireGuard interface" | sudo tee -a /etc/ssh/sshd_config >/dev/null
    echo "ListenAddress 10.8.0.1" | sudo tee -a /etc/ssh/sshd_config >/dev/null
    sudo systemctl restart sshd
    echo "✅ SSH configured to listen on WireGuard interface"
else
    echo "✅ SSH already configured for WireGuard"
fi

# 7. Show status
echo ""
echo "=== WIREGUARD SETUP COMPLETE ==="
echo ""
echo "Server Public Key (share with friend):"
echo "$SERVER_PUBLIC_KEY"
echo ""
echo "Server IP in VPN: 10.8.0.1"
echo "Server Port: 51820"
echo ""
echo "Current WireGuard status:"
sudo wg show
echo ""
echo "=== TO ADD FRIEND (run on Pi) ==="
echo ""
echo "1. Friend generates keys on their device:"
echo "   wg genkey | tee private.key | wg pubkey > public.key"
echo ""
echo "2. Friend gives you their public key"
echo ""
echo "3. Add friend to Pi config:"
echo "   sudo nano /etc/wireguard/wg0.conf"
echo ""
echo "   Add this section:"
echo "   [Peer]"
echo "   PublicKey = FRIEND_PUBLIC_KEY"
echo "   AllowedIPs = 10.8.0.2/32"
echo ""
echo "4. Restart WireGuard:"
echo "   sudo systemctl restart wg-quick@wg0"
echo ""
echo "5. Friend connects to: ssh andre@10.8.0.1"
echo ""
echo "=== FIREWALL NOTE ==="
echo "Make sure port 51820/UDP is open on your router/firewall"
echo ""
