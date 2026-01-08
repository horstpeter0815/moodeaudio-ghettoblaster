#!/bin/bash
################################################################################
# ALL-IN-ONE SETUP FÜR BEIDE PIS
# ghettopi5 (mit AMP100) und ghettopi5-2 (ohne AMP100)
################################################################################

set -e

# IPs direkt setzen
PI1="andre@192.168.178.143"
PI2="andre@192.168.178.134"

# Versuche auch Hostnamen
PI1_HOSTNAME="andre@ghettopi5"
PI2_HOSTNAME="andre@ghettopi5-2"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "============================================================"
echo "ALL-IN-ONE SETUP FÜR BEIDE PIS"
echo "============================================================"
echo ""

# 1. Prüfe Verbindungen
echo "=== 1. VERBINDUNG PRÜFEN ==="
echo ""

echo "Prüfe ghettopi5 (192.168.178.143)..."
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$PI1" "hostname" > /dev/null 2>&1; then
    PI1_HOST=$(ssh -o StrictHostKeyChecking=no "$PI1" "hostname")
    echo "✅ ghettopi5 erreichbar: $PI1_HOST (192.168.178.143)"
else
    echo "⚠️  IP 143 nicht erreichbar - versuche Hostname..."
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$PI1_HOSTNAME" "hostname" > /dev/null 2>&1; then
        PI1="$PI1_HOSTNAME"
        PI1_HOST=$(ssh -o StrictHostKeyChecking=no "$PI1" "hostname")
        echo "✅ ghettopi5 erreichbar via Hostname: $PI1_HOST"
    else
        echo "❌ ghettopi5 nicht erreichbar"
        exit 1
    fi
fi

echo ""
echo "Prüfe ghettopi5-2 (192.168.178.134)..."
if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$PI2" "hostname" > /dev/null 2>&1; then
    PI2_HOST=$(ssh -o StrictHostKeyChecking=no "$PI2" "hostname")
    echo "✅ ghettopi5-2 erreichbar: $PI2_HOST (192.168.178.134)"
else
    echo "⚠️  IP 134 nicht erreichbar - versuche Hostname..."
    if ssh -o ConnectTimeout=5 -o StrictHostKeyChecking=no "$PI2_HOSTNAME" "hostname" > /dev/null 2>&1; then
        PI2="$PI2_HOSTNAME"
        PI2_HOST=$(ssh -o StrictHostKeyChecking=no "$PI2" "hostname")
        echo "✅ ghettopi5-2 erreichbar via Hostname: $PI2_HOST"
    else
        echo "❌ ghettopi5-2 nicht erreichbar"
        exit 1
    fi
fi

echo ""
echo "=== 2. SCRIPTS KOPIEREN ==="
echo ""

echo "Kopiere Scripts auf ghettopi5 (192.168.178.143)..."
scp -o StrictHostKeyChecking=no "$SCRIPT_DIR/SETUP_ON_PI.sh" "$SCRIPT_DIR/VIDEO_PIPELINE_TEST_SAFE.sh" "$PI1:/home/andre/" 2>/dev/null && echo "✅ ghettopi5" || echo "⚠️  ghettopi5 Fehler"

echo "Kopiere Scripts auf ghettopi5-2 (192.168.178.134)..."
scp -o StrictHostKeyChecking=no "$SCRIPT_DIR/SETUP_ON_PI.sh" "$SCRIPT_DIR/VIDEO_PIPELINE_TEST_SAFE.sh" "$PI2:/home/andre/" 2>/dev/null && echo "✅ ghettopi5-2" || echo "⚠️  ghettopi5-2 Fehler"

echo ""
echo "=== 3. RECHTE SETZEN ==="
echo ""

ssh -o StrictHostKeyChecking=no "$PI1" 'chmod +x ~/SETUP_ON_PI.sh ~/VIDEO_PIPELINE_TEST_SAFE.sh' 2>/dev/null && echo "✅ ghettopi5 Rechte" || echo "⚠️  ghettopi5 Rechte-Fehler"
ssh -o StrictHostKeyChecking=no "$PI2" 'chmod +x ~/SETUP_ON_PI.sh ~/VIDEO_PIPELINE_TEST_SAFE.sh' 2>/dev/null && echo "✅ ghettopi5-2 Rechte" || echo "⚠️  ghettopi5-2 Rechte-Fehler"

echo ""
echo "=== 4. SUPERVISOR INSTALLIEREN ==="
echo ""

SUPERVISOR_SCRIPT='#!/bin/bash
LOG=/home/andre/supervisor.log
echo "[$(date)] supervisor invoked: $@" >> "$LOG"

case "$1" in
  status)
    echo "--- STATUS ---"
    hostname
    ip a | grep "inet " | grep -v 127.0.0.1
    ps aux | grep -E "Xorg|chromium-browser" | grep -v grep
    ;;
  display-fix)
    if [ -x /home/andre/SETUP_ON_PI.sh ]; then
      bash /home/andre/SETUP_ON_PI.sh
    else
      echo "SETUP_ON_PI.sh nicht gefunden"
    fi
    ;;
  video-test)
    if [ -x /home/andre/VIDEO_PIPELINE_TEST_SAFE.sh ]; then
      bash /home/andre/VIDEO_PIPELINE_TEST_SAFE.sh
    else
      echo "VIDEO_PIPELINE_TEST_SAFE.sh nicht gefunden"
    fi
    ;;
  *)
    echo "Usage: $0 {status|display-fix|video-test}"
    ;;
