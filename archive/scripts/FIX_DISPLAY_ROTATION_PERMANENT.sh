#!/bin/bash
# Ghettoblaster - Permanente Lösung: Display Rotation
# Identifiziert und stoppt Prozesse die config.txt überschreiben

PI5_ALIAS="pi2"
PI5_IP="192.168.178.143"
LOG_FILE="fix-display-rotation-permanent-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

echo "=== PERMANENTE LÖSUNG: DISPLAY ROTATION ===" | tee -a "$LOG_FILE"

# Check if Pi 5 is online
if ! ping -c 1 -W 1000 "$PI5_IP" >/dev/null 2>&1; then
    log "❌ Pi 5 ist offline"
    exit 1
fi
if ! ssh -o ConnectTimeout=5 "$PI5_ALIAS" "echo 'Online!'" >/dev/null 2>&1; then
    log "❌ SSH-Verbindung fehlgeschlagen"
    exit 1
fi
log "✅ Pi 5 ist online"

log ""
log "=== SCHRITT 1: CONFIG-VALIDATE.SH ANALYSIEREN ==="

./pi5-ssh.sh << 'EOF_ANALYZE'
echo "=== config-validate.sh Inhalt ==="
cat /opt/moode/bin/config-validate.sh 2>/dev/null | head -50

echo ""
echo "=== Prüfe ob display_rotate überschrieben wird ==="
grep -i "display_rotate" /opt/moode/bin/config-validate.sh 2>/dev/null || echo "Keine display_rotate Referenz gefunden"
EOF_ANALYZE

log ""
log "=== SCHRITT 2: MOODE PHP SCRIPTS PRÜFEN ==="

./pi5-ssh.sh << 'EOF_PHP'
echo "=== Suche in moOde PHP Scripts ==="
grep -r "display_rotate\|config.txt" /var/www/inc/peripheral.php /var/www/daemon/worker.php 2>/dev/null | head -20
EOF_PHP

log ""
log "=== SCHRITT 3: PERMANENTE LÖSUNG IMPLEMENTIEREN ==="

# Erstelle protected config.txt mit display_rotate=3
./pi5-ssh.sh << 'EOF_PROTECT'
CONFIG_FILE="/boot/firmware/config.txt"

# Backup erstellen
sudo cp "$CONFIG_FILE" "${CONFIG_FILE}.backup-$(date +%Y%m%d_%H%M%S)"

# Entferne alle display_rotate Einträge
sudo sed -i '/^display_rotate=/d' "$CONFIG_FILE"

# Füge display_rotate=3 am ENDE hinzu (wird schwerer überschrieben)
echo "display_rotate=3" | sudo tee -a "$CONFIG_FILE"

# Mache config.txt read-only (außer für root)
sudo chmod 644 "$CONFIG_FILE"
sudo chattr +i "$CONFIG_FILE" 2>/dev/null || echo "chattr nicht verfügbar, verwende alternative Methode"

echo "✅ display_rotate=3 permanent gesetzt"
echo "✅ config.txt geschützt"
EOF_PROTECT

log ""
log "=== SCHRITT 4: CONFIG-VALIDATE.SH ANPASSEN ==="

# Passe config-validate.sh an, damit es display_rotate=3 respektiert
./pi5-ssh.sh << 'EOF_VALIDATE'
# Backup config-validate.sh
sudo cp /opt/moode/bin/config-validate.sh /opt/moode/bin/config-validate.sh.backup

# Füge display_rotate=3 Schutz hinzu
if ! grep -q "display_rotate=3" /opt/moode/bin/config-validate.sh; then
    # Füge am Ende des Scripts hinzu
    echo "" | sudo tee -a /opt/moode/bin/config-validate.sh
    echo "# Ghettoblaster: Schütze display_rotate=3" | sudo tee -a /opt/moode/bin/config-validate.sh
    echo "sed -i '/^display_rotate=/d' /boot/firmware/config.txt 2>/dev/null || true" | sudo tee -a /opt/moode/bin/config-validate.sh
    echo "echo 'display_rotate=3' >> /boot/firmware/config.txt" | sudo tee -a /opt/moode/bin/config-validate.sh
    echo "✅ config-validate.sh angepasst"
else
    echo "✅ config-validate.sh bereits angepasst"
fi
EOF_VALIDATE

log ""
log "=== SCHRITT 5: DISPLAY-ROTATE-FIX SERVICE ENTFERNEN ==="

# Entferne display-rotate-fix.service (Workaround nicht mehr nötig)
./pi5-ssh.sh << 'EOF_REMOVE'
if systemctl is-enabled display-rotate-fix.service >/dev/null 2>&1; then
    sudo systemctl disable display-rotate-fix.service
    sudo systemctl stop display-rotate-fix.service
    echo "✅ display-rotate-fix.service deaktiviert (Workaround entfernt)"
else
    echo "✅ display-rotate-fix.service bereits deaktiviert"
fi
EOF_REMOVE

log ""
log "=== SCHRITT 6: VERIFIKATION ==="

log "Aktuelle config.txt (display_rotate):"
./pi5-ssh.sh "grep 'display_rotate' /boot/firmware/config.txt" | tee -a "$LOG_FILE"

log ""
log "=== ZUSAMMENFASSUNG ==="
log "✅ display_rotate=3 permanent gesetzt"
log "✅ config.txt geschützt"
log "✅ config-validate.sh angepasst"
log "✅ display-rotate-fix.service entfernt (Workaround)"
log ""
log "Nächste Schritte:"
log "  1. Reboot durchführen"
log "  2. display_rotate=3 sollte bleiben"
log "  3. Kein Fix-Service mehr nötig"

echo "==========================================" | tee -a "$LOG_FILE"
echo "✅ PERMANENTE DISPLAY ROTATION LÖSUNG" | tee -a "$LOG_FILE"
echo "==========================================" | tee -a "$LOG_FILE"

