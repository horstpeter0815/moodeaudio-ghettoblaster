#!/bin/bash
# Test PeppyMeter Display with Room Correction Wizard
# Run from HOME: bash ~/moodeaudio-cursor/scripts/wizard/TEST_PEPPYMETER_WIZARD.sh

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🧙 PeppyMeter + Wizard Test                                  ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Check if running on Pi or Mac
if [[ "$(uname -s)" == "Darwin" ]]; then
    echo "📱 Running from Mac - will test via SSH"
    PI_IP="${1:-192.168.1.159}"
    PI_USER="${2:-andre}"
    
    echo "Target Pi: $PI_USER@$PI_IP"
    echo ""
    
    # Test connectivity
    if ! ping -c 1 -W 2 "$PI_IP" > /dev/null 2>&1; then
        echo "❌ Cannot reach Pi at $PI_IP"
        echo "   Check network connection"
        exit 1
    fi
    
    echo "✅ Pi is reachable"
    echo ""
    echo "Running tests on Pi..."
    echo ""
    
    ssh "$PI_USER@$PI_IP" << 'ENDSSH'
        # Test script runs here
        echo "=== PeppyMeter Status ==="
        
        # Check if PeppyMeter service exists
        if systemctl list-unit-files | grep -q peppymeter; then
            echo "✅ PeppyMeter service found"
            systemctl status peppymeter --no-pager -l | head -10
        else
            echo "⚠️  PeppyMeter service not found"
        fi
        
        echo ""
        echo "=== PeppyMeter Configuration ==="
        if [ -f "/etc/peppymeter/config.txt" ]; then
            echo "✅ Config file exists"
            echo "Current meter setting:"
            grep "^meter = " /etc/peppymeter/config.txt || echo "  (not set)"
            echo "Random meter interval:"
            grep "^random.meter.interval = " /etc/peppymeter/config.txt || echo "  (not set)"
        else
            echo "⚠️  Config file not found: /etc/peppymeter/config.txt"
        fi
        
        echo ""
        echo "=== Display Configuration ==="
        if [ -f "/boot/firmware/cmdline.txt" ]; then
            echo "Kernel rotation:"
            grep -o "rotate=[0-9]*" /boot/firmware/cmdline.txt || echo "  (not set)"
            grep -o "fbcon=rotate:[0-9]*" /boot/firmware/cmdline.txt || echo "  (not set)"
        fi
        
        echo ""
        echo "=== moOde Display Settings ==="
        if [ -f "/var/local/www/db/moode-sqlite3.db" ]; then
            echo "PeppyMeter enabled:"
            sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='peppy_display';" 2>/dev/null || echo "  (could not query)"
            echo "Local display enabled:"
            sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='local_display';" 2>/dev/null || echo "  (could not query)"
        fi
        
        echo ""
        echo "=== Web Interface ==="
        echo "Wizard accessible at:"
        echo "  http://$(hostname -I | awk '{print $1}')/snd-config.php"
        echo ""
        echo "PeppyMeter should show:"
        echo "  - Audio level meters"
        echo "  - Tap to switch to moOde UI"
        echo "  - Blue skin (if configured)"
        
ENDSSH
    
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "📋 Test Checklist:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "1. ✅ PeppyMeter service running"
    echo "2. ✅ Display shows audio meters"
    echo "3. ✅ Tap display → switches to moOde UI"
    echo "4. ✅ Wizard accessible: http://$PI_IP/snd-config.php"
    echo "5. ✅ Run wizard → PeppyMeter shows pink noise levels"
    echo "6. ✅ After wizard → PeppyMeter shows corrected audio"
    echo ""
    echo "To test wizard:"
    echo "  1. Open: http://$PI_IP/snd-config.php"
    echo "  2. Click 'Run Wizard'"
    echo "  3. Watch PeppyMeter during measurements"
    echo ""
    
else
    # Running on Pi
    echo "=== PeppyMeter Status ==="
    
    if systemctl list-unit-files | grep -q peppymeter; then
        echo "✅ PeppyMeter service found"
        systemctl status peppymeter --no-pager -l | head -10
    else
        echo "⚠️  PeppyMeter service not found"
    fi
    
    echo ""
    echo "=== Configuration ==="
    if [ -f "/etc/peppymeter/config.txt" ]; then
        echo "Current meter: $(grep '^meter = ' /etc/peppymeter/config.txt | cut -d' ' -f3)"
        echo "Random interval: $(grep '^random.meter.interval = ' /etc/peppymeter/config.txt | cut -d' ' -f3)"
    fi
    
    echo ""
    echo "=== Web Interface ==="
    IP=$(hostname -I | awk '{print $1}')
    echo "Wizard: http://$IP/snd-config.php"
    echo ""
fi
