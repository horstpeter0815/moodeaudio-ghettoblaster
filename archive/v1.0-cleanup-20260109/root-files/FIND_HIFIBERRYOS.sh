#!/bin/bash
# Finde HiFiBerryOS im Netzwerk

echo "=== SUCHE HIFIBERRYOS IM NETZWERK ==="
echo ""

# Scanne Netzwerk nach HiFiBerryOS
echo "Scanne 192.168.178.0/24 nach HiFiBerryOS..."
echo ""

for ip in {1..254}; do
    IP="192.168.178.$ip"
    echo -n "Prüfe $IP... "
    
    # Prüfe ob Port 22 (SSH) offen ist
    if timeout 1 bash -c "echo > /dev/tcp/$IP/22" 2>/dev/null; then
        # Versuche SSH-Verbindung mit root/hifiberry
        if sshpass -p "hifiberry" ssh -o ConnectTimeout=2 -o StrictHostKeyChecking=no root@"$IP" "hostname" 2>/dev/null | grep -qi "hifiberry\|raspberry"; then
            echo "✅ HiFiBerryOS gefunden!"
            echo "   IP: $IP"
            echo "   User: root"
            echo "   Pass: hifiberry"
            echo ""
            echo "Verwende diese IP in HIFIBERRYOS_TO_MOODE.sh"
            exit 0
        fi
    fi
    echo "❌"
done

echo ""
echo "⚠️  HiFiBerryOS nicht im Netzwerk gefunden"
echo "   Mögliche Gründe:"
echo "   - System ist offline"
echo "   - IP-Adresse ist anders"
echo "   - SSH ist deaktiviert"
echo ""
echo "   Manuell prüfen:"
echo "   - Router-Interface checken"
echo "   - Display auf Pi checken (zeigt IP an)"

