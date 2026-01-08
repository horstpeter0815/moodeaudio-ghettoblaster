#!/bin/bash
# Quick Boot Status Check

PI_IP="192.168.10.2"

echo "🔍 Schneller Boot-Status-Check"
echo ""

# Ping
if ping -c 1 -W 1 "$PI_IP" >/dev/null 2>&1; then
    echo "✅ Ping: ERFOLGREICH"
else
    echo "⏳ Ping: Noch nicht erreichbar"
fi

# SSH Port
if nc -z -w 1 "$PI_IP" 22 2>/dev/null; then
    echo "✅ SSH Port 22: OFFEN"
    echo ""
    echo "SSH-Verbindung möglich:"
    echo "  ssh andre@$PI_IP"
else
    echo "⏳ SSH Port 22: Noch geschlossen"
fi

echo ""
echo "📊 Monitoring-Log (letzte 10 Zeilen):"
tail -10 /tmp/boot_monitor.log 2>/dev/null || echo "Kein Log gefunden"

