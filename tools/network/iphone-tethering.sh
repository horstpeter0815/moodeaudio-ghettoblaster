#!/bin/bash
################################################################################
#
# IPHONE TETHERING HELPER
# 
# Hilft beim Einrichten und Nutzen von iPhone Mobile Data
#
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[TETHERING]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

################################################################################
# CHECK FUNCTIONS
################################################################################

check_iphone_connected() {
    info "Prüfe iPhone-Verbindung..."
    
    # Check USB connection
    if system_profiler SPUSBDataType 2>/dev/null | grep -i "iphone\|ipad" >/dev/null; then
        log "✅ iPhone per USB verbunden"
        return 0
    fi
    
    # Check network interfaces
    if ifconfig | grep -E "en[0-9]+" | grep -i "iphone\|usb" >/dev/null; then
        log "✅ iPhone-Netzwerk-Interface gefunden"
        return 0
    fi
    
    # Check for iPhone hotspot in network services
    if networksetup -listallnetworkservices 2>/dev/null | grep -i "iphone\|personal" >/dev/null; then
        log "✅ iPhone Personal Hotspot gefunden"
        return 0
    fi
    
    warn "⚠️  iPhone nicht erkannt"
    return 1
}

check_tethering_active() {
    info "Prüfe ob Tethering aktiv ist..."
    
    # Get default route
    local default_route=$(route -n get default 2>/dev/null | grep interface | awk '{print $2}')
    
    if [ -z "$default_route" ]; then
        default_route=$(netstat -rn | grep default | head -1 | awk '{print $6}')
    fi
    
    if [ -n "$default_route" ]; then
        info "Aktuelle Standard-Route: $default_route"
        
        # Check if it's iPhone-related
        if echo "$default_route" | grep -E "en[0-9]+" >/dev/null; then
            local interface_info=$(ifconfig "$default_route" 2>/dev/null)
            if echo "$interface_info" | grep -i "iphone\|usb" >/dev/null; then
                log "✅ iPhone Tethering ist aktiv (Interface: $default_route)"
                return 0
            fi
        fi
    fi
    
    warn "⚠️  iPhone Tethering scheint nicht aktiv zu sein"
    return 1
}

show_network_status() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  📡 NETWORK STATUS                                           ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    
    # Default route
    local default_route=$(route -n get default 2>/dev/null | grep interface | awk '{print $2}')
    if [ -z "$default_route" ]; then
        default_route=$(netstat -rn | grep default | head -1 | awk '{print $6}')
    fi
    
    if [ -n "$default_route" ]; then
        info "Standard-Route: $default_route"
        
        # Get IP
        local ip=$(ifconfig "$default_route" 2>/dev/null | grep "inet " | awk '{print $2}' | head -1)
        if [ -n "$ip" ]; then
            info "IP-Adresse: $ip"
        fi
        
        # Get gateway
        local gateway=$(route -n get default 2>/dev/null | grep gateway | awk '{print $2}')
        if [ -z "$gateway" ]; then
            gateway=$(netstat -rn | grep default | head -1 | awk '{print $2}')
        fi
        if [ -n "$gateway" ]; then
            info "Gateway: $gateway"
        fi
    else
        warn "Keine Standard-Route gefunden"
    fi
    
    echo ""
    info "Verfügbare Netzwerk-Interfaces:"
    ifconfig | grep -E "^[a-z]" | awk '{print $1}' | sed 's/:$//' | while read interface; do
        local status=$(ifconfig "$interface" 2>/dev/null | grep "status:" | awk '{print $2}' || echo "unknown")
        local ip=$(ifconfig "$interface" 2>/dev/null | grep "inet " | awk '{print $2}' | head -1 || echo "no IP")
        echo "  - $interface: $status ($ip)"
    done
}

################################################################################
# SETUP FUNCTIONS
################################################################################

show_setup_instructions() {
    echo ""
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  📱 IPHONE TETHERING SETUP                                    ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Um iPhone Mobile Data zu nutzen:"
    echo ""
    echo "1. Auf iPhone:"
    echo "   Einstellungen → Persönlicher Hotspot → Aktivieren"
    echo "   Oder: Einstellungen → Persönlicher Hotspot → USB aktivieren"
    echo ""
    echo "2. USB-Verbindung:"
    echo "   - iPhone per USB mit Mac verbinden"
    echo "   - 'Diesem Computer vertrauen' bestätigen"
    echo "   - macOS sollte automatisch iPhone-Netzwerk erkennen"
    echo ""
    echo "3. WiFi-Hotspot:"
    echo "   - iPhone Hotspot aktivieren"
    echo "   - Auf Mac: WiFi → iPhone Hotspot verbinden"
    echo ""
    echo "4. Bluetooth-Tethering:"
    echo "   - iPhone und Mac per Bluetooth koppeln"
    echo "   - iPhone Hotspot über Bluetooth aktivieren"
    echo ""
    echo "5. Prüfen:"
    echo "   Systemeinstellungen → Netzwerk"
    echo "   → iPhone sollte als Netzwerk-Interface erscheinen"
    echo ""
}

test_connection() {
    info "Teste Internet-Verbindung..."
    
    if ping -c 2 -W 2 8.8.8.8 >/dev/null 2>&1; then
        log "✅ Internet-Verbindung funktioniert"
        
        # Test speed (simple)
        info "Teste Geschwindigkeit (einfacher Test)..."
        local start_time=$(date +%s)
        if curl -s --max-time 5 https://www.google.com >/dev/null 2>&1; then
            local end_time=$(date +%s)
            local duration=$((end_time - start_time))
            info "Google erreichbar in ${duration}s"
        fi
        return 0
    else
        error "❌ Keine Internet-Verbindung"
        return 1
    fi
}

################################################################################
# MAIN
################################################################################

main() {
    case "${1:-}" in
        check|status)
            check_iphone_connected
            check_tethering_active
            show_network_status
            ;;
        setup|instructions)
            show_setup_instructions
            ;;
        test)
            test_connection
            ;;
        *)
            echo "iPhone Tethering Helper"
            echo ""
            echo "Usage: $0 <command>"
            echo ""
            echo "Commands:"
            echo "  check        - Prüfe iPhone-Verbindung und Status"
            echo "  setup        - Zeige Setup-Anleitung"
            echo "  test         - Teste Internet-Verbindung"
            echo ""
            echo "Quick check:"
            check_iphone_connected || true
            check_tethering_active || true
            show_network_status
            ;;
    esac
}

main "$@"

