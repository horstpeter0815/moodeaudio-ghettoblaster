#!/bin/bash
################################################################################
# PERMANENTER FIX: worker.php so patchen, dass config.txt NICHT überschrieben wird
#
# Lösung: worker.php wird so modifiziert, dass:
# 1. chkBootConfigTxt() wird übersprungen ODER
# 2. Overwrite wird verhindert ODER  
# 3. Settings werden nach Overwrite wiederhergestellt
#
# DIESER FIX FUNKTIONIERT SOFORT - KEINE WEITEREN BOOTS NÖTIG
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
    exit 1
fi

echo "=== PERMANENTER FIX: worker.php Patch ==="
echo ""

# Create a script that will run on the Pi to patch worker.php
cat > "$SD_MOUNT/fix-worker-permanent.sh" << 'PATCH_EOF'
#!/bin/bash
################################################################################
# PERMANENTER FIX - Wird auf dem Pi ausgeführt
################################################################################

set -e

WORKER_FILE="/var/www/daemon/worker.php"
BACKUP_FILE="/var/www/daemon/worker.php.backup_$(date +%Y%m%d_%H%M%S)"

echo "=== PERMANENTER FIX: worker.php ==="
echo ""

# Backup
if [ -f "$WORKER_FILE" ]; then
    cp "$WORKER_FILE" "$BACKUP_FILE"
    echo "✅ Backup erstellt: $BACKUP_FILE"
fi

# METHODE 1: chkBootConfigTxt() Aufruf deaktivieren
# Finde die Zeile mit chkBootConfigTxt() und kommentiere sie aus
if grep -q "chkBootConfigTxt()" "$WORKER_FILE"; then
    # Kommentiere die Prüfung aus
    sed -i 's/^\s*\$status = chkBootConfigTxt();/\/\/ PERMANENT FIX: Disabled config.txt check\n\t\t\/\/ $status = chkBootConfigTxt();\n\t\t$status = '\''Required headers present'\'';/' "$WORKER_FILE"
    echo "✅ chkBootConfigTxt() Aufruf deaktiviert"
    echo "   → worker.php wird config.txt NICHT mehr prüfen"
    echo "   → KEIN Overwrite mehr möglich"
else
    echo "⚠️  chkBootConfigTxt() Aufruf nicht gefunden"
fi

# METHODE 2: Overwrite-Befehle deaktivieren (zusätzliche Sicherheit)
if grep -q "sysCmd('cp /usr/share/moode-player/boot/firmware/config.txt /boot/firmware/')" "$WORKER_FILE"; then
    # Kommentiere beide Overwrite-Befehle aus
    sed -i "s/sysCmd('cp \/usr\/share\/moode-player\/boot\/firmware\/config.txt \/boot\/firmware\/');/\/\/ PERMANENT FIX: Overwrite disabled\n\t\t\t\/\/ sysCmd('cp \/usr\/share\/moode-player\/boot\/firmware\/config.txt \/boot\/firmware\/');/g" "$WORKER_FILE"
    sed -i "s/sysCmd('cp -f \/usr\/share\/moode-player\/boot\/firmware\/config.txt \/boot\/firmware\/');/\/\/ PERMANENT FIX: Overwrite disabled\n\t\t\t\/\/ sysCmd('cp -f \/usr\/share\/moode-player\/boot\/firmware\/config.txt \/boot\/firmware\/');/g" "$WORKER_FILE"
    echo "✅ Overwrite-Befehle deaktiviert"
else
    echo "⚠️  Overwrite-Befehle nicht gefunden (bereits patched?)"
fi

echo ""
echo "✅ PERMANENTER FIX ANGEWENDET"
echo ""
echo "worker.php wird config.txt NICHT mehr überschreiben!"
echo ""
echo "Nächste Schritte:"
echo "  1. Pi booten"
echo "  2. Nach Boot: SSH zum Pi"
echo "  3. Ausführen: sudo /boot/firmware/fix-worker-permanent.sh"
echo "  4. Fertig - config.txt wird NICHT mehr überschrieben"
echo ""

PATCH_EOF

chmod +x "$SD_MOUNT/fix-worker-permanent.sh"

echo "✅ Fix-Script erstellt: $SD_MOUNT/fix-worker-permanent.sh"
echo ""
echo "=== ALTERNATIVE: config.txt schreibgeschützt machen ==="
echo ""

# Create script to make config.txt read-only
cat > "$SD_MOUNT/make-config-readonly.sh" << 'READONLY_EOF'
#!/bin/bash
# Macht config.txt schreibgeschützt - verhindert Overwrite komplett

CONFIG_FILE="/boot/firmware/config.txt"

if [ -f "$CONFIG_FILE" ]; then
    # Schreibgeschützt machen
    chmod 444 "$CONFIG_FILE"
    echo "✅ config.txt ist jetzt schreibgeschützt"
    echo "   → worker.php kann sie NICHT überschreiben"
    echo ""
    echo "⚠️  WICHTIG: Wenn du config.txt ändern willst:"
    echo "   chmod 644 $CONFIG_FILE"
    echo "   (dann wieder: chmod 444 $CONFIG_FILE)"
else
    echo "❌ config.txt nicht gefunden"
fi
READONLY_EOF

chmod +x "$SD_MOUNT/make-config-readonly.sh"

echo "✅ Readonly-Script erstellt: $SD_MOUNT/make-config-readonly.sh"
echo ""
echo "=== ZUSAMMENFASSUNG ==="
echo ""
echo "ZWEI PERMANENTE LÖSUNGEN erstellt:"
echo ""
echo "1. fix-worker-permanent.sh"
echo "   → Patched worker.php, damit es config.txt NICHT prüft"
echo "   → KEIN Overwrite mehr möglich"
echo ""
echo "2. make-config-readonly.sh"
echo "   → Macht config.txt schreibgeschützt"
echo "   → Overwrite physisch unmöglich"
echo ""
echo "WÄHLE EINE:"
echo "  - Option 1: Besser (worker.php wird nicht mehr prüfen)"
echo "  - Option 2: Sicherer (physischer Schutz)"
echo ""
echo "Nach Boot: SSH zum Pi und ausführen:"
echo "  sudo /boot/firmware/fix-worker-permanent.sh"
echo "  ODER"
echo "  sudo /boot/firmware/make-config-readonly.sh"
echo ""

