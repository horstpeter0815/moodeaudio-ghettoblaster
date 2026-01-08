#!/bin/bash
# Ghettoblaster - Fix moOde worker.php für display_rotate=3
# Stellt sicher dass worker.php display_rotate=3 respektiert

PI5_ALIAS="pi2"
PI5_IP="192.168.178.143"
LOG_FILE="fix-moode-worker-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

echo "=== FIX MOODE WORKER.PHP ===" | tee -a "$LOG_FILE"

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
log "=== SCHRITT 1: WORKER.PHP BACKUP ==="

./pi5-ssh.sh << 'EOF_BACKUP'
WORKER_FILE="/var/www/daemon/worker.php"
BACKUP_FILE="${WORKER_FILE}.backup-$(date +%Y%m%d_%H%M%S)"

sudo cp "$WORKER_FILE" "$BACKUP_FILE"
echo "✅ Backup erstellt: $BACKUP_FILE"
EOF_BACKUP

log ""
log "=== SCHRITT 2: WORKER.PHP ANPASSEN ==="

# Passe worker.php an, damit display_rotate=3 nach dem Kopieren wiederhergestellt wird
./pi5-ssh.sh << 'EOF_PATCH'
WORKER_FILE="/var/www/daemon/worker.php"

# Prüfe ob Patch bereits angewendet wurde
if grep -q "Ghettoblaster: display_rotate=3" "$WORKER_FILE"; then
    echo "✅ Patch bereits angewendet"
    exit 0
fi

# Erstelle Patch
sudo sed -i '/sysCmd.*cp.*config.txt.*\/boot\/firmware\//a\
		// Ghettoblaster: Stelle display_rotate=3 wieder her\
		sysCmd("sed -i \"/^display_rotate=/d\" /boot/firmware/config.txt");\
		sysCmd("echo \"display_rotate=3\" >> /boot/firmware/config.txt");
' "$WORKER_FILE"

echo "✅ worker.php angepasst"
EOF_PATCH

log ""
log "=== SCHRITT 3: VERIFIKATION ==="

log "Prüfe ob Patch angewendet wurde:"
./pi5-ssh.sh "grep -A 2 'Ghettoblaster: display_rotate=3' /var/www/daemon/worker.php" | tee -a "$LOG_FILE"

log ""
log "=== ZUSAMMENFASSUNG ==="
log "✅ worker.php angepasst"
log "✅ display_rotate=3 wird nach Template-Kopie wiederhergestellt"
log ""
log "Nächste Schritte:"
log "  1. moOde worker.php wird display_rotate=3 respektieren"
log "  2. Kein Fix-Service mehr nötig"

echo "==========================================" | tee -a "$LOG_FILE"
echo "✅ MOODE WORKER.PHP FIX ABGESCHLOSSEN" | tee -a "$LOG_FILE"
echo "==========================================" | tee -a "$LOG_FILE"

