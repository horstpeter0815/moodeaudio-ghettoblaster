#!/bin/bash
# Install Ansatz 1 (Service Delay) on moOde Audio
# Run this script on Pi 2 (192.168.178.178)

set -e  # Exit on error

echo "=========================================="
echo "  ANSATZ 1: FT6236 DELAY SERVICE"
echo "  moOde Audio Implementation"
echo "=========================================="
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo "❌ Bitte mit sudo ausführen:"
    echo "   sudo bash install_ansatz1_moode.sh"
    exit 1
fi

echo "📋 SCHRITT 1: Backup config.txt erstellen..."
BACKUP_FILE="/boot/firmware/config.txt.backup-$(date +%Y%m%d-%H%M%S)"
cp /boot/firmware/config.txt "$BACKUP_FILE"
echo "✅ Backup erstellt: $BACKUP_FILE"
echo ""

echo "📋 SCHRITT 2: FT6236 Overlay auskommentieren..."
if grep -q "^dtoverlay=ft6236" /boot/firmware/config.txt; then
    sed -i 's/^dtoverlay=ft6236/#dtoverlay=ft6236/' /boot/firmware/config.txt
    echo "✅ FT6236 Overlay auskommentiert"
elif grep -q "^#dtoverlay=ft6236" /boot/firmware/config.txt; then
    echo "⚠️  FT6236 Overlay ist bereits auskommentiert"
else
    echo "⚠️  FT6236 Overlay nicht in config.txt gefunden"
fi
echo ""

echo "📋 SCHRITT 3: systemd-Service erstellen..."
cat > /etc/systemd/system/ft6236-delay.service << 'EOF'
[Unit]
Description=Load FT6236 touchscreen after display
After=graphical.target
After=localdisplay.service
Wants=localdisplay.service

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'sleep 3 && modprobe ft6236'
RemainAfterExit=yes
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=graphical.target
EOF

echo "✅ Service-Datei erstellt: /etc/systemd/system/ft6236-delay.service"
echo ""

echo "📋 SCHRITT 4: Service aktivieren..."
systemctl daemon-reload
systemctl enable ft6236-delay.service
echo "✅ Service aktiviert"
echo ""

echo "📋 SCHRITT 5: Service starten (Test)..."
systemctl start ft6236-delay.service
sleep 2
echo "✅ Service gestartet"
echo ""

echo "📋 SCHRITT 6: Verifikation..."
echo ""
echo "Service-Status:"
systemctl status ft6236-delay.service --no-pager -l | head -10
echo ""

echo "FT6236 Modul:"
if lsmod | grep -q ft6236; then
    echo "✅ FT6236 Modul ist geladen"
    lsmod | grep ft6236
else
    echo "⚠️  FT6236 Modul ist noch nicht geladen (wird nach 3 Sekunden geladen)"
fi
echo ""

echo "Touchscreen-Devices:"
ls -la /dev/input/event* 2>/dev/null | head -5 || echo "   (noch keine Devices gefunden)"
echo ""

echo "localdisplay.service Status:"
systemctl is-active localdisplay.service && echo "✅ localdisplay.service ist aktiv" || echo "⚠️  localdisplay.service ist nicht aktiv"
echo ""

echo "=========================================="
echo "✅ INSTALLATION ABGESCHLOSSEN"
echo "=========================================="
echo ""
echo "📋 NÄCHSTE SCHRITTE:"
echo "   1. Reboot durchführen: sudo reboot"
echo "   2. Nach Reboot prüfen:"
echo "      - Display funktioniert?"
echo "      - Touchscreen funktioniert nach 3 Sekunden?"
echo "      - Keine X Server Crashes?"
echo "      - Audio funktioniert weiterhin?"
echo ""
echo "📋 ROLLBACK (falls nötig):"
echo "   sudo systemctl disable ft6236-delay.service"
echo "   sudo systemctl stop ft6236-delay.service"
echo "   sudo cp $BACKUP_FILE /boot/firmware/config.txt"
echo "   sudo reboot"
echo ""

