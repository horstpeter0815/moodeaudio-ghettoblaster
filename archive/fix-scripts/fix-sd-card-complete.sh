#!/bin/bash
################################################################################
# COMPLETE SD CARD FIX
# 
# Fixes everything on the SD card before booting:
# 1. Enable SSH (create /boot/firmware/ssh file)
# 2. Fix config.txt (display_rotate=0, moOde header, hdmi_timings)
# 3. Fix cmdline.txt (remove video= rotate parameter)
# 4. Verify all settings
#
# Usage: ./fix-sd-card-complete.sh [SD_MOUNT_POINT]
################################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[FIX]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🔧 COMPLETE SD CARD FIX                                     ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# STEP 1: FIND SD CARD
################################################################################

log "=== STEP 1: FIND SD CARD ==="
echo ""

SD_MOUNT="${1:-}"

if [ -z "$SD_MOUNT" ]; then
    # Auto-detect SD card
    if [ -d "/Volumes/bootfs" ]; then
        SD_MOUNT="/Volumes/bootfs"
    elif [ -d "/Volumes/boot" ]; then
        SD_MOUNT="/Volumes/boot"
    else
        # Try diskutil
        BOOT_PARTITION=$(diskutil list external 2>/dev/null | grep "Windows_FAT_32\|FAT32" | head -1 | awk '{print $NF}' || echo "")
        if [ -n "$BOOT_PARTITION" ]; then
            MOUNT_POINT=$(mount | grep "$BOOT_PARTITION" | awk '{print $3}' | head -1)
            if [ -n "$MOUNT_POINT" ]; then
                SD_MOUNT="$MOUNT_POINT"
            fi
        fi
    fi
fi

if [ -z "$SD_MOUNT" ] || [ ! -d "$SD_MOUNT" ]; then
    error "SD-Karte nicht gefunden!"
    echo ""
    info "Bitte SD-Karte einstecken oder Mount-Point angeben:"
    echo "  ./fix-sd-card-complete.sh /Volumes/bootfs"
    echo ""
    info "Oder prüfe manuell:"
    echo "  diskutil list external"
    echo "  ls -la /Volumes/"
    exit 1
fi

log "✅ SD-Karte gefunden: $SD_MOUNT"
echo ""

# Check if config.txt exists
if [ ! -f "$SD_MOUNT/config.txt" ]; then
    error "config.txt nicht gefunden auf $SD_MOUNT"
    exit 1
fi

info "SD-Karte Inhalt:"
ls -la "$SD_MOUNT/" | head -10
echo ""

################################################################################
# STEP 2: ENABLE SSH
################################################################################

log "=== STEP 2: ENABLE SSH ==="
echo ""

# Create SSH flag file
if [ ! -f "$SD_MOUNT/ssh" ]; then
    touch "$SD_MOUNT/ssh"
    log "✅ SSH-Flag-Datei erstellt: $SD_MOUNT/ssh"
else
    log "✅ SSH-Flag-Datei bereits vorhanden"
fi

# Also check firmware directory (Pi 5 uses /boot/firmware/)
if [ -d "$SD_MOUNT/firmware" ]; then
    if [ ! -f "$SD_MOUNT/firmware/ssh" ]; then
        touch "$SD_MOUNT/firmware/ssh"
        log "✅ SSH-Flag-Datei erstellt: $SD_MOUNT/firmware/ssh"
    else
        log "✅ SSH-Flag-Datei bereits vorhanden in firmware/"
    fi
fi

echo ""

################################################################################
# STEP 3: FIX CONFIG.TXT
################################################################################

log "=== STEP 3: FIX CONFIG.TXT ==="
echo ""

CONFIG_FILE="$SD_MOUNT/config.txt"

# Backup
if [ ! -f "${CONFIG_FILE}.backup_$(date +%Y%m%d)" ]; then
    cp "$CONFIG_FILE" "${CONFIG_FILE}.backup_$(date +%Y%m%d_%H%M%S)"
    log "✅ Backup erstellt: ${CONFIG_FILE}.backup_$(date +%Y%m%d_%H%M%S)"
fi

# Add moOde header if missing (prevents worker.php overwrite)
if ! grep -q "# This file is managed by moOde" "$CONFIG_FILE"; then
    # Add header at the beginning
    {
        echo "#########################################"
        echo "# This file is managed by moOde"
        echo "#########################################"
        echo ""
        cat "$CONFIG_FILE"
    } > "${CONFIG_FILE}.tmp"
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    log "✅ moOde Header hinzugefügt"
fi

