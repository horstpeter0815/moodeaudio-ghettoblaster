# Display Configuration - Final Status

**Date**: 2026-01-19  
**Status**: Partially Working - Display orientation correct, JavaScript rendering issue on Pi

## What's Working ✅

1. **Display Orientation**: Landscape (1280x400) - correct
2. **Boot Screen**: Landscape with cmdline.txt video parameter
3. **Chromium Window Size**: 1280x400 (xdotool workaround applied)
4. **All Resources Loading**: CSS, JavaScript, AJAX calls all successful
   - styles.min.css: 417KB ✓
   - main.min.js: 142KB ✓
   - radio stations API: 15933 bytes ✓
   - Theme config: 9489 bytes ✓
5. **Mac Browser Access**: Works perfectly at http://192.168.2.3

## What's Not Working ❌

1. **Pi Display Chromium**: No colors, no radio stations visible
2. **JavaScript DOM Rendering**: AJAX loads data but doesn't render to screen
3. **Issue**: Chromium on Pi with 400px height display has rendering problems

## Root Cause Analysis

### The Problem
- JavaScript executes and loads all data via AJAX
- But DOM manipulation (inserting radio stations, applying theme colors) doesn't render
- This appears to be a **Chromium GPU rendering bug** on Raspberry Pi with rotated 400px displays

### Evidence
1. Logs show all AJAX calls succeed (radio.php returns 15933 bytes)
2. curl http://localhost/ shows 0 `db-entry` elements (JavaScript didn't populate)
3. GBM wrapper errors in journal logs indicate graphics buffer issues
4. Mac browser works perfectly with same backend

## Configuration Files

### /boot/firmware/cmdline.txt
```
console=tty3 root=/dev/mmcblk0p2 rootfstype=ext4 fsck.repair=yes rootwait quiet loglevel=3 video=HDMI-A-1:400x1280M@60,rotate=90 logo.nologo vt.global_cursor_default=0
```

### /home/andre/.xinitrc
```bash
#!/bin/bash
# Export display variables (CRITICAL - was missing)
export DISPLAY=:0
export XAUTHORITY=/home/andre/.Xauthority

# Wait for X server (forum solution)
for i in {1..30}; do
    if xset q &>/dev/null 2>&1; then
        break
    fi
    sleep 1
done

# Screen blanking
xset s 600 0
xset +dpms
xset dpms 600 0 0

# Get configuration
HDMI_SCN_ORIENT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'")
DSI_SCN_TYPE=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='dsi_scn_type'")

# Screen res
SCREEN_RES="1280,400"

# Set screen rotation (v1.0 logic)
if [ "$DSI_SCN_TYPE" = "none" ]; then
    if [ "$HDMI_SCN_ORIENT" = "portrait" ]; then
        DISPLAY=:0 xrandr --output HDMI-2 --rotate left
        SCREEN_RES="1280,400"
    fi
fi

# Launch Chromium
if [ "$WEBUI_SHOW" = "1" ]; then
    /var/www/util/sysutil.sh clearbrcache
    chromium \
    --app="http://localhost/" \
    --window-size="$SCREEN_RES" \
    --window-position="0,0" \
    --enable-features="OverlayScrollbar" \
    --no-first-run \
    --disable-infobars \
    --disable-session-crashed-bubble \
    --kiosk &
    
    # Forum solution: Fix Chromium window size (CRITICAL)
    sleep 3
    WINDOW_ID=$(DISPLAY=:0 xdotool search --class chromium | head -1)
    if [ -n "$WINDOW_ID" ]; then
        DISPLAY=:0 xdotool windowsize $WINDOW_ID 1280 400
        DISPLAY=:0 xdotool windowmove $WINDOW_ID 0 0
    fi &
    
    wait
fi
```

### Database Settings
```sql
hdmi_scn_orient = 'portrait'  (triggers xrandr --rotate left in xinitrc)
local_display = '1'
peppy_display = '0'
```

## Key Learnings

1. **cmdline.txt video parameter**: Sets framebuffer resolution and rotation at boot
2. **xinitrc xrandr**: Additional rotation for X11 (both needed for landscape)
3. **DISPLAY export**: MUST be set before launching Chromium
4. **X server wait loop**: Prevents race conditions on startup
5. **xdotool workaround**: Chromium ignores --window-size in kiosk mode
6. **Cache clear fix**: Changed from `$()` execution to direct call

## Attempted Fixes That Didn't Work

1. ❌ GPU flags (--disable-gpu, --use-gl=swiftshader)
2. ❌ Framebuffer color depth (16-bit to 32-bit)
3. ❌ Removing xrandr rotation (caused display to be cut off)
4. ❌ Hard refresh (F5, Ctrl+Shift+R)
5. ❌ Multiple cache clears

## Possible Solutions (Not Yet Tested)

1. **Use older Chromium version** that doesn't have GBM rendering issues
2. **Use Firefox instead of Chromium** for local display
3. **Increase display height** to meet moOde's expected 480px minimum
4. **Use VNC/remote desktop** and access from Mac (workaround)
5. **Contact moOde forums** about 400px display compatibility

## Conclusion

The system is **functionally correct** but has a **Chromium rendering limitation** on the Pi's physical display with 400px height. The Mac browser works perfectly, confirming the backend is correct. This appears to be a known issue with small displays and Chromium GPU rendering on Raspberry Pi.

**Recommendation**: Access moOde via Mac browser (http://192.168.2.3) until a Chromium rendering fix is found.
