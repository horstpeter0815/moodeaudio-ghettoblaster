#!/bin/bash
# Ghetto OS - Vinyl Stream Integration
# Fügt Vinyl-Player Web-Stream zu MPD hinzu

VINYL_IP=${1:-"192.168.178.XXX"}
VINYL_PORT=${2:-"8000"}
STREAM_NAME=${3:-"Vinyl Player"}
STREAM_URL="http://$VINYL_IP:$VINYL_PORT/stream"
LOG_FILE="/var/log/ghetto-os-vinyl.log"

log() {
    echo "[$(date +%H:%M:%S)] $1" | tee -a "$LOG_FILE"
}

log "=== GHETTO OS - VINYL STREAM INTEGRATION ==="
log "Vinyl Pi IP: $VINYL_IP"
log "Vinyl Pi Port: $VINYL_PORT"
log "Stream URL: $STREAM_URL"

# Prüfe ob MPD läuft
if ! systemctl is-active --quiet mpd.service; then
    log "❌ MPD Service läuft nicht"
    log "   Starte MPD Service..."
    sudo systemctl start mpd.service
    sleep 2
fi

# Prüfe Stream-Erreichbarkeit
log "Prüfe Stream-Erreichbarkeit..."
if curl -s --head --max-time 5 "$STREAM_URL" > /dev/null 2>&1; then
    log "✅ Stream erreichbar: $STREAM_URL"
else
    log "⚠️  Stream nicht erreichbar: $STREAM_URL"
    log "   Bitte Vinyl Pi IP und Port prüfen"
    exit 1
fi

# Füge Stream zu MPD hinzu
log "Füge Stream zu MPD hinzu..."
mpc add "$STREAM_URL" 2>&1 | tee -a "$LOG_FILE"

if [ $? -eq 0 ]; then
    log "✅ Stream hinzugefügt"
    
    # Speichere als Playlist
    mpc save "$STREAM_NAME" 2>&1 | tee -a "$LOG_FILE"
    log "✅ Playlist gespeichert: $STREAM_NAME"
    
    # Zeige Playlist
    log "Verfügbare Playlists:"
    mpc lsplaylists | tee -a "$LOG_FILE"
else
    log "❌ Fehler beim Hinzufügen des Streams"
    exit 1
fi

log ""
log "=== VINYL STREAM INTEGRATION ABGESCHLOSSEN ==="
log "Stream-URL: $STREAM_URL"
log "Playlist: $STREAM_NAME"
log ""
log "Verwendung:"
log "  mpc play \"$STREAM_NAME\""
log "  mpc stop"

