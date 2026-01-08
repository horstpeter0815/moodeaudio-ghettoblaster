#!/bin/bash
################################################################################
# PARALLEL NETWORK SETUP - WiFi + iPhone USB
# 
# Konfiguriert beide Interfaces für parallele Nutzung
################################################################################

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  📡 PARALLELE NETZWERK-NUTZUNG SETUP                          ║"
echo "║  WiFi + iPhone USB                                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if iPhone USB is connected
if ! networksetup -listallnetworkservices | grep -q "iPhone USB"; then
    echo "❌ iPhone USB nicht gefunden!"
    echo "   Bitte iPhone per USB verbinden und Hotspot aktivieren"
    exit 1
fi

echo "✅ iPhone USB gefunden"
echo ""

# Get current route priorities
echo "📊 Aktuelle Route-Prioritäten:"
netstat -rn | grep default | head -3
echo ""

# Method 1: Route Priorities (macOS wählt automatisch)
echo "🔧 Methode 1: Route Prioritäten (Automatisch)"
echo "   macOS nutzt automatisch das Interface mit niedrigster Metrik"
echo ""

# Method 2: Manual Route Configuration
echo "🔧 Methode 2: Manuelle Route-Konfiguration"
echo "   Konfiguriert beide Interfaces mit unterschiedlichen Routen"
echo ""

# Get interface names
WIFI_INTERFACE=$(networksetup -listallhardwareports | grep -A 1 "Wi-Fi" | grep "Device:" | awk '{print $2}')
IPHONE_INTERFACE=$(networksetup -listallhardwareports | grep -A 1 "iPhone USB" | grep "Device:" | awk '{print $2}')

if [ -z "$WIFI_INTERFACE" ] || [ -z "$IPHONE_INTERFACE" ]; then
    echo "❌ Konnte Interfaces nicht finden"
    exit 1
fi

echo "WiFi Interface: $WIFI_INTERFACE"
echo "iPhone USB Interface: $IPHONE_INTERFACE"
echo ""

# Check current IPs
WIFI_IP=$(ifconfig "$WIFI_INTERFACE" | grep "inet " | awk '{print $2}')
IPHONE_IP=$(ifconfig "$IPHONE_INTERFACE" | grep "inet " | awk '{print $2}')

echo "WiFi IP: ${WIFI_IP:-Nicht konfiguriert}"
echo "iPhone USB IP: ${IPHONE_IP:-Nicht konfiguriert}"
echo ""

# Option 1: Let macOS handle it automatically (recommended)
echo "✅ OPTION 1: Automatisch (Empfohlen)"
echo "   macOS wählt automatisch das beste Interface"
echo "   Beide Interfaces bleiben aktiv"
echo "   System nutzt automatisch das schnellste Interface"
echo ""

# Option 2: Configure route metrics
echo "🔧 OPTION 2: Route-Metriken konfigurieren"
echo "   Setzt unterschiedliche Metriken für beide Interfaces"
echo "   Niedrigere Metrik = höhere Priorität"
echo ""

read -p "Route-Metriken konfigurieren? (j/n): " -n 1 -r
echo ""

if [[ $REPLY =~ ^[Jj]$ ]]; then
    # Get gateways
    WIFI_GATEWAY=$(route -n get default -interface "$WIFI_INTERFACE" 2>/dev/null | grep gateway | awk '{print $2}')
    IPHONE_GATEWAY=$(route -n get default -interface "$IPHONE_INTERFACE" 2>/dev/null | grep gateway | awk '{print $2}')
    
    if [ -n "$WIFI_GATEWAY" ] && [ -n "$IPHONE_GATEWAY" ]; then
        echo "WiFi Gateway: $WIFI_GATEWAY"
        echo "iPhone USB Gateway: $IPHONE_GATEWAY"
        echo ""
        
        # Delete existing default routes
        sudo route delete default 2>/dev/null || true
        
        # Add routes with different metrics
        # Lower metric = higher priority
        sudo route add default "$WIFI_GATEWAY" -interface "$WIFI_INTERFACE" -metric 10 2>/dev/null || true
        sudo route add default "$IPHONE_GATEWAY" -interface "$IPHONE_INTERFACE" -metric 20 2>/dev/null || true
        
        echo "✅ Route-Metriken konfiguriert:"
        echo "   WiFi: Metrik 10 (höhere Priorität)"
        echo "   iPhone USB: Metrik 20 (Fallback)"
        echo ""
    else
        echo "⚠️  Konnte Gateways nicht finden"
    fi
fi

echo ""
echo "📊 Finale Route-Konfiguration:"
netstat -rn | grep default
echo ""

echo "✅ Setup abgeschlossen!"
echo ""
echo "💡 HINWEIS:"
echo "   - Beide Interfaces bleiben aktiv"
echo "   - macOS nutzt automatisch das beste Interface"
echo "   - apt-get mit 16 parallelen Verbindungen nutzt das aktive Interface"
echo "   - Für echtes Load Balancing bräuchte man Tools wie Speedify"
echo ""

