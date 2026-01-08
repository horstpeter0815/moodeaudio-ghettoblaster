#!/bin/bash
# Reparatur der Services die das Boot blockieren könnten

echo "=== REPARATUR PI 5 BOOT-SERVICES ==="
echo ""

# Prüfe ob Pi 5 online ist
if ! ping -c 1 -W 2000 192.168.178.134 >/dev/null 2>&1; then
    echo "❌ Pi 5 ist nicht erreichbar"
    echo ""
    echo "⚠️  Mögliche Probleme mit implementierten Services:"
    echo ""
    echo "1. config-validate.service:"
    echo "   - Hat kein Timeout"
    echo "   - Könnte hängen wenn Script fehlschlägt"
    echo "   → Lösung: Timeout hinzufügen"
    echo ""
    echo "2. set-mpd-volume.service:"
    echo "   - Wartet auf mpd.service"
    echo "   - Könnte hängen wenn MPD nicht startet"
    echo "   → Lösung: Timeout und Fehlerbehandlung"
    echo ""
    echo "3. mpd.service:"
    echo "   - Hat 45s Timeout"
    echo "   - Könnte trotzdem hängen"
    echo "   → Lösung: Timeout prüfen"
    echo ""
    echo "→ Services müssen repariert werden sobald Pi 5 wieder online ist"
    exit 1
fi

echo "✅ Pi 5 ist online - Repariere Services..."
echo ""

# Erstelle reparierte Services lokal
cat > /tmp/config-validate-fixed.service << 'EOF'
[Unit]
Description=Validate config.txt
Before=localdisplay.service
After=local-fs.target

[Service]
Type=oneshot
TimeoutStartSec=10
ExecStart=/opt/moode/bin/config-validate.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

cat > /tmp/set-mpd-volume-fixed.service << 'EOF'
[Unit]
Description=Set MPD Volume to 0% (Auto-Mute)
After=mpd.service
Wants=mpd.service

[Service]
Type=oneshot
TimeoutStartSec=30
ExecStartPre=/bin/sleep 5
ExecStart=/usr/bin/mpc volume 0 || true
ExecStartPost=/bin/bash -c 'sleep 10 && /usr/bin/mpc volume 0 || true'
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
EOF

# Kopiere reparierte Services
echo "1. Repariere config-validate.service..."
./pi5-ssh.sh "sudo tee /etc/systemd/system/config-validate.service > /dev/null" < /tmp/config-validate-fixed.service 2>&1

echo "2. Repariere set-mpd-volume.service..."
./pi5-ssh.sh "sudo tee /etc/systemd/system/set-mpd-volume.service > /dev/null" < /tmp/set-mpd-volume-fixed.service 2>&1

# Reload systemd
echo "3. Reload systemd..."
./pi5-ssh.sh "sudo systemctl daemon-reload" 2>&1

echo ""
echo "✅ Services repariert!"
echo ""
echo "Prüfe Status..."
./pi5-ssh.sh "systemctl status config-validate set-mpd-volume mpd --no-pager | head -30" 2>&1
