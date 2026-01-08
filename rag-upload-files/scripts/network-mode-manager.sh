#!/bin/bash
################################################################################
#
# NETWORK MODE MANAGER
#
# Unified network configuration manager that selects the appropriate
# connectivity mode based on available interfaces and configuration.
#
# Modes:
# 1. USB Gadget (usb0) - Static IP 192.168.10.2
# 2. Ethernet Static (eth0) - Static IP 192.168.10.2, Gateway 192.168.10.1
# 3. Ethernet DHCP (eth0) - DHCP from Mac Internet Sharing
# 4. WiFi (wlan0) - DHCP, lower priority than Ethernet
#
################################################################################

set -e

LOG_FILE="/var/log/network-mode-manager.log"
DEBUG_LOG="/boot/firmware/network-debug.log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
    # Also write to boot partition (persistent)
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$DEBUG_LOG" 2>/dev/null || true
}

log "=== NETWORK MODE MANAGER START ==="

################################################################################
# DETECT AVAILABLE INTERFACES
################################################################################

log "Detecting available interfaces..."

INTERFACES=()

# Check for USB gadget interface
if [ -d /sys/class/net/usb0 ] && ip link show usb0 >/dev/null 2>&1; then
    INTERFACES+=("usb0")
    log "Found USB gadget interface (usb0)"
fi

# Check for Ethernet interface
if [ -d /sys/class/net/eth0 ] && ip link show eth0 >/dev/null 2>&1; then
    INTERFACES+=("eth0")
    log "Found Ethernet interface (eth0)"
    # #region agent log
    ETH0_EXISTS=$(test -d /sys/class/net/eth0 && echo "true" || echo "false")
    ETH0_LINK=$(ip link show eth0 2>/dev/null | head -1 || echo "none")
    echo "{\"id\":\"log_$(date +%s)_eth0_detect\",\"timestamp\":$(date +%s000),\"location\":\"network-mode-manager.sh:42\",\"message\":\"eth0 interface detection\",\"data\":{\"exists\":\"$ETH0_EXISTS\",\"link_info\":\"$ETH0_LINK\"},\"sessionId\":\"debug-session\",\"runId\":\"run1\",\"hypothesisId\":\"C\"}" >> /tmp/network-debug.log 2>/dev/null || true
    # #endregion
fi

# Check for WiFi interface
if [ -d /sys/class/net/wlan0 ] && ip link show wlan0 >/dev/null 2>&1; then
    INTERFACES+=("wlan0")
    log "Found WiFi interface (wlan0)"
fi

log "Available interfaces: ${INTERFACES[*]}"

################################################################################
# DETERMINE NETWORK MODE
################################################################################

MODE=""
ACTIVE_INTERFACE=""

# Priority 1: USB Gadget Mode (highest priority)
if [[ " ${INTERFACES[@]} " =~ " usb0 " ]]; then
    MODE="usb-gadget"
    ACTIVE_INTERFACE="usb0"
    log "Selected mode: USB Gadget (usb0)"
    
# Priority 2: Ethernet (check for static or DHCP)
elif [[ " ${INTERFACES[@]} " =~ " eth0 " ]]; then
    # Check if Ethernet should use static IP or DHCP
    # Check for mode indicator file
    if [ -f /boot/firmware/network-mode ]; then
        CONFIGURED_MODE=$(cat /boot/firmware/network-mode | tr -d '[:space:]')
        if [ "$CONFIGURED_MODE" = "ethernet-dhcp" ]; then
            MODE="ethernet-dhcp"
            ACTIVE_INTERFACE="eth0"
            log "Selected mode: Ethernet DHCP (configured via /boot/firmware/network-mode)"
        else
            MODE="ethernet-static"
            ACTIVE_INTERFACE="eth0"
            log "Selected mode: Ethernet Static (default for direct Mac connection)"
        fi
