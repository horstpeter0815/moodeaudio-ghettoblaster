#!/bin/bash
# SYSTEM MONITOR - Prüft beide Pis und zeigt Cockpit-Status

PI1="192.168.178.62"
PI2="192.168.178.134"
USER="andre"
PASS="0815"

echo "=========================================="
echo "  SYSTEM MONITOR - COCKPIT STATUS"
echo "=========================================="
echo ""

check_pi() {
    local IP=$1
    local NAME=$2
    
    echo "=== $NAME ($IP) ==="
    
    # Ping check
    if ping -c 1 -W 1 $IP >/dev/null 2>&1; then
        echo "✅ Online"
    else
        echo "❌ Offline"
        return 1
    fi
    
    # Display
    sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$IP "systemctl is-active localdisplay.service 2>&1" 2>&1 | grep -q "active" && echo "✅ Display: active" || echo "❌ Display: inactive"
    
    # FT6236 Service
    sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$IP "systemctl is-enabled ft6236-delay.service 2>&1" 2>&1 | grep -q "enabled" && echo "✅ FT6236 Service: enabled" || echo "❌ FT6236 Service: disabled"
    
    # FT6236 Module
    sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$IP "lsmod | grep ft6236" 2>&1 | grep -q "ft6236" && echo "✅ FT6236 Module: loaded" || echo "⚠️  FT6236 Module: not loaded"
    
    # Audio (PI 2 only)
    if [ "$IP" = "$PI2" ]; then
        sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$IP "aplay -l 2>&1 | grep -q 'card'" && echo "✅ Audio: Soundcard found" || echo "❌ Audio: No soundcard"
        sshpass -p "$PASS" ssh -o StrictHostKeyChecking=no $USER@$IP "systemctl is-active mpd.service 2>&1" 2>&1 | grep -q "active" && echo "✅ MPD: active" || echo "❌ MPD: inactive"
    fi
    
    echo ""
}

check_pi $PI1 "PI 1 (RaspiOS)"
check_pi $PI2 "PI 2 (moOde)"

echo "=========================================="
echo "  COCKPIT FILES:"
echo "=========================================="
echo ""
echo "📁 Markdown Cockpit:"
echo "   WISSENSBASIS/COCKPIT_AUDIO_VIDEO_CHAIN.md"
echo ""
echo "📁 HTML Cockpit:"
echo "   pipeline_cockpit_detailed.html"
echo "   pipeline_cockpit.html"
echo ""
echo "📁 Test Suite:"
echo "   STANDARD_TEST_SUITE.md"
echo ""
echo "✅ Öffne Cockpit:"
echo "   open pipeline_cockpit_detailed.html"
echo ""

