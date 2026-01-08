#!/bin/bash
# Fix PeppyMeter Screensaver Touch Detection
# Improves touch detection to properly close PeppyMeter

echo "=== FIXING PEPPYMETER TOUCH DETECTION ==="
echo ""

PI5_ALIAS="pi2"

# Check if Pi 5 is online
if ! ssh -o ConnectTimeout=5 "$PI5_ALIAS" "echo 'Online'" >/dev/null 2>&1; then
    echo "❌ Pi 5 is not online."
    exit 1
fi

echo "✅ Pi 5 is online"
echo ""

# Create improved screensaver script
echo "1. Creating improved PeppyMeter screensaver script..."
ssh "$PI5_ALIAS" "sudo tee /usr/local/bin/peppymeter-screensaver.sh > /dev/null << 'SCREENSAVER_SCRIPT'
#!/bin/bash
# PeppyMeter Screensaver - Improved Touch Detection
# Activates after 10 minutes of inactivity
# Deactivates on touch

export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority

INACTIVITY_TIMEOUT=600  # 10 minutes
LAST_ACTIVITY_FILE=\"/tmp/peppymeter_last_activity\"
TOUCH_LOG=\"/tmp/peppymeter_screensaver.log\"
PEPPY_ACTIVE=false

log() {
    echo \"[\\\$(date +%H:%M:%S)] \\\$1\" | tee -a \"\\\$TOUCH_LOG\"
}

# Initialize last activity
date +%s > \"\\\$LAST_ACTIVITY_FILE\"

