#!/bin/bash
################################################################################
#
# macOS: Apply Waveshare 7.9" Display config to a mounted moOde SD card
#
# What this does (idempotent):
# - Patches /Volumes/bootfs/cmdline.txt to include the known-good video mode and
#   clean boot flags WITHOUT touching root=PARTUUID and other critical params.
# - Appends an override block to /Volumes/bootfs/config.txt for Pi 5 + Waveshare.
# - Installs touch calibration into /Volumes/rootfs/etc/X11/xorg.conf.d/
#
# Requirements:
# - SD card inserted and BOTH partitions mounted (bootfs + rootfs)
# - Run with sudo (writes into /Volumes/*)
#
################################################################################

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
DEBUG_LOG="$PROJECT_ROOT/.cursor/debug.log"

log() { echo "[DISPLAY-SD] $*"; }
die() { echo "[DISPLAY-SD] ERROR: $*" >&2; exit 1; }

debug_log() {
  local hypothesis_id="$1"
  local location="$2"
  local message="$3"
  local data_json="${4:-{}}"
  # #region agent log
  python3 -c 'import json, time, os, sys; p=os.environ.get("DEBUG_LOG_PATH"); \
payload={"id":f"log_{int(time.time())}_{sys.argv[1]}", "timestamp":int(time.time()*1000), \
"location":sys.argv[2], "message":sys.argv[3], "data":json.loads(sys.argv[4]) if sys.argv[4] else {}, \
"sessionId":"debug-session","runId":"run1","hypothesisId":sys.argv[1]}; \
open(p,"a",encoding="utf-8").write(json.dumps(payload)+"\n")' \
    "$hypothesis_id" "$location" "$message" "$data_json" 2>/dev/null || true
  # #endregion
}

require_writable() {
  local p="$1"
  if [ ! -w "$p" ]; then
    die "Path not writable: $p (re-run with sudo)"
  fi
}

find_mount() {
  local label="$1"; shift
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
  cp "$f" "${f}.bak.${ts}"
  log "Backup: ${f}.bak.${ts}"
}

install_fix_xinitrc_display_script() {
  local bootfs="$1"
  local src="$PROJECT_ROOT/tools/fix/templates/fix-xinitrc-display.sh"
  local dst="$bootfs/fix-xinitrc-display.sh"

  if [ ! -f "$src" ]; then
    die "Missing template: $src"
  fi

  if [ -f "$dst" ]; then
    backup_file "$dst"
  fi
  cp "$src" "$dst"
  chmod +x "$dst" 2>/dev/null || true
  log "Installed helper script on bootfs: $dst"
}

patch_cmdline() {
  local cmdline_file="$1"
  local hdmi_connector="${2:-HDMI-A-1}"
  local target_video="video=${hdmi_connector}:400x1280M@60,rotate=90"

  python3 - "$cmdline_file" "$target_video" << 'PY'
import sys, re

path = sys.argv[1]
target_video = sys.argv[2]

with open(path, "r", encoding="utf-8", errors="ignore") as f:
    s = f.read().strip()

# Normalize whitespace
s = re.sub(r"\s+", " ", s).strip()

# Drop existing tokens we control
s = re.sub(r"(^| )video=[^ ]+", "", s)
s = re.sub(r"(^| )console=[^ ]+", "", s)
s = re.sub(r"(^| )quiet( |$)", " ", s)
s = re.sub(r"(^| )loglevel=\d+", "", s)
s = re.sub(r"(^| )logo\.nologo( |$)", " ", s)
s = re.sub(r"(^| )vt\.global_cursor_default=0( |$)", " ", s)

# Re-normalize
s = re.sub(r"\s+", " ", s).strip()

# Add required tokens (keep root=PARTUUID etc untouched)
tokens = []
tokens.append("console=tty3")
tokens.append(s)
tokens.append("quiet")
tokens.append("loglevel=3")
tokens.append("logo.nologo")
tokens.append("vt.global_cursor_default=0")
tokens.append(target_video)

out = re.sub(r"\s+", " ", " ".join([t for t in tokens if t])).strip()

with open(path, "w", encoding="utf-8") as f:
    f.write(out + "\n")
print(out)
PY
}

