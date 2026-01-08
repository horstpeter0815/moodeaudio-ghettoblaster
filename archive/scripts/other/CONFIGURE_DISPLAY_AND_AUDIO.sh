#!/bin/bash
# ╔══════════════════════════════════════════════════════════════╗
# ║  🖥️  DISPLAY & AUDIO KONFIGURIEREN                          ║
# ╚══════════════════════════════════════════════════════════════╝

PI_IP="192.168.178.161"
MOODE_URL="http://$PI_IP"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🖥️  DISPLAY & AUDIO KONFIGURIEREN                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Prüfe Erreichbarkeit
echo "🔍 Prüfe Pi-Erreichbarkeit..."
if ! ping -c 1 -W 2 $PI_IP >/dev/null 2>&1; then
    echo "❌ Pi ist nicht erreichbar: $PI_IP"
    exit 1
fi
echo "✅ Pi ist online: $PI_IP"
echo ""

# Prüfe Web-UI
echo "🌐 Prüfe Web-UI..."
if ! curl -s -f "$MOODE_URL" >/dev/null 2>&1; then
    echo "❌ Web-UI ist nicht erreichbar"
    exit 1
fi
echo "✅ Web-UI ist erreichbar: $MOODE_URL"
echo ""

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  📋 MANUELLE KONFIGURATION ÜBER WEB-UI ERFORDERLICH          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "🌐 Öffne Web-UI: $MOODE_URL"
echo ""
echo "📋 SCHRITTE:"
echo ""
echo "1️⃣  DISPLAY ROTATION (Landscape):"
echo "   → Configure → System"
echo "   → Display Rotation: 0° (Landscape)"
echo "   → Save"
echo ""
echo "2️⃣  LOCAL DISPLAY AKTIVIEREN:"
echo "   → Configure → Peripherals"
echo "   → Local Display: ✅ Aktivieren"
echo "   → URL: http://localhost"
echo "   → Save"
echo ""
echo "3️⃣  AUDIO OUTPUT:"
echo "   → Configure → Audio"
echo "   → Output Device: HiFiBerry AMP100"
echo "   → Save"
echo ""
echo "4️⃣  SYSTEM NEUSTARTEN:"
echo "   → System → Restart"
echo "   → Warte 1-2 Minuten"
echo ""
echo "5️⃣  TEST:"
echo "   → Spiele etwas ab (Radio oder Musik)"
echo "   → Prüfe Display (sollte moOde-Interface zeigen)"
echo "   → Prüfe Audio (sollte aus Lautsprechern kommen)"
echo ""
echo "✅ Nach Neustart sollte alles funktionieren!"
echo ""

