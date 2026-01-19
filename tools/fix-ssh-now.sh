#!/bin/bash
# FIX SSH TO PI - PERMANENT SOLUTION
# Run this on your Mac

PI_IP="192.168.2.1"
PI_USER="andre"

echo "=== FIXING SSH CONNECTION ==="
echo ""

# Step 1: Remove old host keys
echo "1. Cleaning old host keys..."
ssh-keygen -R $PI_IP 2>/dev/null
ssh-keygen -R pi4.local 2>/dev/null

# Step 2: Create/use simple SSH key
echo "2. Setting up SSH key..."
if [ ! -f ~/.ssh/id_rsa ]; then
    ssh-keygen -t rsa -b 2048 -f ~/.ssh/id_rsa -N ""
fi

# Step 3: Copy key to Pi (will ask for password ONCE)
echo "3. Copying SSH key to Pi..."
echo "   Enter password when prompted (should be: 0815)"
ssh-copy-id -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null ${PI_USER}@${PI_IP}

# Step 4: Test connection
echo ""
echo "4. Testing SSH connection..."
if ssh -o StrictHostKeyChecking=no ${PI_USER}@${PI_IP} "echo 'SSH WORKS!'"; then
    echo ""
    echo "✅ SSH FIXED! You can now use: ssh andre@192.168.2.1"
else
    echo ""
    echo "❌ Still failing. Run this on your Pi:"
    echo "   sudo sed -i 's/PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config"
    echo "   sudo systemctl restart ssh"
    echo "   Then run this script again."
fi
