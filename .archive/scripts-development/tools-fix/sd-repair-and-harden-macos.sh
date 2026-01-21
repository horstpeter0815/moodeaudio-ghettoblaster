#!/usr/bin/env bash
################################################################################
# macOS SD Repair + Harden (one-shot)
#
# Goal:
# - If extFS mounted rootfs read-only (dirty flag / unsafe), try to repair ext4
# - Then run the SD hardening script to restore network/display/audio configs
#
# Run:
#   cd ~/moodeaudio-cursor && sudo ./tools/fix/sd-repair-and-harden-macos.sh
################################################################################

set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
BOOTFS="/Volumes/bootfs"
ROOTFS=""
MIN_E2FSCK_VERSION="1.47.0"
PREFLIGHT_ONLY=0

log() { echo "[SD-REPAIR] $*"; }
die() { echo "[SD-REPAIR] ERROR: $*" >&2; exit 1; }

require_macos() {
  if [ "$(uname -s)" != "Darwin" ]; then
    die "This script is intended for macOS."
  fi
}

detect_mounts() {
  # extFS can mount as "rootfs", "rootfs 1", "rootfs 2", ...
  # Prefer "/Volumes/rootfs" if present, otherwise take the first matching variant.
  if [ -d "/Volumes/rootfs" ]; then
    ROOTFS="/Volumes/rootfs"
    return 0
  fi

  local candidates=()
  while IFS= read -r p; do
    candidates+=("$p")
  done < <(ls -1d /Volumes/rootfs\ * 2>/dev/null || true)

  if [ "${#candidates[@]}" -gt 0 ]; then
    ROOTFS="${candidates[0]}"
  else
    ROOTFS=""
  fi
}

version_ge() {
  # returns 0 if $1 >= $2 (semantic version with 3 numeric components)
  local a="$1"
  local b="$2"
  [ "$(printf "%s\n%s\n" "$b" "$a" | sort -V | head -n 1)" = "$b" ]
}

find_brew() {
  if command -v brew >/dev/null 2>&1; then
    command -v brew
    return 0
  fi
  # Common Homebrew locations
  if [ -x /opt/homebrew/bin/brew ]; then echo /opt/homebrew/bin/brew; return 0; fi
  if [ -x /usr/local/bin/brew ]; then echo /usr/local/bin/brew; return 0; fi
  return 1
}

brew_as_user() {
  local brewbin
  brewbin="$(find_brew)" || return 1

  # Never run Homebrew as root. If we're under sudo, run as the invoking user.
  if [ "$(id -u)" -eq 0 ] && [ -n "${SUDO_USER:-}" ]; then
    # Reduce surprise work: don't auto-update unless user explicitly does it.
    sudo -u "$SUDO_USER" -H env HOMEBREW_NO_AUTO_UPDATE=1 "$brewbin" "$@"
  else
    env HOMEBREW_NO_AUTO_UPDATE=1 "$brewbin" "$@"
  fi
}

ensure_e2fsprogs() {
  # Ensure a new-enough e2fsck is available via Homebrew.
  # Returns 0 if we (now) have it, 1 if we can't ensure it automatically.
  local brewbin=""
  if ! brewbin="$(find_brew)"; then
    return 1
  fi

  log "Homebrew detected: $brewbin"

  # Install if missing
  if ! brew_as_user list --versions e2fsprogs >/dev/null 2>&1; then
    log "Installing e2fsprogs via Homebrew..."
    brew_as_user install e2fsprogs
  else
    log "e2fsprogs is installed (checking for upgrades if needed)..."
  fi

  return 0
}

get_devnode_for_mount() {
  local mp="$1"
  # Use df instead of parsing `mount` output (mount formatting + spaces can vary with extFS/FUSE).
  # `df -P <path>` yields a stable, POSIX single-line output.
  df -P "$mp" 2>/dev/null | awk 'NR==2 {print $1; exit}'
}

is_rootfs_readonly() {
  local mp="$1"
  mount | grep -F " on $mp (" | grep -q "read-only"
}

write_test() {
  local mp="$1"
  local t="$mp/.rwtest_sdrepair"
  if ( : > "$t" ) 2>/dev/null; then
    rm -f "$t" 2>/dev/null || true
    return 0
  fi
  return 1
}

