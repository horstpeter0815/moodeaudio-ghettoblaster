#!/bin/bash
# Fix Display Rotation (Portrait → Landscape) und starte Browser

PI_IP="192.168.178.161"
PI_USER="pi"

# Finde Passwort
PASS=""
for p in "DSD" "moodeaudio" "raspberry" "pi"; do
    if sshpass -p "$p" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 "$PI_USER@$PI_IP" "echo OK" >/dev/null 2>&1; then
        PASS="$p"
        break
    fi
done

if [ -z "$PASS" ]; then
    echo "❌ SSH nicht verfügbar"
    exit 1
fi

echo "✅ SSH funktioniert"
echo ""

# 1. Display-Rotation: Portrait (3) → Landscape (0)
echo "🖥️  Ändere Display-Rotation: Portrait → Landscape..."
sshpass -p "$PASS" ssh "$PI_USER@$PI_IP" "sudo sed -i 's/display_rotate=3/display_rotate=0/' /boot/firmware/config.txt" 2>/dev/null
sshpass -p "$PASS" ssh "$PI_USER@$PI_IP" "grep display_rotate /boot/firmware/config.txt" 2>/dev/null
echo ""

# 2. Prüfe Chromium-Service
echo "🌐 Prüfe Chromium-Service..."
sshpass -p "$PASS" ssh "$PI_USER@$PI_IP" "systemctl status chromium-kiosk 2>/dev/null | head -5 || systemctl status chromium 2>/dev/null | head -5 || echo 'Chromium-Service nicht gefunden'"
echo ""

# 3. Starte Chromium
echo "🚀 Starte Chromium..."
sshpass -p "$PASS" ssh "$PI_USER@$PI_IP" "sudo systemctl start chromium-kiosk 2>/dev/null || sudo systemctl start chromium 2>/dev/null || echo 'Chromium manuell starten'"
echo ""

# 4. Neustart für Display-Änderung
echo "⚠️  Neustart erforderlich für Display-Rotation"
echo "   Soll ich jetzt neu starten? (yes/no)"
read -t 5 REBOOT || REBOOT="no"
if [ "$REBOOT" = "yes" ]; then
    echo "🔄 Starte Neustart..."
    sshpass -p "$PASS" ssh "$PI_USER@$PI_IP" "sudo reboot"
    echo "✅ Neustart gestartet"
else
    echo "📋 Neustart manuell: sudo reboot"
fi

