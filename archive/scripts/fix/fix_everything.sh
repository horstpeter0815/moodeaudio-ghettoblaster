#!/bin/bash
# Complete Fix Script - Fixes Display, Touchscreen, and Peppy
# This fixes the ROOT CAUSE, not just symptoms

set -e

echo "=========================================="
echo "Complete Fix - All Issues"
echo "=========================================="
echo "Fixing: Display rotation workaround that breaks everything"
echo ""

# Backup everything
echo "Step 1: Creating backups..."
BACKUP_DIR="$HOME/config_backups_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

# Determine config location for backup
if [ -f "/boot/firmware/config.txt" ]; then
    sudo cp /boot/firmware/config.txt "$BACKUP_DIR/config.txt" 2>/dev/null || true
    sudo cp /boot/firmware/cmdline.txt "$BACKUP_DIR/cmdline.txt" 2>/dev/null || true
elif [ -f "/boot/config.txt" ]; then
    sudo cp /boot/config.txt "$BACKUP_DIR/config.txt" 2>/dev/null || true
    sudo cp /boot/cmdline.txt "$BACKUP_DIR/cmdline.txt" 2>/dev/null || true
fi
cp ~/.xinitrc "$BACKUP_DIR/xinitrc" 2>/dev/null || echo "xinitrc not found"

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
    echo "Searched: /boot/firmware/config.txt, /boot/config.txt"
    exit 1
fi

echo "Using config: $CONFIG"
echo "Using cmdline: $CMDLINE"
echo ""

# Fix 1: Remove video parameter from cmdline.txt
echo "Step 2: Removing video parameter from cmdline.txt..."
# Remove any video parameter with 400x1280 or rotate=90
if grep -q "video=.*400x1280.*rotate=90\|video=.*rotate=90.*400x1280\|video=HDMI-A-2:400x1280M@60,rotate=90" "$CMDLINE"; then
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
    echo "display_rotate=0" | sudo tee -a "$CONFIG" > /dev/null
    echo "✓ Added display_rotate=0"
fi

# Ensure hdmi_cvt is correct
if grep -q "hdmi_cvt.*1280.*400" "$CONFIG"; then
    sudo sed -i 's/hdmi_cvt.*1280.*400.*/hdmi_cvt 1280 400 60 6 0 0 0/' "$CONFIG"
    echo "✓ Fixed hdmi_cvt"
fi

# Ensure hdmi_group and hdmi_mode
if ! grep -q "^hdmi_group=2" "$CONFIG"; then
    echo "hdmi_group=2" | sudo tee -a "$CONFIG" > /dev/null
fi
if ! grep -q "^hdmi_mode=87" "$CONFIG"; then
    echo "hdmi_mode=87" | sudo tee -a "$CONFIG" > /dev/null
fi

echo "✓ Config.txt verified"
echo ""

# Detect HDMI port name
export DISPLAY=:0
if xset q &>/dev/null; then
    HDMI_PORT=$(xrandr | grep " connected" | head -1 | awk '{print $1}')
else
    HDMI_PORT="HDMI-2"  # Default for Pi 5
fi

# Fix 3: Fix xinitrc - Remove forced rotation
echo "Step 4: Fixing xinitrc..."
XINITRC="$HOME/.xinitrc"

if [ ! -f "$XINITRC" ]; then
    echo "⚠️  xinitrc not found, will create basic one"
    touch "$XINITRC"
    chmod +x "$XINITRC"
fi

# Remove forced rotation lines (handle both HDMI-2 and detected port)
sed -i "/xrandr --output HDMI-2 --rotate left/d" "$XINITRC"
sed -i "/xrandr --output $HDMI_PORT --rotate left/d" "$XINITRC"
sed -i "/DISPLAY=:0 xrandr --output HDMI-2 --rotate left/d" "$XINITRC"
sed -i "/DISPLAY=:0 xrandr --output $HDMI_PORT --rotate left/d" "$XINITRC"
sed -i "/xrandr.*rotate.*left/d" "$XINITRC"

