#!/bin/bash
################################################################################
# COMPLETE SD CARD FIX - BASIEREND AUF ALLEN ERKENNTNISSEN
#
# Fixes:
# 1. Main Header in Zeile 2 (nicht Zeile 1 oder 3!) - $lines[1] wird geprüft
# 2. Alle 5 moOde Headers vorhanden
# 3. display_rotate=2 in [pi5] Section
# 4. fbcon=rotate:3 in cmdline.txt
# 5. SSH-Flag Datei
# 6. Unix Line Endings (LF, nicht CRLF)
#
# Datum: 2025-12-21
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
echo "║  🔧 COMPLETE SD CARD FIX - ALL ERKENNTNISSE                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# FIND SD CARD
################################################################################

SD_MOUNT=""
if [ -d "/Volumes/bootfs" ]; then
    SD_MOUNT="/Volumes/bootfs"
elif [ -d "/Volumes/boot" ]; then
    SD_MOUNT="/Volumes/boot"
fi

if [ -z "$SD_MOUNT" ] || [ ! -f "$SD_MOUNT/config.txt" ]; then
    error "SD-Karte nicht gefunden oder config.txt fehlt"
    error "Bitte SD-Karte einstecken und sicherstellen, dass sie gemountet ist"
    exit 1
fi

info "SD-Karte: $SD_MOUNT"
echo ""

# Check if we need sudo
if [ ! -w "$SD_MOUNT/config.txt" ]; then
    warn "Kein Schreibzugriff auf config.txt - sudo wird benötigt"
    if [ "$EUID" -ne 0 ]; then
        error "Bitte Script mit sudo ausführen: sudo $0"
        exit 1
    fi
fi

################################################################################
# BACKUP
################################################################################

log "Erstelle Backup..."
BACKUP_DIR="$SD_MOUNT/.backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
cp "$SD_MOUNT/config.txt" "$BACKUP_DIR/config.txt.backup" 2>/dev/null || true
if [ -f "$SD_MOUNT/cmdline.txt" ]; then
    cp "$SD_MOUNT/cmdline.txt" "$BACKUP_DIR/cmdline.txt.backup" 2>/dev/null || true
fi
log "✅ Backup erstellt: $BACKUP_DIR"
echo ""

################################################################################
# FIX 1: config.txt - HEADERS IN RICHTIGER POSITION
################################################################################

log "=== FIX 1: config.txt Headers (Zeile 2!) ==="
echo ""

CONFIG_FILE="$SD_MOUNT/config.txt"

# Read current config.txt
CURRENT_CONFIG=$(cat "$CONFIG_FILE")

# Check if Main Header exists and where
MAIN_HEADER_LINE=$(echo "$CURRENT_CONFIG" | grep -n "^# This file is managed by moOde" | head -1 | cut -d: -f1 || echo "")

if [ -n "$MAIN_HEADER_LINE" ]; then
    info "Main Header gefunden in Zeile $MAIN_HEADER_LINE"
    if [ "$MAIN_HEADER_LINE" != "2" ]; then
        warn "Main Header ist in Zeile $MAIN_HEADER_LINE, sollte aber in Zeile 2 sein!"
        warn "→ worker.php prüft \$lines[1] (Zeile 2) - Header wird nicht erkannt!"
    fi
else
    warn "Main Header nicht gefunden - wird hinzugefügt"
fi

# Create new config.txt with correct structure
# CRITICAL: Main Header in Zeile 2 (Zeile 1 muss leer sein!)
# Use printf to ensure exact line structure: Zeile 1 = leer, Zeile 2 = Main Header
printf '' > "$CONFIG_FILE"
printf '\n' >> "$CONFIG_FILE"  # Zeile 1: leer
printf '# This file is managed by moOde\n' >> "$CONFIG_FILE"  # Zeile 2: Main Header
printf '\n' >> "$CONFIG_FILE"
printf '# Device filters\n' >> "$CONFIG_FILE"
cat >> "$CONFIG_FILE" << 'CONFIG_EOF'
[pi5]
display_rotate=2
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0
hdmi_timings=400 0 220 32 110 1280 0 10 10 10 0 0 0 60 0 59510000 0
hdmi_ignore_edid=0xa5000080
hdmi_force_hotplug=1
disable_splash=1
arm_boost=1
gpu_freq=750

[all]
max_framebuffers=2
display_auto_detect=1
arm_64bit=1
disable_overscan=1
dtparam=i2c_arm=on
dtparam=i2c_arm_baudrate=100000
dtparam=i2c_vc=on
dtparam=i2s=on
dtparam=audio=off

