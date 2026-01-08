#!/bin/bash
################################################################################
#
# ADD AUDIO & VIDEO DEBUGGING TOOLS
#
# Fügt die kritischen Audio- und Video-Debugging-Tools zur Build-Konfiguration hinzu.
#
################################################################################

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

log() { echo -e "${GREEN}[INFO]${NC} $1"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1"; }

PROJECT_ROOT="/Users/andrevollmer/moodeaudio-cursor"
STAGE2_PACKAGES="$PROJECT_ROOT/imgbuild/moode-cfg/stage2_04-moode-install_01-packages"
CUSTOM_SCRIPT="$PROJECT_ROOT/imgbuild/pi-gen-64/stage3/03-ghettoblaster-custom/00-run-chroot.sh"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🎵🎬 ADD AUDIO & VIDEO DEBUGGING TOOLS                       ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

################################################################################
# STEP 1: Add to stage2 packages (Standard Moode packages)
################################################################################

log "Step 1: Adding to stage2 packages..."

if [ ! -f "$STAGE2_PACKAGES" ]; then
    error "Stage2 packages file not found: $STAGE2_PACKAGES"
    exit 1
fi

# Check if already added
if grep -q "^alsa-utils$" "$STAGE2_PACKAGES"; then
    warn "alsa-utils already in stage2 packages"
else
    log "Adding alsa-utils to stage2 packages..."
    echo "alsa-utils" >> "$STAGE2_PACKAGES"
    log "✅ alsa-utils added"
fi

if grep -q "^x11-utils$" "$STAGE2_PACKAGES"; then
    warn "x11-utils already in stage2 packages"
else
    log "Adding x11-utils to stage2 packages..."
    echo "x11-utils" >> "$STAGE2_PACKAGES"
    log "✅ x11-utils added"
fi

if grep -q "^fbset$" "$STAGE2_PACKAGES"; then
    warn "fbset already in stage2 packages"
else
    log "Adding fbset to stage2 packages..."
    echo "fbset" >> "$STAGE2_PACKAGES"
    log "✅ fbset added"
fi

echo ""

################################################################################
# STEP 2: Add to custom build script (as fallback/alternative)
################################################################################

log "Step 2: Adding to custom build script (as fallback)..."

if [ ! -f "$CUSTOM_SCRIPT" ]; then
    warn "Custom script not found: $CUSTOM_SCRIPT"
    warn "Skipping custom script modification"
else
    # Check if already added
    if grep -q "alsa-utils\|x11-utils\|fbset" "$CUSTOM_SCRIPT" | grep -q "apt-get install"; then
        warn "Audio/Video tools already in custom script"
    else
        log "Adding audio/video tools installation to custom script..."
        
        # Find the Python dependencies installation line
        PYTHON_LINE=$(grep -n "apt-get install.*python3-scipy" "$CUSTOM_SCRIPT" | head -1 | cut -d: -f1)
        
        if [ -n "$PYTHON_LINE" ]; then
            # Add audio/video tools after Python dependencies
            sed -i.bak "${PYTHON_LINE}s/.*/apt-get update \&\& apt-get install -y python3-scipy python3-soundfile python3-numpy xdotool alsa-utils x11-utils fbset || echo \"⚠️  Some packages may not be available in chroot\"/" "$CUSTOM_SCRIPT"
            log "✅ Audio/Video tools added to custom script (line $PYTHON_LINE)"
        else
            # Add at the end of the script (before the final echo)
            sed -i.bak '/^echo "=== GHETTOBLASTER/i\
################################################################################\
# Install Audio/Video Debugging Tools\
################################################################################\
\
echo "Installing Audio/Video Debugging Tools..."\
apt-get update && apt-get install -y alsa-utils x11-utils fbset || echo "⚠️  Some Audio/Video packages may not be available in chroot"\
echo "✅ Audio/Video Debugging Tools installed"\
' "$CUSTOM_SCRIPT"
            log "✅ Audio/Video tools added to custom script (before final echo)"
        fi
    fi
fi

echo ""

################################################################################
# SUMMARY
################################################################################

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ ZUSAMMENFASSUNG                                          ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

log "Hinzugefügte Pakete:"
echo "  1. alsa-utils"
echo "     → aplay, arecord, alsamixer, alsactl, amixer, speaker-test"
echo ""
echo "  2. x11-utils"
echo "     → xdpyinfo, xwininfo, xev, xinput"
echo ""
echo "  3. fbset"
echo "     → Framebuffer-Einstellungen"
echo ""

log "Dateien geändert:"
echo "  - $STAGE2_PACKAGES"
if [ -f "$CUSTOM_SCRIPT" ]; then
    echo "  - $CUSTOM_SCRIPT"
    if [ -f "${CUSTOM_SCRIPT}.bak" ]; then
        echo "    (Backup erstellt: ${CUSTOM_SCRIPT}.bak)"
    fi
fi
echo ""

log "Nächste Schritte:"
echo "  1. Build neues Image mit: ./imgbuild/build.sh"
echo "  2. Nach dem Boot verfügbar:"
echo "     - aplay -l (Audio-Device-Liste)"
echo "     - xdpyinfo (Display-Info)"
echo "     - xev (Touchscreen-Debugging)"
echo ""

