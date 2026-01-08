#!/usr/bin/env bash
################################################################################
# Harden SD card (bootfs/rootfs) so settings survive reboots and remounts.
#
# What this does (safe, idempotent):
# - Verifies /Volumes/bootfs and /Volumes/rootfs (or /Volumes/rootfs 1)
# - Restores/creates:
#   - /bootfs/cmdline.txt (adds video=... rotate=90 without touching root=PARTUUID)
#   - /rootfs/etc/NetworkManager/system-connections/Ethernet.nmconnection
#   - /rootfs/home/andre/.xinitrc
# - Patches CamillaDSP configs on SD to avoid known regressions:
#   - Fix CamillaDSP v3 schema: pipeline "channel:" -> "channels: [x]"
#   - Ensure wizard-generated configs don't output to "peppy" loop
#
# Run from Mac terminal:
#   cd ~/moodeaudio-cursor && sudo ./tools/fix/harden-sd.sh
################################################################################

set -euo pipefail

BOOTFS="/Volumes/bootfs"
if [ -d "/Volumes/rootfs 1" ]; then
  ROOTFS="/Volumes/rootfs 1"
elif [ -d "/Volumes/rootfs" ]; then
  ROOTFS="/Volumes/rootfs"
else
  ROOTFS=""
fi

die() { echo "[SD-HARDEN] ERROR: $*" >&2; exit 1; }
log() { echo "[SD-HARDEN] $*"; }

require_paths() {
  [ -d "$BOOTFS" ] || die "bootfs not mounted at $BOOTFS"
  [ -n "$ROOTFS" ] || die "rootfs not mounted (expected /Volumes/rootfs or /Volumes/rootfs 1)"
  [ -d "$ROOTFS" ] || die "rootfs path invalid: $ROOTFS"
}

check_writable() {
  # We must be able to write BOTH partitions, otherwise we risk partial state.
  local bf_test="$BOOTFS/.sd_harden_write_test"
  local rf_test="$ROOTFS/.sd_harden_write_test"

  if ! ( : > "$bf_test" ) 2>/dev/null; then
    die "bootfs is not writable at $BOOTFS (check mount/permissions)."
  fi
  rm -f "$bf_test" 2>/dev/null || true

  if ! ( : > "$rf_test" ) 2>/dev/null; then
    die "rootfs is mounted READ-ONLY at $ROOTFS.\n\nFix: enable ext4 write support on macOS (extFS/Paragon), then remount the SD so rootfs is writable.\nAfter that rerun: cd ~/moodeaudio-cursor && sudo ./tools/fix.sh --sd"
  fi
  rm -f "$rf_test" 2>/dev/null || true
}

backup_file() {
  local f="$1"
  if [ -f "$f" ]; then
    local ts
    ts="$(date +%Y%m%d_%H%M%S)"
    cp -a "$f" "${f}.bak_${ts}"
    log "Backup: ${f}.bak_${ts}"
  fi
}

ensure_cmdline_video() {
  local f="$BOOTFS/cmdline.txt"
  [ -f "$f" ] || die "Missing $f. (If this was deleted, restore it first; we must not lose root=PARTUUID.)"

  backup_file "$f"

  # Keep cmdline.txt clean - do NOT add video= or fbcon=rotate tokens here.
  # Display rotation is handled by config.txt (hdmi_cvt=400 1280) + .xinitrc (xrandr).
  # Remove any existing video=... or fbcon=rotate tokens to avoid conflicts.
  local cur
  cur="$(cat "$f")"
  cur="$(echo "$cur" | sed -E 's/(^|[[:space:]])video=[^[:space:]]+//g' | tr -s ' ')"
  cur="$(echo "$cur" | sed -E 's/(^|[[:space:]])fbcon=rotate:[0-9]+//g' | tr -s ' ')"
  cur="${cur% }"
  echo "$cur" > "$f"
  log "Updated cmdline.txt (removed conflicting video/fbcon rotation tokens)"
}

write_ethernet_nmconnection() {
  local dir="$ROOTFS/etc/NetworkManager/system-connections"
  local f="$dir/Ethernet.nmconnection"
  mkdir -p "$dir"

  backup_file "$f"

  cat > "$f" <<'EOF'
[connection]
id=Ethernet
uuid=f8eba0b7-862d-4ccc-b93a-52815eb9c28d
type=ethernet
interface-name=eth0
autoconnect=true
autoconnect-priority=50

[ethernet]
mac-address-blacklist=

[ipv4]
address1=192.168.10.2/24,192.168.10.1
dns=8.8.8.8;8.8.4.4;
method=manual

[ipv6]
addr-gen-mode=default
method=ignore
EOF

  chmod 600 "$f"
  chown 0:0 "$f" || true
  log "Wrote $f (static 192.168.10.2)"
}

