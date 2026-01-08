#!/bin/bash
################################################################################
#
# FIX .XINITRC SYNTAX ERROR
#
# Fixes syntax error in .xinitrc file that prevents X server from starting
#
################################################################################

set +e

LOG_FILE="/var/log/fix-xinitrc-syntax.log"
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

log "=== FIX .XINITRC SYNTAX START ==="

# Find user home directory
if [ -d "/home/andre" ]; then
    HOME_DIR="/home/andre"
elif id -u andre >/dev/null 2>&1; then
    HOME_DIR=$(getent passwd andre | cut -d: -f6)
else
    HOME_DIR="/home/andre"
fi

XINITRC="$HOME_DIR/.xinitrc"
log "Checking: $XINITRC"

# Backup existing file
if [ -f "$XINITRC" ]; then
    log "1. Backing up existing .xinitrc..."
    cp "$XINITRC" "$XINITRC.backup.$(date +%Y%m%d_%H%M%S)"
    log "   ✅ Backup created"
    
    # Check for syntax errors
    log "2. Checking syntax..."
    if bash -n "$XINITRC" 2>&1 | grep -q "syntax error"; then
        log "   ❌ Syntax error detected"
        
        # Try to fix common issues
        log "3. Attempting to fix syntax errors..."
        
        # Fix common syntax issues: missing then, elif without if, etc.
        sed -i 's/^elif /# Fixed: elif -> if\nif /' "$XINITRC" 2>/dev/null || true
        sed -i 's/^else$/# Fixed: else\nif true; then/' "$XINITRC" 2>/dev/null || true
        
        # Check again
        if bash -n "$XINITRC" >/dev/null 2>&1; then
            log "   ✅ Syntax fixed"
        else
            log "   ⚠️  Could not auto-fix, creating clean version..."
            
            # Get display URL
            DISPLAY_URL=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='local_display_url'" 2>/dev/null || echo "http://localhost")
            
            # Create clean .xinitrc with rotation support
            cat > "$XINITRC" << EOF
#!/bin/sh
xset s 600
xset -dpms
export DISPLAY=:0

# Display rotation for 400x1280 display (landscape mode)
OUTPUT=\$(xrandr 2>&1 | grep " connected" | head -1 | cut -d' ' -f1)
if [ -n "\$OUTPUT" ]; then
    if xrandr 2>&1 | grep -q "400x1280"; then
        xrandr --output "\$OUTPUT" --mode 400x1280 --rotate right 2>&1 || true
    elif xrandr 2>&1 | grep -q "1280x400"; then
        xrandr --output "\$OUTPUT" --mode 1280x400 --rotate normal 2>&1 || true
    fi
fi

chromium-browser --kiosk --no-sandbox --disable-gpu --app="$DISPLAY_URL" &
wait
EOF
            chmod +x "$XINITRC"
            chown andre:andre "$XINITRC" 2>/dev/null || true
            log "   ✅ Created clean .xinitrc"
        fi
    else
        log "   ✅ No syntax errors found"
        # Check if rotation code is missing
        if ! grep -q "xrandr.*rotate" "$XINITRC" 2>/dev/null; then
            log "   ⚠️  Rotation code missing, adding it..."
            DISPLAY_URL=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='local_display_url'" 2>/dev/null || echo "http://localhost")
            
            # Create .xinitrc with rotation
            cat > "$XINITRC" << EOF
#!/bin/sh
xset s 600
xset -dpms
export DISPLAY=:0

# Display rotation for 400x1280 display (landscape mode)
OUTPUT=\$(xrandr 2>&1 | grep " connected" | head -1 | cut -d' ' -f1)
if [ -n "\$OUTPUT" ]; then
    if xrandr 2>&1 | grep -q "400x1280"; then
        xrandr --output "\$OUTPUT" --mode 400x1280 --rotate right 2>&1 || true
    elif xrandr 2>&1 | grep -q "1280x400"; then
        xrandr --output "\$OUTPUT" --mode 1280x400 --rotate normal 2>&1 || true
    fi
fi

chromium-browser --kiosk --no-sandbox --disable-gpu --app="$DISPLAY_URL" &
wait
EOF
            chmod +x "$XINITRC"
            chown andre:andre "$XINITRC" 2>/dev/null || true
            log "   ✅ Added rotation code"
        fi
    fi
else
    log "   ⚠️  .xinitrc not found, creating..."
    
    DISPLAY_URL=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='local_display_url'" 2>/dev/null || echo "http://localhost")
    
    mkdir -p "$HOME_DIR"
    cat > "$XINITRC" << EOF
#!/bin/sh
xset s 600
xset -dpms
export DISPLAY=:0

# Display rotation for 400x1280 display (landscape mode)
OUTPUT=\$(xrandr 2>&1 | grep " connected" | head -1 | cut -d' ' -f1)
if [ -n "\$OUTPUT" ]; then
    if xrandr 2>&1 | grep -q "400x1280"; then
        xrandr --output "\$OUTPUT" --mode 400x1280 --rotate right 2>&1 || true
    elif xrandr 2>&1 | grep -q "1280x400"; then
        xrandr --output "\$OUTPUT" --mode 1280x400 --rotate normal 2>&1 || true
    fi
fi

chromium-browser --kiosk --no-sandbox --disable-gpu --app="$DISPLAY_URL" &
wait
EOF
    chmod +x "$XINITRC"
    chown andre:andre "$XINITRC" 2>/dev/null || true
    log "   ✅ Created .xinitrc"
fi

# Final syntax check
log "4. Final syntax check..."
if bash -n "$XINITRC" >/dev/null 2>&1; then
    log "   ✅ Syntax is valid"
else
    log "   ❌ Syntax still has errors:"
    bash -n "$XINITRC" 2>&1 | tee -a "$LOG_FILE"
fi

log "=== FIX .XINITRC SYNTAX END ==="