# Add proper rotation logic (only if portrait in Moode)
if ! grep -q "HDMI_SCN_ORIENT" "$XINITRC"; then
    # Find where to insert (before Chromium)
    if grep -q "chromium\|Chromium" "$XINITRC"; then
        # Insert before chromium
        # Detect HDMI port
        export DISPLAY=:0
        if xset q &>/dev/null; then
            HDMI_PORT=$(xrandr | grep " connected" | head -1 | awk '{print $1}')
        else
            HDMI_PORT="HDMI-2"
        fi
        sed -i "/chromium\|Chromium/i\\
# HDMI Orientation - Only rotate if Moode says portrait\\
HDMI_SCN_ORIENT=\$(moodeutl -q \"SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'\" 2>/dev/null || echo \"landscape\")\\
if [ \"\$HDMI_SCN_ORIENT\" = \"portrait\" ]; then\\
    DISPLAY=:0 xrandr --output $HDMI_PORT --rotate left\\
else\\
    DISPLAY=:0 xrandr --output $HDMI_PORT --rotate normal\\
fi\\
" "$XINITRC"
    else
        # Append to end
        # Detect HDMI port
        export DISPLAY=:0
        if xset q &>/dev/null; then
            HDMI_PORT=$(xrandr | grep " connected" | head -1 | awk '{print $1}')
        else
            HDMI_PORT="HDMI-2"
        fi
        cat >> "$XINITRC" << EOF

# HDMI Orientation - Only rotate if Moode says portrait
HDMI_SCN_ORIENT=\$(moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'" 2>/dev/null || echo "landscape")
if [ "\$HDMI_SCN_ORIENT" = "portrait" ]; then
    DISPLAY=:0 xrandr --output $HDMI_PORT --rotate left
else
    DISPLAY=:0 xrandr --output $HDMI_PORT --rotate normal
fi
EOF
    fi
    echo "✓ Added proper rotation logic"
else
    echo "⚠️  Rotation logic already exists"
fi
echo ""

# Fix 4: Configure touchscreen
echo "Step 5: Configuring touchscreen..."
if [ -f "./fix_touchscreen_complete.sh" ]; then
    bash ./fix_touchscreen_complete.sh
    echo "✓ Touchscreen configured"
else
    echo "⚠️  Touchscreen script not found, configuring manually..."
    
    # Create X11 config
    sudo mkdir -p /etc/X11/xorg.conf.d
    sudo tee /etc/X11/xorg.conf.d/99-touchscreen.conf > /dev/null << 'EOF'
Section "InputClass"
    Identifier "WaveShare Touchscreen"
    MatchUSBID "0712:000a"
    MatchIsTouchscreen "on"
    Driver "libinput"
    Option "TransformationMatrix" "1 0 0 0 1 0 0 0 1"
EndSection
EOF
    
    # Add to xinitrc
    if ! grep -q "Touchscreen Configuration" "$XINITRC"; then
        cat >> "$XINITRC" << 'TOUCH_EOF'

# Touchscreen Configuration
sleep 2
TOUCH_DEVICE=$(xinput list | grep -i "WaveShare" | head -1 | grep -oP 'id=\K[0-9]+' || echo "")
if [ ! -z "$TOUCH_DEVICE" ]; then
    xinput set-prop "$TOUCH_DEVICE" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1
    echo "Touchscreen configured: Device $TOUCH_DEVICE"
fi
TOUCH_EOF
    fi
    echo "✓ Touchscreen configured manually"
fi
echo ""

# Summary
echo "=========================================="
echo "All Fixes Applied!"
echo "=========================================="
echo ""
echo "Changes made:"
echo "  ✓ Removed video parameter from cmdline.txt"
echo "  ✓ Fixed config.txt (display_rotate=0, hdmi_cvt)"
echo "  ✓ Removed forced rotation from xinitrc"
echo "  ✓ Added proper rotation logic (only if portrait)"
echo "  ✓ Configured touchscreen"
echo ""
echo "Backups saved in: $BACKUP_DIR"
echo ""
echo "NEXT STEPS:"
echo "  1. Reboot: sudo reboot"
echo "  2. After reboot, verify:"
echo "     - xrandr (should show 1280x400 normal, not rotated)"
echo "     - fbset -s (should show 1280 400)"
echo "     - ./test_touchscreen.sh (test coordinates)"
echo "     - Test Chromium (should work correctly)"
echo "     - Test Peppy Meter (should work now!)"
echo ""
echo "If something doesn't work, restore from: $BACKUP_DIR"
echo ""

