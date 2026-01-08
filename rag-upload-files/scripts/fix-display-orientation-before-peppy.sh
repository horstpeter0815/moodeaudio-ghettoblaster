#!/bin/bash
################################################################################
#
# Fix Display Orientation Before PeppyMeter Starts (INSTRUMENTED)
# 
# This script ensures the display is correctly oriented (landscape 1280x400)
# and applies any necessary inversions BEFORE PeppyMeter starts.
#
# The issue: Display hardware reports 400x1280 (portrait) but should be
# 1280x400 (landscape). This script fixes it at X11 level.
#
################################################################################

LOG_FILE="/tmp/video-chain-debug.log"

debug_log() {
    local hypothesis_id="$1"
    local location="$2"
    local message="$3"
    local data="$4"
    echo "{\"id\":\"log_$(date +%s)_$$\",\"timestamp\":$(date +%s)000,\"location\":\"$location\",\"message\":\"$message\",\"data\":$data,\"sessionId\":\"peppy-fix\",\"runId\":\"fix-run\",\"hypothesisId\":\"$hypothesis_id\"}" >> "$LOG_FILE"
}

echo "=== FIX DISPLAY ORIENTATION BEFORE PEPPYMETER ==="
debug_log "B" "fix-display-orientation-before-peppy.sh:start" "Script started" "{}"

# Wait for X11 to be ready
MAX_WAIT=30
WAITED=0
while [ $WAITED -lt $MAX_WAIT ]; do
    if [ -S /tmp/.X11-unix/X0 ] && DISPLAY=:0 xdpyinfo >/dev/null 2>&1; then
        echo "✅ X11 is ready"
        debug_log "B" "fix-display-orientation-before-peppy.sh:x11-ready" "X11 is ready" "{\"waited\":$WAITED}"
        break
    fi
    sleep 1
    WAITED=$((WAITED + 1))
done

if [ $WAITED -ge $MAX_WAIT ]; then
    echo "⚠️  X11 not ready after $MAX_WAIT seconds"
    debug_log "B" "fix-display-orientation-before-peppy.sh:x11-timeout" "X11 not ready" "{\"waited\":$WAITED}"
    exit 1
fi

# Check framebuffer first (boot-level rotation)
FB_DIM=$(fbset -s 2>/dev/null | awk '$1 == "geometry" {print $2"x"$3}' || echo "")
echo "Framebuffer dimensions: $FB_DIM"
debug_log "B" "fix-display-orientation-before-peppy.sh:framebuffer" "Framebuffer dimensions" "{\"dimensions\":\"$FB_DIM\"}"

# Get current display dimensions (get first match only)
CURRENT_DIM=$(DISPLAY=:0 xdpyinfo 2>/dev/null | grep dimensions | grep -oE '[0-9]+x[0-9]+' | head -1)
CURRENT_ROTATION=$(DISPLAY=:0 xrandr 2>/dev/null | grep HDMI-1 | grep -oE '(normal|left|right|inverted)' | head -1)

echo "Current display: $CURRENT_DIM, rotation: $CURRENT_ROTATION"
debug_log "B" "fix-display-orientation-before-peppy.sh:current-state" "Current display state" "{\"dimensions\":\"$CURRENT_DIM\",\"rotation\":\"$CURRENT_ROTATION\"}"

# If framebuffer is already 1280x400, display is rotated at boot level - no X11 rotation needed
if [ "$FB_DIM" = "1280x400" ]; then
    echo "✅ Display already rotated at boot level (framebuffer: $FB_DIM)"
    echo "   No X11 rotation needed - PeppyMeter coordinates will be correct"
    debug_log "B" "fix-display-orientation-before-peppy.sh:boot-rotated" "Display rotated at boot level" "{\"framebuffer\":\"$FB_DIM\"}"
    
    # Just verify X11 matches
    if [ "$CURRENT_DIM" = "1280x400" ]; then
        echo "✅ X11 display matches framebuffer: $CURRENT_DIM"
        exit 0
    else
        echo "⚠️  X11 ($CURRENT_DIM) doesn't match framebuffer ($FB_DIM) - may need X11 rotation"
        # Continue to rotation logic below
    fi
fi

# Target: 1280x400 (landscape)
TARGET_WIDTH=1280
TARGET_HEIGHT=400

