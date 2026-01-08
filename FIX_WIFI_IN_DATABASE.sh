#!/bin/bash
# Fix WiFi by storing credentials in moOde database (survives network.php cleanup)
# Run: cd ~/moodeaudio-cursor && sudo ./FIX_WIFI_IN_DATABASE.sh

ROOTFS="/Volumes/rootfs"
DB="/Volumes/rootfs/var/local/www/db/moode-sqlite3.db"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ SD card not mounted"
    exit 1
fi

echo "=== FIXING WIFI IN MOODE DATABASE ==="
echo ""

# 1. Store Hotel WiFi in cfg_ssid table (moOde will auto-create connection)
echo "1. Storing Hotel WiFi in moOde database..."
UUID=$(sqlite3 "$DB" "SELECT hex(randomblob(16));" | sed 's/\(........\)\(....\)\(....\)\(....\)\(............\)/\1-\2-\3-\4-\5/')

sqlite3 "$DB" << EOF
-- Insert Hotel WiFi into cfg_ssid (moOde will create connection automatically)
INSERT OR REPLACE INTO cfg_ssid (ssid, uuid, security, psk, saepwd, priority) 
VALUES ('The Wing Hotel', '$UUID', 'wpa-psk', 'thewing2019', '', 100);
EOF

echo "✅ Hotel WiFi stored in database"

# 2. Also set as active WiFi connection in cfg_network
echo "2. Setting Hotel WiFi as active connection..."
sqlite3 "$DB" << EOF
-- Update wlan0 to use Hotel WiFi
UPDATE cfg_network SET 
    wlanssid='The Wing Hotel',
    wlanuuid='$UUID',
    wlansec='wpa-psk',
    wlanpsk='thewing2019',
    method='dhcp'
WHERE id=1;
EOF

echo "✅ Hotel WiFi set as active"

# 3. Create Ethernet config in database (static IP)
echo "3. Setting Ethernet to static IP..."
sqlite3 "$DB" << EOF
-- Update eth0 to static IP
UPDATE cfg_network SET 
    method='static',
    ipaddr='192.168.10.2',
    netmask='255.255.255.0',
    gateway='192.168.10.1',
    pridns='192.168.10.1',
    secdns='8.8.8.8'
WHERE id=0;
EOF

echo "✅ Ethernet set to static IP"

# 4. Verify
echo ""
echo "=== VERIFICATION ==="
echo "Saved WiFi networks:"
sqlite3 "$DB" "SELECT ssid, security FROM cfg_ssid;" 2>/dev/null
echo ""
echo "Active WiFi:"
sqlite3 "$DB" "SELECT wlanssid, wlansec FROM cfg_network WHERE id=1;" 2>/dev/null
echo ""
echo "Ethernet config:"
sqlite3 "$DB" "SELECT method, ipaddr, gateway FROM cfg_network WHERE id=0;" 2>/dev/null
echo ""
echo "✅✅✅ DATABASE CONFIGURED ✅✅✅"
echo ""
echo "After boot:"
echo "  moOde will auto-create Hotel WiFi connection from database"
echo "  Ethernet will be configured as static 192.168.10.2"
echo "  Connections survive moOde's network.php cleanup"
echo ""

