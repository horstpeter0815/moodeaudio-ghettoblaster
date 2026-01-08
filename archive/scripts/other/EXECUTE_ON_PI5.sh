#!/bin/bash
# Execute fix script on Pi 5 at 192.168.178.178
# This script will copy and execute MASTER_FIX_ALL.sh on the Pi 5

PI5_IP="192.168.178.178"
PI5_USER="${1:-pi}"

echo "=========================================="
echo "Connecting to Pi 5 at $PI5_USER@$PI5_IP"
echo "=========================================="
echo ""

# Check if script exists
if [ ! -f "MASTER_FIX_ALL.sh" ]; then
    echo "ERROR: MASTER_FIX_ALL.sh not found!"
    exit 1
fi

# Copy script to Pi 5
echo "Step 1: Copying MASTER_FIX_ALL.sh to Pi 5..."
scp -o StrictHostKeyChecking=no "MASTER_FIX_ALL.sh" "$PI5_USER@$PI5_IP:/tmp/MASTER_FIX_ALL.sh"

if [ $? -ne 0 ]; then
    echo ""
    echo "ERROR: Could not copy script. Trying with password..."
    echo "Please enter password for $PI5_USER@$PI5_IP when prompted:"
    scp "MASTER_FIX_ALL.sh" "$PI5_USER@$PI5_IP:/tmp/MASTER_FIX_ALL.sh"
fi

echo ""
echo "Step 2: Executing fix on Pi 5..."
echo "Please enter password for $PI5_USER@$PI5_IP when prompted:"
ssh -o StrictHostKeyChecking=no "$PI5_USER@$PI5_IP" "chmod +x /tmp/MASTER_FIX_ALL.sh && /tmp/MASTER_FIX_ALL.sh"

echo ""
echo "=========================================="
echo "Done! Check your Pi 5 display."
echo "=========================================="

