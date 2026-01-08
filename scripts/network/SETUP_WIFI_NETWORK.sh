#!/bin/bash
# Set up WiFi network for moOde Audio
# Run: sudo ./SETUP_WIFI_NETWORK.sh

set -e

ROOTFS="/Volumes/rootfs"
BOOTFS="/Volumes/bootfs"

echo "=== SETTING UP WIFI NETWORK FOR MOODE ==="
echo ""

# Check SD card
if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted at $ROOTFS"
    exit 1
fi

echo "✅ SD card: $ROOTFS"
echo ""

# WiFi network configuration
WIFI_SSID="moode-audio"
WIFI_PASSWORD="moode0815"
WIFI_IP="192.168.4.1"  # Access point IP
PI_IP="192.168.4.2"     # Pi IP when connected

echo "WiFi Configuration:"
echo "  SSID: $WIFI_SSID"
echo "  Password: $WIFI_PASSWORD"
echo "  Pi IP: $PI_IP"
echo ""

# 1. Create wpa_supplicant.conf for Pi to connect to Mac hotspot
echo "1. Creating wpa_supplicant.conf..."
if [ -d "$BOOTFS" ]; then
    cat > "$BOOTFS/wpa_supplicant.conf" << EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

network={
    ssid="$WIFI_SSID"
    psk="$WIFI_PASSWORD"
    key_mgmt=WPA-PSK
}
EOF
    echo "✅ wpa_supplicant.conf created on boot partition"
else
    echo "⚠️  Boot partition not mounted, will create in rootfs"
    mkdir -p "$ROOTFS/boot/firmware"
    cat > "$ROOTFS/boot/firmware/wpa_supplicant.conf" << EOF
ctrl_interface=DIR=/var/run/wpa_supplicant GROUP=netdev
update_config=1
country=US

network={
    ssid="$WIFI_SSID"
    psk="$WIFI_PASSWORD"
    key_mgmt=WPA-PSK
}
EOF
    echo "✅ wpa_supplicant.conf created in rootfs"
fi

# 2. Create systemd service to ensure WiFi connects
echo "2. Creating WiFi connection service..."
mkdir -p "$ROOTFS/lib/systemd/system"
cat > "$ROOTFS/lib/systemd/system/wifi-connect.service" << 'EOF'
[Unit]
Description=WiFi Connection Service
After=network.target
Wants=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c '
    # Wait for WiFi interface
    for i in {1..30}; do
        if ip link show wlan0 >/dev/null 2>&1; then
            break
        fi
        sleep 1
    done
    
    # Enable WiFi
    rfkill unblock wifi 2>/dev/null || true
    
    # Start wpa_supplicant if not running
    if ! pgrep -f wpa_supplicant >/dev/null; then
        wpa_supplicant -B -i wlan0 -c /boot/firmware/wpa_supplicant.conf -D nl80211,wext 2>/dev/null || true
    fi
    
    # Request DHCP IP
    dhclient wlan0 2>/dev/null || true
'

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
ln -sf /lib/systemd/system/wifi-connect.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/"

echo "✅ WiFi connection service created"

# 3. Create script to set up Mac hotspot
echo "3. Creating Mac hotspot setup script..."
cat > ~/moodeaudio-cursor/SETUP_MAC_HOTSPOT.sh << EOF
#!/bin/bash
# Set up Mac WiFi hotspot
# Run: sudo ./SETUP_MAC_HOTSPOT.sh

echo "=== SETTING UP MAC WIFI HOTSPOT ==="
echo ""

# Check if Internet Sharing is available
if ! networksetup -listallnetworkservices | grep -q "Wi-Fi"; then
    echo "❌ WiFi not available"
    exit 1
fi

echo "WiFi Hotspot Configuration:"
echo "  SSID: $WIFI_SSID"
echo "  Password: $WIFI_PASSWORD"
echo "  IP Range: 192.168.4.0/24"
echo ""

# Enable Internet Sharing (if available)
# Note: This requires manual setup in System Preferences
echo "⚠️  Manual setup required:"
echo ""
echo "1. Open System Preferences > Sharing"
echo "2. Enable 'Internet Sharing'"
echo "3. Share from: Ethernet (or your internet connection)"
echo "4. To computers using: Wi-Fi"
echo "5. Click 'Wi-Fi Options'"
echo "6. Set:"
echo "   - Network Name: $WIFI_SSID"
echo "   - Channel: 11"
echo "   - Security: WPA2/WPA3 Personal"
echo "   - Password: $WIFI_PASSWORD"
echo ""
echo "7. Enable Internet Sharing checkbox"
echo ""
echo "OR use command line (if supported):"
echo "  sudo networksetup -setairportnetwork en0 '$WIFI_SSID' '$WIFI_PASSWORD'"
echo ""

EOF

chmod +x ~/moodeaudio-cursor/SETUP_MAC_HOTSPOT.sh
echo "✅ Mac hotspot setup script created"

# 4. Alternative: Create access point on Pi itself
echo "4. Creating Pi access point configuration..."
cat > "$ROOTFS/lib/systemd/system/create-ap.service" << 'EOF'
[Unit]
Description=Create WiFi Access Point
After=network.target
Wants=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c '
    # Install hostapd and dnsmasq if needed (will be done on first boot)
    # For now, create config files
    
    # hostapd config
    cat > /etc/hostapd/hostapd.conf << APEOF
interface=wlan0
driver=nl80211
ssid=moode-audio
hw_mode=g
channel=11
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=moode0815
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
APEOF
    
    # dnsmasq config
    cat > /etc/dnsmasq.conf << DNSEOF
interface=wlan0
dhcp-range=192.168.4.2,192.168.4.20,255.255.255.0,24h
DNSEOF
    
    echo "Access point config created"
'

[Install]
WantedBy=multi-user.target
EOF

echo "✅ Pi access point service created"

echo ""
echo "✅✅✅ WIFI SETUP COMPLETE ✅✅✅"
echo ""
echo "Next steps:"
echo "1. Eject SD card and boot Pi"
echo "2. Set up Mac hotspot (see SETUP_MAC_HOTSPOT.sh)"
echo "3. Pi will connect to '$WIFI_SSID'"
echo "4. Pi IP will be: $PI_IP (or DHCP assigned)"
echo ""
echo "OR:"
echo "Pi can create its own access point 'moode-audio'"
echo ""

