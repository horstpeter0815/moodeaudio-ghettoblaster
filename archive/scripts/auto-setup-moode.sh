#!/bin/bash
################################################################################
# Automatisches moOde Setup
# Konfiguriert das System nach dem ersten Boot
################################################################################

PI_HOST="moode.local"
PI_IP="192.168.178.161"
PI_USER="pi"
PI_PASS="DSD"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 AUTOMATISCHES MOODE SETUP                                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Prüfe Verbindung
echo "🔍 Prüfe Verbindung..."
if ping -c 2 "$PI_HOST" >/dev/null 2>&1; then
    PI_TARGET="$PI_HOST"
elif ping -c 2 "$PI_IP" >/dev/null 2>&1; then
    PI_TARGET="$PI_IP"
else
    echo "❌ Pi nicht erreichbar"
    echo "   Warte bis System gebootet ist..."
    exit 1
fi

echo "✅ Pi erreichbar: $PI_TARGET"
echo ""

# Prüfe Web-UI
echo "🌐 Prüfe Web-UI..."
for i in {1..30}; do
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --connect-timeout 3 "http://$PI_TARGET" 2>/dev/null)
    if [ "$HTTP_CODE" = "200" ] || [ "$HTTP_CODE" = "302" ]; then
        echo "✅ Web-UI erreichbar"
        break
    fi
    echo "   Warte... ($i/30)"
    sleep 2
done

if [ "$HTTP_CODE" != "200" ] && [ "$HTTP_CODE" != "302" ]; then
    echo "⚠️  Web-UI noch nicht erreichbar"
    echo "   Versuche SSH..."
fi

# SSH Setup (falls verfügbar)
echo ""
echo "🔌 Versuche SSH-Setup..."
if sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_TARGET" "echo 'SSH OK'" >/dev/null 2>&1; then
    echo "✅ SSH verfügbar"
    echo ""
    echo "📋 Konfiguriere System..."
    
    # Audio-Output: HiFiBerry AMP100
    sshpass -p "$PI_PASS" ssh "$PI_USER@$PI_TARGET" "sudo moodeutl -a 'hifiberry-amp100'" 2>/dev/null
    
    # Display-Konfiguration (falls nötig)
    # Wird normalerweise über Web-UI gemacht
    
    echo "✅ Basis-Konfiguration durchgeführt"
else
    echo "⚠️  SSH noch nicht verfügbar"
    echo "   Setup muss über Web-UI durchgeführt werden"
fi

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  📋 NÄCHSTE SCHRITTE                                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "1. Web-UI öffnen: http://$PI_TARGET"
echo "2. Setup-Wizard durchführen:"
echo "   - Keyboard: Deutsch (oder deine Präferenz)"
echo "   - Country: Deutschland"
echo "   - Timezone: Europe/Berlin"
echo "3. Audio-Output: HiFiBerry AMP100"
echo "4. Display: 1280x400 (falls konfigurierbar)"
echo ""

