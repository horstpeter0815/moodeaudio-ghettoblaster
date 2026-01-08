#!/bin/bash

# CONNECT TO PI - FINAL VERSION
# Reads connection info and tries multiple methods

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INFO_FILE="$SCRIPT_DIR/PI_CONNECTION_INFO.txt"

# Read connection info
if [ -f "$INFO_FILE" ]; then
    source "$INFO_FILE"
else
    PI_HOSTNAME="ghettopi4.local"
    PI_USER="andre"
    PI_PASSWORD="0815"
fi

echo "=========================================="
echo "CONNECTING TO PI"
echo "=========================================="
echo "Hostname: $PI_HOSTNAME"
echo "User: $PI_USER"
echo ""

# Method 1: Try hostname directly
echo "Method 1: Trying $PI_HOSTNAME..."
if ping -c 1 -W 2 "$PI_HOSTNAME" &>/dev/null; then
    IP=$(ping -c 1 "$PI_HOSTNAME" | grep -oE '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
    echo "✓ Resolved to: $IP"
    
    if command -v sshpass &> /dev/null; then
        sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOSTNAME"
    else
        ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOSTNAME"
    fi
    exit 0
fi

# Method 2: Try IP directly if we can get it
echo ""
echo "Method 2: Scanning network for Pi..."
LOCAL_IP=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null || echo "")
if [ -n "$LOCAL_IP" ]; then
    NETWORK=$(echo "$LOCAL_IP" | cut -d. -f1-3)
    echo "Scanning ${NETWORK}.0/24..."
    
    for i in {1..254}; do
        IP="${NETWORK}.${i}"
        if ping -c 1 -W 0.5 "$IP" &>/dev/null; then
            # Try SSH
            if timeout 1 ssh -o ConnectTimeout=1 -o StrictHostKeyChecking=no "$PI_USER@$IP" "echo pi" &>/dev/null; then
                echo "✓ Found Pi at: $IP"
                if command -v sshpass &> /dev/null; then
                    sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$IP"
                else
                    ssh -o StrictHostKeyChecking=no "$PI_USER@$IP"
                fi
                exit 0
            fi
        fi
    done
fi

# Method 3: Ask for IP
echo ""
echo "❌ Could not find Pi automatically"
echo ""
echo "Please provide Pi IP address:"
read -p "IP: " PI_IP

if [ -n "$PI_IP" ]; then
    echo "Connecting to $PI_USER@$PI_IP..."
    if command -v sshpass &> /dev/null; then
        sshpass -p "$PI_PASSWORD" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP"
    else
        ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP"
    fi
else
    echo "No IP provided. Exiting."
    exit 1
fi