else
    # Default to static IP for Ethernet (direct Mac connection)
    MODE="ethernet-static"
    ACTIVE_INTERFACE="eth0"
    log "Selected mode: Ethernet Static (default)"
    # #region agent log
    echo "{\"id\":\"log_$(date +%s)_mode_selected\",\"timestamp\":$(date +%s000),\"location\":\"network-mode-manager.sh:87\",\"message\":\"Network mode selected\",\"data\":{\"mode\":\"$MODE\",\"interface\":\"$ACTIVE_INTERFACE\",\"reason\":\"default\"},\"sessionId\":\"debug-session\",\"runId\":\"run1\",\"hypothesisId\":\"A\"}" >> /tmp/network-debug.log 2>/dev/null || true
    # #endregion
fi
    
# Priority 3: WiFi (lowest priority)
elif [[ " ${INTERFACES[@]} " =~ " wlan0 " ]]; then
    MODE="wifi"
    ACTIVE_INTERFACE="wlan0"
    log "Selected mode: WiFi"
    
else
    log "⚠️  No network interfaces found"
    exit 1
fi

log "Active interface: $ACTIVE_INTERFACE"
log "Network mode: $MODE"

################################################################################
# CONFIGURE SELECTED MODE
################################################################################

log "Configuring network mode: $MODE"

