#!/bin/bash
# Monitor Boot Process - Überwacht Pi-Boot kontinuierlich

set -e

PI_IP="192.168.10.2"
PI_USER="andre"
PI_PASS="0815"
MAX_WAIT=300  # Max 5 Minuten warten

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔍 BOOT-PROZESS ÜBERWACHEN                                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""
echo "Pi IP: $PI_IP"
echo "User: $PI_USER"
echo "Max Wartezeit: ${MAX_WAIT} Sekunden (5 Minuten)"
echo ""
echo "⏳ Warte auf Pi-Boot..."
echo ""

START_TIME=$(date +%s)
LAST_PING_TIME=0
BOOT_COMPLETE=false

# Funktion: Prüfe Pi-Erreichbarkeit
check_pi() {
    local ping_result=$(ping -c 1 -W 1 "$PI_IP" 2>&1)
    if echo "$ping_result" | grep -q "1 packets transmitted, 1 received"; then
        return 0  # Pi ist erreichbar
    else
        return 1  # Pi ist nicht erreichbar
    fi
}

# Funktion: Prüfe SSH-Verfügbarkeit
check_ssh() {
    if timeout 2 nc -z "$PI_IP" 22 2>/dev/null; then
        return 0  # SSH Port ist offen
    else
        return 1  # SSH Port ist geschlossen
    fi
}

# Funktion: Hole Boot-Status vom Pi
get_boot_status() {
    if check_ssh; then
        sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=3 "$PI_USER@$PI_IP" 2>/dev/null << 'EOF' || return 1
            echo "=== BOOT STATUS ==="
            echo "Uptime: $(uptime -p 2>/dev/null || uptime)"
            echo ""
            echo "=== NETWORK STATUS ==="
            echo "eth0 IP: $(ip addr show eth0 2>/dev/null | grep 'inet ' | awk '{print $2}' || echo 'N/A')"
            echo "wlan0 IP: $(ip addr show wlan0 2>/dev/null | grep 'inet ' | awk '{print $2}' || echo 'N/A')"
            echo ""
            echo "=== SYSTEMD STATUS ==="
            systemctl is-active cloud-init.target 2>/dev/null && echo "cloud-init.target: ✅ ACTIVE" || echo "cloud-init.target: ⏳ WAITING"
            systemctl is-active network-online.target 2>/dev/null && echo "network-online.target: ✅ ACTIVE" || echo "network-online.target: ⏳ WAITING"
            systemctl is-active NetworkManager 2>/dev/null && echo "NetworkManager: ✅ ACTIVE" || echo "NetworkManager: ❌ INACTIVE"
            echo ""
            echo "=== SSH STATUS ==="
            systemctl is-active ssh 2>/dev/null && echo "SSH: ✅ ACTIVE" || systemctl is-active sshd 2>/dev/null && echo "SSH: ✅ ACTIVE" || echo "SSH: ❌ INACTIVE"
            echo ""
            echo "=== RECENT BOOT LOGS ==="
            journalctl -b --no-pager -n 20 2>/dev/null | tail -10 || echo "Logs nicht verfügbar"
EOF
        return 0
    else
        return 1
    fi
}

# Haupt-Loop
while true; do
    CURRENT_TIME=$(date +%s)
    ELAPSED=$((CURRENT_TIME - START_TIME))
    
    # Prüfe ob Max-Wartezeit erreicht
    if [ $ELAPSED -ge $MAX_WAIT ]; then
        echo ""
        echo "⏱️  Max Wartezeit erreicht (${MAX_WAIT}s)"
        echo "❌ Pi ist nach ${ELAPSED} Sekunden noch nicht erreichbar"
        echo ""
        echo "Mögliche Probleme:"
        echo "  1. Boot hängt (cloud-init.target?)"
        echo "  2. Netzwerk nicht konfiguriert"
        echo "  3. SSH startet nicht"
        echo ""
        exit 1
    fi
    
    # Prüfe Ping alle 2 Sekunden
    if [ $((ELAPSED - LAST_PING_TIME)) -ge 2 ]; then
        if check_pi; then
            echo -n "✅ Pi ist erreichbar (Ping OK)"
            
            # Prüfe SSH
            if check_ssh; then
                echo " | SSH Port 22: ✅ OFFEN"
                
                # Versuche Boot-Status zu holen
                echo ""
                echo "📊 Hole Boot-Status vom Pi..."
                if get_boot_status; then
                    echo ""
                    echo "╔══════════════════════════════════════════════════════════════╗"
                    echo "║  ✅ PI IST ONLINE UND FUNKTIONSFÄHIG!                        ║"
                    echo "╚══════════════════════════════════════════════════════════════╝"
                    echo ""
                    echo "SSH-Verbindung:"
                    echo "  ssh $PI_USER@$PI_IP"
                    echo "  Password: $PI_PASS"
                    echo ""
                    BOOT_COMPLETE=true
                    break
                else
                    echo "⚠️  SSH Port offen, aber Verbindung fehlgeschlagen"
                fi
            else
                echo " | SSH Port 22: ⏳ NOCH GESCHLOSSEN"
            fi
        else
            echo "⏳ [$ELAPSED s] Pi noch nicht erreichbar..."
        fi
        LAST_PING_TIME=$ELAPSED
    fi
    
    sleep 1
done

if [ "$BOOT_COMPLETE" = true ]; then
    exit 0
else
    exit 1
fi

