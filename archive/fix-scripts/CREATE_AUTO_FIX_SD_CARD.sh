#!/bin/bash
################################################################################
# AUTOMATISCHER FIX - Läuft beim Boot und verhindert Overwrite SOFORT
#
# Erstellt:
# 1. Script, das worker.php patcht (deaktiviert chkBootConfigTxt)
# 2. systemd Service, der beim Boot läuft
# 3. rc.local Eintrag als Fallback
#
# FUNKTIONIERT BEIM NÄCHSTEN BOOT AUTOMATISCH
################################################################################

set -e

SD_MOUNT=""
if [ -d "/Volumes/bootfs" ]; then
    SD_MOUNT="/Volumes/bootfs"
elif [ -d "/Volumes/boot" ]; then
    SD_MOUNT="/Volumes/boot"
fi

if [ -z "$SD_MOUNT" ]; then
    echo "❌ SD-Karte nicht gefunden"
    echo "Bitte SD-Karte einstecken"
    exit 1
fi

echo "=== AUTOMATISCHER FIX - Wird beim Boot ausgeführt ==="
echo ""

# 1. Create fix script
cat > "$SD_MOUNT/fix-worker-no-overwrite.sh" << 'FIX_EOF'
#!/bin/bash
# PERMANENTER FIX: Verhindert config.txt Overwrite

WORKER_FILE="/var/www/daemon/worker.php"

if [ ! -f "$WORKER_FILE" ]; then
    exit 0  # worker.php noch nicht vorhanden, später versuchen
fi

# Backup
if [ ! -f "$WORKER_FILE.backup_fix" ]; then
    cp "$WORKER_FILE" "$WORKER_FILE.backup_fix"
fi

# METHODE: chkBootConfigTxt() immer "Required headers present" zurückgeben lassen
# Finde die Zeile und ersetze sie
if grep -q "chkBootConfigTxt()" "$WORKER_FILE" && ! grep -q "PERMANENT FIX: config.txt check disabled" "$WORKER_FILE"; then
    # Ersetze: $status = chkBootConfigTxt();
    # Mit: $status = 'Required headers present'; // PERMANENT FIX
    sed -i "s/\$status = chkBootConfigTxt();/\$status = 'Required headers present'; \/\/ PERMANENT FIX: config.txt check disabled/g" "$WORKER_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ worker.php patched - config.txt wird NICHT mehr überschrieben" >> /var/log/fix-worker.log
fi

# ZUSÄTZLICH: Overwrite-Befehle deaktivieren
if grep -q "sysCmd('cp /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/')" "$WORKER_FILE" && ! grep -q "PERMANENT FIX: Overwrite disabled" "$WORKER_FILE"; then
    sed -i "s|sysCmd('cp /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');|// PERMANENT FIX: Overwrite disabled\n\t\t\t// sysCmd('cp /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');|g" "$WORKER_FILE"
    sed -i "s|sysCmd('cp -f /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');|// PERMANENT FIX: Overwrite disabled\n\t\t\t// sysCmd('cp -f /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/');|g" "$WORKER_FILE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] ✅ Overwrite-Befehle deaktiviert" >> /var/log/fix-worker.log
fi

exit 0
FIX_EOF

chmod +x "$SD_MOUNT/fix-worker-no-overwrite.sh"

# 2. Create systemd service
mkdir -p "$SD_MOUNT/systemd-fix"
cat > "$SD_MOUNT/systemd-fix/prevent-config-overwrite.service" << 'SERVICE_EOF'
[Unit]
Description=Prevent config.txt Overwrite
After=network.target
Before=worker.service

[Service]
Type=oneshot
ExecStart=/boot/firmware/fix-worker-no-overwrite.sh
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
SERVICE_EOF

# 3. Create installation script
cat > "$SD_MOUNT/install-auto-fix.sh" << 'INSTALL_EOF'
#!/bin/bash
# Installiert den automatischen Fix auf dem Pi

echo "=== INSTALLIERE AUTOMATISCHEN FIX ==="

# Copy fix script
cp /boot/firmware/fix-worker-no-overwrite.sh /usr/local/bin/
chmod +x /usr/local/bin/fix-worker-no-overwrite.sh

# Install systemd service
if [ -f "/boot/firmware/systemd-fix/prevent-config-overwrite.service" ]; then
    cp /boot/firmware/systemd-fix/prevent-config-overwrite.service /etc/systemd/system/
    systemctl daemon-reload
    systemctl enable prevent-config-overwrite.service
    systemctl start prevent-config-overwrite.service
    echo "✅ systemd Service installiert und gestartet"
fi

# Add to rc.local as fallback
if [ -f "/etc/rc.local" ]; then
    if ! grep -q "fix-worker-no-overwrite" /etc/rc.local; then
        sed -i '/^exit 0/i /usr/local/bin/fix-worker-no-overwrite.sh' /etc/rc.local
        echo "✅ rc.local Eintrag hinzugefügt"
    fi
fi

# Run immediately
/usr/local/bin/fix-worker-no-overwrite.sh

echo ""
echo "✅ AUTOMATISCHER FIX INSTALLIERT"
echo "   → worker.php wird config.txt NICHT mehr überschreiben"
echo "   → Funktioniert bei jedem Boot automatisch"
echo ""
INSTALL_EOF

chmod +x "$SD_MOUNT/install-auto-fix.sh"

echo "✅ Automatischer Fix erstellt:"
echo "   - fix-worker-no-overwrite.sh (Haupt-Script)"
echo "   - prevent-config-overwrite.service (systemd Service)"
echo "   - install-auto-fix.sh (Installation auf Pi)"
echo ""
echo "=== NÄCHSTE SCHRITTE ==="
echo ""
echo "1. SD-Karte sicher auswerfen"
echo "2. SD-Karte in Pi einstecken"
echo "3. Pi booten"
echo "4. Nach Boot: SSH zum Pi"
echo "5. Ausführen: sudo /boot/firmware/install-auto-fix.sh"
echo ""
echo "DANACH:"
echo "  → worker.php wird config.txt NICHT mehr überschreiben"
echo "  → Funktioniert bei jedem Boot automatisch"
echo "  → KEINE weiteren Fixes nötig!"
echo ""

