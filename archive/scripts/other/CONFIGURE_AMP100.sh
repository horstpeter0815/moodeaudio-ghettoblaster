#!/bin/bash
# Konfiguriert HiFiBerry AMP100 auf Moode Audio Pi 5

PI_IP="192.168.178.178"
PI_USER="andre"
PI_PASS="0815"

echo "=== HIFIBERRY AMP100 KONFIGURATION ==="
echo ""

sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_IP" << 'CONFIGURE_AMP100'
set -e

echo "1. Backup config.txt..."
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup.amp100.$(date +%Y%m%d_%H%M%S)
echo "✅ Backup erstellt"
echo ""

echo "2. Prüfe aktuelle Overlays..."
grep -E "dtoverlay|dtparam" /boot/firmware/config.txt | grep -i "hifiberry\|amp\|i2c\|i2s" || echo "Keine AMP100-Overlays gefunden"
echo ""

echo "3. Füge AMP100 Overlay hinzu..."
# Entferne alte hifiberry-Overlays
sudo sed -i '/dtoverlay=hifiberry/d' /boot/firmware/config.txt
sudo sed -i '/dtoverlay=.*amp/d' /boot/firmware/config.txt

# Füge AMP100 Overlay hinzu (nach [all] Sektion)
if grep -q "\[all\]" /boot/firmware/config.txt; then
    # Füge nach [all] hinzu
    sudo sed -i '/\[all\]/a dtoverlay=hifiberry-amp100' /boot/firmware/config.txt
else
    # Füge am Anfang hinzu
    echo "dtoverlay=hifiberry-amp100" | sudo tee -a /boot/firmware/config.txt > /dev/null
fi

# Stelle sicher, dass I2C aktiviert ist
if ! grep -q "dtparam=i2c=on" /boot/firmware/config.txt; then
    sudo sed -i '/\[all\]/a dtparam=i2c=on' /boot/firmware/config.txt
fi

echo "✅ AMP100 Overlay hinzugefügt"
echo ""

echo "4. Prüfe I2C-Geräte..."
i2cdetect -y 1 2>/dev/null | grep -E "1a|1b" && echo "✅ AMP100 erkannt (WM8960 auf 0x1a)" || echo "⚠️  AMP100 nicht erkannt (nach Reboot prüfen)"
echo ""

echo "5. Prüfe ALSA-Geräte..."
aplay -l 2>/dev/null | grep -i "hifiberry\|amp100" && echo "✅ ALSA-Gerät erkannt" || echo "⚠️  ALSA-Gerät nicht erkannt (nach Reboot prüfen)"
echo ""

echo "6. Setze ALSA Default-Gerät..."
sudo tee /etc/asound.conf > /dev/null << 'ALSA_EOF'
pcm.!default {
    type hw
    card 0
}

ctl.!default {
    type hw
    card 0
}
ALSA_EOF
echo "✅ ALSA-Konfiguration gesetzt"
echo ""

echo "7. Prüfe dmesg für AMP100..."
dmesg | grep -i "hifiberry\|amp100\|wm8960" | tail -5 || echo "Keine AMP100-Info in dmesg (nach Reboot prüfen)"
echo ""

echo "=== KONFIGURATION ABGESCHLOSSEN ==="
echo ""
echo "✅ AMP100 Overlay hinzugefügt"
echo "✅ I2C aktiviert"
echo "✅ ALSA-Konfiguration gesetzt"
echo ""
echo "⚠️  REBOOT ERFORDERLICH"
echo ""
echo "Nach Reboot prüfen:"
echo "  - i2cdetect -y 1 (sollte 0x1a zeigen)"
echo "  - aplay -l (sollte AMP100 zeigen)"
echo "  - dmesg | grep hifiberry"
echo ""
CONFIGURE_AMP100

echo ""
echo "=== FERTIG ==="
echo "Pi muss rebootet werden für AMP100-Aktivierung"
echo ""

