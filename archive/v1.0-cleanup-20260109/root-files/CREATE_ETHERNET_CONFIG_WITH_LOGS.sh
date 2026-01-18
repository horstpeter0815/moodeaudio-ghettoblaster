#!/bin/bash
# Create Ethernet config and add logging
# Run: cd ~/moodeaudio-cursor && sudo ./CREATE_ETHERNET_CONFIG_WITH_LOGS.sh

ROOTFS="/Volumes/rootfs"
LOG_PATH="/Users/andrevollmer/moodeaudio-cursor/.cursor/debug.log"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted"
    exit 1
fi

echo "=== Creating Ethernet Config ==="

# Create Ethernet.nmconnection
UUID=$(uuidgen)
sudo mkdir -p "$ROOTFS/etc/NetworkManager/system-connections"
sudo tee "$ROOTFS/etc/NetworkManager/system-connections/Ethernet.nmconnection" > /dev/null << EOF
[connection]
id=Ethernet
uuid=${UUID}
type=ethernet
interface-name=eth0
autoconnect=true

[ethernet]

[ipv4]
method=manual
addresses=192.168.10.2/24
gateway=192.168.10.1
dns=8.8.8.8;8.8.4.4;

[ipv6]
method=disabled
EOF

sudo chmod 600 "$ROOTFS/etc/NetworkManager/system-connections/Ethernet.nmconnection"
echo "✅ Ethernet config created"

# Add logging to network-mode-ethernet-static.service
echo "=== Adding logs to network service ==="
SERVICE_FILE="$ROOTFS/lib/systemd/system/network-mode-ethernet-static.service"

if [ -f "$SERVICE_FILE" ]; then
    # Backup original
    sudo cp "$SERVICE_FILE" "${SERVICE_FILE}.bak"
    
    # Add logging
    sudo sed -i '' 's|echo "🔧 Configuring Ethernet|echo "🔧 Configuring Ethernet|' "$SERVICE_FILE"
    sudo sed -i '' 's|ip link set eth0 up|ip link set eth0 up; echo "{\\\"id\\\":\\\"log_$(date +%s)_1\\\",\\\"timestamp\\\":$(date +%s000),\\\"location\\\":\\\"network-mode-ethernet-static.service:18\\\",\\\"message\\\":\\\"eth0 interface brought up\\\",\\\"data\\\":{\\\"interface\\\":\\\"eth0\\\"},\\\"sessionId\\\":\\\"debug-session\\\",\\\"runId\\\":\\\"run1\\\",\\\"hypothesisId\\\":\\\"C\\\"}" >> /tmp/network-debug.log|' "$SERVICE_FILE"
    sudo sed -i '' 's|ip addr add 192.168.10.2/24 dev eth0|ip addr add 192.168.10.2/24 dev eth0; echo "{\\\"id\\\":\\\"log_$(date +%s)_2\\\",\\\"timestamp\\\":$(date +%s000),\\\"location\\\":\\\"network-mode-ethernet-static.service:22\\\",\\\"message\\\":\\\"Static IP configured\\\",\\\"data\\\":{\\\"ip\\\":\\\"192.168.10.2\\\",\\\"gateway\\\":\\\"192.168.10.1\\\"},\\\"sessionId\\\":\\\"debug-session\\\",\\\"runId\\\":\\\"run1\\\",\\\"hypothesisId\\\":\\\"A\\\"}" >> /tmp/network-debug.log|' "$SERVICE_FILE"
    
    echo "✅ Logging added to network service"
else
    echo "⚠️ Service file not found, creating..."
fi

echo ""
echo "✅✅✅ Config created with logging ✅✅✅"

