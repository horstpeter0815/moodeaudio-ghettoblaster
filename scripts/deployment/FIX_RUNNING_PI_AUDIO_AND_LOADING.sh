#!/bin/bash
################################################################################
#
# FIX RUNNING PI - Audio Output and Loading Speed
# 
# For downloaded moOde images (not custom builds)
# Fixes: Audio set to HDMI, slow radio/playlist loading
#
################################################################################

set -e

PI_HOST="${PI_HOST:-192.168.10.2}"
PI_USER="${PI_USER:-andre}"
PI_PASS="${PI_PASS:-0815}"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${GREEN}[FIX]${NC} $1"; }
error() { echo -e "${RED}[ERROR]${NC} $1" >&2; }
warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
info() { echo -e "${BLUE}[INFO]${NC} $1"; }

log "=== FIXING RUNNING PI ==="
log "Pi: $PI_USER@$PI_HOST"
echo ""

# Check if Pi is reachable
if ! ping -c 1 -W 1 "$PI_HOST" >/dev/null 2>&1; then
    error "Cannot reach $PI_HOST"
    error "Is the Pi powered on and connected?"
    exit 1
fi

# Check for sshpass
if ! command -v sshpass >/dev/null 2>&1; then
    warn "sshpass not found. Installing..."
    if command -v brew >/dev/null 2>&1; then
        brew install hudochenkov/sshpass/sshpass || {
            error "Failed to install sshpass"
            exit 1
        }
    else
        error "sshpass not found and Homebrew not available"
        exit 1
    fi
fi

# Create fix script to run on Pi
FIX_SCRIPT="/tmp/fix-audio-loading-$(date +%Y%m%d).sh"

log "Creating fix script..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=accept-new "$PI_USER@$PI_HOST" "cat > $FIX_SCRIPT << 'SCRIPT_EOF'
#!/bin/bash
set -e

MOODE_DB=\"/var/local/www/db/moode-sqlite3.db\"

echo \"=== FIXING AUDIO AND LOADING ===\"
echo \"\"

# Fix 1: Set adevname to HiFiBerry AMP100 (prevents HDMI fallback)
echo \"Fix 1: Setting adevname to HiFiBerry AMP100...\"
if [ -f \"\$MOODE_DB\" ]; then
    CURRENT_ADEVNAME=\$(sqlite3 \"\$MOODE_DB\" \"SELECT value FROM cfg_system WHERE param='adevname';\" 2>/dev/null || echo \"\")
    echo \"Current adevname: \$CURRENT_ADEVNAME\"
    
    if [ \"\$CURRENT_ADEVNAME\" != \"HiFiBerry AMP100\" ]; then
        sudo sqlite3 \"\$MOODE_DB\" \"UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='adevname';\" 2>/dev/null || {
            echo \"ERROR: Failed to update adevname\"
            exit 1
        }
        echo \"✅ adevname set to HiFiBerry AMP100\"
    else
        echo \"✅ adevname already correct\"
    fi
    
    # Also ensure i2sdevice is set
    CURRENT_I2S=\$(sqlite3 \"\$MOODE_DB\" \"SELECT value FROM cfg_system WHERE param='i2sdevice';\" 2>/dev/null || echo \"\")
    if [ \"\$CURRENT_I2S\" != \"HiFiBerry AMP100\" ]; then
        sudo sqlite3 \"\$MOODE_DB\" \"UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='i2sdevice';\" 2>/dev/null || true
        echo \"✅ i2sdevice set to HiFiBerry AMP100\"
    fi
    
    # Ensure MPD device is _audioout
    MPD_DEVICE=\$(sqlite3 \"\$MOODE_DB\" \"SELECT value FROM cfg_mpd WHERE param='device';\" 2>/dev/null || echo \"\")
    if [ \"\$MPD_DEVICE\" != \"_audioout\" ]; then
        sudo sqlite3 \"\$MOODE_DB\" \"UPDATE cfg_mpd SET value='_audioout' WHERE param='device';\" 2>/dev/null || true
        echo \"✅ MPD device set to _audioout\"
    fi
else
    echo \"ERROR: Database not found\"
    exit 1
fi
echo \"\"

# Fix 2: Reduce lazy load timeout in JavaScript
echo \"Fix 2: Reducing lazy load timeout...\"
PLAYERLIB=\"/var/www/js/playerlib.js\"
if [ -f \"\$PLAYERLIB\" ]; then
    # Backup first
    sudo cp \"\$PLAYERLIB\" \"\${PLAYERLIB}.backup.\$(date +%Y%m%d_%H%M%S)\"
    
    # Replace LAZYLOAD_TIMEOUT
    sudo sed -i \"s/const LAZYLOAD_TIMEOUT  = 1000;/const LAZYLOAD_TIMEOUT  = 100; \/\/ Reduced for faster loading/\" \"\$PLAYERLIB\" && {
        echo \"✅ Lazy load timeout reduced to 100ms\"
    } || {
        echo \"⚠️  Could not update lazy load timeout (may already be updated)\"
    }
else
    echo \"⚠️  playerlib.js not found at \$PLAYERLIB\"
fi
echo \"\"

# Fix 3: Restart services
echo \"Fix 3: Restarting services...\"
sudo systemctl restart mpd 2>/dev/null && echo \"✅ MPD restarted\" || echo \"⚠️  Could not restart MPD\"
sudo systemctl restart nginx 2>/dev/null && echo \"✅ nginx restarted\" || echo \"⚠️  Could not restart nginx\"
echo \"\"

echo \"=== FIX COMPLETE ===\"
echo \"\"
echo \"Next steps:\"
echo \"  1. Clear browser cache (Ctrl+Shift+Delete)\"
echo \"  2. Hard refresh moOde web interface (Ctrl+F5)\"
echo \"  3. Check audio output: System → Audio → Output device (should be HiFiBerry AMP100)\"
echo \"  4. Test radio stations - should load faster\"
echo \"  5. Test play button - should use AMP100\"
echo \"\"
SCRIPT_EOF
chmod +x $FIX_SCRIPT" || {
    error "Failed to create fix script on Pi"
    exit 1
}

log "Running fix script on Pi..."
sshpass -p "$PI_PASS" ssh -o StrictHostKeyChecking=accept-new "$PI_USER@$PI_HOST" "sudo bash $FIX_SCRIPT" || {
    error "Failed to run fix script"
    exit 1
}

log ""
log "✅✅✅ FIX COMPLETE ✅✅✅"
log ""
log "Fixes applied:"
log "  1. ✅ adevname set to HiFiBerry AMP100 (prevents HDMI fallback)"
log "  2. ✅ Lazy load timeout reduced to 100ms (10x faster)"
log "  3. ✅ Services restarted"
log ""
log "Next steps:"
log "  1. Clear browser cache (Ctrl+Shift+Delete)"
log "  2. Hard refresh moOde web interface (Ctrl+F5)"
log "  3. Check audio output in System → Audio"
log "  4. Test radio stations and play button"
log ""
