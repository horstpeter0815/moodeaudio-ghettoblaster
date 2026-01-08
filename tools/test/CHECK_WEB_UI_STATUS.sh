#!/bin/bash
# Check Web UI Status and Help User Complete Setup

PI_IP="${1:-192.168.1.101}"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🌐 WEB UI STATUS CHECK                                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "Prüfe Web-UI: http://$PI_IP"
echo ""

# Check if web UI responds
HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 http://$PI_IP 2>/dev/null)

if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ Web-UI antwortet (HTTP $HTTP_CODE)"
    
    # Check what's being served
    CONTENT=$(curl -s http://$PI_IP 2>&1 | head -50)
    
    if echo "$CONTENT" | grep -qi "moode"; then
        echo "✅ moOde Web-UI erkannt"
        echo ""
        echo "📋 Nächste Schritte:"
        echo "   1. Öffne: http://$PI_IP"
        echo "   2. Logge dich ein (falls Login erforderlich)"
        echo "   3. Führe das FirstBoot-Setup durch"
    elif echo "$CONTENT" | grep -qi "login\|first.*boot\|setup"; then
        echo "⚠️  FirstBoot-Setup oder Login-Screen erkannt"
        echo ""
        echo "📋 Du musst:"
        echo "   1. Web-UI öffnen: http://$PI_IP"
        echo "   2. FirstBoot-Setup abschließen"
        echo "   3. Oder dich einloggen"
    else
        echo "⚠️  Web-UI antwortet, aber Inhalt unklar"
        echo ""
        echo "📋 Bitte manuell prüfen:"
        echo "   → http://$PI_IP"
    fi
else
    echo "❌ Web-UI nicht erreichbar (HTTP $HTTP_CODE)"
    echo ""
    echo "📋 Mögliche Ursachen:"
    echo "   - Pi bootet noch"
    echo "   - Web-Server läuft nicht"
    echo "   - Falsche IP-Adresse"
fi

echo ""
echo "🔗 Web-UI öffnen:"
echo "   open http://$PI_IP"
echo ""

