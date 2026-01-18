#!/bin/bash
#
# moOde DB smoke test (simulation + CI-style invariant checks)
# - Builds a sqlite DB from the seed SQL
# - Asserts key invariants that protect against the IEC958 regression and HDMI fallback
#
# Expected input:
# - /opt/moode-seed/moode-sqlite3.db.sql (bind-mounted by docker-compose.complete-simulation.yml)
#

set -euo pipefail

SQL_IN="/opt/moode-seed/moode-sqlite3.db.sql"
DB_DIR="/var/local/www/db"
DB_PATH="$DB_DIR/moode-sqlite3.db"

log() {
  echo "[$(date '+%Y-%m-%d %H:%M:%S')] [moode-db-smoketest] $*"
}

fail() {
  log "FAIL: $*"
  exit 1
}

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || fail "missing command: $1"
}

require_cmd sqlite3

if [ ! -f "$SQL_IN" ]; then
  fail "seed SQL not found: $SQL_IN"
fi

mkdir -p "$DB_DIR"
rm -f "$DB_PATH"

log "Creating sqlite DB from seed SQL: $SQL_IN"
sqlite3 "$DB_PATH" <"$SQL_IN"

q() {
  local sql="$1"
  sqlite3 -batch -noheader "$DB_PATH" "$sql" | tr -d '\r'
}

assert_eq() {
  local name="$1"
  local got="$2"
  local want="$3"
  if [ "$got" != "$want" ]; then
    fail "$name expected '$want' but got '$got'"
  fi
  log "OK: $name = $want"
}

assert_nonempty() {
  local name="$1"
  local got="$2"
  if [ -z "$got" ]; then
    fail "$name expected non-empty but got empty"
  fi
  log "OK: $name is non-empty"
}

log "Checking invariants (audio + display)"

# Audio path invariants
mpd_device="$(q "SELECT value FROM cfg_mpd WHERE param='device' LIMIT 1;")"
alsa_output_mode="$(q "SELECT value FROM cfg_system WHERE param='alsa_output_mode' LIMIT 1;")"
adevname="$(q "SELECT value FROM cfg_system WHERE param='adevname' LIMIT 1;")"

assert_eq "cfg_mpd.device" "$mpd_device" "_audioout"
assert_eq "cfg_system.alsa_output_mode" "$alsa_output_mode" "plughw"
assert_nonempty "cfg_system.adevname" "$adevname"

# Safety: reject HDMI default
if echo "$adevname" | grep -qi "HDMI"; then
  fail "cfg_system.adevname unexpectedly points to HDMI: '$adevname'"
fi
log "OK: cfg_system.adevname is not HDMI ('$adevname')"

# Display invariants (optional, but useful)
local_display="$(q "SELECT value FROM cfg_system WHERE param='local_display' LIMIT 1;")"
local_display_url="$(q "SELECT value FROM cfg_system WHERE param='local_display_url' LIMIT 1;")"
hdmi_scn_orient="$(q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient' LIMIT 1;")"

assert_nonempty "cfg_system.local_display" "$local_display"
assert_nonempty "cfg_system.local_display_url" "$local_display_url"
assert_nonempty "cfg_system.hdmi_scn_orient" "$hdmi_scn_orient"

log "All DB smoke checks passed"
