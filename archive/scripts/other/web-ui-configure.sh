#!/bin/bash
# Konfiguration über Web-UI API

PI_IP="192.168.178.161"

echo "🔧 Konfiguration über Web-UI API..."

# Prüfe verfügbare Audio-Geräte über API
echo "🔍 Prüfe verfügbare Audio-Geräte..."
curl -s "http://$PI_IP/command/snd-config.php" 2>/dev/null | grep -i "hifiberry\|amp100" | head -5

# Versuche Audio-Output zu setzen
echo ""
echo "🔊 Setze Audio-Output..."
# Die genaue API-Struktur muss noch ermittelt werden

echo ""
echo "✅ Konfiguration versucht"
echo ""
echo "📋 Bitte manuell in Web-UI prüfen:"
echo "   http://$PI_IP"
echo "   → Audio Settings → Output Device"