esac'

echo "Installiere Supervisor auf ghettopi5..."
ssh -o StrictHostKeyChecking=no "$PI1" "cat > ~/supervisor.sh << 'EOF'
$SUPERVISOR_SCRIPT
EOF
chmod +x ~/supervisor.sh" 2>/dev/null && echo "✅ ghettopi5 Supervisor" || echo "⚠️  ghettopi5 Supervisor-Fehler"

echo "Installiere Supervisor auf ghettopi5-2..."
ssh -o StrictHostKeyChecking=no "$PI2" "cat > ~/supervisor.sh << 'EOF'
$SUPERVISOR_SCRIPT
EOF
chmod +x ~/supervisor.sh" 2>/dev/null && echo "✅ ghettopi5-2 Supervisor" || echo "⚠️  ghettopi5-2 Supervisor-Fehler"

echo ""
echo "=== 5. DISPLAY-FIX AUSFÜHREN ==="
echo ""

echo "ghettopi5 Display-Fix (192.168.178.143)..."
ssh -o StrictHostKeyChecking=no "$PI1" './supervisor.sh display-fix' || echo "⚠️  ghettopi5 Display-Fix Fehler"

echo ""
echo "ghettopi5-2 Display-Fix (192.168.178.134)..."
ssh -o StrictHostKeyChecking=no "$PI2" './supervisor.sh display-fix' || echo "⚠️  ghettopi5-2 Display-Fix Fehler"

echo ""
echo "=== 6. REBOOT BEIDE PIS ==="
echo ""

read -p "Beide Pis jetzt rebooten? (j/n): " -n 1 -r
echo
if [[ $REPLY =~ ^[Jj]$ ]]; then
    echo "Reboote ghettopi5 (192.168.178.143)..."
    ssh -o StrictHostKeyChecking=no "$PI1" 'sudo reboot' || echo "⚠️  ghettopi5 Reboot-Fehler"
    
    echo "Reboote ghettopi5-2 (192.168.178.134)..."
    ssh -o StrictHostKeyChecking=no "$PI2" 'sudo reboot' || echo "⚠️  ghettopi5-2 Reboot-Fehler"
    
    echo ""
    echo "Warte 30 Sekunden auf Boot..."
    sleep 30
    
    echo ""
    echo "=== 7. VERIFIKATION NACH REBOOT ==="
    echo ""
    
    echo "Prüfe ghettopi5 (192.168.178.143)..."
    if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$PI1" "hostname" > /dev/null 2>&1; then
        echo "✅ ghettopi5 ist wieder online"
        ssh -o StrictHostKeyChecking=no "$PI1" './supervisor.sh status' 2>/dev/null || echo "⚠️  Status-Check fehlgeschlagen"
    else
        echo "⚠️  ghettopi5 noch nicht online (warte noch 30 Sekunden...)"
        sleep 30
        ssh -o StrictHostKeyChecking=no "$PI1" './supervisor.sh status' 2>/dev/null || echo "⚠️  Status-Check fehlgeschlagen"
    fi
    
    echo ""
    echo "Prüfe ghettopi5-2 (192.168.178.134)..."
    if ssh -o ConnectTimeout=10 -o StrictHostKeyChecking=no "$PI2" "hostname" > /dev/null 2>&1; then
        echo "✅ ghettopi5-2 ist wieder online"
        ssh -o StrictHostKeyChecking=no "$PI2" './supervisor.sh status' 2>/dev/null || echo "⚠️  Status-Check fehlgeschlagen"
    else
        echo "⚠️  ghettopi5-2 noch nicht online (warte noch 30 Sekunden...)"
        sleep 30
        ssh -o StrictHostKeyChecking=no "$PI2" './supervisor.sh status' 2>/dev/null || echo "⚠️  Status-Check fehlgeschlagen"
    fi
else
    echo "Reboot übersprungen - führe manuell aus:"
    echo "  ssh $PI1 sudo reboot"
    echo "  ssh $PI2 sudo reboot"
fi

echo ""
echo "============================================================"
echo "SETUP ABGESCHLOSSEN"
echo "============================================================"
echo ""
echo "IPs:"
echo "  ghettopi5:     192.168.178.143"
echo "  ghettopi5-2:  192.168.178.134"
echo ""
echo "Nächste Schritte (nach Reboot):"
echo "  ssh andre@192.168.178.143 ./supervisor.sh video-test"
echo "  ssh andre@192.168.178.134 ./supervisor.sh video-test"
echo ""
echo "Supervisor-Befehle:"
echo "  ./supervisor.sh status      - Status anzeigen"
echo "  ./supervisor.sh display-fix - Display konfigurieren"
echo "  ./supervisor.sh video-test  - Video-Pipeline testen (READ-ONLY)"
echo ""
