#!/bin/bash
# Fix Display Problem - Stoppe alle X Prozesse und starte neu

echo "=== FIXE DISPLAY ==="

# Stoppe alle X Prozesse
sudo systemctl stop localdisplay.service 2>/dev/null
sudo pkill -9 Xorg 2>/dev/null
sudo pkill -9 xinit 2>/dev/null
sleep 2

# Prüfe .xinitrc
if [ ! -f ~/.xinitrc ]; then
    echo "Erstelle .xinitrc..."
    cat > ~/.xinitrc << 'XINITRC'
#!/bin/bash
export DISPLAY=:0
xrandr --output HDMI-1 --rotate left 2>/dev/null
xinput set-prop "FT6236" "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1 2>/dev/null
chromium-browser --kiosk --show-cursor http://localhost/ &
wait
XINITRC
    chmod +x ~/.xinitrc
fi

# Fixe Service
sudo tee /usr/lib/systemd/system/localdisplay.service > /dev/null << 'EOF'
[Unit]
Description=Start Local Display
After=graphical.target

[Service]
Type=simple
User=andre
ExecStart=/usr/bin/xinit -- :0 -nolisten tcp
Restart=always
RestartSec=5

[Install]
WantedBy=graphical.target
EOF

# Reload und Start
sudo systemctl daemon-reload
sudo systemctl enable localdisplay.service
sudo systemctl start localdisplay.service

sleep 5

# Prüfe Status
if systemctl is-active localdisplay.service >/dev/null 2>&1; then
    echo "✅ X Server läuft"
    ps aux | grep -E 'Xorg|xinit' | grep -v grep
else
    echo "❌ X Server läuft nicht"
    journalctl -u localdisplay.service -n 20 --no-pager
fi

