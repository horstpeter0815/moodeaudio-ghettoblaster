#!/bin/bash

# AUTO CONNECT TO PI AFTER BOOT
# Waits for Pi to boot and connects automatically

echo "=========================================="
echo "WAITING FOR PI TO BOOT AND CONNECTING"
echo "=========================================="
echo ""

PI_HOSTNAME="moode.local"
PI_IP=""
MAX_WAIT=120  # 2 minutes
WAIT_TIME=0

echo "Waiting for Pi to boot..."
echo "Checking: $PI_HOSTNAME"
echo ""

while [ $WAIT_TIME -lt $MAX_WAIT ]; do
    # Try to ping
    if ping -c 1 -W 1 "$PI_HOSTNAME" &>/dev/null; then
        PI_IP=$(ping -c 1 "$PI_HOSTNAME" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
        echo "✓ Pi is online at $PI_HOSTNAME ($PI_IP)"
        
        # Try SSH connection
        for user in moode pi; do
            if ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no "$user@$PI_HOSTNAME" "echo connected" &>/dev/null; then
                echo "✓ SSH connection successful as $user"
                echo ""
                echo "=========================================="
                echo "CONNECTING TO PI..."
                echo "=========================================="
                echo ""
                ssh "$user@$PI_HOSTNAME"
                exit 0
            fi
        done
        
        echo "Pi is online but SSH not ready yet, waiting..."
    fi
    
    sleep 2
    WAIT_TIME=$((WAIT_TIME + 2))
    echo -n "."
done

echo ""
echo "❌ Pi did not come online within $MAX_WAIT seconds"
echo ""
echo "Manual connection:"
echo "  ssh moode@moode.local"
echo "  ssh pi@raspberrypi.local"
echo ""

