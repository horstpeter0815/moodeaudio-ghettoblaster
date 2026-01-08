#!/bin/bash
# Execute MASTER_FIX_ALL.sh on Pi 5 via SSH
# Usage: ./EXECUTE_REMOTELY.sh [PI5_IP] [USER]

PI5_IP="${1:-192.168.178.20}"
PI5_USER="${2:-pi}"

echo "Connecting to Pi 5 at $PI5_USER@$PI5_IP..."
echo ""

# Copy master fix script to Pi 5
echo "Copying MASTER_FIX_ALL.sh to Pi 5..."
scp "MASTER_FIX_ALL.sh" "$PI5_USER@$PI5_IP:/tmp/MASTER_FIX_ALL.sh"

# Execute on Pi 5
echo "Executing fix on Pi 5..."
ssh "$PI5_USER@$PI5_IP" "chmod +x /tmp/MASTER_FIX_ALL.sh && /tmp/MASTER_FIX_ALL.sh"

echo ""
echo "Done! Check your Pi 5 display."

