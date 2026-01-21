#!/bin/bash
################################################################################
#
# macOS: Apply deterministic Ethernet + SSH config to a mounted moOde SD card
#
# Target architecture (deterministic):
# - Mac: 192.168.10.1/24
# - Pi:  192.168.10.2/24 (eth0 static, NO DHCP fallback)
#
# What this does (idempotent):
# - Creates /Volumes/bootfs/ssh to enable SSH on first boot
# - Creates a NetworkManager connection "eth0-static" for eth0 with static IPv4
# - Masks NetworkManager-wait-online to avoid long boot delays
# - Enables ssh.service if present by creating a wants symlink
# - Installs boot-report service + script (writes boot/network/display report to bootfs)
#
# Notes:
# - Requires SD partitions mounted: bootfs + rootfs (EXTFS often mounts as "rootfs 1")
# - Run with sudo if the volumes are not writable
#
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

log() { echo "[NET-SD] $*"; }
die() { echo "[NET-SD] ERROR: $*" >&2; exit 1; }

require_writable() {
  local p="$1"
  [ -w "$p" ] || die "Path not writable: $p (re-run with sudo)"
}

find_mount() {
  local candidate
  for candidate in "$@"; do
    if [ -d "$candidate" ] && diskutil info "$candidate" >/dev/null 2>&1; then
      echo "$candidate"
      return 0
    fi
  done
  return 1
}

backup_file() {
  local f="$1"
  local ts
  ts="$(date +%Y%m%d_%H%M%S)"
  if [ -f "$f" ]; then
    cp "$f" "${f}.bak.${ts}"
    log "Backup: ${f}.bak.${ts}"
  fi
}

write_nmconnection() {
  local rootfs="$1"
  local nm_dir="$rootfs/etc/NetworkManager/system-connections"
  local nm_file="$nm_dir/eth0-static.nmconnection"

  mkdir -p "$nm_dir"
  backup_file "$nm_file"

  # Create deterministic NM profile for eth0
  cat > "$nm_file" << 'EOF'
[connection]
id=eth0-static
type=ethernet
interface-name=eth0
autoconnect=true
autoconnect-priority=100

[ethernet]

[ipv4]
method=manual
addresses1=192.168.10.2/24,192.168.10.1
dns=192.168.10.1;1.1.1.1;
dns-search=
may-fail=false

[ipv6]
method=ignore
EOF

  # NM requires 600 perms; on EXTFS this should work.
  chmod 600 "$nm_file" 2>/dev/null || true
  log "Wrote NetworkManager profile: $nm_file"
}

mask_wait_online() {
  local rootfs="$1"
  local sysd="$rootfs/etc/systemd/system"
  mkdir -p "$sysd"

  # Mask NetworkManager-wait-online.service if it exists on the image
  ln -sf /dev/null "$sysd/NetworkManager-wait-online.service" 2>/dev/null || true
  ln -sf /dev/null "$sysd/NetworkManager-wait-online.target" 2>/dev/null || true
  log "Masked NetworkManager-wait-online (prevents long boot stalls)"
}

enable_ssh() {
  local rootfs="$1"
  local bootfs="$2"

  # Raspberry Pi style SSH flag (works on many images)
  touch "$bootfs/ssh" 2>/dev/null || true
  log "Created SSH flag: $bootfs/ssh"

  # Also enable ssh.service via wants symlink if present
  local wants="$rootfs/etc/systemd/system/multi-user.target.wants"
  mkdir -p "$wants"

  if [ -f "$rootfs/lib/systemd/system/ssh.service" ]; then
    ln -sf ../../../../lib/systemd/system/ssh.service "$wants/ssh.service" 2>/dev/null || true
    log "Enabled ssh.service via wants symlink"
  elif [ -f "$rootfs/lib/systemd/system/sshd.service" ]; then
    ln -sf ../../../../lib/systemd/system/sshd.service "$wants/sshd.service" 2>/dev/null || true
    log "Enabled sshd.service via wants symlink"
  else
    log "Note: ssh.service not found in rootfs (will rely on bootfs/ssh flag if supported)"
  fi
}

