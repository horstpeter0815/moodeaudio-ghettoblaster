#!/bin/bash
# Boot-Screen-Nachricht hinzufügen
# Verewigt den Entwickler auf jedem Boot-Screen

PI5_ALIAS="pi2"
PI5_IP="192.168.178.143"
LOG_FILE="boot-message-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

echo "=== BOOT SCREEN MESSAGE IMPLEMENTATION ===" | tee -a "$LOG_FILE"

# Prüfe ob Pi 5 online ist
if ! ping -c 1 -W 1000 "$PI5_IP" >/dev/null 2>&1; then
    log "❌ Pi 5 ist offline. Bitte sicherstellen, dass er läuft."
    exit 1
fi
if ! ssh -o ConnectTimeout=5 "$PI5_ALIAS" "echo 'Online!'" >/dev/null 2>&1; then
    log "❌ SSH-Verbindung fehlgeschlagen. Bitte SSH-Setup prüfen."
    exit 1
fi
log "✅ Pi 5 ist online"

log "1. Erstelle /etc/issue (Boot-Screen Text)..."
./pi5-ssh.sh << 'EOF_ISSUE'
sudo tee /etc/issue > /dev/null << 'ISSUE_EOF'
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║          moOde Audio Player - Custom Build                  ║
║                                                              ║
║     Powered by Advanced AI Engineering                      ║
║     Developed with precision and care                       ║
║                                                              ║
║     "Excellence is not a destination,                       ║
║      it's a continuous journey."                            ║
║                                                              ║
║     Built for audio enthusiasts who                        ║
║     demand perfection in every detail.                     ║
║                                                              ║
║     System initializing...                                 ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

ISSUE_EOF
EOF_ISSUE
log "   ✅ /etc/issue erstellt"

log "2. Erstelle /etc/motd (Message of the Day)..."
./pi5-ssh.sh << 'EOF_MOTD'
sudo tee /etc/motd > /dev/null << 'MOTD_EOF'

╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║          moOde Audio Player - Custom Build                  ║
║                                                              ║
║     Powered by Advanced AI Engineering                      ║
║     Developed with precision and care                       ║
║                                                              ║
║     "Excellence is not a destination,                       ║
║      it's a continuous journey."                            ║
║                                                              ║
║     Built for audio enthusiasts who                        ║
║     demand perfection in every detail.                     ║
║                                                              ║
║     Welcome to your audio system!                           ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝

MOTD_EOF
EOF_MOTD
log "   ✅ /etc/motd erstellt"

log "3. Aktiviere systemd.show_status=yes in cmdline.txt..."
./pi5-ssh.sh << 'EOF_CMDLINE'
CMDLINE_FILE="/boot/firmware/cmdline.txt"
if ! grep -q "systemd.show_status=yes" "$CMDLINE_FILE"; then
    sudo sed -i 's/rootwait/rootwait systemd.show_status=yes/' "$CMDLINE_FILE"
    log "   ✅ systemd.show_status=yes hinzugefügt"
else
    log "   ℹ️  systemd.show_status=yes bereits vorhanden"
fi
EOF_CMDLINE

log "4. Verifikation..."
log "   /etc/issue:"
./pi5-ssh.sh "cat /etc/issue" | tee -a "$LOG_FILE"
log ""
log "   /etc/motd:"
./pi5-ssh.sh "cat /etc/motd" | tee -a "$LOG_FILE"

echo "==========================================" | tee -a "$LOG_FILE"
echo "✅ BOOT SCREEN MESSAGE IMPLEMENTIERT" | tee -a "$LOG_FILE"
echo "==========================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Die Nachricht wird bei jedem Boot angezeigt!" | tee -a "$LOG_FILE"
echo "Reboot, um die Änderungen zu sehen." | tee -a "$LOG_FILE"

