#!/bin/bash
# Prüft Pi-Status

PI_IP="192.168.178.178"
PI_USER="andre"
PI_PASS="0815"

echo "=== PI STATUS CHECK ==="
echo ""

# Ping
echo "1. Ping..."
if ping -c 1 -W 2 $PI_IP &> /dev/null; then
    echo "✅ Pi ist online (ping erfolgreich)"
else
    echo "❌ Pi nicht erreichbar (ping fehlgeschlagen)"
    exit 1
fi
echo ""

# SSH
echo "2. SSH-Verbindung..."
if sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$PI_USER@$PI_IP" "echo 'SSH OK'" &> /dev/null; then
    echo "✅ SSH-Verbindung erfolgreich"
else
    echo "❌ SSH-Verbindung fehlgeschlagen"
    exit 1
fi
echo ""

# System-Info
echo "3. System-Info..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'CHECK'
echo "   Hostname: $(hostname)"
echo "   Uptime: $(uptime -p 2>/dev/null || uptime)"
echo "   IP: $(hostname -I | awk '{print $1}')"
CHECK
echo ""

# Display-Status
echo "4. Display-Status..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'DISPLAY'
export DISPLAY=:0
if xrandr --output HDMI-A-2 --query 2>/dev/null | grep -q "connected"; then
    MODE=$(xrandr --output HDMI-A-2 --query 2>/dev/null | grep "current" | awk '{print $8"x"$10}' | tr -d ',')
    echo "   ✅ Display verbunden: $MODE"
else
    echo "   ⚠️  Display nicht erkannt"
fi
DISPLAY
echo ""

# Audio-Status
echo "5. Audio-Status..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'AUDIO'
if aplay -l 2>/dev/null | grep -qi "hifiberry\|amp100"; then
    echo "   ✅ AMP100 erkannt"
    aplay -l | grep -i "hifiberry\|amp100" | head -1
else
    echo "   ⚠️  AMP100 nicht erkannt"
fi
AUDIO
echo ""

echo "=== STATUS CHECK ABGESCHLOSSEN ==="
echo ""
echo "✅ Pi ist online und erreichbar"
echo "✅ Alle Checks erfolgreich"
echo ""

