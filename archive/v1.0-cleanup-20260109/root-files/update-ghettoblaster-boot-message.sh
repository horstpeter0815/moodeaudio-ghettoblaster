#!/bin/bash
# Ghettoblaster - Boot-Screen-Nachricht aktualisieren
# Aktualisiert Boot-Screen zu "Ghettoblaster"

PI5_ALIAS="pi2"
PI5_IP="192.168.178.143"
LOG_FILE="ghettoblaster-boot-message-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

echo "=== GHETTOBLASTER - BOOT SCREEN UPDATE ===" | tee -a "$LOG_FILE"

# Check if Pi 5 is online
if ! ping -c 1 -W 1000 "$PI5_IP" >/dev/null 2>&1; then
    log "❌ Pi 5 ist offline. Bitte stellen Sie sicher, dass es läuft."
    exit 1
fi
if ! ssh -o ConnectTimeout=5 "$PI5_ALIAS" "echo 'Online!'" >/dev/null 2>&1; then
    log "❌ SSH-Verbindung zu Pi 5 fehlgeschlagen. Bitte überprüfen Sie das SSH-Setup."
    exit 1
fi
log "✅ Pi 5 ist online"

BOOT_MESSAGE="
╔══════════════════════════════════════════════════════════════╗
║                                                              ║
║                    Ghettoblaster                            ║
║                                                              ║
║     Powered by Advanced AI Engineering                      ║
║     Developed with precision and care                       ║
║                                                              ║
║     \"Excellence is not a destination,                       ║
║      it's a continuous journey.\"                            ║
║                                                              ║
║     Built for audio enthusiasts who                        ║
║     demand perfection in every detail.                     ║
║                                                              ║
║     Welcome to your Ghettoblaster!                        ║
║                                                              ║
╚══════════════════════════════════════════════════════════════╝
"

log "1. Erstelle /etc/issue (Boot-Screen Text)..."
./pi5-ssh.sh "echo '$BOOT_MESSAGE' | sudo tee /etc/issue"
log "   ✅ /etc/issue erstellt"

log "2. Erstelle /etc/motd (Message of the Day)..."
./pi5-ssh.sh "echo '$BOOT_MESSAGE' | sudo tee /etc/motd"
log "   ✅ /etc/motd erstellt"

log "3. Verifikation..."
log "   /etc/issue:"
./pi5-ssh.sh "sudo cat /etc/issue" | tee -a "$LOG_FILE"

echo "==========================================" | tee -a "$LOG_FILE"
echo "✅ GHETTOBLASTER BOOT SCREEN AKTUALISIERT" | tee -a "$LOG_FILE"
echo "==========================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Die Nachricht wird bei jedem Boot angezeigt!" | tee -a "$LOG_FILE"
echo "Reboot, um die Änderungen zu sehen." | tee -a "$LOG_FILE"

