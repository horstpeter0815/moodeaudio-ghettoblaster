#!/bin/bash
#
# Diagnostic script to understand display rotation issue
# DO NOT APPLY FIXES - JUST DIAGNOSE
#

echo "=== DISPLAY ROTATION DIAGNOSTIC ==="
echo ""
echo "1. Check current database settings:"
echo "   hdmi_scn_orient:"
sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient';" 2>/dev/null || echo "  Cannot query database"
echo ""
echo "   dsi_scn_type:"
sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='dsi_scn_type';" 2>/dev/null || echo "  Cannot query database"
echo ""
echo "2. Check .xinitrc rotation logic:"
echo "   Looking for rotation commands..."
grep -A 5 "Set screen rotation" /home/andre/.xinitrc 2>/dev/null | head -20
echo ""
echo "3. Check what .xinitrc actually does for HDMI:"
DSI_SCN_TYPE=$(sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='dsi_scn_type';" 2>/dev/null)
HDMI_SCN_ORIENT=$(sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient';" 2>/dev/null)
echo "   dsi_scn_type='$DSI_SCN_TYPE'"
echo "   hdmi_scn_orient='$HDMI_SCN_ORIENT'"
echo ""
echo "   If dsi_scn_type='none' and hdmi_scn_orient='portrait', rotation should happen"
echo "   If dsi_scn_type='none' and hdmi_scn_orient='landscape', no rotation"
echo ""
echo "4. Check X server actual output:"
DISPLAY=:0 xrandr 2>/dev/null | grep -E "connected|disconnected" | head -5
echo ""
echo "5. Check current X server resolution and rotation:"
DISPLAY=:0 xrandr --query 2>/dev/null | grep -E "HDMI|connected" -A 5 | head -10
echo ""
echo "6. Check if xrandr rotation command exists in .xinitrc:"
if grep -q "xrandr.*--rotate\|xrandr.*--output.*rotate" /home/andre/.xinitrc; then
    echo "   ✓ xrandr rotation command found in .xinitrc"
    grep "xrandr.*--rotate\|xrandr.*--output.*rotate" /home/andre/.xinitrc
else
    echo "   ✗ No xrandr rotation command found in .xinitrc"
fi
echo ""
echo "7. Check Chromium window size vs display:"
if pgrep chromium >/dev/null 2>&1; then
    CHROMIUM_SIZE=$(ps aux | grep chromium | grep "window-size" | head -1 | grep -o "window-size=[^ ]*" | cut -d= -f2)
    echo "   Chromium window-size: $CHROMIUM_SIZE"
    echo "   Display is 400x1280 (portrait)"
    echo "   Expected for landscape: 1280x400"
fi
echo ""
echo "8. Check framebuffer resolution:"
FB_RES=$(cat /sys/class/graphics/fb0/virtual_size 2>/dev/null)
echo "   Framebuffer: $FB_RES"
echo ""
echo "=== DIAGNOSTIC COMPLETE ==="
echo ""
echo "ROOT CAUSE ANALYSIS:"
echo "   If hdmi_scn_orient='landscape' in DB → .xinitrc won't rotate (thinks it's already landscape)"
echo "   But HDMI timing is 400x1280 (portrait) → Display shows portrait"
echo "   Solution: Set hdmi_scn_orient='portrait' in DB so .xinitrc rotates it to landscape"
echo ""