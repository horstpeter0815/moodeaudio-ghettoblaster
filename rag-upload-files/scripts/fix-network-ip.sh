#!/bin/bash
################################################################################
#
# Fix Network IP Configuration (Ghettoblaster)
#
# Purpose: Ensure Pi gets a different IP than 142/143 (repeaters)
# Method: Configure static IP or DHCP with preferred IP range
#
################################################################################

LOG_FILE="/var/log/fix-network-ip.log"

log() {
    echo "[$(date +%Y-%m-%d %H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

log "=== NETWORK IP FIX START ==="

# Target IP: 192.168.178.161 (away from 142/143)
TARGET_IP="192.168.178.161"
GATEWAY="192.168.178.1"
NETMASK="255.255.255.0"
DNS="192.168.178.1"

# Check if systemd-networkd is used
if [ -d "/etc/systemd/network" ]; then
    log "Using systemd-networkd for network configuration"
    
    # Create ethernet network config (priority: static IP)
    cat > /etc/systemd/network/10-ethernet-static.network << EOF
[Match]
Name=eth0

[Network]
Address=$TARGET_IP/24
Gateway=$GATEWAY
DNS=$DNS
EOF
    
    # Create wireless network config (DHCP with fallback)
    cat > /etc/systemd/network/20-wireless-dhcp.network << EOF
[Match]
Name=wlan0

[Network]
DHCP=yes
DNS=$DNS

[DHCP]
RouteMetric=20
EOF
    
    log "✅ systemd-networkd configs created"
    systemctl enable systemd-networkd 2>/dev/null || true
    systemctl restart systemd-networkd 2>/dev/null || true
    
# Check if dhcpcd is used
elif [ -f "/etc/dhcpcd.conf" ]; then
    log "Using dhcpcd for network configuration"
    
    # Backup original
    cp /etc/dhcpcd.conf /etc/dhcpcd.conf.bak 2>/dev/null || true
    
    # Add static IP for eth0
    if ! grep -q "interface eth0" /etc/dhcpcd.conf; then
        cat >> /etc/dhcpcd.conf << EOF

# Ghettoblaster: Static IP for eth0 (avoid 142/143)
interface eth0
static ip_address=$TARGET_IP/24
static routers=$GATEWAY
static domain_name_servers=$DNS
EOF
        log "✅ dhcpcd static IP configured for eth0"
    fi
    
    # Ensure wlan0 uses DHCP (but with preferred range)
    if ! grep -q "interface wlan0" /etc/dhcpcd.conf; then
        cat >> /etc/dhcpcd.conf << EOF

# Ghettoblaster: DHCP for wlan0 (prefer range 160-180)
interface wlan0
EOF
        log "✅ dhcpcd DHCP configured for wlan0"
    fi
    
    systemctl enable dhcpcd 2>/dev/null || true
    systemctl restart dhcpcd 2>/dev/null || true
    
# Fallback: Use /etc/network/interfaces (ifconfig style)
elif [ -f "/etc/network/interfaces" ]; then
    log "Using /etc/network/interfaces for network configuration"
    
    # Backup original
    cp /etc/network/interfaces /etc/network/interfaces.bak 2>/dev/null || true
    
    # Add static IP for eth0
    if ! grep -q "iface eth0 inet static" /etc/network/interfaces; then
        cat >> /etc/network/interfaces << EOF

# Ghettoblaster: Static IP for eth0 (avoid 142/143)
auto eth0
iface eth0 inet static
    address $TARGET_IP
    netmask $NETMASK
    gateway $GATEWAY
    dns-nameservers $DNS
EOF
        log "✅ /etc/network/interfaces static IP configured for eth0"
    fi
    
    # wlan0 stays DHCP
    if ! grep -q "iface wlan0 inet dhcp" /etc/network/interfaces; then
        cat >> /etc/network/interfaces << EOF

# Ghettoblaster: DHCP for wlan0
auto wlan0
iface wlan0 inet dhcp
EOF
        log "✅ /etc/network/interfaces DHCP configured for wlan0"
    fi
fi

# Service should already exist (created during build)
# Just ensure it's enabled
if [ -f "/etc/systemd/system/fix-network-ip.service" ] || [ -f "/lib/systemd/system/fix-network-ip.service" ]; then
    log "✅ fix-network-ip.service already exists"
    systemctl enable fix-network-ip.service 2>/dev/null || true
    log "✅ Network IP fix service enabled"
else
    log "⚠️  fix-network-ip.service not found - creating it"
    cat > /etc/systemd/system/fix-network-ip.service << 'SERVICE_EOF'
[Unit]
Description=Fix Network IP (Ghettoblaster - avoid 142/143)
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/fix-network-ip.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE_EOF
    systemctl enable fix-network-ip.service 2>/dev/null || true
    log "✅ Network IP fix service created and enabled"
fi

chmod +x /usr/local/bin/fix-network-ip.sh 2>/dev/null || true

log "=== NETWORK IP FIX END ==="

