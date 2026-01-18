#!/usr/bin/env bash
################################################################################
#
# Dev convenience launcher
#
# Goal:
# - In devcontainer: show status + quick URLs, verify services are up.
# - Outside devcontainer: provide a safe fallback using PHP built-in server.
#
# Notes:
# - This does NOT try to reconfigure system nginx/php-fpm on a real moOde install.
# - For real hardware/audio validation, use: scripts/diagnose_audio.sh
#
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

PORT="${PORT:-8080}"
WEB_ROOT_DEFAULT="$PROJECT_ROOT/moode-source/www"
WEB_ROOT="${WEB_ROOT:-$WEB_ROOT_DEFAULT}"

usage() {
  cat <<EOF
Usage:
  cd ~/moodeaudio-cursor && ./scripts/start.sh [--status|--php]

Modes:
  --status   Print basic status checks (default)
  --php      Run PHP built-in server on :$PORT (portable fallback)

Environment:
  PORT=8080
  WEB_ROOT=/path/to/docroot (default: moode-source/www)
EOF
}

have() { command -v "$1" >/dev/null 2>&1; }

status() {
  echo "=== moOde dev status ==="
  echo "Project root: $PROJECT_ROOT"
  echo "Web root:     $WEB_ROOT"
  echo "Port:         $PORT"
  echo ""

if [ -d "/workspaces" ]; then
    echo "Environment:  devcontainer (detected /workspaces)"
  else
    echo "Environment:  host (no /workspaces detected)"
  fi
  echo ""

  if have nginx; then
    echo "--- nginx ---"
    nginx -v || true
    if have curl; then
      curl -fsS "http://127.0.0.1:${PORT}/" >/dev/null 2>&1 && echo "HTTP:         OK (http://127.0.0.1:${PORT}/)" || echo "HTTP:         not reachable on :${PORT}"
    else
      echo "HTTP:         (curl not installed)"
    fi
    echo ""
  fi

  if have php-fpm; then
    echo "--- php-fpm ---"
    php-fpm -v || true
    echo ""
  fi

  if have mpd && have mpc; then
    echo "--- mpd/mpc ---"
    mpc status || true
    mpc outputs || true
    echo ""
  fi

  echo "Open in browser:"
  echo "  http://127.0.0.1:${PORT}/"
}

run_php_builtin() {
  if ! have php; then
    echo "[ERROR] php not found. In devcontainer it should be installed." >&2
    exit 1
  fi

  if [ ! -d "$WEB_ROOT" ]; then
    echo "[ERROR] WEB_ROOT directory not found: $WEB_ROOT" >&2
    exit 1
  fi

  echo "Starting PHP built-in server:"
  echo "  Docroot: $WEB_ROOT"
  echo "  URL:     http://127.0.0.1:${PORT}/"
  echo ""
  echo "Press Ctrl-C to stop."
  echo ""
  exec php -S "0.0.0.0:${PORT}" -t "$WEB_ROOT"
}

case "${1:-"--status"}" in
  --status) status ;;
  --php) run_php_builtin ;;
  -h|--help) usage ;;
  *)
    echo "[ERROR] Unknown option: ${1:-}" >&2
    usage
    exit 2
    ;;
esac