write_xinitrc() {
  local f="$ROOTFS/home/andre/.xinitrc"
  mkdir -p "$(dirname "$f")"

  backup_file "$f"

  cat > "$f" <<'EOF'
#!/bin/bash
# Waveshare 7.9" HDMI (400x1280 portrait) -> 1280x400 landscape
# - config.txt: hdmi_cvt=400 1280 (portrait native)
# - X11: xrandr rotate left (always, unconditional for Ghettoblaster)
# - Chromium: force 1280x400, no scaling surprises

set -e

export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority

xset -dpms || true
xset s 600 0 || true

# Always force SCREEN_RES to landscape for Chromium
SCREEN_RES="1280,400"

# Wait for X server
for i in {1..30}; do
  if xset q &>/dev/null 2>&1; then break; fi
  sleep 1
done

# ALWAYS rotate display for Ghettoblaster (Waveshare 7.9" portrait -> landscape)
HDMI_OUT=""
for i in {1..10}; do
  HDMI_OUT=$(DISPLAY=:0 xrandr --query 2>/dev/null | awk '/^HDMI-[0-9]+ connected/{print $1; exit}')
  [ -n "${HDMI_OUT:-}" ] && break
  sleep 1
done
[ -z "${HDMI_OUT:-}" ] && HDMI_OUT="HDMI-2"

DISPLAY=:0 xrandr --output "$HDMI_OUT" --rotate normal 2>/dev/null || true
sleep 1
DISPLAY=:0 xrandr --output "$HDMI_OUT" --mode 400x1280 2>/dev/null || true
sleep 1
DISPLAY=:0 xrandr --output "$HDMI_OUT" --rotate left 2>/dev/null || true
sleep 1

# Read moOde flags
WEBUI_SHOW=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='local_display'" 2>/dev/null || echo 0)
PEPPY_SHOW=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='peppy_display'" 2>/dev/null || echo 0)
PEPPY_TYPE=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='peppy_display_type'" 2>/dev/null || echo '')

if [ "${WEBUI_SHOW:-0}" = "1" ]; then
  /var/www/util/sysutil.sh clearbrcache >/dev/null 2>&1 || true
  chromium \
    --app="http://localhost/" \
    --window-size="$SCREEN_RES" \
    --force-device-scale-factor=1 \
    --window-position="0,0" \
    --enable-features="OverlayScrollbar" \
    --no-first-run \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --start-fullscreen \
    --kiosk
elif [ "${PEPPY_SHOW:-0}" = "1" ]; then
  if [ "${PEPPY_TYPE:-}" = 'meter' ]; then
    cd /opt/peppymeter && python3 peppymeter.py
  else
    cd /opt/peppyspectrum && python3 spectrum.py
  fi
fi
EOF

  chmod 755 "$f"
  chown 1000:1000 "$f" || true
  log "Wrote $f"
}

patch_camilladsp_configs() {
  local dir="$ROOTFS/usr/share/camilladsp/configs"
  [ -d "$dir" ] || { log "CamillaDSP configs dir not found on SD: $dir (skipping)"; return 0; }

  # 1) Fix CamillaDSP v3 schema: pipeline 'channel:' -> 'channels: [x]'
  #    Only for room_correction_20band_* files (known offenders).
  for f in "$dir"/room_correction_20band_*.yml "$dir"/room_correction_20band_*.yaml; do
    [ -f "$f" ] || continue
    if grep -qE '^\s*channel:\s*[01]\s*$' "$f"; then
      backup_file "$f"
      python3 - "$f" <<'PY'
from pathlib import Path
import re, sys
p = Path(sys.argv[1])
s = p.read_text()
lines = s.splitlines(True)
out = []
i = 0
changed = 0
while i < len(lines):
    if lines[i].rstrip("\n") == "  - type: Filter" and i + 1 < len(lines):
        m = re.match(r"^(\s*)channel:\s*([0-9]+)\s*$", lines[i+1].rstrip("\n"))
        if m:
            indent, ch = m.group(1), m.group(2)
            out.append(lines[i])
            out.append(f"{indent}channels: [{ch}]\n")
            i += 2
            changed += 1
            continue
    out.append(lines[i])
    i += 1
p.write_text("".join(out))
print(f"patched {p.name}: channel->channels changes={changed}")
PY
    fi
  done

  # 2) Avoid peppy loop for playback device in room_correction configs
  #    (only patch if device: "peppy" present)
  for f in "$dir"/room_correction_*.yml "$dir"/room_correction_*.yaml; do
    [ -f "$f" ] || continue
    if grep -q 'device: *"peppy"' "$f"; then
      backup_file "$f"
      sed -i '' 's/device: *"peppy"/device: "default:CARD=sndrpihifiberry"/g' "$f" 2>/dev/null || \
      sed -i 's/device: *"peppy"/device: "default:CARD=sndrpihifiberry"/g' "$f"
      log "Patched playback device in $(basename "$f")"
    fi
  done
}

main() {
  require_paths
  check_writable
  log "Mounts:"
  log "  bootfs: $BOOTFS"
  log "  rootfs: $ROOTFS"

  ensure_cmdline_video
  write_ethernet_nmconnection
  write_xinitrc
  patch_camilladsp_configs

  log "✅ SD hardening complete."
  log "Next: eject SD safely, boot Pi, then verify:"
  log "  - ethernet: 192.168.10.2"
  log "  - display: 1280x400"
  log "  - wizard: /wizard/wizard-control.html + /wizard/display.html"
}

main "$@"


