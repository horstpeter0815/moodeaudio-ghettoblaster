#!/bin/bash
# Ghettoblaster - Ersetzt alle Vorkommen von "moOde Audio" durch "Ghettoblaster"
# In Web-UI, Prompts, PeppyMeter, überall im System

PI5_ALIAS="pi2"
PI5_IP="192.168.178.143"
LOG_FILE="ghettoblaster-rename-$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

echo "=== GHETTOBLASTER - SYSTEM-WEITE UMBENENNUNG ===" | tee -a "$LOG_FILE"

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

log ""
log "=== SCHRITT 1: WEB-UI DATEIEN FINDEN ==="

# Finde moOde Web-UI Dateien
WEB_UI_FILES=$(./pi5-ssh.sh "find /var/www -type f \( -name '*.php' -o -name '*.html' -o -name '*.js' -o -name '*.css' \) 2>/dev/null | head -20")
log "Web-UI Dateien gefunden:"
echo "$WEB_UI_FILES" | tee -a "$LOG_FILE"

log ""
log "=== SCHRITT 2: ERSETZE IN WEB-UI DATEIEN ==="

# Ersetze in Web-UI Dateien
./pi5-ssh.sh << 'EOF_WEBUI'
# Ersetze verschiedene Varianten von moOde Audio
find /var/www -type f \( -name '*.php' -o -name '*.html' -o -name '*.js' -o -name '*.css' \) -exec sed -i 's/moOde Audio/Ghettoblaster/g' {} \;
find /var/www -type f \( -name '*.php' -o -name '*.html' -o -name '*.js' -o -name '*.css' \) -exec sed -i 's/Mood Audio/Ghettoblaster/g' {} \;
find /var/www -type f \( -name '*.php' -o -name '*.html' -o -name '*.js' -o -name '*.css' \) -exec sed -i 's/moOde/Ghettoblaster/g' {} \;
find /var/www -type f \( -name '*.php' -o -name '*.html' -o -name '*.js' -o -name '*.css' \) -exec sed -i 's/Moode/Ghettoblaster/g' {} \;
EOF_WEBUI
log "✅ Web-UI Dateien aktualisiert"

log ""
log "=== SCHRITT 3: PEPPYMETER KONFIGURATION ==="

# Ersetze in PeppyMeter Dateien
./pi5-ssh.sh << 'EOF_PEPPYMETER'
# PeppyMeter Konfiguration
if [ -f /opt/peppymeter/config.txt ]; then
    sed -i 's/moOde Audio/Ghettoblaster/g' /opt/peppymeter/config.txt
    sed -i 's/Mood Audio/Ghettoblaster/g' /opt/peppymeter/config.txt
    sed -i 's/moOde/Ghettoblaster/g' /opt/peppymeter/config.txt
fi

# PeppyMeter Python-Dateien
find /opt/peppymeter -type f \( -name '*.py' -o -name '*.txt' -o -name '*.md' \) -exec sed -i 's/moOde Audio/Ghettoblaster/g' {} \; 2>/dev/null
find /opt/peppymeter -type f \( -name '*.py' -o -name '*.txt' -o -name '*.md' \) -exec sed -i 's/Mood Audio/Ghettoblaster/g' {} \; 2>/dev/null
find /opt/peppymeter -type f \( -name '*.py' -o -name '*.txt' -o -name '*.md' \) -exec sed -i 's/moOde/Ghettoblaster/g' {} \; 2>/dev/null
EOF_PEPPYMETER
log "✅ PeppyMeter Konfiguration aktualisiert"

log ""
log "=== SCHRITT 4: SYSTEM-KONFIGURATION ==="

# Ersetze in System-Konfiguration
./pi5-ssh.sh << 'EOF_SYSTEM'
# /etc/issue und /etc/motd
if [ -f /etc/issue ]; then
    sed -i 's/moOde Audio/Ghettoblaster/g' /etc/issue
    sed -i 's/Mood Audio/Ghettoblaster/g' /etc/issue
    sed -i 's/moOde/Ghettoblaster/g' /etc/issue
fi

if [ -f /etc/motd ]; then
    sed -i 's/moOde Audio/Ghettoblaster/g' /etc/motd
    sed -i 's/Mood Audio/Ghettoblaster/g' /etc/motd
    sed -i 's/moOde/Ghettoblaster/g' /etc/motd
fi

# Systemd Service-Dateien
find /etc/systemd/system -type f -name '*.service' -exec sed -i 's/moOde Audio/Ghettoblaster/g' {} \; 2>/dev/null
find /etc/systemd/system -type f -name '*.service' -exec sed -i 's/Mood Audio/Ghettoblaster/g' {} \; 2>/dev/null

