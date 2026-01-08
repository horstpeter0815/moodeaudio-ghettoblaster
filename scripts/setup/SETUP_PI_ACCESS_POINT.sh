#!/bin/bash
# Set up Pi to create its own WiFi access point (no Mac hotspot needed)
# Run: sudo ./SETUP_PI_ACCESS_POINT.sh

ROOTFS="/Volumes/rootfs"
BOOTFS="/Volumes/bootfs"

echo "=== SETTING UP PI AS WIFI ACCESS POINT ==="
echo ""
echo "This makes Pi create its own WiFi network"
echo "No Mac hotspot needed!"
echo ""

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted"
    exit 1
fi

echo "✅ SD card: $ROOTFS"
echo ""

# Access point configuration
AP_SSID="moode-audio"
AP_PASSWORD="moode0815"
AP_IP="192.168.4.1"
AP_RANGE="192.168.4.2,192.168.4.20"

echo "Access Point Configuration:"
echo "  SSID: $AP_SSID"
echo "  Password: $AP_PASSWORD"
echo "  Pi IP: $AP_IP"
echo "  Client IP Range: $AP_RANGE"
echo ""

# 1. Create hostapd configuration
echo "1. Creating hostapd configuration..."
mkdir -p "$ROOTFS/etc/hostapd"
cat > "$ROOTFS/etc/hostapd/hostapd.conf" << EOF
interface=wlan0
driver=nl80211
ssid=$AP_SSID
hw_mode=g
channel=11
wmm_enabled=0
macaddr_acl=0
auth_algs=1
ignore_broadcast_ssid=0
wpa=2
wpa_passphrase=$AP_PASSWORD
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
EOF
echo "✅ hostapd.conf created"

# 2. Create dnsmasq configuration
echo "2. Creating dnsmasq configuration..."
cat > "$ROOTFS/etc/dnsmasq.conf" << EOF
interface=wlan0
dhcp-range=$AP_RANGE,255.255.255.0,24h
dhcp-option=3,$AP_IP
dhcp-option=6,$AP_IP
server=8.8.8.8
server=8.8.4.4
EOF
echo "✅ dnsmasq.conf created"

# 3. Configure static IP for wlan0
echo "3. Creating network configuration..."
mkdir -p "$ROOTFS/etc/systemd/network"
cat > "$ROOTFS/etc/systemd/network/10-wlan0-ap.network" << EOF
[Match]
Name=wlan0

[Network]
Address=$AP_IP/24
DHCPServer=yes
EOF
echo "✅ Network config created"

# 4. Create access point service
echo "4. Creating access point service..."
mkdir -p "$ROOTFS/lib/systemd/system"
cat > "$ROOTFS/lib/systemd/system/create-ap.service" << 'EOF'
[Unit]
Description=Create WiFi Access Point
After=network.target
Wants=network.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c '
    # Enable WiFi
    rfkill unblock wifi 2>/dev/null || true
    
    # Stop conflicting services
    systemctl stop wpa_supplicant 2>/dev/null || true
    systemctl stop NetworkManager 2>/dev/null || true
    
    # Configure wlan0 with static IP
    ip link set wlan0 up 2>/dev/null || true
    ip addr add 192.168.4.1/24 dev wlan0 2>/dev/null || true
    
    # Start hostapd (if installed)
    if command -v hostapd >/dev/null 2>&1; then
        systemctl enable hostapd 2>/dev/null || true
        systemctl start hostapd 2>/dev/null || true
    fi
    
    # Start dnsmasq (if installed)
    if command -v dnsmasq >/dev/null 2>&1; then
        systemctl enable dnsmasq 2>/dev/null || true
        systemctl start dnsmasq 2>/dev/null || true
    fi
    
    echo "Access point configured"
'

[Install]
WantedBy=multi-user.target
EOF

# Enable the service
mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
ln -sf /lib/systemd/system/create-ap.service "$ROOTFS/etc/systemd/system/multi-user.target.wants/"
echo "✅ Access point service created and enabled"

# 5. Create installation script for hostapd and dnsmasq
echo "5. Creating package installation script..."
cat > "$ROOTFS/usr/local/bin/install-ap-packages.sh" << 'EOF'
#!/bin/bash
# Install hostapd and dnsmasq for access point
apt-get update
apt-get install -y hostapd dnsmasq
systemctl unmask hostapd
systemctl enable hostapd
systemctl enable dnsmasq
EOF
chmod +x "$ROOTFS/usr/local/bin/install-ap-packages.sh" 2>/dev/null || true
echo "✅ Installation script created"

# 6. Create first-boot script to install packages
echo "6. Creating first-boot installation service..."
cat > "$ROOTFS/lib/systemd/system/install-ap-on-boot.service" << 'EOF'
[Unit]
Description=Install Access Point Packages on First Boot
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/install-ap-packages.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Enable only if not already installed
mkdir -p "$ROOTFS/etc/systemd/system/multi-user.target.wants"
# Don't enable by default - user can enable after first boot
echo "✅ Installation service created"

echo ""
echo "✅✅✅ PI ACCESS POINT SETUP COMPLETE ✅✅✅"
echo ""
echo "Configuration:"
echo "  SSID: $AP_SSID"
echo "  Password: $AP_PASSWORD"
echo "  Pi IP: $AP_IP"
echo ""
echo "Next steps:"
echo "1. Eject SD card and boot Pi"
echo "2. On first boot, install packages:"
echo "   ssh andre@192.168.4.1"
echo "   sudo /usr/local/bin/install-ap-packages.sh"
echo "   sudo systemctl enable create-ap.service"
echo "   sudo reboot"
echo ""
echo "OR: Pi will try to create AP automatically (if packages installed)"
echo ""
echo "After boot, connect to WiFi 'moode-audio' and access:"
echo "  http://192.168.4.1"
echo ""

