#!/bin/bash
################################################################################
# Install PeppyMeter Swipe Gesture Control
# Enables swipe up/down to toggle between PeppyMeter and moOde UI
################################################################################

set -e

echo "==================================="
echo "PeppyMeter Swipe Gesture Installer"
echo "==================================="
echo ""

# Check if running on Pi
if [ ! -f "/var/local/www/db/moode-sqlite3.db" ]; then
    echo "ERROR: This script must run on the Raspberry Pi (moOde system)"
    exit 1
fi

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}This will install swipe gesture control for PeppyMeter${NC}"
echo "Swipe UP or DOWN on the display to toggle between PeppyMeter and moOde UI"
echo ""
read -p "Continue? (y/n) " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Installation cancelled"
    exit 0
fi

# 1. Copy Python wrapper to system
echo ""
echo "Step 1: Installing swipe detection wrapper..."
sudo cp "$(dirname "$0")/peppymeter-swipe-wrapper.py" /usr/local/bin/
sudo chmod +x /usr/local/bin/peppymeter-swipe-wrapper.py
echo -e "${GREEN}✓${NC} Wrapper installed"

# 2. Backup current .xinitrc
echo ""
echo "Step 2: Backing up .xinitrc..."
if [ -f "/home/andre/.xinitrc" ]; then
    sudo cp /home/andre/.xinitrc /home/andre/.xinitrc.backup-$(date +%Y%m%d-%H%M%S)
    echo -e "${GREEN}✓${NC} Backup created"
fi

# 3. Update .xinitrc to use swipe wrapper
echo ""
echo "Step 3: Updating .xinitrc..."

# Read current xinitrc
XINITRC_PATH="/home/andre/.xinitrc"

# Create updated xinitrc with swipe wrapper
sudo tee "$XINITRC_PATH" > /dev/null << 'EOF'
#!/bin/bash
# Ghettoblaster .xinitrc - Display Configuration
# Handles display rotation and application launch

export DISPLAY=:0

# Wait for X server
while ! xdpyinfo >/dev/null 2>&1; do
    sleep 0.5
done

# Get display settings from database
HDMI_OUTPUT=$(xrandr | grep " connected" | head -n 1 | awk '{print $1}')
HDMI_SCN_ORIENT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'")
WEBUI_SHOW=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='local_display'")
PEPPY_SHOW=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='peppy_display'")

# Setup display mode (1280x400 landscape)
xrandr --newmode "1280x400_60" 59.51 1280 1390 1422 1510 400 410 420 430 -hsync +vsync 2>/dev/null || true
xrandr --addmode "$HDMI_OUTPUT" 1280x400_60 2>/dev/null || true
xrandr --output "$HDMI_OUTPUT" --mode 1280x400_60 2>/dev/null || true

# Apply rotation if needed
if [ "$HDMI_SCN_ORIENT" = "landscape" ]; then
    xrandr --output "$HDMI_OUTPUT" --rotate left
    SCREEN_RES="1280,400"
else
    SCREEN_RES="400,1280"
fi

# Disable screen blanking
xset s off
xset -dpms
xset s noblank

# Launch application based on database settings
if [ "$PEPPY_SHOW" = "1" ]; then
    # Launch PeppyMeter WITH swipe gesture detection
    echo "Starting PeppyMeter with swipe gesture control..."
    python3 /usr/local/bin/peppymeter-swipe-wrapper.py
elif [ "$WEBUI_SHOW" = "1" ]; then
    # Launch moOde WebUI (Chromium)
    echo "Starting moOde WebUI..."
    /usr/bin/chromium \
        --kiosk \
        --noerrdialogs \
        --disable-infobars \
        --no-first-run \
        --disable-session-crashed-bubble \
        --disable-features=TranslateUI \
        --app=http://localhost/ \
        --window-size=$SCREEN_RES \
        --window-position=0,0 \
        --disable-pinch \
        --overscroll-history-navigation=0
fi
EOF

sudo chmod +x "$XINITRC_PATH"
sudo chown andre:andre "$XINITRC_PATH"
echo -e "${GREEN}✓${NC} .xinitrc updated with swipe gesture support"

# 4. Install Python dependencies (if needed)
echo ""
echo "Step 4: Checking Python dependencies..."
if ! python3 -c "import pygame" 2>/dev/null; then
    echo "Installing pygame..."
    sudo apt-get update
    sudo apt-get install -y python3-pygame
    echo -e "${GREEN}✓${NC} pygame installed"
else
    echo -e "${GREEN}✓${NC} pygame already installed"
fi

# 5. Test permissions
echo ""
echo "Step 5: Setting permissions..."
sudo usermod -a -G input andre 2>/dev/null || true
sudo usermod -a -G video andre 2>/dev/null || true
echo -e "${GREEN}✓${NC} Permissions configured"

# Done!
echo ""
echo "======================================"
echo -e "${GREEN}Installation Complete!${NC}"
echo "======================================"
echo ""
echo "How to use:"
echo "1. Toggle to PeppyMeter using the web UI button"
echo "2. When PeppyMeter is showing, SWIPE UP or SWIPE DOWN on the display"
echo "3. The system will switch back to moOde UI"
echo "4. Click the PeppyMeter button again to return to PeppyMeter"
echo ""
echo "Note: Swipe must be at least 100 pixels vertical movement"
echo "      Works with both swipe up and swipe down"
echo ""
echo -e "${YELLOW}Restart localdisplay service to activate:${NC}"
echo "  sudo systemctl restart localdisplay"
echo ""
