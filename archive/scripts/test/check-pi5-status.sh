#!/bin/bash
# Kontinuierliche Prüfung ob Pi 5 wieder online ist

PI5_IP="192.168.178.134"
PI5_USER="andre"
MAX_ATTEMPTS=200  # ~50 Minuten bei 15s Intervall
ATTEMPT=0

echo "=== KONTINUIERLICHE PI 5 ÜBERWACHUNG ==="
echo "Start: $(date)"
echo ""

while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
    ATTEMPT=$((ATTEMPT + 1))
    
    if ssh -o StrictHostKeyChecking=no -o ConnectTimeout=5 "$PI5_USER@$PI5_IP" "hostname" 2>/dev/null | grep -q "GhettoPi4"; then
        echo ""
        echo "✅✅✅ PI 5 IST WIEDER ONLINE! ✅✅✅"
        echo "Zeit: $(date)"
        echo "Versuche: $ATTEMPT"
        echo ""
        echo "=== VOLLSTÄNDIGE SYSTEM-PRÜFUNG ==="
        
        ssh -o StrictHostKeyChecking=no "$PI5_USER@$PI5_IP" << 'EOF'
echo "Hostname: $(hostname)"
echo "Uptime: $(uptime)"
echo ""
echo "=== SERVICES ==="
systemctl is-active mpd localdisplay set-mpd-volume config-validate 2>&1
echo ""
echo "=== VOLUME ==="
mpc volume 2>&1
echo ""
echo "=== MPD STATUS ==="
systemctl status mpd --no-pager | head -12
echo ""
echo "=== VOLUME SERVICE STATUS ==="
systemctl status set-mpd-volume.service --no-pager | head -8
echo ""
echo "=== CONFIG VALIDATION ==="
journalctl -u config-validate.service -n 5 --no-pager
echo ""
echo "=== DISPLAY ==="
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null || echo "Display-Info nicht verfügbar"
echo ""
echo "=== BOOT TIMING ==="
systemd-analyze time
systemd-analyze blame | grep -E 'localdisplay|mpd|set-mpd-volume|config-validate' | head -5
EOF
        
        echo ""
        echo "✅ System-Prüfung abgeschlossen!"
        exit 0
    else
        if [ $((ATTEMPT % 20)) -eq 0 ]; then
            echo "$(date): Noch nicht online... (Versuch $ATTEMPT/$MAX_ATTEMPTS)"
        fi
        sleep 15
    fi
done

echo ""
echo "⚠️ Pi 5 ist nach $MAX_ATTEMPTS Versuchen nicht wieder online gekommen."
echo "Ende: $(date)"
exit 1