case "$MODE" in
    "usb-gadget")
        log "Configuring USB gadget mode (usb0)..."
        
        # Bring up interface
        ip link set usb0 up || true
        
        # Configure static IP
        ip addr flush dev usb0 2>/dev/null || true
        ip addr add 192.168.10.2/24 dev usb0 || true
        
        # Verify configuration
        if ip addr show usb0 | grep -q "192.168.10.2"; then
            log "✅ USB gadget configured: 192.168.10.2/24"
        else
            log "⚠️  Failed to configure USB gadget IP"
        fi
        ;;
        
    "ethernet-static")
        log "Configuring Ethernet static mode (eth0)..."
        
        # #region agent log
        echo "{\"id\":\"log_$(date +%s)_eth_static_start\",\"timestamp\":$(date +%s000),\"location\":\"network-mode-manager.sh:129\",\"message\":\"Ethernet static mode start\",\"data\":{\"mode\":\"ethernet-static\",\"interface\":\"eth0\"},\"sessionId\":\"debug-session\",\"runId\":\"run1\",\"hypothesisId\":\"A\"}" >> "$DEBUG_LOG" 2>/dev/null || true
        # #endregion
        
        # Bring up interface
        ip link set eth0 up || true
        
        # #region agent log
        ETH0_STATE=$(ip link show eth0 2>/dev/null | grep -oP 'state \K\S+' || echo "unknown")
        echo "{\"id\":\"log_$(date +%s)_eth0_up\",\"timestamp\":$(date +%s000),\"location\":\"network-mode-manager.sh:133\",\"message\":\"eth0 interface state after up\",\"data\":{\"state\":\"$ETH0_STATE\"},\"sessionId\":\"debug-session\",\"runId\":\"run1\",\"hypothesisId\":\"C\"}" >> "$DEBUG_LOG" 2>/dev/null || true
        # #endregion
        
        # Configure static IP
        ip addr flush dev eth0 2>/dev/null || true
        ip addr add 192.168.10.2/24 dev eth0 || true
        
        # #region agent log
        ETH0_IP=$(ip addr show eth0 2>/dev/null | grep "inet " | awk '{print $2}' || echo "none")
        echo "{\"id\":\"log_$(date +%s)_eth0_ip\",\"timestamp\":$(date +%s000),\"location\":\"network-mode-manager.sh:137\",\"message\":\"IP after static config\",\"data\":{\"ip\":\"$ETH0_IP\",\"expected\":\"192.168.10.2/24\"},\"sessionId\":\"debug-session\",\"runId\":\"run1\",\"hypothesisId\":\"A\"}" >> /tmp/network-debug.log 2>/dev/null || true
        # #endregion
        
        # Set default route
        ip route del default 2>/dev/null || true
        ip route add default via 192.168.10.1 dev eth0 2>/dev/null || true
        
        # Configure DNS
        echo "nameserver 192.168.10.1" > /etc/resolv.conf 2>/dev/null || true
        echo "nameserver 8.8.8.8" >> /etc/resolv.conf 2>/dev/null || true
        
        # Verify configuration
        if ip addr show eth0 | grep -q "192.168.10.2"; then
            log "✅ Ethernet static configured: 192.168.10.2/24, gateway 192.168.10.1"
            # #region agent log
            echo "{\"id\":\"log_$(date +%s)_eth_static_success\",\"timestamp\":$(date +%s000),\"location\":\"network-mode-manager.sh:148\",\"message\":\"Ethernet static config success\",\"data\":{\"ip\":\"192.168.10.2\"},\"sessionId\":\"debug-session\",\"runId\":\"run1\",\"hypothesisId\":\"A\"}" >> /tmp/network-debug.log 2>/dev/null || true
            # #endregion
        else
            log "⚠️  Failed to configure Ethernet static IP"
            # #region agent log
            echo "{\"id\":\"log_$(date +%s)_eth_static_fail\",\"timestamp\":$(date +%s000),\"location\":\"network-mode-manager.sh:151\",\"message\":\"Ethernet static config failed\",\"data\":{\"actual_ip\":\"$ETH0_IP\"},\"sessionId\":\"debug-session\",\"runId\":\"run1\",\"hypothesisId\":\"A\"}" >> /tmp/network-debug.log 2>/dev/null || true
            # #endregion
        fi
        ;;
        
    "ethernet-dhcp")
        log "Configuring Ethernet DHCP mode (eth0)..."
        
        # Bring up interface
        ip link set eth0 up || true
        
        # Flush any existing IP configuration
        ip addr flush dev eth0 2>/dev/null || true
        
        # Try DHCP clients in order
        DHCP_SUCCESS=false
        
        # Try dhclient first (common on Debian-based systems)
        if command -v dhclient >/dev/null 2>&1; then
            log "Attempting DHCP with dhclient..."
            if timeout 10 dhclient -v eth0 2>&1 | tee -a "$LOG_FILE"; then
                DHCP_SUCCESS=true
                log "✅ DHCP configured via dhclient"
            fi
        fi
        
        # Try dhcpcd if dhclient failed
        if [ "$DHCP_SUCCESS" = false ] && command -v dhcpcd >/dev/null 2>&1; then
            log "Attempting DHCP with dhcpcd..."
            if timeout 10 dhcpcd eth0 2>&1 | tee -a "$LOG_FILE"; then
                DHCP_SUCCESS=true
                log "✅ DHCP configured via dhcpcd"
            fi
        fi
        
        # Fallback to NetworkManager if available
        if [ "$DHCP_SUCCESS" = false ] && command -v nmcli >/dev/null 2>&1; then
            log "Attempting DHCP with NetworkManager..."
            nmcli connection up "Ethernet" 2>&1 | tee -a "$LOG_FILE" || true
            sleep 3
            if ip addr show eth0 | grep -q "inet "; then
                DHCP_SUCCESS=true
                log "✅ DHCP configured via NetworkManager"
            fi
        fi
        
        if [ "$DHCP_SUCCESS" = false ]; then
            log "⚠️  Failed to obtain DHCP lease"
        fi
        
        # Show obtained IP
        OBTAINED_IP=$(ip addr show eth0 | grep "inet " | awk '{print $2}' | head -1 || echo "none")
        log "Ethernet IP: $OBTAINED_IP"
        ;;
        
    "wifi")
        log "Configuring WiFi mode (wlan0)..."
        
        # WiFi should be configured via wpa_supplicant or NetworkManager
        # Just ensure interface is up
        ip link set wlan0 up || true
        
        # Wait a bit for WiFi to connect
        sleep 5
        
        # Show WiFi IP if connected
        WIFI_IP=$(ip addr show wlan0 | grep "inet " | awk '{print $2}' | head -1 || echo "none")
        if [ "$WIFI_IP" != "none" ]; then
            log "✅ WiFi connected: $WIFI_IP"
        else
            log "⚠️  WiFi interface up but no IP assigned yet"
        fi
        ;;
        
    *)
        log "❌ Unknown network mode: $MODE"
        exit 1
        ;;
