#!/bin/bash
################################################################################
#
# UNIFIED DEV TOOL
#
# Purpose:
# - Devcontainer-friendly status checks
# - Pi-friendly audio diagnostics entrypoint
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() { echo -e "${GREEN}[DEV]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

usage() {
  cat <<EOF
Usage:
  cd ~/moodeaudio-cursor && ./tools/dev.sh [--status|--start|--diagnose-audio|--diagnose-boot|--sync-pi|--ssh-diagnose-audio|--ssh-diagnose-boot]

Commands:
  --status          Show local dev status (web URL, service hints)
  --start           Run ./scripts/start.sh --status
  --diagnose-audio  Run ./scripts/diagnose_audio.sh
  --diagnose-boot   Run ./scripts/diagnose_boot.sh (Pi boot/systemd evidence)
  --sync-pi         Rsync this repo to the Pi (fast iteration loop)
  --ssh-diagnose-audio  Run audio diagnostics on the Pi over SSH
  --ssh-diagnose-boot   Run boot/systemd diagnostics on the Pi over SSH
  --ssh-test-audio     Test direct audio configuration on Pi over SSH
  --ssh-fix-audio      Fix direct audio configuration on Pi over SSH

Environment (sync/ssh):
  PI_HOST=192.168.10.2
  PI_USER=andre
  PI_DEST=~/moodeaudio-cursor
EOF
}

dev_status() {
  log "Dev status"
  echo ""
  echo "Web (devcontainer): http://127.0.0.1:8080/"
  echo ""
  info "Tip: inside Cursor devcontainer, run:"
  echo "  cd ~/moodeaudio-cursor && ./scripts/start.sh --status"
  echo ""
  info "Truth-on-Pi audio checks:"
  echo "  cd ~/moodeaudio-cursor && ./scripts/diagnose_audio.sh"
}

sync_pi() {
  local pi_host="${PI_HOST:-192.168.10.2}"
  local pi_user="${PI_USER:-andre}"
  local pi_dest="${PI_DEST:-~/moodeaudio-cursor}"

  if ! command -v rsync >/dev/null 2>&1; then
    error "rsync not found"
    exit 1
  fi

  log "Syncing repo to Pi via rsync"
  echo ""
  echo "Target: ${pi_user}@${pi_host}:${pi_dest}"
  echo ""

  rsync -av --delete \
    --exclude '.git' \
    --exclude 'archive' \
    --exclude 'downloads' \
    --exclude 'imgbuild' \
    --exclude 'kernel-build' \
    --exclude 'drivers-repos' \
    --exclude 'services-repos' \
    --exclude 'complete-sim-logs' \
    --exclude 'system-sim-logs' \
    --exclude 'network-test-logs' \
    --exclude '.cursor' \
    --exclude '.DS_Store' \
    "$PROJECT_ROOT/" "${pi_user}@${pi_host}:${pi_dest}/"

  log "Sync complete"
  echo "Next on Pi:"
  echo "  cd ~/moodeaudio-cursor && ./scripts/diagnose_audio.sh"
}

ssh_diagnose_audio() {
  local pi_host="${PI_HOST:-192.168.10.2}"
  local pi_user="${PI_USER:-andre}"
  local pi_dest="${PI_DEST:-~/moodeaudio-cursor}"

  if ! command -v ssh >/dev/null 2>&1; then
    error "ssh not found"
    exit 1
  fi

  log "Running audio diagnostics on Pi over SSH"
  echo ""
  echo "Target: ${pi_user}@${pi_host}"
  echo ""
  ssh "${pi_user}@${pi_host}" "cd ${pi_dest} && ./scripts/diagnose_audio.sh"
}

ssh_diagnose_boot() {
  local pi_host="${PI_HOST:-192.168.10.2}"
  local pi_user="${PI_USER:-andre}"
  local pi_dest="${PI_DEST:-~/moodeaudio-cursor}"

  if ! command -v ssh >/dev/null 2>&1; then
    error "ssh not found"
    exit 1
  fi

  log "Running boot/systemd diagnostics on Pi over SSH"
  echo ""
  echo "Target: ${pi_user}@${pi_host}"
  echo ""
  ssh "${pi_user}@${pi_host}" "cd ${pi_dest} && ./scripts/diagnose_boot.sh"
}

ssh_test_audio() {
  local pi_host="${PI_HOST:-192.168.10.2}"
  local pi_user="${PI_USER:-andre}"
  local pi_dest="${PI_DEST:-~/moodeaudio-cursor}"

  if ! command -v ssh >/dev/null 2>&1; then
    error "ssh not found"
    exit 1
  fi

  log "Testing direct audio configuration on Pi over SSH"
  echo ""
  echo "Target: ${pi_user}@${pi_host}"
  echo ""
  ssh "${pi_user}@${pi_host}" "cd ${pi_dest} && sudo bash scripts/audio/TEST_DIRECT_AUDIO.sh"
}

ssh_fix_audio() {
  local pi_host="${PI_HOST:-192.168.10.2}"
  local pi_user="${PI_USER:-andre}"
  local pi_dest="${PI_DEST:-~/moodeaudio-cursor}"

  if ! command -v ssh >/dev/null 2>&1; then
    error "ssh not found"
    exit 1
  fi

  log "Fixing direct audio configuration on Pi over SSH"
  echo ""
  echo "Target: ${pi_user}@${pi_host}"
  echo ""
  ssh "${pi_user}@${pi_host}" "cd ${pi_dest} && sudo bash scripts/audio/FIX_DIRECT_AUDIO.sh"
}

main() {
  case "${1:-}" in
    --status|"")
      dev_status
      ;;
    --start)
      bash "$PROJECT_ROOT/scripts/start.sh" --status
      ;;
    --diagnose-audio)
      bash "$PROJECT_ROOT/scripts/diagnose_audio.sh"
      ;;
    --diagnose-boot)
      bash "$PROJECT_ROOT/scripts/diagnose_boot.sh"
      ;;
    --sync-pi)
      sync_pi
      ;;
    --ssh-diagnose-audio)
      ssh_diagnose_audio
      ;;
    --ssh-diagnose-boot)
      ssh_diagnose_boot
      ;;
    --ssh-test-audio)
      ssh_test_audio
      ;;
    --ssh-fix-audio)
      ssh_fix_audio
      ;;
    -h|--help)
      usage
      ;;
    *)
      error "Unknown option: $1"
      usage
      exit 2
      ;;
  esac
}

main "$@"