# Ensure [pi5] section exists with display_rotate=0
if grep -q "^\[pi5\]" "$CONFIG_FILE"; then
    # Remove existing display_rotate from [pi5] section
    awk '
        /^\[pi5\]/ { in_pi5=1; print; next }
        /^\[/ && in_pi5 { in_pi5=0 }
        in_pi5 && /^display_rotate=/ { next }
        { print }
    ' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    
    # Add display_rotate=0 after [pi5] (macOS-compatible)
    awk '/^\[pi5\]/ {print; print "display_rotate=0"; next} {print}' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    log "✅ display_rotate=0 in [pi5] Section gesetzt"
else
    # [pi5] section doesn't exist, add it
    echo "" >> "$CONFIG_FILE"
    echo "[pi5]" >> "$CONFIG_FILE"
    echo "display_rotate=0" >> "$CONFIG_FILE"
    log "✅ [pi5] Section mit display_rotate=0 hinzugefügt"
fi

# Ensure hdmi_timings in [pi5] section (for Waveshare 7.9")
if ! grep -A 10 "^\[pi5\]" "$CONFIG_FILE" | grep -q "hdmi_timings"; then
    # Add hdmi_timings after [pi5] (macOS-compatible)
    awk '/^\[pi5\]/ {print; print "hdmi_timings=400 0 220 32 110 1280 0 10 10 10 0 0 0 60 0 59510000 0"; print "hdmi_ignore_edid=0xa5000080"; print "hdmi_force_hotplug=1"; next} {print}' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    log "✅ hdmi_timings in [pi5] Section hinzugefügt"
fi

# Ensure dtoverlay=vc4-kms-v3d-pi5,noaudio in [pi5]
if ! grep -A 10 "^\[pi5\]" "$CONFIG_FILE" | grep -q "dtoverlay=vc4-kms-v3d-pi5"; then
    awk '/^\[pi5\]/ {print; print "dtoverlay=vc4-kms-v3d-pi5,noaudio"; print "hdmi_enable_4kp60=0"; next} {print}' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    log "✅ Pi 5 KMS Overlay hinzugefügt"
fi

# Remove display_rotate from [all] section (conflict)
awk '
    /^\[all\]/ { in_all=1; print; next }
    /^\[/ && in_all { in_all=0 }
    in_all && /^display_rotate=/ { next }
    { print }
' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

# Set disable_splash=1 to show boot messages (no splash screen)
if grep -q "^disable_splash=" "$CONFIG_FILE"; then
    sed -i '' 's/^disable_splash=.*/disable_splash=1/' "$CONFIG_FILE"
else
    # Add disable_splash=1 in [all] section
    awk '/^\[all\]/ {print; print "disable_splash=1"; next} {print}' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
    mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
fi
log "✅ disable_splash=1 gesetzt (Splash Screen deaktiviert, Boot-Meldungen sichtbar)"

# Ensure hdmi_group=2 and hdmi_mode=87 in [all] section
if ! grep -q "^hdmi_group=2" "$CONFIG_FILE"; then
    if grep -q "^\[all\]" "$CONFIG_FILE"; then
        awk '/^\[all\]/ {print; print "hdmi_group=2"; print "hdmi_mode=87"; next} {print}' "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
        mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"
    else
        echo "" >> "$CONFIG_FILE"
        echo "[all]" >> "$CONFIG_FILE"
        echo "hdmi_group=2" >> "$CONFIG_FILE"
        echo "hdmi_mode=87" >> "$CONFIG_FILE"
    fi
    log "✅ hdmi_group=2 und hdmi_mode=87 hinzugefügt"
fi

# Remove disable_fw_kms_setup (must be removed for custom timings)
grep -v "^disable_fw_kms_setup=" "$CONFIG_FILE" > "${CONFIG_FILE}.tmp"
mv "${CONFIG_FILE}.tmp" "$CONFIG_FILE"

# Ensure HiFiBerry AMP100 overlay
if ! grep -q "dtoverlay=hifiberry-amp100" "$CONFIG_FILE"; then
    echo "dtoverlay=hifiberry-amp100" >> "$CONFIG_FILE"
    log "✅ HiFiBerry AMP100 Overlay hinzugefügt"
fi

log "✅ config.txt vollständig gefixt"
echo ""

################################################################################
# STEP 4: FIX CMDLINE.TXT
################################################################################

log "=== STEP 4: FIX CMDLINE.TXT ==="
echo ""

CMDLINE_FILE="$SD_MOUNT/cmdline.txt"

if [ ! -f "$CMDLINE_FILE" ]; then
    warn "cmdline.txt nicht gefunden, überspringe"
else
    # Backup
    if [ ! -f "${CMDLINE_FILE}.backup_$(date +%Y%m%d)" ]; then
        cp "$CMDLINE_FILE" "${CMDLINE_FILE}.backup_$(date +%Y%m%d_%H%M%S)"
        log "✅ Backup erstellt"
    fi
    
    # Remove video= parameter with rotate (macOS-compatible)
    sed 's/ video=[^ ]*rotate[^ ]*//g' "$CMDLINE_FILE" > "${CMDLINE_FILE}.tmp"
    mv "${CMDLINE_FILE}.tmp" "$CMDLINE_FILE"
    
    # Add fbcon=rotate:1 for framebuffer console rotation
    if ! grep -q "fbcon=rotate:1" "$CMDLINE_FILE"; then
        # Add fbcon=rotate:1 to cmdline.txt (macOS-compatible)
        sed 's/$/ fbcon=rotate:1/' "$CMDLINE_FILE" > "${CMDLINE_FILE}.tmp"
        mv "${CMDLINE_FILE}.tmp" "$CMDLINE_FILE"
        log "✅ fbcon=rotate:1 hinzugefügt"
    else
        log "✅ fbcon=rotate:1 bereits vorhanden"
    fi
    
    # Clean up double spaces
    sed 's/  / /g' "$CMDLINE_FILE" > "${CMDLINE_FILE}.tmp"
    mv "${CMDLINE_FILE}.tmp" "$CMDLINE_FILE"
    
    log "✅ cmdline.txt gefixt (fbcon=rotate:1 hinzugefügt)"
fi

echo ""

################################################################################
# STEP 5: VERIFICATION
################################################################################

log "=== STEP 5: VERIFICATION ==="
echo ""

info "Prüfe finale Einstellungen..."
echo ""

echo "1. SSH-Flag-Dateien:"
[ -f "$SD_MOUNT/ssh" ] && echo "  ✅ $SD_MOUNT/ssh" || echo "  ❌ Nicht gefunden"
[ -f "$SD_MOUNT/firmware/ssh" ] && echo "  ✅ $SD_MOUNT/firmware/ssh" || echo "  ⚠️  firmware/ssh nicht vorhanden (normal für Pi 4)"
echo ""

echo "2. config.txt [pi5] Section:"
if grep -q "^\[pi5\]" "$CONFIG_FILE"; then
    sed -n '/^\[pi5\]/,/^\[/p' "$CONFIG_FILE" | head -10
    echo ""
    grep -q "display_rotate=0" "$CONFIG_FILE" && echo "  ✅ display_rotate=0 gefunden" || echo "  ❌ display_rotate=0 NICHT gefunden"
    grep -q "hdmi_timings" "$CONFIG_FILE" && echo "  ✅ hdmi_timings gefunden" || echo "  ⚠️  hdmi_timings nicht gefunden"
else
    echo "  ❌ [pi5] Section nicht gefunden"
fi
echo ""

echo "3. config.txt moOde Header:"
head -3 "$CONFIG_FILE" | grep -q "managed by moOde" && echo "  ✅ Header vorhanden" || echo "  ⚠️  Header fehlt"
echo ""

echo "4. cmdline.txt video=:"
if grep -q "video=" "$CMDLINE_FILE" 2>/dev/null; then
    grep -o 'video=[^ ]*' "$CMDLINE_FILE" | head -1
    echo "  ⚠️  video= Parameter noch vorhanden"
else
    echo "  ✅ Kein video= Parameter (gut)"
fi
echo ""

################################################################################
# SUMMARY
################################################################################

log "=== FIX ABGESCHLOSSEN ==="
echo ""
info "Alle Änderungen auf SD-Karte angewendet:"
echo "  ✅ SSH aktiviert"
echo "  ✅ config.txt gefixt (display_rotate=0, moOde Header, hdmi_timings)"
echo "  ✅ cmdline.txt gefixt (video= rotate entfernt)"
echo ""
warn "⚠️  SD-Karte kann jetzt aus Mac entfernt werden"
echo ""
info "Nächste Schritte:"
echo "  1. SD-Karte aus Mac entfernen"
echo "  2. SD-Karte in Pi einstecken"
echo "  3. Pi booten lassen"
echo "  4. SSH sollte funktionieren: ssh andre@<PI_IP> (Pass: 0815)"
echo "  5. Display sollte in Landscape (1280x400) starten"
echo ""
log "Fix abgeschlossen!"

