#!/bin/bash
# Systematisches Debug-Script - Findet die echte Ursache

set -e

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 SYSTEMATISCHES DEBUG - ECHTE URACHE FINDEN             ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Prüfe ob Pi online ist
PI_IP=""
if ping -c 1 -W 1 192.168.10.2 >/dev/null 2>&1; then
    PI_IP="192.168.10.2"
elif ping -c 1 -W 1 192.168.1.101 >/dev/null 2>&1; then
    PI_IP="192.168.1.101"
fi

if [ -z "$PI_IP" ]; then
    echo "❌ Pi ist nicht online"
    echo "   Bitte Pi booten und warten bis er online ist"
    exit 1
fi

echo "✅ Pi ist online: $PI_IP"
echo ""

# Prüfe SSH
echo "⏳ Prüfe SSH..."
for i in {1..30}; do
    if sshpass -p "0815" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 andre@$PI_IP "echo 'SSH OK'" >/dev/null 2>&1; then
        echo "✅ SSH funktioniert"
        break
    fi
    if [ $i -eq 30 ]; then
        echo "❌ SSH nicht verfügbar nach 60 Sekunden"
        exit 1
    fi
    sleep 2
done

echo ""
echo "📋 SYSTEMATISCHE PRÜFUNG:"
echo ""

# 1. Boot-Zeit
echo "1. Boot-Zeit:"
sshpass -p "0815" ssh -o StrictHostKeyChecking=no andre@$PI_IP "uptime" 2>/dev/null || echo "  Kann nicht abgerufen werden"

# 2. Services die blockieren könnten
echo ""
echo "2. Services die blockieren könnten:"
sshpass -p "0815" ssh -o StrictHostKeyChecking=no andre@$PI_IP "systemctl list-units --type=service --state=failed | head -10" 2>/dev/null || echo "  Keine fehlgeschlagenen Services"

# 3. fix-ssh-service Status
echo ""
echo "3. fix-ssh-service Status:"
sshpass -p "0815" ssh -o StrictHostKeyChecking=no andre@$PI_IP "systemctl status fix-ssh-service.service --no-pager 2>&1 | head -10" 2>/dev/null || echo "  Service nicht gefunden oder nicht aktiv"

# 4. Display-Services
echo ""
echo "4. Display-Services:"
sshpass -p "0815" ssh -o StrictHostKeyChecking=no andre@$PI_IP "systemctl list-units --type=service | grep -E 'display|chromium|xserver|localdisplay' | head -10" 2>/dev/null || echo "  Keine Display-Services gefunden"

# 5. X Server
echo ""
echo "5. X Server Status:"
sshpass -p "0815" ssh -o StrictHostKeyChecking=no andre@$PI_IP "ps aux | grep -E '[X]org|[X]vfb' | head -3" 2>/dev/null || echo "  X Server läuft nicht"

# 6. Chromium
echo ""
echo "6. Chromium Status:"
sshpass -p "0815" ssh -o StrictHostKeyChecking=no andre@$PI_IP "ps aux | grep -i chromium | head -3" 2>/dev/null || echo "  Chromium läuft nicht"

# 7. Boot-Logs (letzte 50 Zeilen)
echo ""
echo "7. Boot-Logs (letzte Fehler):"
sshpass -p "0815" ssh -o StrictHostKeyChecking=no andre@$PI_IP "journalctl -b --no-pager | tail -50 | grep -iE 'error|fail|block|timeout|fix-ssh' | head -20" 2>/dev/null || echo "  Keine relevanten Fehler gefunden"

# 8. Systemd Dependencies
echo ""
echo "8. Was blockiert multi-user.target?"
sshpass -p "0815" ssh -o StrictHostKeyChecking=no andre@$PI_IP "systemctl list-dependencies multi-user.target --reverse --no-pager | grep -E 'fix-ssh|moode-startup' | head -10" 2>/dev/null || echo "  Keine Blockierungen gefunden"

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ DEBUG ABGESCHLOSSEN                                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "📋 Analysiere die Ausgabe oben um die echte Ursache zu finden"
echo ""

