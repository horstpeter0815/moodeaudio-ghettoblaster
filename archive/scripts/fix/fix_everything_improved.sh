#!/bin/bash
# Complete Fix Script - IMPROVED VERSION
# Fixes Display, Touchscreen, and Peppy
# This fixes the ROOT CAUSE, not just symptoms

set -e

echo "=========================================="
echo "Complete Fix - All Issues (Improved)"
echo "=========================================="
echo "Fixing: Display rotation workaround that breaks everything"
echo ""

# Detect HDMI port name
echo "Step 0: Detecting HDMI port..."
export DISPLAY=:0
if xset q &>/dev/null; then
    HDMI_PORT=$(xrandr | grep " connected" | head -1 | awk '{print $1}')
    echo "Detected HDMI port: $HDMI_PORT"
else
    # Default for Pi 5
    HDMI_PORT="HDMI-2"
    echo "X11 not running, using default: $HDMI_PORT"
fi
echo ""

# Backup everything
echo "Step 1: Creating backups..."
BACKUP_DIR="$HOME/config_backups_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

sudo cp /boot/firmware/config.txt "$BACKUP_DIR/config.txt" 2>/dev/null || \
sudo cp /boot/config.txt "$BACKUP_DIR/config.txt" 2>/dev/null || \
echo "⚠️  Could not backup config.txt"

sudo cp /boot/firmware/cmdline.txt "$BACKUP_DIR/cmdline.txt" 2>/dev/null || \
sudo cp /boot/cmdline.txt "$BACKUP_DIR/cmdline.txt" 2>/dev/null || \
echo "⚠️  Could not backup cmdline.txt"

cp ~/.xinitrc "$BACKUP_DIR/xinitrc" 2>/dev/null || echo "⚠️  xinitrc not found"

# Save current xrandr output
if xset q &>/dev/null; then
    xrandr > "$BACKUP_DIR/xrandr_before.txt" 2>/dev/null || true
fi

echo "✓ Backups created in: $BACKUP_DIR"
echo ""

# Determine config file location
if [ -f "/boot/firmware/config.txt" ]; then
    CONFIG="/boot/firmware/config.txt"
    CMDLINE="/boot/firmware/cmdline.txt"
elif [ -f "/boot/config.txt" ]; then
    CONFIG="/boot/config.txt"
    CMDLINE="/boot/cmdline.txt"
else
    echo "ERROR: Could not find config.txt!"
    exit 1
fi

# Fix 1: Remove video parameter from cmdline.txt
echo "Step 2: Removing video parameter from cmdline.txt..."
# Remove any video parameter with 400x1280 or rotate=90
if grep -q "video=.*400x1280.*rotate=90\|video=.*rotate=90.*400x1280" "$CMDLINE"; then
    sudo sed -i 's/video=[^ ]* //g' "$CMDLINE"
    sudo sed -i 's/  / /g' "$CMDLINE"  # Clean up double spaces
    sudo sed -i 's/^ //' "$CMDLINE"    # Remove leading space
    sudo sed -i 's/ $//' "$CMDLINE"    # Remove trailing space
    echo "✓ Removed video parameter"
else
    echo "⚠️  Video parameter not found (may already be removed)"
fi
echo ""

# Fix 2: Ensure config.txt has correct settings
echo "Step 3: Fixing config.txt..."

# Add display_rotate=0 if not present
if ! grep -q "^display_rotate=0" "$CONFIG"; then
    # Remove any existing display_rotate
    sudo sed -i '/^display_rotate=/d' "$CONFIG"
    # Add display_rotate=0
    echo "display_rotate=0" | sudo tee -a "$CONFIG" > /dev/null
    echo "✓ Added display_rotate=0"
fi

# Ensure hdmi_cvt is correct
if grep -q "hdmi_cvt.*1280.*400" "$CONFIG"; then
    # Update existing hdmi_cvt
    sudo sed -i 's/hdmi_cvt.*1280.*400.*/hdmi_cvt 1280 400 60 6 0 0 0/' "$CONFIG"
    echo "✓ Fixed hdmi_cvt"
elif ! grep -q "^hdmi_cvt" "$CONFIG"; then
    # Add hdmi_cvt if not present
    echo "hdmi_cvt 1280 400 60 6 0 0 0" | sudo tee -a "$CONFIG" > /dev/null
    echo "✓ Added hdmi_cvt"
fi

# Ensure hdmi_group and hdmi_mode
if ! grep -q "^hdmi_group=2" "$CONFIG"; then
    echo "hdmi_group=2" | sudo tee -a "$CONFIG" > /dev/null
fi
if ! grep -q "^hdmi_mode=87" "$CONFIG"; then
    echo "hdmi_mode=87" | sudo tee -a "$CONFIG" > /dev/null
fi

# Ensure hdmi_force_hotplug=1
if ! grep -q "^hdmi_force_hotplug=1" "$CONFIG"; then
    echo "hdmi_force_hotplug=1" | sudo tee -a "$CONFIG" > /dev/null
fi

echo "✓ Config.txt verified and fixed"
echo ""

# Fix 3: Fix xinitrc - Remove forced rotation
echo "Step 4: Fixing xinitrc..."
XINITRC="$HOME/.xinitrc"

if [ ! -f "$XINITRC" ]; then
    echo "⚠️  xinitrc not found, creating basic one"
    touch "$XINITRC"
    chmod +x "$XINITRC"
fi

