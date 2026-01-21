#!/bin/bash
# Setup Mac Internet Sharing: iPhone (USB) → Mac → Ethernet → Pi

echo "========================================="
echo "MAC INTERNET SHARING SETUP"
echo "========================================="
echo ""
echo "STEP 1: Enable Internet Sharing on Mac"
echo "----------------------------------------"
echo ""
echo "1. Open System Settings (System Preferences)"
echo "2. Go to: General → Sharing (or just 'Sharing')"
echo "3. Click 'Internet Sharing' on the left"
echo "4. Set up:"
echo "   - Share your connection from: iPhone USB"
echo "   - To computers using: [✓] Thunderbolt Ethernet (or USB Ethernet)"
echo "5. Enable 'Internet Sharing' (turn it ON)"
echo "6. Confirm when prompted"
echo ""
echo "Your Mac will create a network on: 192.168.2.x"
echo "(Mac will be 192.168.2.1, Pi will get 192.168.2.x via DHCP)"
echo ""
read -p "Have you enabled Internet Sharing on Mac? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Please enable it first, then run this script again."
    exit 1
fi

echo ""
echo "========================================="
echo "STEP 2: Find Mac Ethernet IP Address"
echo "========================================="
echo ""
echo "Checking Mac's Ethernet interface..."
echo ""

# Find the Ethernet interface and its IP
ETHERNET_IP=$(ifconfig | grep -A 3 "en.*:.*<.*UP.*>" | grep "inet " | grep "192.168.2" | awk '{print $2}' | head -1)

if [ -z "$ETHERNET_IP" ]; then
    echo "⚠️  Could not find Ethernet IP in 192.168.2.x range"
    echo ""
    echo "Please check manually:"
    echo "  ifconfig | grep -A 3 'en.*:' | grep 'inet '"
    echo ""
    echo "Your Ethernet interface should show: 192.168.2.1"
    exit 1
fi

echo "✅ Mac Ethernet IP: $ETHERNET_IP"
echo ""

if [ "$ETHERNET_IP" != "192.168.2.1" ]; then
    echo "⚠️  Warning: Expected 192.168.2.1, got $ETHERNET_IP"
    echo "This might still work, but verify Pi connectivity."
fi

echo ""
echo "========================================="
echo "STEP 3: Connect to Pi and Configure"
echo "========================================="
echo ""

# Try to find Pi on the network
echo "Scanning for Pi on network..."
for ip in 192.168.2.{2..20}; do
    if ping -c 1 -W 1 $ip &> /dev/null; then
        echo "Found device at: $ip"
        # Try to SSH
        if sshpass -p "0815" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 andre@$ip "hostname" 2>/dev/null | grep -q "moode"; then
            PI_IP=$ip
            echo "✅ Found Pi at: $PI_IP"
            break
        fi
    fi
done

if [ -z "$PI_IP" ]; then
    echo "❌ Could not find Pi on network"
    echo ""
    echo "Manual steps:"
    echo "1. Connect Pi to Mac via Ethernet cable"
    echo "2. Wait 30 seconds for DHCP"
    echo "3. Check Mac's DHCP clients:"
    echo "   cat /var/db/dhcpd_leases"
    echo ""
    exit 1
fi

echo ""
echo "Configuring Pi network settings..."

sshpass -p "0815" ssh -o StrictHostKeyChecking=no andre@$PI_IP << 'ENDSSH'
echo "=== Pi Network Configuration ==="
echo ""
echo "Current network:"
ip -4 addr show eth0 | grep inet
echo ""

# Set static IP (optional, for stability)
read -p "Set static IP 192.168.2.10? (recommended) (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    sudo nmcli con mod "Wired connection 1" ipv4.addresses 192.168.2.10/24
    sudo nmcli con mod "Wired connection 1" ipv4.gateway 192.168.2.1
    sudo nmcli con mod "Wired connection 1" ipv4.dns "8.8.8.8,8.8.4.4"
    sudo nmcli con mod "Wired connection 1" ipv4.method manual
    sudo nmcli con up "Wired connection 1"
    echo "✅ Static IP set to 192.168.2.10"
else
    echo "Keeping DHCP"
fi

echo ""
echo "=== Testing Connectivity ==="
ping -c 2 8.8.8.8 && echo "✅ Internet works!" || echo "❌ No internet"
echo ""
echo "=== Restarting AirPlay ==="
sudo systemctl restart shairport-sync
echo "✅ AirPlay restarted"
ENDSSH

echo ""
echo "========================================="
echo "✅ SETUP COMPLETE"
echo "========================================="
echo ""
echo "Network Configuration:"
echo "  Mac (Ethernet):  192.168.2.1"
echo "  Pi (Ethernet):   $PI_IP (or 192.168.2.10 if static)"
echo ""
echo "AirPlay Device: 'Moode AirPlay'"
echo ""
echo "Test from your iPhone:"
echo "1. iPhone should be on same network (via Mac USB)"
echo "2. Open Music/Spotify app"
echo "3. Look for 'Moode AirPlay' in AirPlay devices"
echo "4. Connect and play!"
echo ""