esac

################################################################################
# DISABLE CONFLICTING SERVICES
################################################################################

log "Disabling conflicting network services..."

# Disable old static IP services (they conflict with mode manager)
systemctl stop 02-eth0-configure.service 2>/dev/null || true
systemctl disable 02-eth0-configure.service 2>/dev/null || true
systemctl stop 03-network-configure.service 2>/dev/null || true
systemctl disable 03-network-configure.service 2>/dev/null || true
systemctl stop 04-network-lan.service 2>/dev/null || true
systemctl disable 04-network-lan.service 2>/dev/null || true

# Only disable 00-boot-network-ssh if it's not the unified boot service
if systemctl list-unit-files | grep -q "00-boot-network-ssh.service"; then
    if [ -f /lib/systemd/system/00-unified-boot.service ]; then
        log "Disabling 00-boot-network-ssh.service (replaced by 00-unified-boot.service)"
        systemctl stop 00-boot-network-ssh.service 2>/dev/null || true
        systemctl disable 00-boot-network-ssh.service 2>/dev/null || true
    fi
fi

log "✅ Conflicting services disabled"

################################################################################
# CONFIGURE NETWORKMANAGER (if mode is DHCP or WiFi)
################################################################################

# #region agent log
NM_STATUS=$(systemctl is-active NetworkManager 2>/dev/null || echo "unknown")
NM_ENABLED=$(systemctl is-enabled NetworkManager 2>/dev/null || echo "unknown")
echo "{\"id\":\"log_$(date +%s)_nm_status\",\"timestamp\":$(date +%s000),\"location\":\"network-mode-manager.sh:259\",\"message\":\"NetworkManager status before config\",\"data\":{\"status\":\"$NM_STATUS\",\"enabled\":\"$NM_ENABLED\",\"mode\":\"$MODE\"},\"sessionId\":\"debug-session\",\"runId\":\"run1\",\"hypothesisId\":\"B\"}" >> /tmp/network-debug.log 2>/dev/null || true
# #endregion

if [ "$MODE" = "ethernet-dhcp" ] || [ "$MODE" = "wifi" ]; then
    log "Configuring NetworkManager for $MODE mode..."
    
    if command -v nmcli >/dev/null 2>&1; then
        # Ensure NetworkManager is running
        systemctl start NetworkManager 2>/dev/null || true
        systemctl enable NetworkManager 2>/dev/null || true
        # #region agent log
        echo "{\"id\":\"log_$(date +%s)_nm_started\",\"timestamp\":$(date +%s000),\"location\":\"network-mode-manager.sh:264\",\"message\":\"NetworkManager started\",\"data\":{\"mode\":\"$MODE\"},\"sessionId\":\"debug-session\",\"runId\":\"run1\",\"hypothesisId\":\"B\"}" >> /tmp/network-debug.log 2>/dev/null || true
        # #endregion
        
        if [ "$MODE" = "ethernet-dhcp" ]; then
            # Set Ethernet to DHCP with highest priority
            if nmcli connection show "Ethernet" >/dev/null 2>&1; then
                nmcli connection modify "Ethernet" ipv4.method auto 2>/dev/null || true
                nmcli connection modify "Ethernet" autoconnect-priority 200 2>/dev/null || true
                nmcli connection up "Ethernet" 2>/dev/null || true
                log "✅ NetworkManager Ethernet configured for DHCP"
            fi
            
            # Disable WiFi autoconnect
            nmcli connection show | grep -i wifi | awk '{print $1}' | while read conn; do
                nmcli connection modify "$conn" autoconnect false 2>/dev/null || true
                nmcli connection modify "$conn" autoconnect-priority 0 2>/dev/null || true
            done
        fi
    fi
fi

log "=== NETWORK MODE MANAGER END ==="
log "Final configuration: Mode=$MODE, Interface=$ACTIVE_INTERFACE"

# Show final network status
log "Network status:"
ip addr show "$ACTIVE_INTERFACE" | grep -E "inet |state" | tee -a "$LOG_FILE" || true

exit 0