patch_config_txt() {
  local config_file="$1"

  python3 - "$config_file" << 'PY'
import sys

path = sys.argv[1]

marker_begin = '# Ghettoblaster Display Overrides (Pi 5 + Waveshare 7.9")'
marker_end = "# ---------------------------------------------------------------------------"

block = """

# ---------------------------------------------------------------------------
# Ghettoblaster Display Overrides (Pi 5 + Waveshare 7.9")
# (managed by moodeaudio-cursor/tools/fix/apply-display-to-sd-macos.sh)
# ---------------------------------------------------------------------------
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0

[all]
max_framebuffers=2
display_auto_detect=1
disable_fw_kms_setup=1
arm_64bit=1

disable_overscan=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt=400 1280 60 6 0 0 0
hdmi_force_mode=1
hdmi_force_hotplug=1
hdmi_drive=2

dtparam=audio=off
# ---------------------------------------------------------------------------
""".lstrip("\n")

with open(path, "r", encoding="utf-8", errors="ignore") as f:
    lines = f.read().splitlines()

out = []
in_old_block = False
for line in lines:
    if line.strip() == marker_begin:
        # Drop everything until the next footer marker line
        in_old_block = True
        continue
    if in_old_block:
        if line.strip() == marker_end:
            in_old_block = False
        continue
    out.append(line)

# Ensure file ends with newline and append fresh block
content = "\n".join(out).rstrip() + "\n" + block.lstrip("\n")
with open(path, "w", encoding="utf-8") as f:
    f.write(content if content.endswith("\n") else content + "\n")
PY
}

install_touch_calibration() {
  local rootfs="$1"
  local src="$PROJECT_ROOT/moode-source/etc/X11/xorg.conf.d/99-touch-calibration.conf"
  local dst_dir="$rootfs/etc/X11/xorg.conf.d"
  local dst="$dst_dir/99-touch-calibration.conf"

  if [ ! -f "$src" ]; then
    die "Missing source calibration file: $src"
  fi

  mkdir -p "$dst_dir"
  if [ -f "$dst" ]; then
    backup_file "$dst"
  fi
  cp "$src" "$dst"
  log "Installed touch calibration: $dst"
}

main() {
  local hdmi_connector="HDMI-A-1"
  if [ "${1:-}" = "--hdmi" ] && [ -n "${2:-}" ]; then
    hdmi_connector="$2"
    shift 2
  fi
  debug_log "A" "apply-display-to-sd-macos.sh:main" "Starting SD display apply" "{\"hdmi_connector\":\"$hdmi_connector\"}"

  local bootfs rootfs
  bootfs="$(find_mount bootfs "/Volumes/bootfs" "/Volumes/bootfs 1" "/Volumes/BOOTFS" "/Volumes/boot")" || die "bootfs not mounted (expected /Volumes/bootfs)"
  # Prefer EXTFS mountpoint "rootfs 1" over any leftover /Volumes/rootfs directory
  rootfs="$(find_mount rootfs "/Volumes/rootfs 1" "/Volumes/rootfs" "/Volumes/ROOTFS" "/Volumes/root")" || die "rootfs not mounted (expected /Volumes/rootfs 1)"

  log "Using bootfs: $bootfs"
  log "Using rootfs: $rootfs"
  debug_log "A" "apply-display-to-sd-macos.sh:mounts" "Detected SD mounts" "{\"bootfs\":\"$bootfs\",\"rootfs\":\"$rootfs\"}"

  local cmdline="$bootfs/cmdline.txt"
  local config="$bootfs/config.txt"

  [ -f "$cmdline" ] || die "Missing $cmdline"
  [ -f "$config" ] || die "Missing $config"
  require_writable "$bootfs"
  require_writable "$rootfs"

  log "Installing forum-solution helper script (fix-xinitrc-display.sh) to bootfs..."
  install_fix_xinitrc_display_script "$bootfs"

  log "Patching cmdline.txt (safe token edit, keeps PARTUUID)..."
  backup_file "$cmdline"
  log "New cmdline:"
  patch_cmdline "$cmdline" "$hdmi_connector" | sed 's/^/[DISPLAY-SD]   /'
  debug_log "A" "apply-display-to-sd-macos.sh:cmdline" "Patched cmdline.txt" "{\"path\":\"$cmdline\"}"

  log "Patching config.txt (append override block)..."
  backup_file "$config"
  patch_config_txt "$config"
  debug_log "B" "apply-display-to-sd-macos.sh:config" "Patched config.txt (override block ensured)" "{\"path\":\"$config\"}"

  log "Installing touchscreen calibration into rootfs..."
  install_touch_calibration "$rootfs"
  debug_log "C" "apply-display-to-sd-macos.sh:touch" "Installed touch calibration" "{\"rootfs\":\"$rootfs\"}"

  log "Verify:"
  grep -E "video=HDMI-A-1:400x1280M@60,rotate=90" "$cmdline" && log "✅ cmdline video ok"
  grep -E "hdmi_cvt=400 1280 60" "$config" && log "✅ config hdmi_cvt ok"
  [ -f "$rootfs/etc/X11/xorg.conf.d/99-touch-calibration.conf" ] && log "✅ touch calibration file present"

  log "Done. You can now eject the SD card."
}

main "$@"

