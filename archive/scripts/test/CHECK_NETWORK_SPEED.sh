#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  📊 NETZWERK-GESCHWINDIGKEIT PRÜFEN                         ║
# ╚══════════════════════════════════════════════════════════════╝

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  📊 NETZWERK-STATUS                                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Aktive Verbindung
DEFAULT_IF=$(route get default 2>/dev/null | grep interface | awk '{print $2}')
echo "🌐 Aktive Verbindung: $DEFAULT_IF"

# Verbindungstyp
if echo "$DEFAULT_IF" | grep -q "en0"; then
    echo "   Typ: Wi-Fi"
elif echo "$DEFAULT_IF" | grep -q "en[4-9]"; then
    echo "   Typ: Ethernet ✅"
else
    echo "   Typ: Unbekannt"
fi

echo ""

# IP-Adresse
IP=$(ifconfig "$DEFAULT_IF" 2>/dev/null | grep "inet " | awk '{print $2}')
if [ -n "$IP" ]; then
    echo "📍 IP-Adresse: $IP"
else
    echo "⚠️  Keine IP-Adresse gefunden"
fi

echo ""

# Ethernet-Status
echo "🔌 Ethernet-Adapter:"
for eth in en4 en5 en6; do
    STATUS=$(ifconfig "$eth" 2>/dev/null | grep "status:" | awk '{print $2}')
    if [ -n "$STATUS" ]; then
        if [ "$STATUS" = "active" ]; then
            IP=$(ifconfig "$eth" 2>/dev/null | grep "inet " | awk '{print $2}')
            echo "   $eth: ✅ Aktiv ($IP)"
        else
            echo "   $eth: ❌ Inaktiv"
        fi
    fi
done

echo ""

# Docker Container Netzwerk
echo "🐳 Docker Container Netzwerk:"
if docker ps | grep -q moode-builder; then
    echo "   ✅ Container läuft"
    echo "   📡 Nutzt: Host-Netzwerk (network_mode: host)"
    echo "   → Verwendet automatisch beste Verbindung"
    
    # Test im Container
    echo ""
    echo "🧪 Teste Verbindung im Container..."
    if docker exec moode-builder ping -c 2 8.8.8.8 >/dev/null 2>&1; then
        PING_TIME=$(docker exec moode-builder ping -c 2 8.8.8.8 2>/dev/null | grep "time=" | tail -1 | awk -F'time=' '{print $2}' | awk '{print $1}')
        echo "   ✅ Internet erreichbar (Ping: ${PING_TIME}ms)"
    else
        echo "   ❌ Internet nicht erreichbar"
    fi
else
    echo "   ⚠️  Container nicht gefunden"
fi

echo ""
echo "💡 Tipp: Ethernet-Kabel anschließen für schnellere Downloads!"