# Check if we need to fix orientation
if [ "$CURRENT_DIM" != "${TARGET_WIDTH}x${TARGET_HEIGHT}" ]; then
    echo "⚠️  Display is $CURRENT_DIM, should be ${TARGET_WIDTH}x${TARGET_HEIGHT}"
    echo "Fixing rotation..."
    debug_log "B" "fix-display-orientation-before-peppy.sh:needs-rotation" "Display needs rotation" "{\"current\":\"$CURRENT_DIM\",\"target\":\"${TARGET_WIDTH}x${TARGET_HEIGHT}\"}"
    
    # If current is 400x1280 (portrait), we need to rotate 90 degrees to get 1280x400 (landscape)
    # The display hardware reports portrait but we want landscape
    
    # Force rotate left (90° counter-clockwise) - this should swap dimensions
    echo "Trying rotate left..."
    DISPLAY=:0 xrandr --output HDMI-1 --rotate left 2>&1
    debug_log "B" "fix-display-orientation-before-peppy.sh:rotate-left" "Applied rotate left" "{}"
    sleep 3  # Increased wait time
    NEW_DIM=$(DISPLAY=:0 xdpyinfo 2>/dev/null | grep dimensions | grep -oE '[0-9]+x[0-9]+' | head -1 || echo "")
    
    if [ "$NEW_DIM" = "${TARGET_WIDTH}x${TARGET_HEIGHT}" ]; then
        echo "✅ Fixed with rotate left: $NEW_DIM"
        debug_log "B" "fix-display-orientation-before-peppy.sh:rotate-success" "Rotation successful" "{\"new_dimensions\":\"$NEW_DIM\"}"
        # Success - don't try other rotations
    else
        echo "Rotate left gave: $NEW_DIM, trying rotate right..."
        debug_log "B" "fix-display-orientation-before-peppy.sh:rotate-left-failed" "Rotate left failed" "{\"result\":\"$NEW_DIM\"}"
        # Try rotate right (90° clockwise)
        DISPLAY=:0 xrandr --output HDMI-1 --rotate right 2>&1
        sleep 3  # Increased wait time
        NEW_DIM=$(DISPLAY=:0 xdpyinfo 2>/dev/null | grep dimensions | grep -oE '[0-9]+x[0-9]+' | head -1 || echo "")
        
        if [ "$NEW_DIM" = "${TARGET_WIDTH}x${TARGET_HEIGHT}" ]; then
            echo "✅ Fixed with rotate right: $NEW_DIM"
            debug_log "B" "fix-display-orientation-before-peppy.sh:rotate-right-success" "Rotation successful" "{\"new_dimensions\":\"$NEW_DIM\"}"
        else
            echo "⚠️  Rotation attempts gave: $NEW_DIM"
            echo "Display may need manual configuration"
            debug_log "B" "fix-display-orientation-before-peppy.sh:rotate-failed" "All rotation attempts failed" "{\"result\":\"$NEW_DIM\"}"
        fi
    fi
else
    echo "✅ Display already correct: $CURRENT_DIM"
    debug_log "B" "fix-display-orientation-before-peppy.sh:already-correct" "Display already correct" "{\"dimensions\":\"$CURRENT_DIM\"}"
fi

# Apply horizontal/vertical inversion if needed
# Check Moode settings for inversion requirements
HDMI_SCN_ORIENT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'" 2>/dev/null || echo "landscape")

echo ""
echo "Moode orientation setting: $HDMI_SCN_ORIENT"
debug_log "B" "fix-display-orientation-before-peppy.sh:moode-setting" "Moode orientation setting" "{\"hdmi_scn_orient\":\"$HDMI_SCN_ORIENT\"}"

# Final verification - wait a bit more for X11 to settle
sleep 2
FINAL_DIM=$(DISPLAY=:0 xdpyinfo 2>/dev/null | grep dimensions | grep -oE '[0-9]+x[0-9]+' | head -1)
FINAL_ROTATION=$(DISPLAY=:0 xrandr 2>/dev/null | grep HDMI-1 | grep -oE '(normal|left|right|inverted)' | head -1)

# Also check Pygame sees the correct dimensions (PeppyMeter uses Pygame)
PYGAME_DIM=$(DISPLAY=:0 python3 -c "import pygame; pygame.display.init(); info = pygame.display.Info(); print(f'{info.current_w}x{info.current_h}')" 2>/dev/null 2>/dev/null | grep -oE '[0-9]+x[0-9]+' | head -1 || echo "")

echo ""
echo "=== FINAL STATE ==="
echo "Display dimensions: $FINAL_DIM"
echo "Rotation: $FINAL_ROTATION"
echo "Pygame dimensions: $PYGAME_DIM"
echo "Target: ${TARGET_WIDTH}x${TARGET_HEIGHT}"

debug_log "B" "fix-display-orientation-before-peppy.sh:final-state" "Final display state" "{\"x11_dimensions\":\"$FINAL_DIM\",\"x11_rotation\":\"$FINAL_ROTATION\",\"pygame_dimensions\":\"$PYGAME_DIM\",\"target\":\"${TARGET_WIDTH}x${TARGET_HEIGHT}\"}"

if [ "$FINAL_DIM" = "${TARGET_WIDTH}x${TARGET_HEIGHT}" ] && [ "$PYGAME_DIM" = "${TARGET_WIDTH}x${TARGET_HEIGHT}" ]; then
    echo "✅ Display orientation correct - PeppyMeter can start"
    debug_log "B" "fix-display-orientation-before-peppy.sh:success" "Display orientation correct" "{}"
    exit 0
else
    echo "⚠️  Display orientation may still be incorrect"
    echo "   X11: $FINAL_DIM, Pygame: $PYGAME_DIM"
    debug_log "B" "fix-display-orientation-before-peppy.sh:warning" "Display orientation may be incorrect" "{\"x11\":\"$FINAL_DIM\",\"pygame\":\"$PYGAME_DIM\"}"
    exit 1
fi

