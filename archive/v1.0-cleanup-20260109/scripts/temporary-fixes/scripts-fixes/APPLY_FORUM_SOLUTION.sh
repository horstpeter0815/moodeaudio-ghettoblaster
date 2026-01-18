#!/bin/bash
# Apply Forum Solution for Waveshare 7.9" Display
# Based on: Moode Forum Thread 6416, User: popeye65

set -e

echo "=========================================="
echo "APPLYING FORUM SOLUTION FOR 7.9\" DISPLAY"
echo "=========================================="
echo ""

# Detect Pi model
PI_MODEL=$(cat /proc/device-tree/model 2>/dev/null | grep -o "Pi [45]" | head -1 || echo "Pi 4")
HDMI_PORT="HDMI-A-1"
if [[ "$PI_MODEL" == *"5"* ]]; then
    HDMI_PORT="HDMI-A-2"
    echo "Detected: Raspberry Pi 5 - Using $HDMI_PORT"
else
    echo "Detected: Raspberry Pi 4 - Using $HDMI_PORT"
fi
echo ""

# Get current user (not pi!)
CURRENT_USER=$(whoami)
echo "Current user: $CURRENT_USER"
echo ""

# Backup files
echo "=== Creating backups ==="
sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup.$(date +%Y%m%d_%H%M%S)
if [ -f /home/$CURRENT_USER/.xinitrc ]; then
    cp /home/$CURRENT_USER/.xinitrc /home/$CURRENT_USER/.xinitrc.backup.$(date +%Y%m%d_%H%M%S)
fi
echo "✅ Backups created"
echo ""

# Get PARTUUID
PARTUUID=$(grep -o "PARTUUID=[^ ]*" /boot/firmware/cmdline.txt | cut -d= -f2 | head -1)
echo "PARTUUID: $PARTUUID"
echo ""

# Apply cmdline.txt
echo "=== Applying cmdline.txt ==="
# Remove existing video parameter if present
sudo sed -i 's/ video=[^ ]*//' /boot/firmware/cmdline.txt

# Add video parameter
sudo sed -i "s/\$/ video=$HDMI_PORT:400x1280M@60,rotate=90/" /boot/firmware/cmdline.txt

echo "✅ cmdline.txt updated"
grep "video=" /boot/firmware/cmdline.txt
echo ""

# Apply .xinitrc
echo "=== Applying .xinitrc ==="
if [ ! -f /home/$CURRENT_USER/.xinitrc ]; then
    echo "⚠️  .xinitrc not found, creating from Moode template..."
    # Try to find Moode's xinitrc template
    if [ -f /usr/local/bin/moode-xinitrc ]; then
        cp /usr/local/bin/moode-xinitrc /home/$CURRENT_USER/.xinitrc
    else
        echo "Creating basic .xinitrc..."
        cat > /home/$CURRENT_USER/.xinitrc << 'EOF'
#!/bin/bash
# Moode xinitrc
EOF
    fi
fi

# Add xrandr rotation BEFORE xset commands
if ! grep -q "xrandr --output.*rotate left" /home/$CURRENT_USER/.xinitrc; then
    # Find xset line and insert before it
    if grep -q "xset" /home/$CURRENT_USER/.xinitrc; then
        # Insert before first xset
        sed -i '/xset/i\
DISPLAY=:0 xrandr --output HDMI-1 --rotate left
' /home/$CURRENT_USER/.xinitrc
    else
        # Add at beginning
        sed -i '1i\
DISPLAY=:0 xrandr --output HDMI-1 --rotate left
' /home/$CURRENT_USER/.xinitrc
    fi
    echo "✅ Added xrandr rotation"
fi

# Fix SCREENSIZE swap ($2 and $3)
if grep -q 'SCREENSIZE.*fbset.*geometry.*print.*\$2.*\$3' /home/$CURRENT_USER/.xinitrc; then
    # Already swapped or needs swap
    sed -i 's/SCREENSIZE="$(fbset -s | awk '\''$1 == "geometry" { print $2","$3 }'\'')"/SCREENSIZE="$(fbset -s | awk '\''$1 == "geometry" { print $3","$2 }'\'')"/' /home/$CURRENT_USER/.xinitrc
    echo "✅ SCREENSIZE swap applied"
fi

# Fix HDMI port for Pi 5
if [[ "$HDMI_PORT" == "HDMI-A-2" ]]; then
    sed -i 's/HDMI-1/HDMI-2/g' /home/$CURRENT_USER/.xinitrc
    echo "✅ Updated HDMI port to HDMI-2 for Pi 5"
fi

chmod +x /home/$CURRENT_USER/.xinitrc
echo "✅ .xinitrc updated"
echo ""

echo "=========================================="
echo "✅ FORUM SOLUTION APPLIED"
echo "=========================================="
echo ""
echo "Changes made:"
echo "  1. cmdline.txt: Added video=$HDMI_PORT:400x1280M@60,rotate=90"
echo "  2. .xinitrc: Added xrandr rotation before xset"
echo "  3. .xinitrc: Swapped SCREENSIZE ($2 and $3)"
echo ""
echo "Next step: REBOOT"
echo "  sudo reboot"
echo ""

