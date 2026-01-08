#!/bin/bash
# Setup script for remote SSH access
# Run on Pi after moOde is installed

echo "=== REMOTE SSH SETUP ==="
echo ""

# 1. Check SSH status
echo "1. Checking SSH status..."
if systemctl is-active --quiet ssh; then
    echo "✅ SSH is running"
else
    echo "⚠️  SSH is not running"
    sudo systemctl enable ssh
    sudo systemctl start ssh
    echo "✅ SSH enabled and started"
fi

# 2. Show Pi information
echo ""
echo "2. Pi Information:"
echo "   Hostname: $(hostname)"
echo "   IP Address: $(hostname -I | awk '{print $1}')"
echo "   User: $(whoami)"
echo "   SSH Port: $(grep -E '^Port' /etc/ssh/sshd_config 2>/dev/null | awk '{print $2}' || echo '22 (default)')"

# 3. Show firewall status
echo ""
echo "3. Firewall Status:"
if command -v ufw &> /dev/null; then
    sudo ufw status
else
    echo "   UFW not installed"
fi

# 4. Show connection information
echo ""
echo "=== CONNECTION INFORMATION ==="
echo ""
echo "Local network access:"
echo "  ssh andre@$(hostname -I | awk '{print $1}')"
echo "  Password: 0815"
echo ""
echo "For remote access, choose one:"
echo "  - VPN (recommended - see docs/REMOTE_SSH_SETUP.md)"
echo "  - Port Forwarding (see docs/REMOTE_SSH_SETUP.md)"
echo "  - Dynamic DNS (see docs/REMOTE_SSH_SETUP.md)"
echo ""

# 5. Security recommendations
echo "=== SECURITY RECOMMENDATIONS ==="
echo ""
echo "1. Change default password:"
echo "   passwd"
echo ""
echo "2. Set up SSH keys (recommended):"
echo "   ssh-keygen -t ed25519"
echo ""
echo "3. Consider changing SSH port (optional)"
echo ""
echo "✅ Setup information displayed"
echo "✅ See docs/REMOTE_SSH_SETUP.md for detailed instructions"




