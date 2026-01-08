#!/bin/bash
################################################################################
# Setup für beide Pis parallel
# ghettopi5 (mit AMP100) und ghettopi5-2 (ohne AMP100)
################################################################################

PI1="andre@ghettopi5"
PI2="andre@ghettopi5-2"

echo "=== SETUP BEIDE PIS ==="
echo ""

# Prüfe ob beide Pis erreichbar sind
echo "1. Prüfe Verbindung zu ghettopi5..."
if ssh -o ConnectTimeout=5 "$PI1" "hostname" > /dev/null 2>&1; then
    echo "✅ ghettopi5 erreichbar"
    PI1_IP=$(ssh "$PI1" "ip a | grep 'inet ' | grep -v 127.0.0.1 | awk '{print \$2}' | cut -d'/' -f1 | head -1")
    echo "   IP: $PI1_IP"
else
    echo "❌ ghettopi5 nicht erreichbar"
    exit 1
fi

echo ""
echo "2. Prüfe Verbindung zu ghettopi5-2..."
if ssh -o ConnectTimeout=5 "$PI2" "hostname" > /dev/null 2>&1; then
    echo "✅ ghettopi5-2 erreichbar"
    PI2_IP=$(ssh "$PI2" "ip a | grep 'inet ' | grep -v 127.0.0.1 | awk '{print \$2}' | cut -d'/' -f1 | head -1")
    echo "   IP: $PI2_IP"
else
    echo "❌ ghettopi5-2 nicht erreichbar - versuche Hostname-Auflösung..."
    # Versuche IP-Scan
    for ip in 192.168.178.{1..255}; do
        if ssh -o ConnectTimeout=2 "$PI2" "hostname" > /dev/null 2>&1; then
            echo "✅ ghettopi5-2 gefunden: $ip"
            PI2="andre@$ip"
            break
        fi
    done
fi

echo ""
echo "=== KOPIERE SCRIPTS ==="
echo ""

# Scripts auf beide Pis kopieren
echo "3. Kopiere Scripts auf ghettopi5..."
scp SETUP_ON_PI.sh VIDEO_PIPELINE_TEST_SAFE.sh "$PI1:/home/andre/" 2>/dev/null && echo "✅ ghettopi5" || echo "⚠️  ghettopi5 Fehler"

echo "4. Kopiere Scripts auf ghettopi5-2..."
scp SETUP_ON_PI.sh VIDEO_PIPELINE_TEST_SAFE.sh "$PI2:/home/andre/" 2>/dev/null && echo "✅ ghettopi5-2" || echo "⚠️  ghettopi5-2 Fehler"

echo ""
echo "=== SETZE RECHTE ==="
echo ""

ssh "$PI1" 'chmod +x ~/SETUP_ON_PI.sh ~/VIDEO_PIPELINE_TEST_SAFE.sh' 2>/dev/null && echo "✅ ghettopi5 Rechte gesetzt" || echo "⚠️  ghettopi5 Rechte-Fehler"
ssh "$PI2" 'chmod +x ~/SETUP_ON_PI.sh ~/VIDEO_PIPELINE_TEST_SAFE.sh' 2>/dev/null && echo "✅ ghettopi5-2 Rechte gesetzt" || echo "⚠️  ghettopi5-2 Rechte-Fehler"

echo ""
echo "=== SUPERVISOR EINRICHTEN ==="
echo ""

# Supervisor auf beide Pis
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

echo "5. Installiere Supervisor auf ghettopi5..."
ssh "$PI1" "cat > ~/supervisor.sh << 'EOF'
$SUPERVISOR_SCRIPT
EOF
chmod +x ~/supervisor.sh" 2>/dev/null && echo "✅ ghettopi5 Supervisor" || echo "⚠️  ghettopi5 Supervisor-Fehler"

echo "6. Installiere Supervisor auf ghettopi5-2..."
ssh "$PI2" "cat > ~/supervisor.sh << 'EOF'
$SUPERVISOR_SCRIPT
EOF
chmod +x ~/supervisor.sh" 2>/dev/null && echo "✅ ghettopi5-2 Supervisor" || echo "⚠️  ghettopi5-2 Supervisor-Fehler"

echo ""
echo "=== STATUS BEIDER PIS ==="
echo ""

echo "ghettopi5 Status:"
ssh "$PI1" './supervisor.sh status' 2>/dev/null || echo "Fehler"

echo ""
echo "ghettopi5-2 Status:"
ssh "$PI2" './supervisor.sh status' 2>/dev/null || echo "Fehler"

echo ""
echo "=== FERTIG ==="
echo ""
echo "Nächste Schritte:"
echo "  ssh $PI1 ./supervisor.sh display-fix"
echo "  ssh $PI2 ./supervisor.sh display-fix"
echo ""

