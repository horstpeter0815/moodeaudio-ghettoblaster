#!/bin/bash
# Execute fix script on Pi 5 with password authentication
# Usage: ./EXECUTE_WITH_PASSWORD.sh [username] [password]

PI5_IP="192.168.178.178"
PI5_USER="${1:-pi}"
PI5_PASS="${2}"

if [ -z "$PI5_PASS" ]; then
    echo "Usage: $0 [username] [password]"
    echo "Example: $0 pi mypassword"
    exit 1
fi

echo "=========================================="
echo "Connecting to Pi 5 at $PI5_USER@$PI5_IP"
echo "=========================================="

# Check if sshpass is available
if ! command -v sshpass &> /dev/null; then
    echo "ERROR: sshpass not installed"
    echo "Install with: brew install hudochenkov/sshpass/sshpass"
    exit 1
fi

# Copy script
echo "Copying MASTER_FIX_ALL.sh to Pi 5..."
sshpass -p "$PI5_PASS" scp -o StrictHostKeyChecking=no "MASTER_FIX_ALL.sh" "$PI5_USER@$PI5_IP:/tmp/MASTER_FIX_ALL.sh"

# Execute script
echo "Executing fix on Pi 5..."
sshpass -p "$PI5_PASS" ssh -o StrictHostKeyChecking=no "$PI5_USER@$PI5_IP" "chmod +x /tmp/MASTER_FIX_ALL.sh && /tmp/MASTER_FIX_ALL.sh"

echo ""
echo "=========================================="
echo "Done! Check your Pi 5 display."
echo "=========================================="

