#!/bin/bash
################################################################################
#
# Add Radio Stations to moOde
# 
# Adds FM4 (Austria) and Deutschlandfunk stations (Nova, Kultur, Main)
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
PI_HOST="${1:-172.24.1.1}"
PI_USER="${2:-andre}"
PI_PASS="${3:-0815}"

log "Adding radio stations to moOde on $PI_USER@$PI_HOST"

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
    
    log "Adding: $name"
    
    # Escape quotes in name for JSON
    local name_escaped=$(echo "$name" | sed 's/"/\\"/g')
    
    # Create station data JSON (using printf to avoid issues with spaces)
    local station_json=$(printf '{"path":{"name":"%s","url":"%s","type":"r","genre":"Various","broadcaster":"%s","language":"German","country":"%s","region":"Europe","bitrate":"128","format":"MP3","geo_fenced":"No","home_page":"","monitor":"No"}}' \
        "$name_escaped" "$url" "$(echo "$name" | cut -d' ' -f1)" "$country")
    
    # Add station via moOde radio API
    local result=$(sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=no "$PI_USER@$PI_HOST" \
        "curl -s -X POST 'http://localhost/command/radio.php?cmd=new_station' \
        -H 'Content-Type: application/json' \
        -d '$station_json'")
    
    if echo "$result" | grep -q "OK\|job submitted"; then
        log "✅ Added: $name"
        return 0
    else
        warn "❌ Failed to add: $name - $result"
        return 1
    fi
}

# Radio stations to add with best quality streams
# FM4 Austria - ORF stream
add_station "FM4" "https://orf-live.ors-shoutcast.at/fm4-q2a" "Austria"
sleep 1

# Deutschlandfunk stations - best quality streams (128kbps MP3)
add_station "Deutschlandfunk" "https://st01.sslstream.dlf.de/dlf/01/128/mp3/stream.mp3" "Germany"
sleep 1

add_station "Deutschlandfunk Nova" "https://st01.sslstream.dlf.de/dlf/02/128/mp3/stream.mp3" "Germany"
sleep 1

add_station "Deutschlandfunk Kultur" "https://st01.sslstream.dlf.de/dlf/03/128/mp3/stream.mp3" "Germany"

log "✅ All radio stations added!"
log "Refresh moOde web interface to see the new stations in the Radio section"
