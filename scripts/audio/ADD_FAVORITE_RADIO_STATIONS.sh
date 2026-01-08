#!/bin/bash
################################################################################
#
# Add Favorite Radio Stations to moOde
# 
# Adds:
# - FM4 (Austria) - 192kbps
# - Radio Ton Heilbronn - 192kbps
# - Deutschlandfunk - AAC 192kbps (best quality)
# - Deutschlandfunk Kultur - AAC 192kbps (best quality)
# - Deutschlandfunk Nova - AAC 192kbps (best quality)
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
cd "$PROJECT_ROOT"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

log() {
    echo -e "${GREEN}[RADIO]${NC} $1"
}

warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

# Check if Pi is reachable
PI_HOST="${1:-192.168.2.3}"
PI_USER="${2:-andre}"
PI_PASS="${3:-0815}"

log "Adding favorite radio stations to moOde on $PI_USER@$PI_HOST"

# Wait for Pi to be reachable
log "Waiting for Pi to be reachable..."
for i in {1..30}; do
    if sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no -o ConnectTimeout=2 "$PI_USER@$PI_HOST" "echo 'OK'" >/dev/null 2>&1; then
        log "Pi is reachable!"
        break
    fi
    if [ $i -eq 30 ]; then
        warn "Pi not reachable after 30 attempts. Please check connection."
        exit 1
    fi
    sleep 2
done

# Function to add a station via moOde API
add_station() {
    local name="$1"
    local url="$2"
    local country="$3"
    local genre="${4:-Various}"
    local bitrate="${5:-192}"
    local format="${6:-AAC}"
    
    log "Adding: $name ($format $bitrate kbps)"
    
    # Escape quotes in name for JSON
    local name_escaped=$(echo "$name" | sed 's/"/\\"/g')
    
    # Create station data JSON
    local station_json=$(printf '{"path":{"name":"%s","url":"%s","type":"r","genre":"%s","broadcaster":"%s","language":"German","country":"%s","region":"Europe","bitrate":"%s","format":"%s","geo_fenced":"No","home_page":"","monitor":"No"}}' \
        "$name_escaped" "$url" "$genre" "$(echo "$name" | cut -d' ' -f1)" "$country" "$bitrate" "$format")
    
    # Add station via moOde radio API
    local result=$(sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" \
        "curl -s -X POST 'http://localhost/command/radio.php?cmd=new_station' \
        -H 'Content-Type: application/json' \
        -d '$station_json'")
    
    if echo "$result" | grep -q "OK\|job submitted"; then
        log "✅ Added: $name"
        return 0
    elif echo "$result" | grep -qi "already exists"; then
        log "⏭️  Skipping: $name (already exists)"
        return 0
    else
        warn "❌ Failed to add: $name - $result"
        return 1
    fi
}

log "Adding favorite radio stations with best quality streams..."

# FM4 Austria - 192kbps MP3
add_station "FM4" "https://orf-live.ors-shoutcast.at/fm4-q2a" "Austria" "Alternative" "192" "MP3"
sleep 1

# Radio Ton Heilbronn - 192kbps MP3
add_station "Radio Ton Heilbronn" "https://stream.radioton.de/radioton-heilbronn/mp3-192" "Germany" "Regional" "192" "MP3"
sleep 1

# Deutschlandfunk - AAC 192kbps (best quality)
add_station "Deutschlandfunk" "https://st01.sslstream.dlf.de/dlf/01/high/aac/stream.aac?aggregator=web" "Germany" "News" "192" "AAC"
sleep 1

# Deutschlandfunk Kultur - AAC 192kbps (best quality)
add_station "Deutschlandfunk Kultur" "https://st02.sslstream.dlf.de/dlf/02/high/aac/stream.aac?aggregator=web" "Germany" "Culture" "192" "AAC"
sleep 1

# Deutschlandfunk Nova - AAC 192kbps (best quality)
add_station "Deutschlandfunk Nova" "https://st03.sslstream.dlf.de/dlf/03/high/aac/stream.aac?aggregator=web" "Germany" "Youth" "192" "AAC"

log ""
log "✅ All favorite radio stations added!"
log "Refresh moOde web interface to see the new stations in the Radio section"
log ""
log "Stations added:"
log "  - FM4 (Austria, 192kbps MP3)"
log "  - Radio Ton Heilbronn (Germany, 192kbps MP3)"
log "  - Deutschlandfunk (Germany, 192kbps AAC)"
log "  - Deutschlandfunk Kultur (Germany, 192kbps AAC)"
log "  - Deutschlandfunk Nova (Germany, 192kbps AAC)"