install_boot_report() {
  local rootfs="$1"

  local src_script="$PROJECT_ROOT/moode-source/usr/local/bin/boot-report.sh"
  local src_service="$PROJECT_ROOT/moode-source/lib/systemd/system/boot-report.service"

  if [ ! -f "$src_script" ] || [ ! -f "$src_service" ]; then
    die "Missing boot-report templates in repo (expected $src_script and $src_service)"
  fi

  mkdir -p "$rootfs/usr/local/bin" "$rootfs/lib/systemd/system" "$rootfs/etc/systemd/system/multi-user.target.wants"
  cp "$src_script" "$rootfs/usr/local/bin/boot-report.sh"
  chmod +x "$rootfs/usr/local/bin/boot-report.sh" 2>/dev/null || true
  cp "$src_service" "$rootfs/lib/systemd/system/boot-report.service"

  ln -sf ../../../../lib/systemd/system/boot-report.service \
    "$rootfs/etc/systemd/system/multi-user.target.wants/boot-report.service" 2>/dev/null || true

  log "Installed + enabled boot-report.service"
}

install_eth0_static_early() {
  local rootfs="$1"

  local src_script="$PROJECT_ROOT/moode-source/usr/local/bin/eth0-static-early.sh"
  local src_service="$PROJECT_ROOT/moode-source/lib/systemd/system/eth0-static-early.service"

  if [ ! -f "$src_script" ] || [ ! -f "$src_service" ]; then
    die "Missing eth0-static-early templates in repo"
  fi

  mkdir -p "$rootfs/usr/local/bin" "$rootfs/lib/systemd/system" "$rootfs/etc/systemd/system/multi-user.target.wants"
  cp "$src_script" "$rootfs/usr/local/bin/eth0-static-early.sh"
  chmod +x "$rootfs/usr/local/bin/eth0-static-early.sh" 2>/dev/null || true
  cp "$src_service" "$rootfs/lib/systemd/system/eth0-static-early.service"

  ln -sf ../../../../lib/systemd/system/eth0-static-early.service \
    "$rootfs/etc/systemd/system/multi-user.target.wants/eth0-static-early.service" 2>/dev/null || true

  log "Installed + enabled eth0-static-early.service"
}

main() {
  local bootfs rootfs
  bootfs="$(find_mount "/Volumes/bootfs" "/Volumes/bootfs 1" "/Volumes/BOOTFS" "/Volumes/boot")" || die "bootfs not mounted"
  rootfs="$(find_mount "/Volumes/rootfs 1" "/Volumes/rootfs" "/Volumes/ROOTFS" "/Volumes/root")" || die "rootfs not mounted (expected /Volumes/rootfs 1)"

  log "Using bootfs: $bootfs"
  log "Using rootfs: $rootfs"
  require_writable "$bootfs"
  require_writable "$rootfs"

  write_nmconnection "$rootfs"
  mask_wait_online "$rootfs"
  enable_ssh "$rootfs" "$bootfs"
  install_boot_report "$rootfs"
  install_eth0_static_early "$rootfs"

  log "Verify:"
  [ -f "$bootfs/ssh" ] && log "✅ bootfs/ssh present"
  grep -q "addresses1=192.168.10.2/24" "$rootfs/etc/NetworkManager/system-connections/eth0-static.nmconnection" \
    && log "✅ eth0-static profile has 192.168.10.2/24"
  [ -L "$rootfs/etc/systemd/system/NetworkManager-wait-online.service" ] && log "✅ wait-online masked"
  [ -f "$rootfs/usr/local/bin/boot-report.sh" ] && log "✅ boot-report.sh installed"
  [ -f "$rootfs/usr/local/bin/eth0-static-early.sh" ] && log "✅ eth0-static-early.sh installed"
  log "Done."
}

main "$@"

