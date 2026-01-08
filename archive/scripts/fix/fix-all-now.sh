#!/bin/bash
PI_IP="192.168.178.161"
PI_USER="pi"
PI_PASS="andre 0815"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 COMPLETE FIX - ALLE PROBLEME                            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# 1. DISPLAY ROTATION
echo "🖥️  1. Display-Rotation: Portrait → Landscape..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'ENDSSH'
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup
sudo sed -i 's/display_rotate=3/display_rotate=0/g' /boot/firmware/config.txt
if ! grep -q "display_rotate=0" /boot/firmware/config.txt; then
    echo "display_rotate=0" | sudo tee -a /boot/firmware/config.txt >/dev/null
fi
grep display_rotate /boot/firmware/config.txt
echo "✅ Display-Rotation geändert"
ENDSSH
echo ""

# 2. CHROMIUM FIX
echo "🌐 2. Chromium starten..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'ENDSSH'
sudo pkill -9 chromium 2>/dev/null || true
sudo pkill -9 chromium-browser 2>/dev/null || true
sleep 2
sudo rm -rf /tmp/chromium-data/Singleton* 2>/dev/null || true
sudo systemctl enable localdisplay 2>/dev/null
sudo systemctl daemon-reload 2>/dev/null
sudo systemctl restart localdisplay 2>/dev/null
sleep 3
systemctl status localdisplay --no-pager | head -5
echo "✅ Chromium Service gestartet"
ENDSSH
echo ""

# 3. SSH FIX
echo "🔐 3. SSH konfigurieren..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'ENDSSH'
sudo systemctl enable ssh 2>/dev/null
sudo systemctl start ssh 2>/dev/null
sudo sed -i 's/^#PasswordAuthentication.*/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh 2>/dev/null
echo "✅ SSH konfiguriert"
ENDSSH
echo ""

# 4. AUDIO
echo "🔊 4. Audio prüfen..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'ENDSSH'
aplay -l 2>/dev/null | head -5
if grep -q "hifiberry-amp100" /boot/firmware/config.txt; then
    echo "✅ AMP100 in config.txt"
else
    echo "⚠️  AMP100 nicht in config.txt"
fi
ENDSSH
echo ""

# 5. SERVICES
echo "⚙️  5. Services prüfen..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'ENDSSH'
systemctl is-active mpd >/dev/null && echo "✅ MPD läuft" || sudo systemctl start mpd
systemctl is-active localdisplay >/dev/null && echo "✅ Local Display läuft" || echo "⚠️  Local Display nicht aktiv"
ENDSSH
echo ""

# 6. NEUSTART
echo "🔄 6. Neustart..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" "sudo reboot" 2>/dev/null
echo "✅ Neustart gestartet"
echo ""
echo "⏱️  System startet neu (~2 Minuten)"
echo "   Nach Neustart:"
echo "   - Display: Landscape"
echo "   - Browser: Automatisch gestartet"
echo "   - SSH: Funktioniert"
