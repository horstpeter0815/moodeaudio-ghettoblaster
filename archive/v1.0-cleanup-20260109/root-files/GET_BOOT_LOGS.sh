#!/bin/bash
# Get Boot Logs from Pi via SSH
# Holt Runtime-Evidence vom Pi

set -e

PI_IP="192.168.10.2"
LOG_DIR="/Users/andrevollmer/moodeaudio-cursor/.cursor"
mkdir -p "$LOG_DIR"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  📥 GET BOOT LOGS FROM PI                                   ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Warte auf Pi
echo "Warte auf Pi ($PI_IP)..."
for i in {1..30}; do
    if ping -c 1 -W 1 "$PI_IP" >/dev/null 2>&1; then
        echo "✅ Pi ist online"
        break
    fi
    echo -n "."
    sleep 2
done
echo ""

# Prüfe SSH
if ! ssh -o ConnectTimeout=3 -o StrictHostKeyChecking=no andre@"$PI_IP" "echo SSH_OK" 2>/dev/null; then
    echo "❌ SSH nicht verfügbar"
    exit 1
fi

echo "✅ SSH funktioniert"
echo ""

# Hole Boot-Logs
echo "Hole Boot-Logs..."
ssh andre@"$PI_IP" "cat /var/log/boot-debug.log 2>/dev/null || echo 'No boot-debug.log'" > "$LOG_DIR/boot-debug.log" 2>/dev/null

# Hole Service-Status
echo "Hole Service-Status..."
ssh andre@"$PI_IP" "systemctl status NetworkManager-wait-online --no-pager 2>&1 | head -20" > "$LOG_DIR/networkmanager-wait-status.txt" 2>/dev/null
ssh andre@"$PI_IP" "systemctl status NetworkManager --no-pager 2>&1 | head -20" > "$LOG_DIR/networkmanager-status.txt" 2>/dev/null
ssh andre@"$PI_IP" "systemctl status ssh --no-pager 2>&1 | head -15" > "$LOG_DIR/ssh-status.txt" 2>/dev/null

# Hole Network-Info
echo "Hole Network-Info..."
ssh andre@"$PI_IP" "ip addr show && echo '---' && ip route show" > "$LOG_DIR/network-info.txt" 2>/dev/null

# Hole Journal-Logs
echo "Hole Journal-Logs..."
ssh andre@"$PI_IP" "journalctl -u NetworkManager-wait-online --no-pager -n 50" > "$LOG_DIR/networkmanager-wait-journal.txt" 2>/dev/null
ssh andre@"$PI_IP" "journalctl -u ssh-asap --no-pager -n 30" > "$LOG_DIR/ssh-asap-journal.txt" 2>/dev/null

echo ""
echo "✅ Logs gesammelt in $LOG_DIR"
echo ""
echo "Dateien:"
ls -lh "$LOG_DIR"/*.txt "$LOG_DIR"/*.log 2>/dev/null | awk '{print "  " $9 " (" $5 ")"}'
echo ""