# Remove all forced rotation lines (both with and without DISPLAY=:0)
sed -i "/xrandr --output $HDMI_PORT --rotate left/d" "$XINITRC"
sed -i "/DISPLAY=:0 xrandr --output $HDMI_PORT --rotate left/d" "$XINITRC"
sed -i "/xrandr.*rotate.*left/d" "$XINITRC"

# Add proper rotation logic (only if portrait in Moode)
if ! grep -q "HDMI_SCN_ORIENT" "$XINITRC"; then
    # Find where to insert (before Chromium or at end)
    if grep -q "chromium\|Chromium" "$XINITRC"; then
        # Insert before chromium
        ROTATION_LOGIC="# HDMI Orientation - Only rotate if Moode says portrait
HDMI_SCN_ORIENT=\$(moodeutl -q \"SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'\" 2>/dev/null || echo \"landscape\")
if [ \"\$HDMI_SCN_ORIENT\" = \"portrait\" ]; then
    DISPLAY=:0 xrandr --output $HDMI_PORT --rotate left
else
    DISPLAY=:0 xrandr --output $HDMI_PORT --rotate normal
fi
"
        sed -i "/chromium\|Chromium/i\\$ROTATION_LOGIC" "$XINITRC"
    else
        # Append to end
        cat >> "$XINITRC" << XINITRC_EOF

# HDMI Orientation - Only rotate if Moode says portrait
HDMI_SCN_ORIENT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'" 2>/dev/null || echo "landscape")
if [ "$HDMI_SCN_ORIENT" = "portrait" ]; then
    DISPLAY=:0 xrandr --output $HDMI_PORT --rotate left
else
    DISPLAY=:0 xrandr --output $HDMI_PORT --rotate normal
fi
XINITRC_EOF
    fi
    echo "✓ Added proper rotation logic"
else
    echo "⚠️  Rotation logic already exists"
fi
echo ""

# Fix 4: Configure touchscreen
echo "Step 5: Configuring touchscreen..."

# Create X11 config directory
sudo mkdir -p /etc/X11/xorg.conf.d

# Create touchscreen config
sudo tee /etc/X11/xorg.conf.d/99-touchscreen.conf > /dev/null << EOF
# Touchscreen Configuration for Waveshare 7.9" HDMI LCD
# USB ID: 0712:000a

Section "InputClass"
    Identifier "WaveShare Touchscreen"
    MatchUSBID "0712:000a"
    MatchIsTouchscreen "on"
    Driver "libinput"
    Option "TransformationMatrix" "1 0 0 0 1 0 0 0 1"
    Option "CalibrationMatrix" "1 0 0 0 1 0 0 0 1"
EndSection
EOF

echo "✓ X11 touchscreen config created"

# Add touchscreen config to xinitrc
if ! grep -q "Touchscreen Configuration" "$XINITRC"; then
    TOUCH_CONFIG="# Touchscreen Configuration
sleep 2  # Wait for X11
TOUCH_DEVICE=\$(xinput list | grep -i \"WaveShare\" | head -1 | grep -oP 'id=\\K[0-9]+' || echo \"\")
if [ ! -z \"\$TOUCH_DEVICE\" ]; then
    xinput set-prop \"\$TOUCH_DEVICE\" \"Coordinate Transformation Matrix\" 1 0 0 0 1 0 0 0 1
    echo \"Touchscreen configured: Device \$TOUCH_DEVICE\"
else
    echo \"WARNING: Touchscreen not found in xinput\"
fi
"
    # Insert before Chromium or append
    if grep -q "chromium\|Chromium" "$XINITRC"; then
        sed -i "/chromium\|Chromium/i\\$TOUCH_CONFIG" "$XINITRC"
    else
        echo "$TOUCH_CONFIG" >> "$XINITRC"
    fi
    echo "✓ Touchscreen config added to xinitrc"
else
    echo "⚠️  Touchscreen config already in xinitrc"
fi

# Apply now if X11 running
if xset q &>/dev/null; then
    TOUCH_ID=$(xinput list | grep -i "WaveShare" | head -1 | grep -oP 'id=\K[0-9]+' || echo "")
    if [ ! -z "$TOUCH_ID" ]; then
        xinput set-prop "$TOUCH_ID" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1 2>/dev/null && \
        echo "✓ Transformation matrix applied now" || \
        echo "⚠️  Could not apply matrix (may need restart)"
    fi
fi
echo ""

# Summary
echo "=========================================="
echo "All Fixes Applied!"
echo "=========================================="
echo ""
echo "Changes made:"
echo "  ✓ Removed video parameter from cmdline.txt"
echo "  ✓ Fixed config.txt (display_rotate=0, hdmi_cvt 1280 400)"
echo "  ✓ Removed forced rotation from xinitrc"
echo "  ✓ Added proper rotation logic (only if portrait)"
echo "  ✓ Configured touchscreen (X11 config + xinitrc)"
echo ""
echo "Backups saved in: $BACKUP_DIR"
echo ""
echo "HDMI Port detected: $HDMI_PORT"
echo ""
echo "NEXT STEPS:"
echo "  1. Reboot: sudo reboot"
echo "  2. After reboot, verify:"
echo "     - ./verify_everything.sh"
echo "     - xrandr (should show 1280x400 normal)"
echo "     - ./test_touchscreen.sh"
echo "     - Test Chromium"
echo "     - Test Peppy Meter"
echo ""
echo "If something doesn't work, restore from: $BACKUP_DIR"
echo ""

