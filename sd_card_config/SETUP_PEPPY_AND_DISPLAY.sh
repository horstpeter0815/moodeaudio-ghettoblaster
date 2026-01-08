#!/bin/bash
# Setup Peppy Meters and Display for Moode Audio
# Run this on the Pi after boot

set -e

echo "=========================================="
echo "SETTING UP PEPPY METERS AND DISPLAY"
echo "=========================================="

# 1. Install Peppy Meters
cd /home/andre
if [ ! -d peppy ]; then
    echo "Installing Peppy Meters..."
    git clone https://github.com/project-owner/peppy.git 2>/dev/null || \
    git clone https://github.com/peppy-meter/peppy.git 2>/dev/null || \
    wget -q https://github.com/project-owner/peppy/archive/master.zip && unzip master.zip && mv peppy-master peppy
fi

# 2. Install dependencies
echo "Installing dependencies..."
sudo apt-get update -qq
sudo apt-get install -y python3 python3-pip python3-pygame python3-numpy 2>&1 | tail -5

# 3. Configure Chromium autostart
echo "Configuring Chromium autostart..."
mkdir -p ~/.config/autostart
cat > ~/.config/autostart/moode-webui.desktop << 'EOF'
[Desktop Entry]
Type=Application
Name=Moode Web UI
Exec=sh -c 'sleep 5 && DISPLAY=:0 chromium-browser --kiosk --noerrdialogs --disable-infobars --window-size=1280,400 --start-fullscreen http://localhost/'
Hidden=false
NoDisplay=false
X-GNOME-Autostart-enabled=true
EOF

# 4. Enable desktop
sudo systemctl set-default graphical.target

echo "✅ Setup complete!"
echo "After reboot, Moode Web UI will start automatically"