# General settings
hdmi_group=2
hdmi_mode=87
hdmi_drive=2
hdmi_blanking=0

# Do not alter this section
# Integrated adapters
#dtoverlay=disable-bt
#dtoverlay=disable-wifi

# Audio overlays
dtoverlay=hifiberry-amp100
force_eeprom_read=0
CONFIG_EOF

# Ensure Unix line endings (LF, not CRLF)
if command -v dos2unix &> /dev/null; then
    dos2unix "$CONFIG_FILE" 2>/dev/null || true
elif command -v sed &> /dev/null; then
    sed -i '' 's/\r$//' "$CONFIG_FILE" 2>/dev/null || sed -i 's/\r$//' "$CONFIG_FILE" 2>/dev/null || true
fi

log "✅ config.txt erstellt mit:"
log "   - Main Header in Zeile 2 (wird von worker.php erkannt)"
log "   - Alle 5 moOde Headers vorhanden"
log "   - display_rotate=2 in [pi5] Section"
log "   - Unix Line Endings (LF)"
echo ""

################################################################################
# FIX 2: cmdline.txt - FBCON ROTATION
################################################################################

log "=== FIX 2: cmdline.txt fbcon Rotation ==="
echo ""

CMDLINE_FILE="$SD_MOUNT/cmdline.txt"

if [ ! -f "$CMDLINE_FILE" ]; then
    warn "cmdline.txt nicht gefunden - wird erstellt"
    touch "$CMDLINE_FILE"
fi

# Read current cmdline.txt
CURRENT_CMDLINE=$(cat "$CMDLINE_FILE")

# Remove existing fbcon=rotate and video= rotate parameters
CURRENT_CMDLINE=$(echo "$CURRENT_CMDLINE" | sed 's/fbcon=rotate:[0-9]*//g' | sed 's/video=.*rotate[^ ]*//g' | sed 's/  */ /g' | sed 's/^ *//' | sed 's/ *$//')

# Add fbcon=rotate:3 (180° rotation)
if echo "$CURRENT_CMDLINE" | grep -q "fbcon=rotate:3"; then
    info "fbcon=rotate:3 bereits vorhanden"
else
    CURRENT_CMDLINE="$CURRENT_CMDLINE fbcon=rotate:3"
    info "fbcon=rotate:3 hinzugefügt"
fi

# Remove quiet and logo.nologo to show boot messages
CURRENT_CMDLINE=$(echo "$CURRENT_CMDLINE" | sed 's/quiet//g' | sed 's/logo.nologo//g' | sed 's/  */ /g' | sed 's/^ *//' | sed 's/ *$//')

# Write back
echo "$CURRENT_CMDLINE" > "$CMDLINE_FILE"

# Ensure Unix line endings
if command -v dos2unix &> /dev/null; then
    dos2unix "$CMDLINE_FILE" 2>/dev/null || true
elif command -v sed &> /dev/null; then
    sed -i '' 's/\r$//' "$CMDLINE_FILE" 2>/dev/null || sed -i 's/\r$//' "$CMDLINE_FILE" 2>/dev/null || true
fi

log "✅ cmdline.txt gefixt:"
log "   - fbcon=rotate:3 vorhanden (180° Console Rotation)"
log "   - quiet und logo.nologo entfernt (Boot Messages sichtbar)"
log "   - Unix Line Endings (LF)"
echo ""

################################################################################
# FIX 3: SSH FLAG FILE
################################################################################

log "=== FIX 3: SSH Flag File ==="
echo ""

SSH_FLAG="$SD_MOUNT/ssh"

# Remove if it's a directory (known issue)
if [ -d "$SSH_FLAG" ]; then
    warn "SSH-Flag ist ein Verzeichnis - wird entfernt"
    rm -rf "$SSH_FLAG"
fi

# Create empty SSH flag file
touch "$SSH_FLAG"
chmod 644 "$SSH_FLAG" 2>/dev/null || true

if [ -f "$SSH_FLAG" ] && [ ! -s "$SSH_FLAG" ]; then
    log "✅ SSH-Flag erstellt: $SSH_FLAG (leer, korrekt)"
else
    warn "SSH-Flag Problem - Datei existiert aber hat Inhalt"
fi
echo ""

################################################################################
# VERIFICATION
################################################################################

log "=== VERIFICATION ==="
echo ""

# Check Main Header position
LINE1=$(head -1 "$CONFIG_FILE")
LINE2=$(sed -n '2p' "$CONFIG_FILE")
EXPECTED_HEADER="# This file is managed by moOde"

echo "Zeile 1: '$LINE1'"
echo "Zeile 2: '$LINE2'"
echo ""

