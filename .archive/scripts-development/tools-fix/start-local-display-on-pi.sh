#!/bin/bash
# Start local display service on Pi to show web UI
# Works from any directory

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

PI_HOST="${1:-192.168.2.3}"
PI_USER="${2:-andre}"
PI_PASS="${3:-0815}"

echo "=== STARTING LOCAL DISPLAY ON PI ==="
echo "Target: $PI_USER@$PI_HOST"
echo ""

# Check for sshpass
if ! command -v sshpass >/dev/null 2>&1; then
    echo "⚠️  sshpass not found. Installing..."
    if command -v brew >/dev/null 2>&1; then
        brew install hudochenkov/sshpass/sshpass || {
            echo "❌ Failed to install sshpass"
            exit 1
        }
    else
        echo "❌ sshpass not found and Homebrew not available"
        exit 1
    fi
fi

# Check if Pi is reachable
if ! ping -c 1 -W 2 "$PI_HOST" >/dev/null 2>&1; then
    echo "❌ Pi not reachable at $PI_HOST"
    exit 1
fi

echo "✅ Pi is reachable"
echo ""

# Create script to start local display
echo "Starting local display service on Pi..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=accept-new "$PI_USER@$PI_HOST" "cat > /tmp/start-local-display.sh << 'SCRIPT_EOF'
#!/bin/bash
set -e

log() { echo -e \"\033[0;32m[INFO]\033[0m \$1\"; }
error() { echo -e \"\033[0;31m[ERROR]\033[0m \$1\" >&2; }
warn() { echo -e \"\033[0;33m[WARN]\033[0m \$1\"; }

echo \"=== Starting Local Display Service ===\"
echo \"\"

# 1. Check if localdisplay service exists
if systemctl list-unit-files | grep -q localdisplay.service; then
    log \"localdisplay.service found\"
    
    # Enable and start the service
    sudo systemctl enable localdisplay.service 2>/dev/null || true
    sudo systemctl start localdisplay.service 2>/dev/null && {
        sleep 3
        if systemctl is-active --quiet localdisplay.service; then
            log \"localdisplay.service started successfully\"
        else
            warn \"localdisplay.service failed to start\"
            sudo systemctl status localdisplay.service --no-pager -l | head -20
        fi
    } || {
        warn \"Could not start localdisplay.service\"
        sudo systemctl status localdisplay.service --no-pager -l | head -20
    }
else
    warn \"localdisplay.service not found\"
    
    # Check for alternative display services
    if systemctl list-unit-files | grep -q kiosk.service; then
        log \"Found kiosk.service, starting it...\"
        sudo systemctl enable kiosk.service 2>/dev/null || true
        sudo systemctl start kiosk.service 2>/dev/null && log \"kiosk.service started\" || warn \"Could not start kiosk.service\"
    fi
    
    # Try to start Chromium manually
    log \"Attempting to start Chromium in kiosk mode...\"
    
    # Check if X is running
    if [ -z \"\$DISPLAY\" ]; then
        export DISPLAY=:0
    fi
    
    # Kill any existing Chromium
    pkill -f chromium 2>/dev/null || true
    sleep 2
    
    # Start Chromium in kiosk mode
    if command -v chromium >/dev/null 2>&1 || command -v chromium-browser >/dev/null 2>&1; then
        CHROMIUM_CMD=\$(command -v chromium 2>/dev/null || command -v chromium-browser 2>/dev/null)
        
        # Get local IP
        LOCAL_IP=\$(ip addr show eth0 2>/dev/null | grep \"inet \" | awk '{print \$2}' | cut -d/ -f1 || echo \"localhost\")
        
        log \"Starting Chromium in kiosk mode pointing to http://\$LOCAL_IP/\"
        
        # Start Chromium as the display user (usually pi or moode)
        sudo -u \$(who | head -1 | awk '{print \$1}') DISPLAY=:0 \$CHROMIUM_CMD \\
            --kiosk \\
            --noerrdialogs \\
            --disable-infobars \\
            --disable-session-crashed-bubble \\
            --disable-restore-session-state \\
            --autoplay-policy=no-user-gesture-required \\
            \"http://\$LOCAL_IP/\" >/dev/null 2>&1 &
        
        sleep 3
        
        if pgrep -f chromium >/dev/null 2>&1; then
            log \"Chromium started successfully\"
        else
            warn \"Chromium failed to start\"
        fi
    else
        error \"Chromium not found - cannot start local display\"
        echo \"Install with: sudo apt-get install chromium-browser\"
    fi
fi

echo \"\"
echo \"=== Summary ===\"
if pgrep -f chromium >/dev/null 2>&1; then
    log \"✅ Chromium is running\"
    echo \"The web UI should now be visible on the Pi's display\"
else
    warn \"⚠️  Chromium is not running\"
    echo \"The web UI is accessible from your computer at: http://\$PI_HOST/\"
fi

echo \"\"
LOCAL_IP=\$(ip addr show eth0 2>/dev/null | grep \"inet \" | awk '{print \$2}' | cut -d/ -f1 || echo \"\")
if [ -n \"\$LOCAL_IP\" ]; then
    echo \"Web UI URL: http://\$LOCAL_IP/\"
fi

SCRIPT_EOF
chmod +x /tmp/start-local-display.sh
sudo bash /tmp/start-local-display.sh" || {
    echo "❌ Failed to start local display"
    exit 1
}

echo ""
echo "✅ Local display service started!"
echo ""
echo "The web UI should now appear on the Pi's display."
echo ""
echo "If it doesn't appear, you can also access it from your computer:"
echo "  http://$PI_HOST/"
echo ""
