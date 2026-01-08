#!/bin/bash
# Kompletter Display-Fix

echo "=== FIXE DISPLAY KOMPLETT ==="

# Stoppe alles
sudo systemctl stop localdisplay.service 2>/dev/null
sudo pkill -9 Xorg 2>/dev/null
sudo pkill -9 xinit 2>/dev/null
sudo pkill -9 chromium 2>/dev/null
sleep 2

# Erstelle .xinitrc
cat > ~/.xinitrc << 'EOF'
#!/bin/bash
export DISPLAY=:0
xrandr --output HDMI-1 --rotate left 2>/dev/null || xrandr --output HDMI-A-1 --rotate left 2>/dev/null || true
xinput set-prop "FT6236" "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1 2>/dev/null || true
chromium-browser --kiosk --show-cursor http://localhost/ 2>&1 &
wait
EOF
chmod +x ~/.xinitrc

# Fixe Service
sudo tee /usr/lib/systemd/system/localdisplay.service > /dev/null << 'EOF'
[Unit]
Description=Start Local Display
After=graphical.target

[Service]
Type=simple
User=andre
Environment=DISPLAY=:0
ExecStart=/usr/bin/xinit -- :0 -nolisten tcp -novtswitch
Restart=on-failure
RestartSec=3
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=graphical.target
EOF

# Aktiviere und Starte
sudo systemctl daemon-reload
sudo systemctl enable localdisplay.service
sudo systemctl start localdisplay.service

sleep 5

# Prüfe
if systemctl is-active localdisplay.service >/dev/null 2>&1; then
    echo "✅ X Server läuft"
    ps aux | grep Xorg | grep -v grep
else
    echo "❌ X Server läuft nicht"
    journalctl -u localdisplay.service -n 20 --no-pager
fi

