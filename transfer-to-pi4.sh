#!/bin/bash
# Transfer der Erkenntnisse auf Pi 4 (moodepi4)

echo "=== TRANSFER AUF PI 4 (MOODEPI4) ==="
echo ""

# Prüfe ob Pi 4 online ist
if ! ./pi4-ssh.sh "hostname" >/dev/null 2>&1; then
    echo "❌ Pi 4 ist nicht erreichbar"
    exit 1
fi

echo "✅ Pi 4 ist online"
echo ""

# 1. Prüfe Config
echo "1. Prüfe config.txt..."
./pi4-ssh.sh "cat /boot/firmware/config.txt | grep -E 'display_rotate|dtoverlay=vc4|dtoverlay=ft6236|dtoverlay=hifiberry'" 2>&1
echo ""

# 2. Erstelle config-validate.sh
echo "2. Erstelle config-validate.sh..."
./pi4-ssh.sh "sudo mkdir -p /opt/moode/bin" 2>&1
cat config-validate.sh | ./pi4-ssh.sh "sudo tee /opt/moode/bin/config-validate.sh > /dev/null" 2>&1
./pi4-ssh.sh "sudo chmod +x /opt/moode/bin/config-validate.sh" 2>&1
echo "✅ config-validate.sh installiert"
echo ""

# 3. Erstelle config-validate.service (MIT TIMEOUT!)
echo "3. Erstelle config-validate.service (mit Timeout)..."
cat > /tmp/config-validate.service << 'EOF'
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

cat /tmp/config-validate.service | ./pi4-ssh.sh "sudo tee /etc/systemd/system/config-validate.service > /dev/null" 2>&1
./pi4-ssh.sh "sudo systemctl enable config-validate.service" 2>&1
echo "✅ config-validate.service installiert (mit Timeout!)"
echo ""

# 4. Erstelle set-mpd-volume.service (MIT TIMEOUT!)
echo "4. Erstelle set-mpd-volume.service (mit Timeout und Fehlerbehandlung)..."
cat > /tmp/set-mpd-volume.service << 'EOF'
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

cat /tmp/set-mpd-volume.service | ./pi4-ssh.sh "sudo tee /etc/systemd/system/set-mpd-volume.service > /dev/null" 2>&1
./pi4-ssh.sh "sudo systemctl enable set-mpd-volume.service" 2>&1
echo "✅ set-mpd-volume.service installiert (mit Timeout!)"
echo ""

# 5. Prüfe MPD Service
echo "5. Prüfe MPD Service..."
./pi4-ssh.sh "systemctl cat mpd.service | grep -A 5 'ExecStartPre\|TimeoutStartSec'" 2>&1
echo ""

# 6. Optimiere MPD Service falls nötig
echo "6. Optimiere MPD Service..."
./pi4-ssh.sh "sudo mkdir -p /etc/systemd/system/mpd.service.d" 2>&1
cat mpd-service-fix.conf | ./pi4-ssh.sh "sudo tee /etc/systemd/system/mpd.service.d/override.conf > /dev/null" 2>&1
./pi4-ssh.sh "sudo systemctl daemon-reload" 2>&1
echo "✅ MPD Service optimiert"
echo ""

# 7. Reload systemd
echo "7. Reload systemd..."
./pi4-ssh.sh "sudo systemctl daemon-reload" 2>&1
echo "✅ systemd neu geladen"
echo ""

# 8. Prüfe Status
echo "8. Prüfe Status aller Services..."
./pi4-ssh.sh "systemctl is-enabled config-validate set-mpd-volume mpd" 2>&1
echo ""

echo "=== TRANSFER ABGESCHLOSSEN ==="
echo ""
echo "✅ Alle Services installiert mit:"
echo "  - Timeouts (verhindert Boot-Blockierung)"
echo "  - Fehlerbehandlung"
echo "  - Optimierte Abhängigkeiten"
echo ""
echo "Nächster Schritt: Reboot testen"