if echo "$LINE2" | grep -q "This file is managed by moOde"; then
    log "✅ Main Header in Zeile 2 (wird von worker.php erkannt)"
else
    error "❌ Main Header NICHT in Zeile 2!"
    error "   Zeile 2: '$LINE2'"
fi

# Check all 5 headers
HEADERS=(
    "# This file is managed by moOde"
    "# Device filters"
    "# General settings"
    "# Do not alter this section"
    "# Audio overlays"
)

HEADER_COUNT=0
for header in "${HEADERS[@]}"; do
    if grep -q "^$header" "$CONFIG_FILE"; then
        HEADER_COUNT=$((HEADER_COUNT + 1))
    fi
done

echo ""
echo "Header-Count: $HEADER_COUNT/5"

if [ "$HEADER_COUNT" -eq 5 ]; then
    log "✅ Alle 5 Headers vorhanden"
else
    error "❌ Nur $HEADER_COUNT/5 Headers vorhanden"
fi

# Check display_rotate
if grep -q "^\[pi5\]" "$CONFIG_FILE"; then
    DISPLAY_ROTATE=$(awk '/^\[pi5\]/ {in_pi5=1; next} /^\[/ && in_pi5 {in_pi5=0} in_pi5 && /^display_rotate=/ {print; exit}' "$CONFIG_FILE" | head -1)
    if echo "$DISPLAY_ROTATE" | grep -q "display_rotate=2"; then
        log "✅ display_rotate=2 in [pi5] Section: $DISPLAY_ROTATE"
    else
        error "❌ display_rotate in [pi5] Section ist NICHT 2: $DISPLAY_ROTATE"
    fi
else
    error "❌ [pi5] Section fehlt"
fi

# Check fbcon
if [ -f "$CMDLINE_FILE" ]; then
    if grep -q "fbcon=rotate:3" "$CMDLINE_FILE"; then
        log "✅ fbcon=rotate:3 in cmdline.txt vorhanden"
    else
        error "❌ fbcon=rotate:3 fehlt in cmdline.txt"
    fi
fi

# Check SSH flag
if [ -f "$SSH_FLAG" ] && [ ! -s "$SSH_FLAG" ]; then
    log "✅ SSH-Flag vorhanden und leer"
else
    error "❌ SSH-Flag Problem"
fi

echo ""

################################################################################
# FINAL SUMMARY
################################################################################

log "=== FINAL SUMMARY ==="
echo ""

ALL_OK=true

[ "$HEADER_COUNT" -eq 5 ] && echo "  ✅ Alle 5 Headers" || { echo "  ❌ Alle 5 Headers"; ALL_OK=false; }
echo "$LINE2" | grep -q "This file is managed by moOde" && echo "  ✅ Main Header in Zeile 2" || { echo "  ❌ Main Header in Zeile 2"; ALL_OK=false; }
[ -f "$SSH_FLAG" ] && [ ! -s "$SSH_FLAG" ] && echo "  ✅ SSH-Flag" || { echo "  ❌ SSH-Flag"; ALL_OK=false; }
grep -q "display_rotate=2" "$CONFIG_FILE" && echo "  ✅ display_rotate=2" || { echo "  ❌ display_rotate=2"; ALL_OK=false; }
[ -f "$CMDLINE_FILE" ] && grep -q "fbcon=rotate:3" "$CMDLINE_FILE" && echo "  ✅ fbcon=rotate:3" || { echo "  ❌ fbcon=rotate:3"; ALL_OK=false; }

echo ""

if [ "$ALL_OK" = true ]; then
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ✅ ALLE FIXES ERFOLGREICH                                   ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    log "Die SD-Karte ist bereit:"
    log "  ✅ worker.php wird config.txt NICHT überschreiben (Header in Zeile 2)"
    log "  ✅ Display wird korrekt rotiert (180°)"
    log "  ✅ SSH wird aktiviert"
    log "  ✅ Console wird rotiert"
    echo ""
    info "Nächste Schritte:"
    echo "  1. SD-Karte sicher auswerfen"
    echo "  2. SD-Karte in Pi einstecken"
    echo "  3. Pi booten"
    echo "  4. Alles sollte funktionieren!"
else
    echo "╔══════════════════════════════════════════════════════════════╗"
    echo "║  ⚠️  EINIGE FIXES KONNTEN NICHT VERIFIZIERT WERDEN          ║"
    echo "╚══════════════════════════════════════════════════════════════╝"
    echo ""
    warn "Bitte prüfe die Fehlermeldungen oben"
fi

echo ""
sync
log "✅ Sync abgeschlossen - Änderungen geschrieben"
