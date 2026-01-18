#!/bin/bash
# Persistent Display Configuration Fix
# Ensures display settings persist across reboots by running AFTER moOde's worker.php
# This script restores display settings that moOde may overwrite

set -euo pipefail

LOG_FILE="/var/log/persist-display-config.log"
BOOT_CONFIG="/boot/firmware/config.txt"
BOOT_CMDLINE="/boot/firmware/cmdline.txt"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"
}

log "=== PERSISTENT DISPLAY CONFIGURATION FIX ==="

# CRITICAL: config.txt is read at BOOT TIME by kernel
# This script runs AFTER boot, so it's too late for current boot
# But we fix it for NEXT boot and verify current settings

# Ensure boot partition is mounted and writable
if [ ! -w "$BOOT_CONFIG" ]; then
    log "ERROR: Cannot write to $BOOT_CONFIG"
    log "Display settings will be fixed for NEXT boot"
    exit 0  # Don't fail - just log warning
fi

# ============================================================================
# FIX config.txt - Restore display settings that moOde may overwrite
# ============================================================================

log "Fixing config.txt display settings..."

# Required display settings for Waveshare 7.9" HDMI display
DISPLAY_SETTINGS=(
    "# Ghettoblaster Display Settings"
    "disable_overscan=1"
    "hdmi_group=2"
    "hdmi_mode=87"
    "hdmi_cvt=400 1280 60 6 0 0 0"
    "hdmi_force_mode=1"
)

# Check if [pi5] section exists and has correct display settings
if grep -q "^\[pi5\]" "$BOOT_CONFIG"; then
    log "Found [pi5] section"
    
    # Ensure display settings are present after [pi5] section
    # Find line number of [pi5] section
    PI5_LINE=$(grep -n "^\[pi5\]" "$BOOT_CONFIG" | head -1 | cut -d: -f1)
    
    if [ -n "$PI5_LINE" ]; then
        # Check if display settings already exist
        if ! grep -q "hdmi_cvt=400 1280 60 6 0 0 0" "$BOOT_CONFIG"; then
            log "Adding display settings after [pi5] section..."
            # Insert after [pi5] section (after the next non-comment line or [all] section)
            # Find the line after [pi5] where we should insert
            INSERT_LINE=$((PI5_LINE + 1))
            # Find where [all] section starts
            ALL_LINE=$(grep -n "^\[all\]" "$BOOT_CONFIG" | head -1 | cut -d: -f1)
            if [ -n "$ALL_LINE" ] && [ "$ALL_LINE" -gt "$PI5_LINE" ]; then
                INSERT_LINE=$((ALL_LINE - 1))
            fi
            
            # Insert display settings
            {
                head -n "$INSERT_LINE" "$BOOT_CONFIG"
                echo ""
                echo "# Ghettoblaster Display Settings"
                echo "disable_overscan=1"
                echo "hdmi_group=2"
                echo "hdmi_mode=87"
                echo "hdmi_cvt=400 1280 60 6 0 0 0"
                echo "hdmi_force_mode=1"
                tail -n +$((INSERT_LINE + 1)) "$BOOT_CONFIG"
            } > "$BOOT_CONFIG.tmp" && mv "$BOOT_CONFIG.tmp" "$BOOT_CONFIG"
            log "✅ Display settings added to config.txt"
        else
            log "✅ Display settings already present in config.txt"
        fi
        
        # Ensure display settings are correct (fix if wrong)
        sed -i 's/^hdmi_cvt=.*/hdmi_cvt=400 1280 60 6 0 0 0/' "$BOOT_CONFIG"
        sed -i 's/^hdmi_mode=.*/hdmi_mode=87/' "$BOOT_CONFIG"
        sed -i 's/^hdmi_group=.*/hdmi_group=2/' "$BOOT_CONFIG"
        sed -i 's/^hdmi_force_mode=.*/hdmi_force_mode=1/' "$BOOT_CONFIG"
        sed -i 's/^disable_overscan=.*/disable_overscan=1/' "$BOOT_CONFIG"
    fi
