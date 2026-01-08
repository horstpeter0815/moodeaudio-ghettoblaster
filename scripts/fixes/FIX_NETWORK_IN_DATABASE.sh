#!/bin/bash
################################################################################
# Fix Network Configuration in moOde Database
#
# This script sets the network configuration in moOde's database so that
# cfgNetworks() creates the correct NetworkManager connection files.
#
# Problem: cfgNetworks() in network.php deletes ALL NetworkManager connections
#          and recreates them from the database. If the database is empty or
#          wrong, the connections are lost.
#
# Solution: Set the values in the database, then cfgNetworks() will create
#           the correct files automatically.
################################################################################

set -e

# Detect mounted rootfs volume on macOS (handles "rootfs" and "rootfs 1")
if [ -d "/Volumes/rootfs 1" ]; then
    ROOTFS="/Volumes/rootfs 1"
elif [ -d "/Volumes/rootfs" ]; then
    ROOTFS="/Volumes/rootfs"
else
    ROOTFS="/Volumes/rootfs"
fi

DB="$ROOTFS/var/local/www/db/moode-sqlite3.db"

if [ ! -d "$ROOTFS" ]; then
    echo "❌ Error: rootfs not mounted at $ROOTFS"
    echo "   Please mount the SD card and try again."
    exit 1
fi

if [ ! -f "$DB" ]; then
    echo "❌ Error: Database not found at $DB"
    exit 1
fi

echo "=== FIXING NETWORK CONFIGURATION IN MOODE DATABASE ==="
echo ""

# Generate UUIDs (Ethernet UUID is hardcoded in network.php)
ETH_UUID="f8eba0b7-862d-4ccc-b93a-52815eb9c28d"
# Generate UUIDs for WiFi (use uuidgen if available, otherwise generate manually)
if command -v uuidgen &> /dev/null; then
    HOTEL_WIFI_UUID=$(uuidgen | tr '[:upper:]' '[:lower:]')
else
    # Fallback: generate UUID manually (version 4, random)
    HOTEL_WIFI_UUID=$(python3 -c "import uuid; print(str(uuid.uuid4()))" 2>/dev/null || \
        echo "00000000-0000-4000-8000-$(openssl rand -hex 6 | sed 's/\(..\)\(..\)\(..\)\(..\)\(..\)\(..\)/\1\2\3\4-\5\6/')")
fi

echo "📝 Setting Ethernet (eth0) to static IP 192.168.10.2..."
sqlite3 "$DB" <<EOF
UPDATE cfg_network 
SET 
    method = 'static',
    ipaddr = '192.168.10.2',
    netmask = '255.255.255.0',
    gateway = '192.168.10.1',
    pridns = '8.8.8.8',
    secdns = '8.8.4.4'
WHERE iface = 'eth0';
EOF

echo "✅ Ethernet configured"

echo ""
echo "📝 Setting WiFi (wlan0) - leaving empty for now (will use cfg_ssid)..."
sqlite3 "$DB" <<EOF
UPDATE cfg_network 
SET 
    wlanssid = '',
    wlanuuid = '',
    wlanpsk = '',
    wlansec = ''
WHERE iface = 'wlan0';
EOF

echo "✅ WiFi cleared (will use saved SSIDs from cfg_ssid)"

echo ""
echo "📝 Adding 'The Wing Hotel' WiFi to cfg_ssid..."
# Delete existing entry if present
sqlite3 "$DB" "DELETE FROM cfg_ssid WHERE ssid = 'The Wing Hotel';" 2>/dev/null || true

# Insert Hotel WiFi
sqlite3 "$DB" <<EOF
INSERT INTO cfg_ssid (ssid, uuid, psk, security, method, ipaddr, netmask, gateway, pridns, secdns, saepwd)
VALUES (
    'The Wing Hotel',
    '$HOTEL_WIFI_UUID',
    'thewing2019',
    'wpa-psk',
    '',
    '',
    '',
    '',
    '',
    '',
    ''
);
EOF

echo "✅ Hotel WiFi added to cfg_ssid"

echo ""
echo "📝 Verifying configuration..."
echo ""
echo "Ethernet (eth0):"
sqlite3 "$DB" "SELECT iface, method, ipaddr, gateway FROM cfg_network WHERE iface = 'eth0';" | column -t -s '|'
echo ""
echo "WiFi (wlan0):"
sqlite3 "$DB" "SELECT iface, wlanssid FROM cfg_network WHERE iface = 'wlan0';" | column -t -s '|'
echo ""
echo "Saved SSIDs:"
sqlite3 "$DB" "SELECT ssid, security FROM cfg_ssid;" | column -t -s '|'

echo ""
echo "✅ Network configuration set in database!"
echo ""
echo "📋 What happens next:"
echo "   1. When moOde boots, cfgNetworks() will read from the database"
echo "   2. It will create Ethernet.nmconnection with static IP 192.168.10.2"
echo "   3. It will create 'The Wing Hotel.nmconnection' from cfg_ssid"
echo "   4. Both connections will have autoconnect=true"
echo ""
echo "⚠️  Note: cfgNetworks() deletes ALL existing connections and recreates them"
echo "   from the database. This is why we must set the database correctly."
echo ""

