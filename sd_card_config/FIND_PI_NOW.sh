#!/bin/bash

# FIND PI - Multiple Methods
# Tries different ways to find the Pi

echo "=========================================="
echo "SEARCHING FOR PI 5"
echo "=========================================="
echo ""

PI_IP=""
PI_USER=""

# Method 1: Try common hostnames
echo "Method 1: Trying common hostnames..."
for hostname in raspberrypi.local moode.local moodeaudio.local pi5.local; do
    if ping -c 1 -W 1 "$hostname" &>/dev/null; then
        PI_IP=$(ping -c 1 "$hostname" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
        echo "✓ Found at: $hostname ($PI_IP)"
        
        # Try SSH
        for user in moode pi root; do
            if ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no "$user@$hostname" "echo connected" &>/dev/null; then
                PI_USER="$user"
                echo "✓ SSH works as $user"
                break 2
            fi
        done
    fi
done

# Method 2: Scan local network
if [ -z "$PI_IP" ]; then
    echo ""
    echo "Method 2: Scanning local network..."
    
    # Get local network
    LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "")
    if [ -n "$LOCAL_IP" ]; then
        NETWORK=$(echo "$LOCAL_IP" | cut -d. -f1-3)
        echo "Scanning network: ${NETWORK}.0/24"
        
        # Quick scan of common IPs (1-50 and 100-150)
        for range in {1..50} {100..150}; do
            IP="${NETWORK}.${range}"
            if ping -c 1 -W 0.3 "$IP" &>/dev/null; then
                # Try SSH to see if it's the Pi
                for user in moode pi root; do
                    if timeout 1 ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no "$user@$IP" "uname -a | grep -q raspberry; echo \$?" &>/dev/null; then
                        RESULT=$(timeout 1 ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no "$user@$IP" "uname -a | grep -q raspberry; echo \$?" 2>/dev/null)
                        if [ "$RESULT" = "0" ]; then
                            PI_IP="$IP"
                            PI_USER="$user"
                            echo "✓ Found Pi at: $IP (user: $user)"
                            break 2
                        fi
                    fi
                done
            fi
        done
    fi
fi

# Method 3: Check ARP table for Raspberry Pi MAC addresses
if [ -z "$PI_IP" ]; then
    echo ""
    echo "Method 3: Checking ARP table for Raspberry Pi MAC addresses..."
    # Raspberry Pi MAC addresses typically start with: b8:27:eb, dc:a6:32, e4:5f:01
    arp -a | grep -iE "b8:27:eb|dc:a6:32|e4:5f:01" | while read line; do
        IP=$(echo "$line" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}')
        if [ -n "$IP" ]; then
            echo "Found potential Pi MAC at: $IP"
            for user in moode pi root; do
                if timeout 1 ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no "$user@$IP" "echo pi" &>/dev/null; then
                    PI_IP="$IP"
                    PI_USER="$user"
                    echo "✓ Confirmed Pi at: $IP (user: $user)"
                    break 2
                fi
            done
        fi
    done
fi

# Method 4: Ask user
if [ -z "$PI_IP" ]; then
    echo ""
    echo "❌ Could not find Pi automatically"
    echo ""
    echo "Please provide Pi IP address or hostname:"
    read -p "Pi address: " PI_INPUT
    
    if [ -n "$PI_INPUT" ]; then
        PI_IP="$PI_INPUT"
        # Try to determine user
        for user in moode pi root; do
            if ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no "$user@$PI_INPUT" "echo connected" &>/dev/null; then
                PI_USER="$user"
                break
            fi
        done
    fi
fi

# Connect if found
if [ -n "$PI_IP" ] && [ -n "$PI_USER" ]; then
    echo ""
    echo "=========================================="
    echo "CONNECTING TO PI"
    echo "=========================================="
    echo "IP: $PI_IP"
    echo "User: $PI_USER"
    echo ""
    ssh "$PI_USER@$PI_IP"
elif [ -n "$PI_IP" ]; then
    echo ""
    echo "Found Pi at $PI_IP but could not determine user"
    echo "Try manually: ssh moode@$PI_IP or ssh pi@$PI_IP"
else
    echo ""
    echo "❌ Could not find Pi"
    echo ""
    echo "Please check:"
    echo "  1. Pi is powered on"
    echo "  2. Pi is on the same network"
    echo "  3. SSH is enabled"
    echo ""
    echo "Or provide IP manually:"
    echo "  ssh moode@<PI_IP>"
    echo "  ssh pi@<PI_IP>"
fi

