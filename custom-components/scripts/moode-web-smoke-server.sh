#!/bin/bash
#
# Minimal WebUI smoke server for Docker simulation.
# Serves /var/www/html (bind-mounted moode-source/www) on port 80.
#

set -euo pipefail

DOCROOT="/var/www/html"
HOST="0.0.0.0"
PORT="80"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [moode-web] $*"
}

if [ ! -d "$DOCROOT" ]; then
  log "ERROR: docroot not found: $DOCROOT"
  exit 1
fi

if ! command -v php >/dev/null 2>&1; then
  log "ERROR: php not installed"
  exit 1
fi

log "Starting PHP built-in server on http://$HOST:$PORT (docroot=$DOCROOT)"
exec php -S "$HOST:$PORT" -t "$DOCROOT"
