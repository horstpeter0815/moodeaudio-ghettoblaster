#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  🚀 SCHNELL-SETUP & TEST                                    ║
# ╚══════════════════════════════════════════════════════════════╝

PI_IP="192.168.178.161"
MOODE_URL="http://$PI_IP"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🚀 SCHNELL-SETUP & TEST                                    ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Prüfe Erreichbarkeit
if ! ping -c 1 -W 2 $PI_IP >/dev/null 2>&1; then
    echo "❌ Pi ist nicht erreichbar: $PI_IP"
    exit 1
fi
echo "✅ Pi ist online: $PI_IP"
echo ""

# Setze Lautstärke
echo "🔊 Setze Lautstärke auf 50%..."
VOL_RESPONSE=$(curl -s "http://$PI_IP/command/?cmd=set_volume%2050")
echo "$VOL_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$VOL_RESPONSE"
echo ""

# Prüfe aktuelle Lautstärke
echo "🔊 Aktuelle Lautstärke:"
VOL_RESPONSE=$(curl -s "http://$PI_IP/command/?cmd=get_volume")
echo "$VOL_RESPONSE" | python3 -m json.tool 2>/dev/null || echo "$VOL_RESPONSE"
echo ""

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  📋 NÄCHSTE SCHRITTE FÜR DISPLAY & AUDIO                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "🌐 Öffne Web-UI: $MOODE_URL"
echo ""
echo "1️⃣  DISPLAY ROTATION:"
echo "   Configure → System → Display Rotation: 0°"
echo ""
echo "2️⃣  LOCAL DISPLAY:"
echo "   Configure → Peripherals → Local Display: ✅ Aktivieren"
echo ""
echo "3️⃣  AUDIO OUTPUT:"
echo "   Configure → Audio → Output Device: HiFiBerry AMP100"
echo ""
echo "4️⃣  RESTART:"
echo "   System → Restart"
echo ""
echo "5️⃣  TEST:"
echo "   → Spiele Radio oder Musik ab"
echo "   → Prüfe Display & Audio"
echo ""