find_e2fsck() {
  local candidates=()
  local p=""

  if command -v e2fsck >/dev/null 2>&1; then
    candidates+=("$(command -v e2fsck)")
  fi

  # common Homebrew paths (Apple Silicon + Intel) + keg-only paths
  for p in \
    /opt/homebrew/sbin/e2fsck \
    /usr/local/sbin/e2fsck \
    /opt/homebrew/opt/e2fsprogs/sbin/e2fsck \
    /usr/local/opt/e2fsprogs/sbin/e2fsck
  do
    if [ -x "$p" ]; then
      candidates+=("$p")
    fi
  done

  # Deduplicate + choose newest version.
  if [ "${#candidates[@]}" -eq 0 ]; then
    return 1
  fi

  # Bash 3.2 (macOS default) does not support associative arrays, so dedupe via awk.
  local uniq=()
  while IFS= read -r p; do
    uniq+=("$p")
  done < <(printf "%s\n" "${candidates[@]}" | awk 'NF && !seen[$0]++')

  local scored=""
  local ver=""
  for p in "${uniq[@]}"; do
    ver="$("$p" -V 2>&1 | awk 'NR==1 {print $2}')"
    if [[ "$ver" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
      scored+="$ver"$'\t'"$p"$'\n'
    fi
  done

  if [ -z "$scored" ]; then
    # Fallback: return the first candidate if we can't parse versions.
    echo "${uniq[0]}"
    return 0
  fi

  printf "%s" "$scored" | sort -V | tail -n 1 | awk '{print $2}'
}

unmount_rootfs() {
  local dev="$1"
  log "Unmounting rootfs ($dev)..."
  diskutil unmount "$dev" >/dev/null || true
}

remount_rootfs() {
  local dev="$1"
  log "Attempting to mount rootfs ($dev)..."
  diskutil mount "$dev" >/dev/null || true
}

main() {
  if [ "${1:-}" = "--preflight" ]; then
    PREFLIGHT_ONLY=1
    shift || true
  fi

  require_macos
  detect_mounts

  [ -d "$BOOTFS" ] || die "bootfs not mounted at $BOOTFS. Insert SD and ensure boot partition is mounted."
  [ -n "$ROOTFS" ] || die "rootfs not mounted (expected /Volumes/rootfs or /Volumes/rootfs 1). Insert SD."

  log "Detected:"
  log "  bootfs: $BOOTFS"
  log "  rootfs: $ROOTFS"

  local dev
  dev="$(get_devnode_for_mount "$ROOTFS")"
  [ -n "$dev" ] || die "Could not determine device node for $ROOTFS (mount parsing failed)."
  log "  device: $dev"

  if [ "$PREFLIGHT_ONLY" -eq 1 ]; then
    echo ""
    log "Preflight checks (no changes will be made):"
    if is_rootfs_readonly "$ROOTFS"; then
      log "  rootfs: mounted read-only ⚠️"
    else
      log "  rootfs: not flagged read-only (may still fail writes) ✅"
    fi

    local e2=""
    if ! e2="$(find_e2fsck)"; then
      log "  e2fsck: not found (would attempt Homebrew install of e2fsprogs)"
    fi

    if [ -n "${e2:-}" ]; then
      local e2ver=""
      e2ver="$("$e2" -V 2>&1 | awk 'NR==1 {print $2}')"
      log "  e2fsck: $e2 (version: ${e2ver:-unknown})"
      if [[ "${e2ver:-}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        if version_ge "$e2ver" "$MIN_E2FSCK_VERSION"; then
          log "  e2fsck meets minimum version (>= $MIN_E2FSCK_VERSION) ✅"
        else
          log "  e2fsck too old (need >= $MIN_E2FSCK_VERSION) ❌"
        fi
      fi
    else
      log "  e2fsck: not available"
    fi

    log "Preflight complete. Exiting without touching the SD."
    exit 0
  fi

  # If already writable, go straight to harden
  if write_test "$ROOTFS"; then
    log "rootfs is already writable ✅"
  else
    log "rootfs is NOT writable (likely mounted read-only)."
    if is_rootfs_readonly "$ROOTFS"; then
      log "Mount flags show read-only."
    fi

    # Try to repair ext4 to clear dirty flag
    local e2
    if ! e2="$(find_e2fsck)"; then
      log "e2fsck not found."
      echo ""
      echo "Attempting to install e2fsprogs via Homebrew..."
      if ensure_e2fsprogs; then
        e2="$(find_e2fsck)" || true
      fi
    fi

    if [ -n "${e2:-}" ]; then
      local e2ver
      e2ver="$("$e2" -V 2>&1 | awk 'NR==1 {print $2}')"
      log "Found e2fsck: $e2 (version: ${e2ver:-unknown})"

      if [[ "${e2ver:-}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        if ! version_ge "$e2ver" "$MIN_E2FSCK_VERSION"; then
          echo ""
          echo "Your e2fsck is too old for this SD card's ext4 features."
          echo "Required: >= $MIN_E2FSCK_VERSION"
          echo "Detected: $e2ver ($e2)"
          echo ""
          echo "Attempting to upgrade e2fsprogs via Homebrew..."
          if ensure_e2fsprogs; then
            brew_as_user upgrade e2fsprogs || true
            e2="$(find_e2fsck)" || true
            e2ver="$("$e2" -V 2>&1 | awk 'NR==1 {print $2}')"
            log "After upgrade, e2fsck: $e2 (version: ${e2ver:-unknown})"
            if [[ "${e2ver:-}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]] && version_ge "$e2ver" "$MIN_E2FSCK_VERSION"; then
              :
            else
              echo ""
              echo "Homebrew upgrade did not provide a new enough e2fsck."
              echo "Please run:"
              echo "  brew update && brew upgrade e2fsprogs"
              echo ""
              die "Upgrade e2fsprogs (e2fsck) and retry."
            fi
          else
            echo ""
            echo "Homebrew not available, cannot auto-upgrade e2fsprogs."
            echo "Please run:"
            echo "  brew update && brew upgrade e2fsprogs"
            echo ""
            die "Upgrade e2fsprogs (e2fsck) and retry."
          fi
        fi
      fi

      unmount_rootfs "$dev"
      log "Running ext4 fsck (this can take a bit)..."
      set +e
      local fsck_out=""
      fsck_out="$("$e2" -f -y "$dev" 2>&1)"
      local fsck_rc=$?
      set -e

      if echo "$fsck_out" | grep -q "has unsupported feature(s)"; then
        echo "$fsck_out"
        echo ""
        echo "This indicates e2fsck still doesn't support the filesystem features on the card."
        echo "Try (re)installing/upgrading Homebrew's e2fsprogs:"
        echo "  brew update && brew install e2fsprogs && brew upgrade e2fsprogs"
        echo ""
        die "e2fsck does not support filesystem features (upgrade required)."
      fi

      # e2fsck exit codes:
      # 0 - no errors, 1 - corrected, 2 - corrected + reboot needed
      # 4/8/16/32/128 - failure conditions
      if [ "$fsck_rc" -ge 4 ]; then
        echo "$fsck_out"
        die "e2fsck failed (exit code: $fsck_rc)."
      fi

      remount_rootfs "$dev"
      sleep 2
      detect_mounts
    else
      echo ""
      echo "You have two options to continue:"
      echo ""
      echo "A) Install e2fsck (recommended):"
      echo "   brew install e2fsprogs"
      echo ""
      echo "B) Use extFS UI to run a filesystem check/repair on the rootfs volume,"
      echo "   then reinsert the SD."
      echo ""
      die "Cannot auto-repair ext4 without e2fsck."
    fi

    if [ -z "${ROOTFS:-}" ] || [ ! -d "$ROOTFS" ]; then
      die "rootfs did not remount after repair. Reinsert the SD and rerun this script."
    fi

    if ! write_test "$ROOTFS"; then
      echo ""
      echo "extFS still mounted rootfs read-only after fsck."
      echo "Open extFS and force a Read/Write mount for the rootfs volume, then rerun:"
      echo "  cd ~/moodeaudio-cursor && sudo ./tools/fix/sd-repair-and-harden-macos.sh"
      die "rootfs still not writable."
    fi

    log "rootfs is now writable ✅"
  fi

  log ""
  log "Running SD hardening (restore display/network/audio files)..."
  sudo "$PROJECT_ROOT/tools/fix/harden-sd.sh"

  log ""
  log "✅ DONE. You can now eject SD and boot the Pi."
}

main "$@"


