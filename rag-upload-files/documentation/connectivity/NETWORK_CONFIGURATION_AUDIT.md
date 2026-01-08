# Network Configuration Audit Report

Generated: $(date '+%Y-%m-%d %H:%M:%S')

## Executive Summary

This audit identifies all network-related configurations, services, and potential conflicts in the moOde Audio custom build project.

## Table of Contents

1. [Systemd Services](#1-systemd-services)
2. [NetworkManager Connections](#2-networkmanager-connections)
3. [Conflicts Detected](#3-conflicts-detected)
4. [Dependencies](#4-dependencies)
5. [Recommendations](#5-recommendations)

---

# Systemd Services Analysis


## 00-boot-network-ssh.service

```
[Unit]
Description=Boot Network and SSH - Configure eth0 and enable SSH early
DefaultDependencies=no
After=local-fs.target
Before=network.target
Before=cloud-init.target
# NICHT Before=sysinit.target - sysinit ist zu früh!
Conflicts=shutdown.target

[Service]
Type=oneshot
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal
# ALLES IN EINEM SERVICE - KEINE ABHÄNGIGKEITEN
ExecStart=/bin/bash -c '
    echo "=== BOOT NETWORK SSH START ==="
    
    # 1. ETH0 DIREKT konfigurieren (wenn Interface vorhanden)
    # Warte max 5 Sekunden auf eth0 Interface
    ETH0_FOUND=false
    for i in {1..5}; do
        if ip link show eth0 >/dev/null 2>&1; then
            ETH0_FOUND=true
            break
        fi
        sleep 1
    done
    
    if [ "$ETH0_FOUND" = "true" ]; then
        echo "🔧 Konfiguriere eth0: 192.168.10.2"
        # Setze IP
        ifconfig eth0 192.168.10.2 netmask 255.255.255.0 up 2>/dev/null || true
        
        # Entferne alte Default Route falls vorhanden (nur für eth0 Gateway)
        route del default gw 192.168.10.1 2>/dev/null || true
        ip route del default via 192.168.10.1 2>/dev/null || true
        # Setze neue Default Route
        route add default gw 192.168.10.1 eth0 2>/dev/null || true
        ip route add default via 192.168.10.1 dev eth0 2>/dev/null || true
        
        # DNS konfigurieren
        echo "nameserver 192.168.10.1" > /etc/resolv.conf 2>/dev/null || true
        echo "nameserver 8.8.8.8" >> /etc/resolv.conf 2>/dev/null || true
        
        # Prüfe ob IP gesetzt wurde
        ETH0_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk "{print \$2}" | cut -d/ -f1)
        if [ "$ETH0_IP" = "192.168.10.2" ]; then
            echo "✅ eth0 konfiguriert: $ETH0_IP"
        else
            echo "⚠️  eth0 IP: $ETH0_IP (sollte 192.168.10.2 sein) - versuche erneut..."
            ifconfig eth0 192.168.10.2 netmask 255.255.255.0 up 2>/dev/null || true
        fi
    else
        echo "⚠️  eth0 Interface nicht gefunden nach 5 Sekunden - wird später versucht"
    fi
    
    # 2. SSH DIREKT starten
    echo "🔧 Starte SSH..."
    touch /boot/firmware/ssh 2>/dev/null || touch /boot/ssh 2>/dev/null || true
    systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
    systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true
    echo "✅ SSH gestartet"
    
    echo "=== BOOT NETWORK SSH END ==="
'

[Install]
WantedBy=local-fs.target

```

**Key Information:**
- **After:** local-fs.target
- **Before:** network.target
- **IP Addresses:** 192.168.10.1 192.168.10.2 
- **Interfaces:** eth0 
- **Mode:** Static IP


## 00-unified-boot.service

```
[Unit]
Description=Unified Boot Service - Network, SSH, and Cloud-init Disable
DefaultDependencies=no
After=local-fs.target
Before=network.target
Before=network-pre.target
Before=cloud-init.target
Before=sysinit.target
Conflicts=shutdown.target

[Service]
Type=oneshot
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

ExecStart=/bin/bash -c '
    echo "=== UNIFIED BOOT SERVICE START ==="
    echo "This service handles: network, SSH, and cloud-init disable"
    echo ""
    
    # ========================================================================
    # PART 1: KILL CLOUD-INIT IMMEDIATELY (BEFORE ANYTHING ELSE)
    # ========================================================================
    echo "🔧 Part 1: Disabling cloud-init..."
    
    # Kill any running cloud-init processes
    pkill -9 cloud-init 2>/dev/null || true
    killall -9 cloud-init 2>/dev/null || true
    
    # Stop all cloud-init services
    systemctl stop cloud-init cloud-init-local cloud-config cloud-final cloud-init.target 2>/dev/null || true
    
    # Mask all cloud-init services and target
    systemctl mask cloud-init cloud-init-local cloud-config cloud-final cloud-init.target 2>/dev/null || true
    
    # Remove cloud-init directories
    rm -rf /var/lib/cloud/* 2>/dev/null || true
    
    echo "✅ Cloud-init disabled"
    echo ""
    
    # ========================================================================
    # PART 2: CONFIGURE NETWORK IMMEDIATELY (NO DEPENDENCIES)
    # ========================================================================
    echo "🔧 Part 2: Configuring network..."
    
    # Wait for eth0 interface (max 10 seconds)
    ETH0_FOUND=false
    for i in {1..10}; do
        if ip link show eth0 >/dev/null 2>&1; then
            ETH0_FOUND=true
            break
        fi
        sleep 1
    done
    
    if [ "$ETH0_FOUND" = "true" ]; then
        echo "✅ eth0 interface found"
        
        # Configure eth0 directly with ifconfig (no dependencies)
        ifconfig eth0 192.168.10.2 netmask 255.255.255.0 up 2>/dev/null || true
        
        # Set default route
        route del default 2>/dev/null || true
        route add default gw 192.168.10.1 eth0 2>/dev/null || true
        ip route del default 2>/dev/null || true
        ip route add default via 192.168.10.1 dev eth0 2>/dev/null || true
        
        # Configure DNS
        echo "nameserver 192.168.10.1" > /etc/resolv.conf 2>/dev/null || true
        echo "nameserver 8.8.8.8" >> /etc/resolv.conf 2>/dev/null || true
        
        # Verify IP
        ETH0_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk "{print \$2}" | cut -d/ -f1)
        if [ "$ETH0_IP" = "192.168.10.2" ]; then
            echo "✅ eth0 configured: $ETH0_IP"
        else
            echo "⚠️  eth0 IP: $ETH0_IP (retrying...)"
            ifconfig eth0 192.168.10.2 netmask 255.255.255.0 up 2>/dev/null || true
        fi
    else
        echo "⚠️  eth0 not found after 10 seconds"
    fi
    echo ""
    
    # ========================================================================
    # PART 3: ENABLE SSH IMMEDIATELY (NO NETWORK DEPENDENCY)
    # ========================================================================
    echo "🔧 Part 3: Enabling SSH..."
    
    # Create SSH flag file
    touch /boot/firmware/ssh 2>/dev/null || touch /boot/ssh 2>/dev/null || true
    
    # Enable SSH service
    systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
    
    # Start SSH service
    systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true
    
    # Unmask SSH (ensure it can start)
    systemctl unmask ssh 2>/dev/null || systemctl unmask sshd 2>/dev/null || true
    
    # Generate SSH keys if missing
    if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
        ssh-keygen -A 2>/dev/null || true
    fi
    
    echo "✅ SSH enabled"
    echo ""
    
    echo "=== UNIFIED BOOT SERVICE END ==="
'

[Install]
WantedBy=local-fs.target
WantedBy=sysinit.target

```

**Key Information:**
- **After:** local-fs.target
- **Before:** network.target
- **IP Addresses:** 192.168.10.1 192.168.10.2 
- **Interfaces:** eth0 
- **Mode:** Static IP


## 01-ssh-enable.service

```
[Unit]
Description=SSH Enable - Enable SSH service early in boot
DefaultDependencies=no
# Start SO FRÜH WIE MÖGLICH - VOR ALLEM ANDEREN
After=local-fs.target
Before=network.target
Before=cloud-init.target
Before=moode-startup.service
Before=sysinit.target
# Force start - kann nicht übersprungen werden
Conflicts=shutdown.target

[Service]
StandardOutput=journal
StandardError=journal

Type=oneshot
RemainAfterExit=yes
# MULTIPLE SAFETY LAYERS - Kann nicht überschrieben werden
ExecStart=/bin/bash -c '
    # Layer 1: SSH Flag-Datei (wird von Raspberry Pi OS erkannt)
    touch /boot/firmware/ssh 2>/dev/null || touch /boot/ssh 2>/dev/null || true
    
    # Layer 2: SSH Service aktivieren (systemd)
    systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
    systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true
    
    # Layer 3: SSH Service maskieren (kann nicht deaktiviert werden)
    systemctl unmask ssh 2>/dev/null || systemctl unmask sshd 2>/dev/null || true
    
    # Layer 4: SSH Config sicherstellen
    mkdir -p /etc/ssh 2>/dev/null || true
    if [ ! -f /etc/ssh/sshd_config ]; then
        ssh-keygen -A 2>/dev/null || true
    fi
    
    # Layer 5: Port 22 sicherstellen
    sed -i "s/#Port 22/Port 22/" /etc/ssh/sshd_config 2>/dev/null || true
    sed -i "s/Port [0-9]*/Port 22/" /etc/ssh/sshd_config 2>/dev/null || true
    
    # Layer 6: SSH Keys generieren falls fehlen
    if [ ! -f /etc/ssh/ssh_host_rsa_key ]; then
        ssh-keygen -A 2>/dev/null || true
    fi
    
    # Layer 7: Permissions sicherstellen
    chmod 600 /etc/ssh/sshd_config 2>/dev/null || true
    chmod 644 /etc/ssh/*.pub 2>/dev/null || true
    
    # Layer 8: Service neu starten
    systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true
    
    # Layer 9: Firewall-Regel (falls vorhanden)
    ufw allow 22/tcp 2>/dev/null || true
    iptables -A INPUT -p tcp --dport 22 -j ACCEPT 2>/dev/null || true
    
    echo "✅ SSH enabled"
'

# Run every 30 seconds for first 5 minutes (safety net)
ExecStartPost=/bin/bash -c 'for i in {1..10}; do sleep 30; systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true; touch /boot/firmware/ssh 2>/dev/null || touch /boot/ssh 2>/dev/null || true; done &'

[Install]
# Installiere in MEHRERE Targets für maximale Sicherheit
WantedBy=sysinit.target
WantedBy=basic.target
WantedBy=local-fs.target
WantedBy=multi-user.target
# Erstelle auch manuellen Symlink falls nötig
RequiredBy=network.target
```

**Key Information:**
- **After:** local-fs.target
- **Before:** network.target


## 02-eth0-configure.service

```
[Unit]
Description=ETH0 Configure - Set static IP for eth0 interface
DefaultDependencies=no
After=local-fs.target
Before=network-pre.target
Before=NetworkManager.service
Before=network-online.target
Before=cloud-init.target
Conflicts=shutdown.target

[Service]
Type=oneshot
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal
# ETH0 DIREKT konfigurieren - KEINE ABHÄNGIGKEITEN, KEIN WARTEN
ExecStart=/bin/bash -c '
    echo "🔧 ETH0 Configure Service starting..."
    
    # Warte max 10 Sekunden auf eth0 Interface
    for i in {1..10}; do
        if ip link show eth0 >/dev/null 2>&1; then
            echo "✅ eth0 Interface gefunden"
            break
        fi
        sleep 1
    done
    
    # Konfiguriere eth0 DIREKT mit ifconfig (funktioniert IMMER, keine Abhängigkeiten)
    if ip link show eth0 >/dev/null 2>&1; then
        echo "🔧 Konfiguriere eth0 DIREKT: 192.168.10.2/24"
        
        # DIREKT ifconfig - funktioniert IMMER
        ifconfig eth0 192.168.10.2 netmask 255.255.255.0 up 2>/dev/null || true
        route add default gw 192.168.10.1 eth0 2>/dev/null || true
        
        # DNS direkt setzen
        echo "nameserver 192.168.10.1" > /etc/resolv.conf 2>/dev/null || true
        echo "nameserver 8.8.8.8" >> /etc/resolv.conf 2>/dev/null || true
        
        # Prüfe ob IP gesetzt wurde
        ETH0_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk "{print \$2}" | cut -d/ -f1)
        if [ "$ETH0_IP" = "192.168.10.2" ]; then
            echo "✅ eth0 DIREKT konfiguriert: $ETH0_IP"
        else
            echo "⚠️  eth0 IP: $ETH0_IP (sollte 192.168.10.2 sein)"
            # Nochmal versuchen
            ifconfig eth0 192.168.10.2 netmask 255.255.255.0 up 2>/dev/null || true
        fi
        
        # Erstelle auch NetworkManager Connection für später (wenn NetworkManager startet)
        mkdir -p /etc/NetworkManager/system-connections 2>/dev/null || true
        cat > /etc/NetworkManager/system-connections/eth0-static.nmconnection << NMEOF
[connection]
id=eth0-static
type=ethernet
interface-name=eth0
autoconnect=true
autoconnect-priority=100

[ethernet]

[ipv4]
method=manual
addresses=192.168.10.2/24
gateway=192.168.10.1
dns=192.168.10.1;8.8.8.8

[ipv6]
method=auto
NMEOF
        chmod 600 /etc/NetworkManager/system-connections/eth0-static.nmconnection 2>/dev/null || true
        echo "✅ NetworkManager Connection erstellt (für später)"
        
    else
        echo "⚠️  eth0 Interface nicht gefunden - wird später versucht"
    fi
    
    echo "✅ ETH0 Configure Service completed"
'

# Watchdog: Prüfe alle 30 Sekunden ob eth0 noch die richtige IP hat
ExecStartPost=/bin/bash -c 'for i in {1..20}; do sleep 30; ETH0_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk "{print \$2}" | cut -d/ -f1); if [ -z "$ETH0_IP" ] || [ "$ETH0_IP" != "192.168.10.2" ]; then echo "⚠️  eth0 IP falsch: $ETH0_IP - korrigiere..."; ifconfig eth0 192.168.10.2 netmask 255.255.255.0 up 2>/dev/null || true; route add default gw 192.168.10.1 eth0 2>/dev/null || true; fi; done &'

[Install]
WantedBy=local-fs.target
WantedBy=sysinit.target

```

**Key Information:**
- **After:** local-fs.target
- **Before:** network-pre.target
- **IP Addresses:** 192.168.10.1 192.168.10.2 
- **Interfaces:** eth0 
- **Mode:** Static IP


## 03-network-configure.service

```
[Unit]
Description=Network Configure - Configure network interfaces
After=02-eth0-configure.service
After=local-fs.target
Before=network.target
Before=cloud-init.target
# KEINE network-online.target Abhängigkeit - verursacht Deadlock!

[Service]
Type=oneshot
RemainAfterExit=yes
# MULTIPLE SAFETY LAYERS für Netzwerk
ExecStart=/bin/bash -c '
    # Layer 1: Statische IP für eth0 (192.168.10.2 - Direct LAN to Mac)
    if ip link show eth0 >/dev/null 2>&1; then
        # Netplan Config (falls vorhanden)
        mkdir -p /etc/netplan 2>/dev/null || true
        cat > /etc/netplan/01-eth0-static.yaml << NETPLAN_EOF
network:
  version: 2
  renderer: NetworkManager
  ethernets:
    eth0:
      dhcp4: no
      addresses:
        - 192.168.10.2/24
      gateway4: 192.168.10.1
      nameservers:
        addresses:
          - 192.168.10.1
          - 8.8.8.8
NETPLAN_EOF
        netplan apply 2>/dev/null || true
        
        # systemd-networkd Config (Fallback)
        mkdir -p /etc/systemd/network 2>/dev/null || true
        cat > /etc/systemd/network/10-eth0-static.network << NETWORKD_EOF
[Match]
Name=eth0

[Network]
Address=192.168.10.2/24
Gateway=192.168.10.1
DNS=192.168.10.1
DNS=8.8.8.8
NETWORKD_EOF
        
        # ifconfig Fallback (wenn alles andere fehlschlägt)
        ifconfig eth0 192.168.10.2 netmask 255.255.255.0 2>/dev/null || true
        route add default gw 192.168.10.1 2>/dev/null || true
        echo "nameserver 192.168.10.1" > /etc/resolv.conf 2>/dev/null || true
        echo "nameserver 8.8.8.8" >> /etc/resolv.conf 2>/dev/null || true
    fi
    
    # Layer 2: WLAN (OPTIONAL - kann sich ändern, ist nicht kritisch)
    # WICHTIG: eth0 hat PRIORITÄT - WLAN darf eth0 nicht überschreiben
    if ip link show wlan0 >/dev/null 2>&1; then
        # WPA Supplicant sollte bereits konfiguriert sein
        # WLAN kann DHCP verwenden (egal welches WLAN)
        systemctl start wpa_supplicant@wlan0 2>/dev/null || true
        systemctl enable wpa_supplicant@wlan0 2>/dev/null || true
    fi
    
    # Layer 3: NetworkManager konfigurieren - ETH0 STATISCH, WLAN DHCP
    # CRITICAL: eth0 MUSS statisch bleiben (192.168.10.2) - unabhängig von WLAN
    systemctl stop systemd-networkd 2>/dev/null || true
    systemctl disable systemd-networkd 2>/dev/null || true
    
    # NetworkManager: Stelle sicher dass eth0 statisch konfiguriert ist
    if command -v nmcli >/dev/null 2>&1; then
        # Prüfe ob eth0 Connection existiert
        if nmcli connection show eth0 >/dev/null 2>&1; then
            # Setze eth0 auf statisch (falls nicht schon gesetzt)
            nmcli connection modify eth0 ipv4.method manual 2>/dev/null || true
            nmcli connection modify eth0 ipv4.addresses 192.168.10.2/24 2>/dev/null || true
            nmcli connection modify eth0 ipv4.gateway 192.168.10.1 2>/dev/null || true
            nmcli connection modify eth0 ipv4.dns "192.168.10.1 8.8.8.8" 2>/dev/null || true
            echo "✅ NetworkManager: eth0 auf statisch gesetzt"
        fi
    fi
    
    # Starte NetworkManager (Moode Standard)
    systemctl restart NetworkManager 2>/dev/null || true
    systemctl enable NetworkManager 2>/dev/null || true
    echo "✅ NetworkManager aktiviert (eth0 statisch, WLAN DHCP)"
    
    # Layer 4: IP-Adresse prüfen und setzen (falls nicht gesetzt)
    ETH0_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk "{print \$2}" | cut -d/ -f1)
    if [ -z "$ETH0_IP" ] || [ "$ETH0_IP" != "192.168.10.2" ]; then
        echo "⚠️  eth0 hat falsche IP: $ETH0_IP - setze auf 192.168.10.2"
        ifconfig eth0 192.168.10.2 netmask 255.255.255.0 2>/dev/null || true
        route add default gw 192.168.10.1 2>/dev/null || true
    fi
    
    echo "✅ Network configured"
'

# Run every 60 seconds for first 10 minutes (safety net)
ExecStartPost=/bin/bash -c 'for i in {1..10}; do sleep 60; /bin/bash -c "ETH0_IP=$(ip addr show eth0 2>/dev/null | grep \"inet \" | awk \"{print \\\$2}\" | cut -d/ -f1); if [ -z \"$ETH0_IP\" ] || [ \"$ETH0_IP\" != \"192.168.10.2\" ]; then ifconfig eth0 192.168.10.2 netmask 255.255.255.0 2>/dev/null || true; route add default gw 192.168.10.1 2>/dev/null || true; fi" & done'

[Install]
WantedBy=multi-user.target
# KEINE network-online.target Abhängigkeit - verursacht Deadlock!
```

**Key Information:**
- **After:** 02-eth0-configure.service
- **Before:** network.target
- **IP Addresses:** 192.168.10.1 192.168.10.2 
- **Interfaces:** eth0 wlan0 
- **Mode:** DHCP


## 04-network-lan.service

```
[Unit]
Description=Network LAN - Configure LAN connection for eth0
After=02-eth0-configure.service
After=local-fs.target
Before=network.target
# KEINE network-online.target Abhängigkeit - verursacht Deadlock!

[Service]
Type=oneshot
RemainAfterExit=yes
# PERMANENT FIX: Direct LAN Connection to Mac
# Sets static IP 192.168.10.2 for eth0 when directly connected to Mac
ExecStart=/bin/bash -c '
    # Statische IP für eth0 (Direct LAN zu Mac: 192.168.10.2)
    if ip link show eth0 >/dev/null 2>&1; then
        # Method 1: systemd-networkd (Priority 1)
        mkdir -p /etc/systemd/network 2>/dev/null || true
        cat > /etc/systemd/network/10-eth0-direct-lan.network << NETWORKD_EOF
[Match]
Name=eth0

[Network]
Address=192.168.10.2/24
Gateway=192.168.10.1
DNS=192.168.10.1
DNS=8.8.8.8
NETWORKD_EOF
        systemctl enable systemd-networkd 2>/dev/null || true
        systemctl restart systemd-networkd 2>/dev/null || true
        
        # Method 2: dhcpcd (Fallback)
        if [ -f /etc/dhcpcd.conf ]; then
            if ! grep -q "interface eth0" /etc/dhcpcd.conf || ! grep -q "192.168.10.2" /etc/dhcpcd.conf; then
                # Remove old eth0 config if exists
                sed -i "/^interface eth0/,/^$/d" /etc/dhcpcd.conf 2>/dev/null || true
                # Add new config
                cat >> /etc/dhcpcd.conf << DHCPCD_EOF

# Direct LAN Connection (Ghettoblaster)
interface eth0
static ip_address=192.168.10.2/24
static routers=192.168.10.1
static domain_name_servers=192.168.10.1 8.8.8.8
DHCPCD_EOF
                systemctl restart dhcpcd 2>/dev/null || true
            fi
        fi
        
        # Method 3: ifconfig (Last Resort Fallback)
        ifconfig eth0 192.168.10.2 netmask 255.255.255.0 2>/dev/null || true
        route add default gw 192.168.10.1 2>/dev/null || true
        echo "nameserver 192.168.10.1" > /etc/resolv.conf 2>/dev/null || true
        echo "nameserver 8.8.8.8" >> /etc/resolv.conf 2>/dev/null || true
    fi
'

[Install]
WantedBy=multi-user.target

```

**Key Information:**
- **After:** 02-eth0-configure.service
- **Before:** network.target
- **IP Addresses:** 192.168.10.1 192.168.10.2 
- **Interfaces:** eth0 
- **Mode:** DHCP


## 05-remove-pi-user.service

```
[Unit]
Description=Remove pi User - Prevent Username Reset Issues
After=local-fs.target
After=fix-user-id.service
Before=multi-user.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c '
    # Remove pi user if it exists (prevents username reset issues)
    if id -u pi >/dev/null 2>&1; then
        echo "Removing pi user to prevent username reset issues..."
        
        # Check if pi has UID 1000 (conflicts with andre)
        PI_UID=$(id -u pi 2>/dev/null || echo "")
        if [ "$PI_UID" = "1000" ]; then
            echo "⚠️  pi user has UID 1000 - this conflicts with andre"
            echo "Removing pi user..."
            
            # Stop any processes running as pi
            pkill -u pi 2>/dev/null || true
            sleep 1
            
            # Remove pi user
            userdel -r pi 2>/dev/null || true
            
            # Remove pi home directory if it still exists
            rm -rf /home/pi 2>/dev/null || true
            
            echo "✅ pi user removed"
        else
            echo "ℹ️  pi user exists but has different UID ($PI_UID) - keeping it"
        fi
    else
        echo "✅ pi user does not exist"
    fi
    
    # Ensure andre is the only user with UID 1000
    ANDRE_UID=$(id -u andre 2>/dev/null || echo "")
    if [ "$ANDRE_UID" != "1000" ]; then
        echo "⚠️  andre does not have UID 1000 - fixing..."
        # This should be handled by fix-user-id.service, but double-check
    fi
'

[Install]
WantedBy=multi-user.target

```

**Key Information:**
- **After:** local-fs.target
- **Before:** multi-user.target


## 06-disable-cloud-init.service

```
[Unit]
Description=Disable Cloud-Init - Prevent Boot Delays
DefaultDependencies=no
After=local-fs.target
Before=multi-user.target
Before=cloud-init.target
Before=cloud-init.service
Before=cloud-init-local.service
Before=cloud-config.service
Before=cloud-final.service
Conflicts=cloud-init.target
Conflicts=cloud-init.service
Conflicts=cloud-init-local.service
Conflicts=cloud-config.service
Conflicts=cloud-final.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c '
    echo "Disabling cloud-init to prevent boot delays..."
    
    # Stop cloud-init services if running
    systemctl stop cloud-init 2>/dev/null || true
    systemctl stop cloud-init-local 2>/dev/null || true
    systemctl stop cloud-config 2>/dev/null || true
    systemctl stop cloud-final 2>/dev/null || true
    
    # Disable cloud-init services
    systemctl disable cloud-init 2>/dev/null || true
    systemctl disable cloud-init-local 2>/dev/null || true
    systemctl disable cloud-config 2>/dev/null || true
    systemctl disable cloud-final 2>/dev/null || true
    
    # Mask cloud-init services (prevents them from being started)
    systemctl mask cloud-init 2>/dev/null || true
    systemctl mask cloud-init-local 2>/dev/null || true
    systemctl mask cloud-config 2>/dev/null || true
    systemctl mask cloud-final 2>/dev/null || true
    systemctl mask cloud-init.target 2>/dev/null || true
    
    # Remove cloud-init configuration if it exists
    if [ -f "/etc/cloud/cloud.cfg" ]; then
        # Backup original config
        cp /etc/cloud/cloud.cfg /etc/cloud/cloud.cfg.backup 2>/dev/null || true
        # Disable cloud-init in config
        sed -i "s/^cloud_init_modules:/#cloud_init_modules:/" /etc/cloud/cloud.cfg 2>/dev/null || true
    fi
    
    echo "✅ Cloud-init disabled and masked"
'

[Install]
WantedBy=multi-user.target
```

**Key Information:**
- **After:** local-fs.target
- **Before:** multi-user.target


## amp100-automute.service

```
[Unit]
Description=AMP100 Auto-Mute - Set Auto-Mute Register After Boot
After=sound.target
After=local-fs.target
Before=mpd.service
Wants=sound.target

[Service]
Type=oneshot
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal
ExecStart=/usr/local/bin/amp100-automute.sh

[Install]
WantedBy=sound.target
WantedBy=multi-user.target

```

**Key Information:**
- **After:** sound.target
- **Before:** mpd.service


## amp100-volume-zero.service

```
[Unit]
Description=AMP100 Volume Zero - Set Volume to 0 on Boot (Maximum Volume Reduction)
DefaultDependencies=no
After=local-fs.target
After=sound.target
Before=mpd.service
Before=moode-startup.service
Wants=sound.target

[Service]
Type=oneshot
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal
# Set AMP100 Volume to 0 on Boot (Maximum Volume Reduction)
ExecStart=/bin/bash -c '
    echo "=== AMP100 VOLUME ZERO START ==="
    
    # Wait for sound system to be ready (max 10 seconds)
    SOUND_READY=false
    for i in {1..10}; do
        if systemctl is-active sound.target >/dev/null 2>&1 || [ -d /proc/asound ]; then
            SOUND_READY=true
            break
        fi
        sleep 1
    done
    
    if [ "$SOUND_READY" != "true" ]; then
        echo "⚠️  Sound system not ready after 10 seconds - continuing anyway"
    fi
    
    # Find AMP100 Card (sndrpihifiberry or similar)
    AMP100_CARD=""
    for card in /proc/asound/card*; do
        if [ -d "$card" ]; then
            CARD_NAME=$(cat "$card/id" 2>/dev/null || echo "")
            if echo "$CARD_NAME" | grep -qiE "hifiberry|sndrpihifiberry|amp100"; then
                CARD_NUM=$(basename "$card" | sed "s/card//")
                AMP100_CARD="$CARD_NUM"
                echo "✅ Found AMP100 Card: $CARD_NUM ($CARD_NAME)"
                break
            fi
        fi
    done
    
    if [ -z "$AMP100_CARD" ]; then
        echo "⚠️  AMP100 Card not found - trying default card 0"
        AMP100_CARD="0"
    fi
    
    # Try multiple mixer controls (AMP100 might use PCM or Digital)
    MIXER_CONTROLS="PCM Digital Master"
    
    for MIXER in $MIXER_CONTROLS; do
        echo "🔧 Setting $MIXER to 0% on Card $AMP100_CARD..."
        # Try unmute first, then set volume to 0
        amixer -c "$AMP100_CARD" sset "$MIXER" 0% unmute 2>/dev/null || \
        amixer -c "$AMP100_CARD" sset "$MIXER" 0% 2>/dev/null || true
        
        # Verify volume is 0
        VOLUME=$(amixer -c "$AMP100_CARD" get "$MIXER" 2>/dev/null | grep -oE "\[[0-9]+%\]" | head -1 | tr -d "[]%" || echo "")
        if [ -n "$VOLUME" ] && [ "$VOLUME" = "0" ]; then
            echo "✅ $MIXER set to 0%"
        else
            echo "⚠️  $MIXER volume: ${VOLUME}% (attempted to set to 0%)"
        fi
    done
    
    # Also set via MPD mixer if available (but MPD might not be running yet)
    if command -v mpc >/dev/null 2>&1; then
        mpc volume 0 2>/dev/null || true
        echo "✅ MPD volume set to 0 (if MPD was running)"
    fi
    
    echo "=== AMP100 VOLUME ZERO END ==="
'

[Install]
WantedBy=sound.target
WantedBy=multi-user.target

```

**Key Information:**
- **After:** local-fs.target
- **Before:** mpd.service


## audio-optimize.service

```
[Unit]
Description=Audio Optimization for High-End HiFi
After=network.target
Before=mpd.service
Wants=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/audio-optimize.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target

```

**Key Information:**
- **After:** network.target
- **Before:** mpd.service


## auto-fix-display.service

```
[Unit]
Description=Auto-Fix Display Service on Boot
After=network.target
Before=localdisplay.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/auto-fix-display.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target

```

**Key Information:**
- **After:** network.target
- **Before:** localdisplay.service


## bluetooth.sed.service

```
[Unit]
Description=Bluetooth service
Documentation=man:bluetoothd(8)
ConditionPathIsDirectory=/sys/class/bluetooth

[Service]
Type=dbus
BusName=org.bluez
ExecStart=/usr/sbin/bluetoothd --noplugin=sap
NotifyAccess=main
#WatchdogSec=10
#Restart=on-failure
CapabilityBoundingSet=CAP_NET_ADMIN CAP_NET_BIND_SERVICE
LimitNPROC=1
ProtectHome=true
ProtectSystem=full

[Install]
WantedBy=bluetooth.target
Alias=dbus-org.bluez.service
```

**Key Information:**


## boot-debug-logger.service

```
[Unit]
Description=Boot Debug Logger - Collects comprehensive boot diagnostics
DefaultDependencies=no
After=local-fs.target
After=00-boot-network-ssh.service
Before=network.target
Before=cloud-init.target

[Service]
Type=oneshot
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal
# Start logging immediately and continue for 10 minutes
ExecStart=/usr/local/bin/boot-debug-logger.sh start
# Keep running in background to collect ongoing logs
ExecStartPost=/bin/bash -c "/usr/local/bin/boot-debug-logger.sh monitor &"

[Install]
WantedBy=local-fs.target
WantedBy=sysinit.target

```

**Key Information:**
- **After:** local-fs.target
- **Before:** network.target


## disable-console.service

```
[Unit]
Description=Disable Console on tty1 (Ghettoblaster)
After=multi-user.target
Before=localdisplay.service

[Service]
Type=oneshot
ExecStart=/bin/systemctl stop getty@tty1.service
ExecStart=/bin/systemctl mask getty@tty1.service
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

**Key Information:**
- **After:** multi-user.target
- **Before:** localdisplay.service


## enable-ssh-early.service

```
[Unit]
Description=Ghettoblaster Enable SSH Early (Before moOde)
# Start SO FRÜH WIE MÖGLICH - NICHT auf network-online warten!
After=local-fs.target
Before=network.target
Before=moode-startup.service
# Force start
Conflicts=shutdown.target

[Service]
StandardOutput=journal
StandardError=journal

Type=oneshot
# Enable SSH very early, before moOde can disable it
ExecStart=/bin/bash -c 'systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true && systemctl enable ssh.service 2>/dev/null || systemctl enable sshd.service 2>/dev/null || true && touch /boot/firmware/ssh 2>/dev/null || touch /boot/ssh 2>/dev/null || true && systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target

```

**Key Information:**
- **After:** local-fs.target
- **Before:** network.target


## first-boot-setup.service

```
[Unit]
Description=First Boot Setup - Run once on first boot
After=network.target local-fs.target
Before=localdisplay.service auto-fix-display.service

[Service]
Type=oneshot
ExecStart=/usr/local/bin/first-boot-setup.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target

```

**Key Information:**
- **After:** network.target local-fs.target
- **Before:** localdisplay.service auto-fix-display.service


## fix-network-ip.service

```
[Unit]
Description=Fix Network IP (Ghettoblaster - avoid 142/143)
After=02-eth0-configure.service
After=local-fs.target
# KEINE network-online.target Abhängigkeit - verursacht Deadlock!

[Service]
Type=oneshot
ExecStart=/usr/local/bin/fix-network-ip.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target

```

**Key Information:**
- **After:** 02-eth0-configure.service
- **Interfaces:** eth0 


## fix-ssh-sudoers.service

```
[Unit]
Description=Ghettoblaster SSH and Sudoers Fix (PERMANENT)
After=local-fs.target
Before=cloud-init.target
Wants=multi-user.target

[Service]
Type=oneshot
# CRITICAL: Enable and start SSH in multiple ways
ExecStart=/bin/bash -c 'echo "andre ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/andre && chmod 0440 /etc/sudoers.d/andre && visudo -c -f /etc/sudoers.d/andre 2>/dev/null || true && systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true && systemctl enable ssh.service 2>/dev/null || systemctl enable sshd.service 2>/dev/null || true && systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true && touch /boot/firmware/ssh 2>/dev/null || touch /boot/ssh 2>/dev/null || true && systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true && echo "✅ SSH and Sudoers fixed"'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target

```

**Key Information:**
- **After:** local-fs.target
- **Before:** cloud-init.target


## fix-user-id.service

```
[Unit]
Description=Ghettoblaster User ID Fix (moOde requires UID 1000)
After=local-fs.target
After=00-boot-network-ssh.service
Wants=multi-user.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c '
    # Prüfe ob andre existiert und UID hat
    ANDRE_UID=$(id -u andre 2>/dev/null || echo "")
    if [ -z "$ANDRE_UID" ] || [ "$ANDRE_UID" != "1000" ]; then
        echo "Fixing andre UID to 1000..."
        # Versuche zuerst groupadd (falls Gruppe fehlt)
        groupadd -g 1000 andre 2>/dev/null || true
        # Versuche usermod (falls User existiert)
        if usermod -u 1000 -g 1000 andre 2>/dev/null; then
            echo "✅ andre UID auf 1000 geändert"
        else
            # Falls usermod fehlschlägt: User neu erstellen
            echo "⚠️  usermod fehlgeschlagen - erstelle User neu..."
            userdel -r andre 2>/dev/null || true
            groupadd -g 1000 andre 2>/dev/null || true
            useradd -m -s /bin/bash -u 1000 -g 1000 andre 2>/dev/null || true
            usermod -aG audio,video,spi,i2c,gpio,plugdev,sudo andre 2>/dev/null || true
            echo "andre:0815" | chpasswd 2>/dev/null || true
            echo "andre ALL=(ALL) NOPASSWD: ALL" > /etc/sudoers.d/andre 2>/dev/null || true
            chmod 0440 /etc/sudoers.d/andre 2>/dev/null || true
            echo "✅ andre User neu erstellt mit UID 1000"
        fi
    else
        echo "✅ andre hat bereits UID 1000"
    fi
'
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target

```

**Key Information:**
- **After:** local-fs.target


## ft6236-delay.service

```
[Unit]
Description=Load FT6236 Touchscreen after Display
After=localdisplay.service
After=xserver-ready.service
Wants=localdisplay.service
Wants=xserver-ready.service
Requires=graphical.target

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 2
ExecStart=/sbin/modprobe ft6236
ExecStartPost=/bin/sleep 1
RemainAfterExit=yes
TimeoutStartSec=10

[Install]
WantedBy=graphical.target
```

**Key Information:**
- **After:** localdisplay.service


## i2c-monitor.service

```
[Unit]
Description=I2C Bus Monitor
After=network.target
Wants=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/i2c-monitor.sh
Restart=on-failure
RestartSec=30
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target

```

**Key Information:**
- **After:** network.target


## i2c-stabilize.service

```
[Unit]
Description=I2C Bus Stabilization
After=network.target
Before=localdisplay.service
Wants=network.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/i2c-stabilize.sh
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target

```

**Key Information:**
- **After:** network.target
- **Before:** localdisplay.service


## localdisplay.service

```
[Unit]
Description=Start Local Display (Ghettoblaster)
After=graphical.target
After=xserver-ready.service
Wants=graphical.target
Wants=xserver-ready.service
Requires=graphical.target

[Service]
Type=simple
User=andre
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/andre/.Xauthority
ExecStartPre=/bin/bash -c 'mkdir -p /var/log/display-chain && echo "[$(date +%Y-%m-%d\ %H:%M:%S.%N)] [SERVICE] localdisplay.service starting" >> /var/log/display-chain/service.log'
ExecStartPre=/usr/local/bin/xserver-ready.sh
ExecStartPre=/bin/bash -c 'echo "[$(date +%Y-%m-%d\ %H:%M:%S.%N)] [SERVICE] X11 ready, waiting 2s" >> /var/log/display-chain/service.log'
ExecStartPre=/bin/sleep 2
ExecStart=/bin/bash -c 'echo "[$(date +%Y-%m-%d\ %H:%M:%S.%N)] [SERVICE] Starting Chromium" >> /var/log/display-chain/service.log && /usr/local/bin/start-chromium-clean.sh'
TimeoutStartSec=60
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Key Information:**
- **After:** graphical.target


## peppymeter-extended-displays.service

```
[Unit]
Description=PeppyMeter Extended Displays Overlay
After=localdisplay.service
After=peppymeter.service
After=mpd.service
Wants=localdisplay.service
Wants=peppymeter.service
Wants=mpd.service
Requires=graphical.target

[Service]
Type=simple
User=andre
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/andre/.Xauthority
ExecStartPre=/bin/bash -c 'until [ -f /tmp/.X11-unix/X0 ]; do sleep 0.5; done'
ExecStart=/usr/local/bin/peppymeter-extended-displays.py
Restart=on-failure
RestartSec=5
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=graphical.target

```

**Key Information:**
- **After:** localdisplay.service


## peppymeter.service

```
[Unit]
Description=PeppyMeter Audio Visualizer
After=localdisplay.service
After=mpd.service
Wants=localdisplay.service
Wants=mpd.service

[Service]
Type=simple
User=andre
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/andre/.Xauthority
ExecStart=/usr/local/bin/peppymeter-wrapper.sh
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
```

**Key Information:**
- **After:** localdisplay.service


## restore-display-config.service

```
[Unit]
Description=Restore Display Configuration After Reboot
After=local-fs.target
After=moode-startup.service
After=multi-user.target
Wants=moode-startup.service

[Service]
Type=oneshot
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal
ExecStart=/usr/local/bin/restore-display-config.sh
# Also run after X11 starts (if available)
ExecStartPost=/bin/bash -c 'sleep 5; /usr/local/bin/restore-display-config.sh'

[Install]
WantedBy=multi-user.target

```

**Key Information:**
- **After:** local-fs.target


## rotenc.service

```
[Unit]
Description=Moode Rotary Encoder Driver
After=sound.target

[Service]
Type=simple

# Launch params
# rotenc <poll_interval in ms> <accel_factor> <volume_step> <pin_a> <pin_b> <print_debug>
# rotenc 100 2 3 23 24 1 (with optional debug print)
# rotenc 100 2 3 23 24 (normal)
# poll_interval:	Number of ms delay for each iteration of the volume update loop. Default=100
# accel_factor:	    Threshold (difference between last and current position of encoder) to determine whether to use 1 step or STEP steps. Default=2.
# volume_step:		Number of steps to use when knob turns at fast rate. Default=3.
# pin_a/b:	        GPIO pin numbers. Defaults: rotenc_py (23,24 - Broadcom SoC), rotenc_c (4,5 wiringPi).
# print_debug:	    Print debug information to console. 1=normal, 2=verbose (2 is for rotenc_c only). This is an optional param.
ExecStart=/var/www/daemon/rotenc.py 100 2 3 23 24

[Install]
WantedBy=multi-user.target
```

**Key Information:**
- **After:** sound.target


## shellinabox.service

```
[Unit] 
Description=Shellinabox daemon
After=network.target

[Service]
ExecStart=/usr/bin/shellinaboxd -t --no-beep --user-css Normal:+"/var/www/css/shellinabox-normal.css",Reverse:-"/var/www/css/shellinabox-reverse.css",Monochrome:-"/var/www/css/shellinabox-mono.css"

[Install]
WantedBy=multi-user.target
```

**Key Information:**
- **After:** Binary file /Users/andrevollmer/moodeaudio-cursor/moode-source/lib/systemd/system/shellinabox.service matches


## squeezelite.service

```
[Unit]
Description=Squeezelite renderer
After=network.target

[Service]
EnvironmentFile=-/etc/squeezelite.conf
ExecStart=/usr/bin/squeezelite -n ${PLAYERNAME} -o $AUDIODEVICE -a ${ALSAPARAMS} -b ${OUTPUTBUFFERS} -p $TASKPRIORITY -c $CODECS $OTHEROPTIONS

[Install]
WantedBy=multi-user.target
```

**Key Information:**
- **After:** network.target


## ssh-asap.service

```
[Unit]
Description=SSH ASAP - Start SSH as early as humanly possible
DefaultDependencies=no
# Start BEFORE everything else
After=local-fs.target
Before=sysinit.target
Before=basic.target
Before=network.target
Before=cloud-init.target
Before=moode-startup.service
Conflicts=shutdown.target

[Service]
Type=oneshot
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal
# MULTIPLE METHODS - SSH SO FRÜH WIE MÖGLICH
ExecStart=/bin/bash -c '
    # Method 1: SSH Flag-Datei (wird von Raspberry Pi OS erkannt)
    touch /boot/firmware/ssh 2>/dev/null || touch /boot/ssh 2>/dev/null || true
    
    # Method 2: systemctl enable (sofort)
    systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
    
    # Method 3: systemctl start (sofort)
    systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true
    
    # Method 4: Direkt sshd starten (wenn systemctl noch nicht bereit)
    /usr/sbin/sshd -t 2>/dev/null && /usr/sbin/sshd -D -p 22 & 2>/dev/null || true
    
    echo "✅ SSH ASAP activated"
'

# Run multiple times for safety
ExecStartPost=/bin/bash -c 'sleep 2; systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true; systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true; touch /boot/firmware/ssh 2>/dev/null || touch /boot/ssh 2>/dev/null || true'
ExecStartPost=/bin/bash -c 'sleep 5; systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true'

[Install]
# Installiere in ALLE möglichen Targets
WantedBy=local-fs.target
WantedBy=sysinit.target
WantedBy=basic.target
WantedBy=multi-user.target
RequiredBy=network.target

```

**Key Information:**
- **After:** local-fs.target
- **Before:** sysinit.target


## ssh-permanent.service

```
[Unit]
Description=SSH Permanent - Ensures SSH Always Enabled (Ghettoblaster)
After=network-online.target
Wants=network-online.target

[Service]
Type=oneshot
RemainAfterExit=yes
# PERMANENT FIX: SSH Always Enabled
# Multiple methods to ensure SSH is always active, even if Moode tries to disable it
ExecStart=/bin/bash -c '
    # Method 1: SSH-Flag Datei (Raspberry Pi OS Standard)
    touch /boot/firmware/ssh 2>/dev/null || true
    chmod 644 /boot/firmware/ssh 2>/dev/null || true
    
    # Method 2: systemctl enable/start ssh
    systemctl enable ssh 2>/dev/null || true
    systemctl enable sshd 2>/dev/null || true
    systemctl start ssh 2>/dev/null || true
    systemctl start sshd 2>/dev/null || true
    
    # Method 3: /etc/rc.local (Fallback - runs on every boot)
    if [ ! -f /etc/rc.local ]; then
        cat > /etc/rc.local << RCLOCAL_EOF
#!/bin/bash
# SSH Permanent Fix (Ghettoblaster)
systemctl start ssh 2>/dev/null || true
systemctl start sshd 2>/dev/null || true
touch /boot/firmware/ssh 2>/dev/null || true
exit 0
RCLOCAL_EOF
        chmod +x /etc/rc.local
    else
        # Add SSH fix to existing rc.local if not present
        if ! grep -q "SSH Permanent Fix" /etc/rc.local; then
            sed -i "/^exit 0/i\\# SSH Permanent Fix (Ghettoblaster)\\nsystemctl start ssh 2>/dev/null || true\\nsystemctl start sshd 2>/dev/null || true\\ntouch /boot/firmware/ssh 2>/dev/null || true" /etc/rc.local 2>/dev/null || true
        fi
    fi
    
    # Method 4: Ensure SSH config allows password auth (if needed)
    if [ -f /etc/ssh/sshd_config ]; then
        # Only modify if PasswordAuthentication is explicitly disabled
        if grep -q "^PasswordAuthentication no" /etc/ssh/sshd_config; then
            sed -i "s/^PasswordAuthentication no/PasswordAuthentication yes/" /etc/ssh/sshd_config 2>/dev/null || true
            systemctl restart sshd 2>/dev/null || true
        fi
    fi
'

[Install]
WantedBy=multi-user.target

```

**Key Information:**
- **After:** network-online.target


## ssh-ultra-early.service

```
[Unit]
Description=SSH Ultra Early - Startet SSH SO FRÜH WIE MÖGLICH
DefaultDependencies=no
# Start SO FRÜH WIE MÖGLICH - VOR ALLEM!
After=local-fs.target
Before=sysinit.target
Before=basic.target
Before=network.target
Before=moode-startup.service
# Force start - kann nicht übersprungen werden
Conflicts=shutdown.target

[Service]
StandardOutput=journal
StandardError=journal

Type=oneshot
RemainAfterExit=yes
# SSH SO FRÜH WIE MÖGLICH aktivieren - MULTIPLE METHODS
ExecStart=/usr/local/bin/force-ssh-on.sh

# Run multiple times for safety
ExecStartPost=/bin/bash -c 'sleep 5; systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true; touch /boot/firmware/ssh 2>/dev/null || touch /boot/ssh 2>/dev/null || true'
ExecStartPost=/bin/bash -c 'sleep 10; systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true; systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true'

[Install]
# Installiere in ALLE möglichen Targets
WantedBy=local-fs.target
WantedBy=sysinit.target
WantedBy=basic.target
WantedBy=multi-user.target
RequiredBy=network.target

```

**Key Information:**
- **After:** local-fs.target
- **Before:** sysinit.target


## ssh-watchdog.service

```
[Unit]
Description=SSH Watchdog - Ensures SSH is always running
After=local-fs.target
Before=network.target
Before=cloud-init.target
# Start early, don't wait for network-online (verursacht Deadlock!)

[Service]
StandardOutput=journal
StandardError=journal

Type=simple
Restart=always
RestartSec=10
ExecStart=/bin/bash -c '
    while true; do
        # Prüfe ob SSH läuft
        if ! systemctl is-active --quiet ssh && ! systemctl is-active --quiet sshd; then
            echo "⚠️  SSH nicht aktiv - starte..."
            systemctl start ssh 2>/dev/null || systemctl start sshd 2>/dev/null || true
            systemctl enable ssh 2>/dev/null || systemctl enable sshd 2>/dev/null || true
            touch /boot/firmware/ssh 2>/dev/null || touch /boot/ssh 2>/dev/null || true
        fi
        
        # Prüfe ob Port 22 offen ist
        if ! netstat -tuln 2>/dev/null | grep -q ":22 "; then
            echo "⚠️  Port 22 nicht offen - starte SSH..."
            systemctl restart ssh 2>/dev/null || systemctl restart sshd 2>/dev/null || true
        fi
        
        sleep 30
    done
'

[Install]
WantedBy=multi-user.target
```

**Key Information:**
- **After:** local-fs.target
- **Before:** network.target


## usb-gadget-network.service

```
[Unit]
Description=Configure USB Gadget Network Interface
After=network-pre.target
Before=network.target
Wants=network-pre.target

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c 'sleep 2 && if [ -d /sys/class/net/usb0 ]; then ip link set usb0 up && ip addr add 192.168.10.2/24 dev usb0 || true; fi'
ExecStop=/bin/bash -c 'if [ -d /sys/class/net/usb0 ]; then ip link set usb0 down || true; fi'

[Install]
WantedBy=multi-user.target

```

**Key Information:**
- **After:** network-pre.target
- **Before:** network.target
- **IP Addresses:** 192.168.10.2 
- **Interfaces:** usb0 
- **Mode:** Static IP


## xserver-ready.service

```
[Unit]
Description=X Server Ready Check
After=graphical.target
Wants=graphical.target

[Service]
Type=oneshot
ExecStart=/usr/local/bin/xserver-ready.sh
RemainAfterExit=yes
TimeoutStartSec=35

[Install]
WantedBy=graphical.target
```

**Key Information:**
- **After:** graphical.target


---

NetworkManager connections directory not found: /Users/andrevollmer/moodeaudio-cursor/moode-source/etc/NetworkManager/system-connections

---

# Network Configuration Conflicts

## Multiple Services Configuring Same IP (192.168.10.2)

- **00-boot-network-ssh.service**
- **00-unified-boot.service**
- **02-eth0-configure.service**
- **03-network-configure.service**
- **04-network-lan.service**
- **usb-gadget-network.service**

## Multiple Services Configuring eth0

- **00-boot-network-ssh.service**
- **00-unified-boot.service**
- **02-eth0-configure.service**
- **03-network-configure.service**
- **04-network-lan.service**
- **fix-network-ip.service**

## Conflicting Network Managers

- **systemd-networkd**
- **dhcpcd**

## Static IP vs DHCP Conflicts

**Static IP Services:**
- 00-boot-network-ssh.service
- 00-unified-boot.service
- 02-eth0-configure.service
- 03-network-configure.service
- 04-network-lan.service
- usb-gadget-network.service

**DHCP Services:**
- 03-network-configure.service
- 04-network-lan.service


---

# Service Dependencies Analysis

## Dependency Chain

### 00-boot-network-ssh.service

- **After:** local-fs.target
- **Before:** network.target

### 00-unified-boot.service

- **After:** local-fs.target
- **Before:** network.target

### 01-ssh-enable.service

- **After:** local-fs.target
- **Before:** network.target

### 02-eth0-configure.service

- **After:** local-fs.target
- **Before:** network-pre.target

### 03-network-configure.service

- **After:** 02-eth0-configure.service
- **Before:** network.target

### 04-network-lan.service

- **After:** 02-eth0-configure.service
- **Before:** network.target

### 05-remove-pi-user.service

- **After:** local-fs.target
- **Before:** multi-user.target

### 06-disable-cloud-init.service

- **After:** local-fs.target
- **Before:** multi-user.target

### amp100-automute.service

- **After:** sound.target
- **Before:** mpd.service
- **Wants:** sound.target

### amp100-volume-zero.service

- **After:** local-fs.target
- **Before:** mpd.service
- **Wants:** sound.target

### audio-optimize.service

- **After:** network.target
- **Before:** mpd.service
- **Wants:** network.target

### auto-fix-display.service

- **After:** network.target
- **Before:** localdisplay.service

### bluetooth.sed.service


### boot-debug-logger.service

- **After:** local-fs.target
- **Before:** network.target

### disable-console.service

- **After:** multi-user.target
- **Before:** localdisplay.service

### enable-ssh-early.service

- **After:** local-fs.target
- **Before:** network.target

### first-boot-setup.service

- **After:** network.target local-fs.target
- **Before:** localdisplay.service auto-fix-display.service

### fix-network-ip.service

- **After:** 02-eth0-configure.service

### fix-ssh-sudoers.service

- **After:** local-fs.target
- **Before:** cloud-init.target
- **Wants:** multi-user.target

### fix-user-id.service

- **After:** local-fs.target
- **Wants:** multi-user.target

### ft6236-delay.service

- **After:** localdisplay.service
- **Wants:** localdisplay.service
- **Requires:** graphical.target

### i2c-monitor.service

- **After:** network.target
- **Wants:** network.target

### i2c-stabilize.service

- **After:** network.target
- **Before:** localdisplay.service
- **Wants:** network.target

### localdisplay.service

- **After:** graphical.target
- **Wants:** graphical.target
- **Requires:** graphical.target

### peppymeter-extended-displays.service

- **After:** localdisplay.service
- **Wants:** localdisplay.service
- **Requires:** graphical.target

### peppymeter.service

- **After:** localdisplay.service
- **Wants:** localdisplay.service

### restore-display-config.service

- **After:** local-fs.target
- **Wants:** moode-startup.service

### rotenc.service

- **After:** sound.target

### shellinabox.service

- **After:** Binary file /Users/andrevollmer/moodeaudio-cursor/moode-source/lib/systemd/system/shellinabox.service matches

### squeezelite.service

- **After:** network.target

### ssh-asap.service

- **After:** local-fs.target
- **Before:** sysinit.target

### ssh-permanent.service

- **After:** network-online.target
- **Wants:** network-online.target

### ssh-ultra-early.service

- **After:** local-fs.target
- **Before:** sysinit.target

### ssh-watchdog.service

- **After:** local-fs.target
- **Before:** network.target

### usb-gadget-network.service

- **After:** network-pre.target
- **Before:** network.target
- **Wants:** network-pre.target

### xserver-ready.service

- **After:** graphical.target
- **Wants:** graphical.target


---

## 5. Recommendations

### Immediate Actions

1. **Consolidate Network Services**
   - Multiple services configure the same interface (eth0) and IP (192.168.10.2)
   - Recommend creating a single authoritative network service

2. **Resolve Network Manager Conflicts**
   - Multiple network managers detected (NetworkManager, systemd-networkd, dhcpcd)
   - Choose one primary manager and disable others

3. **Separate Connectivity Modes**
   - Create mode-based network configuration:
     - USB Gadget Mode (usb0, static IP)
     - Ethernet Static (eth0, static IP 192.168.10.2)
     - Ethernet DHCP (eth0, DHCP from Mac)
     - WiFi (wlan0, DHCP, lower priority)

4. **Fix Priority Conflicts**
   - WiFi and Ethernet have same priority in NetworkManager
   - Set Ethernet priority higher than WiFi

### Long-term Solutions

1. Implement unified network mode manager
2. Use Docker test suite to validate network configurations
3. Document each connectivity method clearly
4. Create runtime scripts to switch between modes

---

**Report Generated:** $(date '+%Y-%m-%d %H:%M:%S')
**Audit Script:** scripts/network/AUDIT_NETWORK_CONFIG.sh