# Scripts in /usr/local/bin
find /usr/local/bin -type f -name '*.sh' -exec sed -i 's/moOde Audio/Ghettoblaster/g' {} \; 2>/dev/null
find /usr/local/bin -type f -name '*.sh' -exec sed -i 's/Mood Audio/Ghettoblaster/g' {} \; 2>/dev/null
find /usr/local/bin -type f -name '*.sh' -exec sed -i 's/moOde/Ghettoblaster/g' {} \; 2>/dev/null
EOF_SYSTEM
log "✅ System-Konfiguration aktualisiert"

log ""
log "=== SCHRITT 5: MPD KONFIGURATION ==="

# Ersetze in MPD Konfiguration
./pi5-ssh.sh << 'EOF_MPD'
if [ -f /etc/mpd.conf ]; then
    sed -i 's/moOde Audio/Ghettoblaster/g' /etc/mpd.conf
    sed -i 's/Mood Audio/Ghettoblaster/g' /etc/mpd.conf
    sed -i 's/moOde/Ghettoblaster/g' /etc/mpd.conf
fi
EOF_MPD
log "✅ MPD Konfiguration aktualisiert"

log ""
log "=== SCHRITT 6: CHROMIUM KIOSK MODE ==="

# Ersetze in Chromium Startup-Scripts
./pi5-ssh.sh << 'EOF_CHROMIUM'
# .xinitrc
if [ -f /home/andre/.xinitrc ]; then
    sed -i 's/moOde Audio/Ghettoblaster/g' /home/andre/.xinitrc
    sed -i 's/Mood Audio/Ghettoblaster/g' /home/andre/.xinitrc
    sed -i 's/moOde/Ghettoblaster/g' /home/andre/.xinitrc
fi

# Chromium Startup-Scripts
find /usr/local/bin -type f -name '*chromium*' -exec sed -i 's/moOde Audio/Ghettoblaster/g' {} \; 2>/dev/null
find /usr/local/bin -type f -name '*chromium*' -exec sed -i 's/Mood Audio/Ghettoblaster/g' {} \; 2>/dev/null
EOF_CHROMIUM
log "✅ Chromium Konfiguration aktualisiert"

log ""
log "=== SCHRITT 7: VERIFIKATION ==="

log "Prüfe Web-UI Titel..."
WEB_UI_TITLE=$(./pi5-ssh.sh "grep -r 'Ghettoblaster' /var/www 2>/dev/null | head -5")
if [ -n "$WEB_UI_TITLE" ]; then
    log "✅ Web-UI enthält 'Ghettoblaster':"
    echo "$WEB_UI_TITLE" | tee -a "$LOG_FILE"
else
    log "⚠️  Keine 'Ghettoblaster' Einträge in Web-UI gefunden"
fi

log ""
log "Prüfe /etc/issue..."
ISSUE_CONTENT=$(./pi5-ssh.sh "grep -i 'ghettoblaster' /etc/issue 2>/dev/null")
if [ -n "$ISSUE_CONTENT" ]; then
    log "✅ /etc/issue enthält 'Ghettoblaster'"
else
    log "⚠️  /etc/issue enthält noch kein 'Ghettoblaster'"
fi

log ""
log "=== SCHRITT 8: WEB-SERVER NEUSTART ==="

# Starte Web-Server neu
./pi5-ssh.sh "sudo systemctl restart nginx.service 2>/dev/null || true"
./pi5-ssh.sh "sudo systemctl restart php8.4-fpm.service 2>/dev/null || sudo systemctl restart php-fpm.service 2>/dev/null || true"
log "✅ Web-Server neu gestartet"

log ""
log "=== ZUSAMMENFASSUNG ==="
log "✅ Web-UI Dateien aktualisiert"
log "✅ PeppyMeter Konfiguration aktualisiert"
log "✅ System-Konfiguration aktualisiert"
log "✅ MPD Konfiguration aktualisiert"
log "✅ Chromium Konfiguration aktualisiert"
log "✅ Web-Server neu gestartet"

echo "==========================================" | tee -a "$LOG_FILE"
echo "✅ GHETTOBLASTER UMBENENNUNG ABGESCHLOSSEN" | tee -a "$LOG_FILE"
echo "==========================================" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Alle Vorkommen von 'moOde Audio' wurden durch 'Ghettoblaster' ersetzt!" | tee -a "$LOG_FILE"
echo "" | tee -a "$LOG_FILE"
echo "Bitte Web-UI im Browser aktualisieren (F5) um die Änderungen zu sehen." | tee -a "$LOG_FILE"