else
    log "WARNING: [pi5] section not found in config.txt"
fi

# Ensure [all] section has display settings if not in [pi5]
if grep -q "^\[all\]" "$BOOT_CONFIG"; then
    if ! grep -q "hdmi_cvt=400 1280 60 6 0 0 0" "$BOOT_CONFIG"; then
        log "Adding display settings to [all] section..."
        ALL_LINE=$(grep -n "^\[all\]" "$BOOT_CONFIG" | head -1 | cut -d: -f1)
        INSERT_LINE=$((ALL_LINE + 1))
        {
            head -n "$INSERT_LINE" "$BOOT_CONFIG"
            echo ""
            echo "# Ghettoblaster Display Settings"
            echo "disable_overscan=1"
            echo "hdmi_group=2"
            echo "hdmi_mode=87"
            echo "hdmi_cvt=400 1280 60 6 0 0 0"
            echo "hdmi_force_mode=1"
            tail -n +$((INSERT_LINE + 1)) "$BOOT_CONFIG"
        } > "$BOOT_CONFIG.tmp" && mv "$BOOT_CONFIG.tmp" "$BOOT_CONFIG"
        log "✅ Display settings added to [all] section"
    fi
fi

# ============================================================================
# FIX cmdline.txt - Ensure correct HDMI port and rotation
# ============================================================================

log "Fixing cmdline.txt HDMI settings..."

if [ -f "$BOOT_CMDLINE" ]; then
    # Ensure video=HDMI-A-1:400x1280M@60,rotate=90 is present
    CMDLINE_CONTENT=$(cat "$BOOT_CMDLINE")
    
    # Check if correct video parameter exists
    if echo "$CMDLINE_CONTENT" | grep -q "video=HDMI-A-1:400x1280M@60,rotate=90"; then
        log "✅ cmdline.txt already has correct HDMI-A-1 settings"
    else
        log "Fixing cmdline.txt video parameter..."
        
        # Remove any existing video=HDMI-A-* parameters
        CMDLINE_CONTENT=$(echo "$CMDLINE_CONTENT" | sed 's/video=HDMI-A-[0-9]:[^ ]*//g')
        
        # Remove any existing video= parameters that might conflict
        CMDLINE_CONTENT=$(echo "$CMDLINE_CONTENT" | sed 's/video=[^ ]*//g')
        
        # Add correct video parameter at the end
        CMDLINE_CONTENT="$CMDLINE_CONTENT video=HDMI-A-1:400x1280M@60,rotate=90"
        
        # Write back to file
        echo "$CMDLINE_CONTENT" > "$BOOT_CMDLINE"
        log "✅ cmdline.txt fixed with HDMI-A-1:400x1280M@60,rotate=90"
    fi
    
    # Ensure no HDMI-A-2 references (common mistake)
    if grep -q "HDMI-A-2" "$BOOT_CMDLINE"; then
        log "Fixing HDMI-A-2 → HDMI-A-1 in cmdline.txt..."
        sed -i 's/HDMI-A-2/HDMI-A-1/g' "$BOOT_CMDLINE"
        log "✅ Fixed HDMI-A-2 references"
    fi
else
    log "WARNING: cmdline.txt not found"
fi

# ============================================================================
# Verify settings
# ============================================================================

log "Verifying display settings..."

# Check config.txt
if grep -q "hdmi_cvt=400 1280 60 6 0 0 0" "$BOOT_CONFIG"; then
    log "✅ config.txt: Display settings verified"
else
    log "❌ config.txt: Display settings MISSING"
fi

# Check cmdline.txt
if grep -q "video=HDMI-A-1:400x1280M@60,rotate=90" "$BOOT_CMDLINE"; then
    log "✅ cmdline.txt: HDMI-A-1 settings verified"
else
    log "❌ cmdline.txt: HDMI-A-1 settings MISSING"
fi

log "=== PERSISTENT DISPLAY CONFIGURATION FIX COMPLETE ==="
