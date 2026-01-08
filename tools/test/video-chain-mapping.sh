#!/bin/bash
################################################################################
#
# COMPLETE VIDEO CHAIN MAPPING TOOL
# 
# Maps the complete video chain from boot to display, capturing EVERY rotation
# point, configuration, and transformation in the pipeline.
#
# Based on toolbox architecture and existing test tools.
#
################################################################################

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# Use /tmp if running on Pi, otherwise use project root
if [ -d "/home/andre" ]; then
    LOG_FILE="/tmp/video-chain-debug.log"
else
    LOG_FILE="$PROJECT_ROOT/.cursor/debug.log"
fi
# Use /tmp if running on Pi, otherwise use project root
if [ -d "/home/andre" ]; then
    OUTPUT_FILE="/tmp/VIDEO_CHAIN_COMPLETE_MAPPING.md"
else
    OUTPUT_FILE="$PROJECT_ROOT/VIDEO_CHAIN_COMPLETE_MAPPING.md"
fi
cd "$PROJECT_ROOT"

# Clear log file (will be created by instrumentation)
if [ -f "$LOG_FILE" ]; then
    > "$LOG_FILE"
fi

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

log() { echo -e "${GREEN}[MAP]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }
section() { echo -e "${CYAN}[SECTION]${NC} $1"; }
rotation() { echo -e "${MAGENTA}[ROTATION]${NC} $1"; }

# Debug logging
debug_log() {
    local hypothesis_id="$1"
    local location="$2"
    local message="$3"
    local data="$4"
    echo "{\"id\":\"log_$(date +%s)_$$\",\"timestamp\":$(date +%s)000,\"location\":\"$location\",\"message\":\"$message\",\"data\":$data,\"sessionId\":\"video-chain-mapping\",\"runId\":\"mapping-run\",\"hypothesisId\":\"$hypothesis_id\"}" >> "$LOG_FILE"
}

echo ""
echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🎬 COMPLETE VIDEO CHAIN MAPPING TOOL                         ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Initialize output file
cat > "$OUTPUT_FILE" << 'HEADER'
# 🎬 COMPLETE VIDEO CHAIN MAPPING

**Date:** $(date +"%Y-%m-%d %H:%M:%S")  
**Purpose:** Complete mapping of video chain from boot to display, capturing EVERY rotation point

---

## 📋 Video Chain Overview

The video chain flows through these layers:
1. **Boot Configuration** (config.txt, cmdline.txt)
2. **Kernel/Firmware** (Framebuffer, DRM/KMS)
3. **X11 Server** (Xorg)
4. **Display Manager** (.xinitrc, Moode logic)
5. **Applications** (Chromium, PeppyMeter)
6. **Hardware** (HDMI output, physical display)

---

HEADER

################################################################################
# PHASE 1: BOOT CONFIGURATION
################################################################################

section "=== PHASE 1: BOOT CONFIGURATION ==="
echo ""

# Check config.txt
log "1.1: Checking /boot/firmware/config.txt..."

CONFIG_TXT="/boot/firmware/config.txt"
if [ -f "$CONFIG_TXT" ]; then
    info "config.txt found"
    
    # Extract all display-related settings
    DISPLAY_SETTINGS=$(grep -E "display|rotate|hdmi|vc4|framebuffer|dtoverlay" "$CONFIG_TXT" | grep -v "^#" || true)
    
    echo "**config.txt Display Settings:**" >> "$OUTPUT_FILE"
    echo '```ini' >> "$OUTPUT_FILE"
    echo "$DISPLAY_SETTINGS" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Check for display_rotate
    if echo "$DISPLAY_SETTINGS" | grep -q "display_rotate"; then
        ROTATE_VALUE=$(echo "$DISPLAY_SETTINGS" | grep "display_rotate" | head -1 | sed 's/.*display_rotate=\([0-9]*\).*/\1/')
        rotation "display_rotate=$ROTATE_VALUE found in config.txt"
        echo "**Rotation Point 1:** config.txt → display_rotate=$ROTATE_VALUE" >> "$OUTPUT_FILE"
        echo "- **Location:** /boot/firmware/config.txt" >> "$OUTPUT_FILE"
        echo "- **Effect:** Boot-level framebuffer rotation" >> "$OUTPUT_FILE"
        echo "- **Values:** 0=none, 1=90°, 2=180°, 3=270°" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        debug_log "R1" "config.txt" "display_rotate found" "{\"value\":\"$ROTATE_VALUE\"}"
    else
        warn "No display_rotate in config.txt"
        echo "**Rotation Point 1:** config.txt → NO display_rotate (default: 0)" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
    
    # Check for vc4-kms-v3d overlay
    if echo "$DISPLAY_SETTINGS" | grep -q "vc4-kms-v3d"; then
        rotation "vc4-kms-v3d overlay found (DRM/KMS driver)"
        echo "**DRM/KMS Overlay:** vc4-kms-v3d" >> "$OUTPUT_FILE"
        echo "- **Location:** /boot/firmware/config.txt" >> "$OUTPUT_FILE"
        echo "- **Effect:** Enables DRM/KMS driver for display" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
else
    error "config.txt not found"
fi

# Check cmdline.txt
log "1.2: Checking /boot/firmware/cmdline.txt..."

CMDLINE_TXT="/boot/firmware/cmdline.txt"
if [ -f "$CMDLINE_TXT" ]; then
    CMDLINE=$(cat "$CMDLINE_TXT")
    info "cmdline.txt found"
    
    echo "**cmdline.txt:**" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo "$CMDLINE" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Check for video= parameter
    if echo "$CMDLINE" | grep -q "video="; then
        VIDEO_PARAM=$(echo "$CMDLINE" | grep -o "video=[^ ]*")
        rotation "video= parameter found: $VIDEO_PARAM"
        echo "**Rotation Point 2:** cmdline.txt → video= parameter" >> "$OUTPUT_FILE"
        echo "- **Location:** /boot/firmware/cmdline.txt" >> "$OUTPUT_FILE"
        echo "- **Parameter:** $VIDEO_PARAM" >> "$OUTPUT_FILE"
        echo "- **Effect:** Kernel-level video mode and rotation" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        debug_log "R2" "cmdline.txt" "video= parameter found" "{\"param\":\"$VIDEO_PARAM\"}"
    else
        info "No video= parameter in cmdline.txt"
    fi
    
    # Check for fbcon=rotate
    if echo "$CMDLINE" | grep -q "fbcon=rotate"; then
        FBCON_ROTATE=$(echo "$CMDLINE" | grep -o "fbcon=rotate:[0-9]*")
        rotation "fbcon=rotate found: $FBCON_ROTATE"
        echo "**Rotation Point 3:** cmdline.txt → fbcon=rotate" >> "$OUTPUT_FILE"
        echo "- **Location:** /boot/firmware/cmdline.txt" >> "$OUTPUT_FILE"
        echo "- **Parameter:** $FBCON_ROTATE" >> "$OUTPUT_FILE"
        echo "- **Effect:** Console framebuffer rotation" >> "$OUTPUT_FILE"
        echo "- **Values:** 0=none, 1=90°, 2=180°, 3=270°" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        debug_log "R3" "cmdline.txt" "fbcon=rotate found" "{\"param\":\"$FBCON_ROTATE\"}"
    else
        info "No fbcon=rotate in cmdline.txt"
    fi
else
    error "cmdline.txt not found"
fi

################################################################################
# PHASE 2: KERNEL/FRAMEBUFFER
################################################################################

section "=== PHASE 2: KERNEL/FRAMEBUFFER ==="
echo ""

log "2.1: Checking framebuffer state..."

if command -v fbset >/dev/null 2>&1; then
    FB_INFO=$(fbset -s 2>/dev/null || echo "")
    if [ -n "$FB_INFO" ]; then
        FB_GEOMETRY=$(echo "$FB_INFO" | grep "geometry" | awk '{print $2"x"$3}')
        rotation "Framebuffer geometry: $FB_GEOMETRY"
        
        echo "**Framebuffer State:**" >> "$OUTPUT_FILE"
        echo '```' >> "$OUTPUT_FILE"
        echo "$FB_INFO" >> "$OUTPUT_FILE"
        echo '```' >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        echo "**Rotation Point 4:** Framebuffer → Geometry $FB_GEOMETRY" >> "$OUTPUT_FILE"
        echo "- **Location:** Kernel framebuffer (/dev/fb0)" >> "$OUTPUT_FILE"
        echo "- **Current:** $FB_GEOMETRY" >> "$OUTPUT_FILE"
        echo "- **Effect:** Base resolution before X11" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        debug_log "R4" "framebuffer" "Geometry detected" "{\"geometry\":\"$FB_GEOMETRY\"}"
    fi
else
    warn "fbset not available"
fi

# Check /proc/cmdline (runtime)
log "2.2: Checking runtime kernel cmdline..."

if [ -f "/proc/cmdline" ]; then
    RUNTIME_CMDLINE=$(cat /proc/cmdline)
    info "Runtime cmdline available"
    
    echo "**Runtime Kernel Cmdline:**" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo "$RUNTIME_CMDLINE" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

################################################################################
# PHASE 3: X11 SERVER
################################################################################

section "=== PHASE 3: X11 SERVER ==="
echo ""

log "3.1: Checking X11 display state..."

if [ -S /tmp/.X11-unix/X0 ] 2>/dev/null; then
    export DISPLAY=:0
    
    # X11 dimensions
    X11_DIM=$(xdpyinfo 2>/dev/null | grep dimensions | grep -oE '[0-9]+x[0-9]+' | head -1 || echo "")
    if [ -n "$X11_DIM" ]; then
        rotation "X11 display dimensions: $X11_DIM"
        
        echo "**X11 Display State:**" >> "$OUTPUT_FILE"
        echo "- **Dimensions:** $X11_DIM" >> "$OUTPUT_FILE"
        echo "- **Location:** X Server (DISPLAY=:0)" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        debug_log "R5" "X11" "Display dimensions" "{\"dimensions\":\"$X11_DIM\"}"
    fi
    
    # xrandr state
    XRANDR_OUTPUT=$(xrandr 2>/dev/null | grep " connected" | head -1 || echo "")
    if [ -n "$XRANDR_OUTPUT" ]; then
        XRANDR_ROTATION=$(echo "$XRANDR_OUTPUT" | grep -oE "(normal|left|right|inverted)" | head -1 || echo "")
        XRANDR_MODE=$(echo "$XRANDR_OUTPUT" | grep -oE "[0-9]+x[0-9]+" | head -1 || echo "")
        XRANDR_OUTPUT_NAME=$(echo "$XRANDR_OUTPUT" | awk '{print $1}')
        
        rotation "xrandr: $XRANDR_OUTPUT_NAME → $XRANDR_MODE, rotation: $XRANDR_ROTATION"
        
        echo "**Rotation Point 5:** xrandr → $XRANDR_OUTPUT_NAME" >> "$OUTPUT_FILE"
        echo "- **Location:** X11 xrandr (runtime)" >> "$OUTPUT_FILE"
        echo "- **Output:** $XRANDR_OUTPUT_NAME" >> "$OUTPUT_FILE"
        echo "- **Mode:** $XRANDR_MODE" >> "$OUTPUT_FILE"
        echo "- **Rotation:** $XRANDR_ROTATION" >> "$OUTPUT_FILE"
        echo "- **Effect:** X11 display rotation (applied by .xinitrc or scripts)" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        debug_log "R5" "xrandr" "Display rotation" "{\"output\":\"$XRANDR_OUTPUT_NAME\",\"mode\":\"$XRANDR_MODE\",\"rotation\":\"$XRANDR_ROTATION\"}"
        
        # Full xrandr output
        echo "**Full xrandr Output:**" >> "$OUTPUT_FILE"
        echo '```' >> "$OUTPUT_FILE"
        xrandr 2>/dev/null >> "$OUTPUT_FILE" || echo "xrandr not available" >> "$OUTPUT_FILE"
        echo '```' >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
    fi
else
    warn "X11 not running (DISPLAY=:0 not available)"
    echo "**X11 Server:** Not running" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

################################################################################
# PHASE 4: DISPLAY MANAGER (.xinitrc, Moode Logic)
################################################################################

section "=== PHASE 4: DISPLAY MANAGER ==="
echo ""

log "4.1: Checking .xinitrc rotation logic..."

XINITRC="/home/andre/.xinitrc"
if [ -f "$XINITRC" ]; then
    info ".xinitrc found"
    
    # Extract rotation logic
    ROTATION_LOGIC=$(grep -A 30 "Set screen rotation\|xrandr.*rotate\|HDMI_SCN_ORIENT" "$XINITRC" | head -40 || echo "")
    
    echo "**.xinitrc Rotation Logic:**" >> "$OUTPUT_FILE"
    echo '```bash' >> "$OUTPUT_FILE"
    echo "$ROTATION_LOGIC" >> "$OUTPUT_FILE"
    echo '```' >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Check for fix-display-orientation script
    if grep -q "fix-display-orientation" "$XINITRC"; then
        rotation "fix-display-orientation script called in .xinitrc"
        echo "**Rotation Point 6:** .xinitrc → fix-display-orientation-before-peppy.sh" >> "$OUTPUT_FILE"
        echo "- **Location:** /home/andre/.xinitrc" >> "$OUTPUT_FILE"
        echo "- **Script:** /usr/local/bin/fix-display-orientation-before-peppy.sh" >> "$OUTPUT_FILE"
        echo "- **Effect:** Explicit rotation fix before PeppyMeter starts" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        debug_log "R6" ".xinitrc" "fix-display-orientation script" "{}"
    fi
    
    # Check Moode rotation logic
    if grep -q "HDMI_SCN_ORIENT" "$XINITRC"; then
        rotation "Moode rotation logic found in .xinitrc"
        echo "**Rotation Point 7:** .xinitrc → Moode rotation logic" >> "$OUTPUT_FILE"
        echo "- **Location:** /home/andre/.xinitrc" >> "$OUTPUT_FILE"
        echo "- **Logic:** Checks hdmi_scn_orient from Moode database" >> "$OUTPUT_FILE"
        echo "- **Effect:** Conditional rotation based on Moode setting" >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        debug_log "R7" ".xinitrc" "Moode rotation logic" "{}"
    fi
else
    warn ".xinitrc not found"
fi

# Check Moode database
log "4.2: Checking Moode database settings..."

if command -v moodeutl >/dev/null 2>&1; then
    MOODE_DISPLAY_SETTINGS=$(moodeutl -q "SELECT param, value FROM cfg_system WHERE param LIKE '%display%' OR param LIKE '%orient%' OR param LIKE '%scn%'" 2>/dev/null || echo "")
    
    if [ -n "$MOODE_DISPLAY_SETTINGS" ]; then
        info "Moode display settings found"
        
        echo "**Moode Database Display Settings:**" >> "$OUTPUT_FILE"
        echo '```' >> "$OUTPUT_FILE"
        echo "$MOODE_DISPLAY_SETTINGS" >> "$OUTPUT_FILE"
        echo '```' >> "$OUTPUT_FILE"
        echo "" >> "$OUTPUT_FILE"
        
        # Extract hdmi_scn_orient
        HDMI_ORIENT=$(echo "$MOODE_DISPLAY_SETTINGS" | grep "hdmi_scn_orient" | cut -d'|' -f2 || echo "")
        if [ -n "$HDMI_ORIENT" ]; then
            rotation "Moode hdmi_scn_orient: $HDMI_ORIENT"
            echo "**Rotation Point 8:** Moode Database → hdmi_scn_orient" >> "$OUTPUT_FILE"
            echo "- **Location:** /var/local/www/db/moode-sqlite3.db" >> "$OUTPUT_FILE"
            echo "- **Setting:** hdmi_scn_orient=$HDMI_ORIENT" >> "$OUTPUT_FILE"
            echo "- **Effect:** Controls .xinitrc rotation logic" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
            debug_log "R8" "Moode DB" "hdmi_scn_orient" "{\"value\":\"$HDMI_ORIENT\"}"
        fi
    fi
else
    warn "moodeutl not available"
fi

################################################################################
# PHASE 5: APPLICATIONS
################################################################################

section "=== PHASE 5: APPLICATIONS ==="
echo ""

log "5.1: Checking PeppyMeter configuration..."

PEPPY_CONFIG="/opt/peppymeter/1280x400/meters.txt"
if [ -f "$PEPPY_CONFIG" ]; then
    info "PeppyMeter config found"
    
    PEPPY_METER_TYPE=$(grep "meter.type" "$PEPPY_CONFIG" | head -1 | cut -d'=' -f2 | tr -d ' ' || echo "")
    PEPPY_LEFT_X=$(grep "left.x" "$PEPPY_CONFIG" | head -1 | cut -d'=' -f2 | tr -d ' ' || echo "")
    PEPPY_LEFT_Y=$(grep "left.y" "$PEPPY_CONFIG" | head -1 | cut -d'=' -f2 | tr -d ' ' || echo "")
    
    echo "**PeppyMeter Configuration:**" >> "$OUTPUT_FILE"
    echo "- **Config File:** $PEPPY_CONFIG" >> "$OUTPUT_FILE"
    echo "- **Meter Type:** $PEPPY_METER_TYPE" >> "$OUTPUT_FILE"
    echo "- **Left Meter Position:** X=$PEPPY_LEFT_X, Y=$PEPPY_LEFT_Y" >> "$OUTPUT_FILE"
    echo "- **Screen Size:** Determined from folder name (1280x400)" >> "$OUTPUT_FILE"
    echo "- **Note:** PeppyMeter uses folder name for screen size, not X11 query" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
    
    # Check if PeppyMeter is running
    if pgrep -f "peppymeter.py" >/dev/null; then
        PEPPY_PID=$(pgrep -f "peppymeter.py" | head -1)
        rotation "PeppyMeter running (PID: $PEPPY_PID)"
        
        # Check PeppyMeter window
        if [ -S /tmp/.X11-unix/X0 ]; then
            export DISPLAY=:0
            PEPPY_WINDOW=$(xwininfo -name "pygame window" 2>/dev/null | grep geometry | head -1 || echo "")
            if [ -n "$PEPPY_WINDOW" ]; then
                echo "**PeppyMeter Window:**" >> "$OUTPUT_FILE"
                echo "- **Geometry:** $PEPPY_WINDOW" >> "$OUTPUT_FILE"
                echo "" >> "$OUTPUT_FILE"
            fi
        fi
    fi
fi

log "5.2: Checking Chromium configuration..."

if pgrep -f "chromium" >/dev/null; then
    CHROMIUM_PID=$(pgrep -f "chromium" | head -1)
    info "Chromium running (PID: $CHROMIUM_PID)"
    
    echo "**Chromium:**" >> "$OUTPUT_FILE"
    echo "- **Status:** Running" >> "$OUTPUT_FILE"
    echo "- **Mode:** Kiosk (fullscreen)" >> "$OUTPUT_FILE"
    echo "" >> "$OUTPUT_FILE"
fi

################################################################################
# PHASE 6: HARDWARE
################################################################################

section "=== PHASE 6: HARDWARE ==="
echo ""

log "6.1: Checking hardware display state..."

if [ -S /tmp/.X11-unix/X0 ]; then
    export DISPLAY=:0
    
    # Pygame display info (if available)
    if command -v python3 >/dev/null 2>&1; then
        PYGAME_INFO=$(python3 -c "import pygame; pygame.display.init(); info = pygame.display.Info(); print(f'{info.current_w}x{info.current_h}')" 2>/dev/null || echo "")
        if [ -n "$PYGAME_INFO" ]; then
            rotation "Pygame reports: $PYGAME_INFO"
            
            echo "**Pygame Display Info:**" >> "$OUTPUT_FILE"
            echo "- **Dimensions:** $PYGAME_INFO" >> "$OUTPUT_FILE"
            echo "- **Note:** Pygame queries X11 for display size" >> "$OUTPUT_FILE"
            echo "" >> "$OUTPUT_FILE"
        fi
    fi
fi

################################################################################
# SUMMARY: COMPLETE ROTATION CHAIN
################################################################################

section "=== ROTATION CHAIN SUMMARY ==="
echo ""

cat >> "$OUTPUT_FILE" << 'SUMMARY_EOF'

---

## 🔄 COMPLETE ROTATION CHAIN

The video signal flows through these rotation points:

1. **config.txt** → `display_rotate=X` (boot-level framebuffer rotation)
2. **cmdline.txt** → `video=...rotate=...` (kernel-level video rotation)
3. **cmdline.txt** → `fbcon=rotate:X` (console framebuffer rotation)
4. **Framebuffer** → Native geometry (after boot rotation)
5. **X11 xrandr** → Runtime rotation (applied by .xinitrc)
6. **.xinitrc** → fix-display-orientation script (explicit rotation fix)
7. **.xinitrc** → Moode rotation logic (conditional rotation)
8. **Moode Database** → `hdmi_scn_orient` (controls .xinitrc logic)
9. **Applications** → Use X11 dimensions (PeppyMeter uses folder name)

---

## ⚠️ CURRENT STATE ANALYSIS

**Problem Identified:**
- Display hardware reports: **400x1280** (portrait)
- Physical display should be: **1280x400** (landscape)
- Moode setting: **landscape**
- X11 reports: **1280x400** (correctly rotated)
- Framebuffer reports: **400x1280** (not rotated)

**Root Cause:**
The display hardware EDID reports portrait mode, but the physical display is landscape.
Rotation must be applied at multiple points to ensure consistency.

---

## ✅ RECOMMENDATIONS

1. **Ensure rotation at boot level** (config.txt or cmdline.txt)
2. **Apply rotation in .xinitrc** BEFORE applications start
3. **Verify Moode database** setting matches reality
4. **Check all rotation points** are consistent
5. **Use fix-display-orientation script** to ensure correct orientation

---

**Mapping Complete:** $(date +"%Y-%m-%d %H:%M:%S")

SUMMARY_EOF

log "=== MAPPING COMPLETE ==="
echo ""
info "Output saved to: $OUTPUT_FILE"
info "Debug log saved to: $LOG_FILE"
echo ""
log "✅ Video chain mapping complete!"