# Function to show PeppyMeter
show_peppymeter() {
    if [ \"\\\$PEPPY_ACTIVE\" = false ]; then
        log \"Activating PeppyMeter screensaver\"
        
        # Start PeppyMeter if not running
        if ! systemctl is-active --quiet peppymeter.service; then
            sudo systemctl start peppymeter.service
            sleep 3
        fi
        
        # Hide Chromium window
        CHROMIUM_WID=\\\$(DISPLAY=:0 xdotool search --classname chromium 2>/dev/null | head -1)
        if [ -n \"\\\$CHROMIUM_WID\" ]; then
            DISPLAY=:0 xdotool windowunmap \"\\\$CHROMIUM_WID\" 2>/dev/null
        fi
        
        PEPPY_ACTIVE=true
    fi
}

# Function to hide PeppyMeter
hide_peppymeter() {
    if [ \"\\\$PEPPY_ACTIVE\" = true ]; then
        log \"Deactivating PeppyMeter, showing Chromium\"
        
        # Stop PeppyMeter
        sudo systemctl stop peppymeter.service
        
        # Show Chromium window
        CHROMIUM_WID=\\\$(DISPLAY=:0 xdotool search --classname chromium 2>/dev/null | head -1)
        if [ -n \"\\\$CHROMIUM_WID\" ]; then
            DISPLAY=:0 xdotool windowmap \"\\\$CHROMIUM_WID\" 2>/dev/null
            DISPLAY=:0 xdotool windowraise \"\\\$CHROMIUM_WID\" 2>/dev/null
            DISPLAY=:0 xdotool windowfocus \"\\\$CHROMIUM_WID\" 2>/dev/null
        fi
        
        PEPPY_ACTIVE=false
        date +%s > \"\\\$LAST_ACTIVITY_FILE\"
    fi
}

# Monitor touch events using xinput
monitor_touch() {
    WAVESHARE_ID=\\\$(DISPLAY=:0 xinput list | grep -i 'WaveShare' | grep -oP 'id=\\\\K[0-9]+' | head -1)
    
    if [ -z \"\\\$WAVESHARE_ID\" ]; then
        log \"Touchscreen not found, using alternative detection\"
        return
    fi
    
    log \"Monitoring touchscreen (ID: \\\$WAVESHARE_ID)\"
    
    # Monitor touch events
    DISPLAY=:0 xinput --test-xi2 \\\$WAVESHARE_ID 2>/dev/null | while IFS= read -r line; do
        if [[ \"\\\$line\" =~ \"EVENT type 15\" ]] || [[ \"\\\$line\" =~ \"EVENT type 14\" ]]; then
            date +%s > \"\\\$LAST_ACTIVITY_FILE\"
            log \"Touch event detected\"
            
            if [ \"\\\$PEPPY_ACTIVE\" = true ]; then
                hide_peppymeter
            fi
        fi
    done
}

# Alternative: Monitor using xev (fallback)
monitor_xev() {
    DISPLAY=:0 xev -root -event button 2>/dev/null | while IFS= read -r line; do
        if [[ \"\\\$line\" =~ \"ButtonPress\" ]]; then
            date +%s > \"\\\$LAST_ACTIVITY_FILE\"
            log \"Button press detected\"
            
            if [ \"\\\$PEPPY_ACTIVE\" = true ]; then
                hide_peppymeter
            fi
        fi
    done
}

# Start touch monitoring in background
monitor_touch &
TOUCH_PID=\\\$!

# Also start xev monitoring as fallback
monitor_xev &
XEV_PID=\\\$!

# Cleanup on exit
trap \"kill \\\$TOUCH_PID \\\$XEV_PID 2>/dev/null; exit\" SIGTERM SIGINT EXIT

# Main loop
log \"PeppyMeter Screensaver started (timeout: \\\$INACTIVITY_TIMEOUT seconds)\"

while true; do
    CURRENT_TIME=\\\$(date +%s)
    LAST_ACTIVITY=\\\$(cat \"\\\$LAST_ACTIVITY_FILE\" 2>/dev/null || echo \\\$CURRENT_TIME)
    INACTIVE_TIME=\\\$((CURRENT_TIME - LAST_ACTIVITY))
    
    if [ \\\$INACTIVE_TIME -ge \\\$INACTIVITY_TIMEOUT ]; then
        if [ \"\\\$PEPPY_ACTIVE\" = false ]; then
            show_peppymeter
        fi
    fi
    
    sleep 1
done
SCREENSAVER_SCRIPT"

echo "   ✅ Script created"
echo ""

# Make executable
ssh "$PI5_ALIAS" "sudo chmod +x /usr/local/bin/peppymeter-screensaver.sh"
echo "   ✅ Script made executable"
echo ""

# Update service file
echo "2. Updating service file..."
ssh "$PI5_ALIAS" "sudo tee /etc/systemd/system/peppymeter-screensaver.service > /dev/null << 'SERVICE_FILE'
[Unit]
Description=PeppyMeter Screensaver (10 min inactivity)
After=localdisplay.service
Wants=peppymeter.service

[Service]
Type=simple
ExecStart=/usr/local/bin/peppymeter-screensaver.sh
Restart=always
RestartSec=5
User=andre
Environment=DISPLAY=:0
Environment=XAUTHORITY=/home/andre/.Xauthority

[Install]
WantedBy=multi-user.target
SERVICE_FILE"

echo "   ✅ Service file updated"
echo ""

# Reload systemd and restart service
echo "3. Restarting service..."
ssh "$PI5_ALIAS" "sudo systemctl daemon-reload"
ssh "$PI5_ALIAS" "sudo systemctl enable peppymeter-screensaver.service"
ssh "$PI5_ALIAS" "sudo systemctl restart peppymeter-screensaver.service"
sleep 2

if ssh "$PI5_ALIAS" "systemctl is-active --quiet peppymeter-screensaver.service"; then
    echo "   ✅ Service is running"
else
    echo "   ⚠️  Service status:"
    ssh "$PI5_ALIAS" "systemctl status peppymeter-screensaver.service --no-pager | head -10"
fi

echo ""
echo "=========================================="
echo "PEPPYMETER TOUCH FIX APPLIED"
echo "=========================================="
echo ""
echo "The screensaver will now:"
echo "  - Activate after 10 minutes of inactivity"
echo "  - Close when you touch the screen"
echo ""
echo "Check logs: ssh pi2 'tail -f /tmp/peppymeter_screensaver.log'"
echo ""

