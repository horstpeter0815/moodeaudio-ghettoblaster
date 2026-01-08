# Working Display Configuration for Waveshare 7.9" HDMI Display

**Status:** ✅ CONFIRMED WORKING - Landscape mode (1280x400)

**Date:** 2025-01-27

## Hardware Configuration

- **Display:** Waveshare 7.9" HDMI (400x1280 native portrait)
- **Target Mode:** Landscape (1280x400)
- **Connection:** HDMI-A-1

## Boot Configuration Files

### `/boot/firmware/config.txt`
```
hdmi_group=0
```

**Note:** The HDMI mode is controlled via the `video` parameter in `cmdline.txt`. The display resolution and rotation are set there.

### `/boot/firmware/cmdline.txt`
```
video=HDMI-A-1:400x1280M@60,rotate=90
```

**Note:** `rotate=90` rotates the framebuffer 90 degrees clockwise, converting 400x1280 portrait to 1280x400 landscape at the kernel level.

## moOde Database Settings

```sql
UPDATE cfg_system SET value='portrait' WHERE param='hdmi_scn_orient';
```

This tells moOde the hardware is portrait-oriented (which it is - 400x1280).

## X11 Configuration (`.xinitrc`)

### Critical Settings

1. **Force SCREEN_RES to landscape before Chromium launch:**
```bash
# Force SCREEN_RES to landscape for Chromium
SCREEN_RES="1280,400"
```

2. **Xrandr rotation sequence (HDMI screens):**
```bash
# CRITICAL: Reset rotation first, then set mode, then apply rotation
DISPLAY=:0 xrandr --output HDMI-1 --rotate normal 2>/dev/null || true
sleep 1
DISPLAY=:0 xrandr --output HDMI-1 --mode 400x1280 2>/dev/null || true
sleep 1
DISPLAY=:0 xrandr --output HDMI-1 --rotate left 2>&1 | tee -a "$LOG_FILE" || true
sleep 1
```

**Key points:**
- Reset to `normal` first
- Set mode to `400x1280` (hardware native)
- Then rotate `left` (which makes it 1280x400 landscape)
- This sequence ensures X11 sees the correct mode before rotation

3. **Chromium launch flags:**
```bash
chromium \
--app="http://localhost/" \
--window-size="1280,400" \
--force-device-scale-factor=1 \
--window-position="0,0" \
--enable-features="OverlayScrollbar" \
--no-first-run \
--disable-infobars \
--disable-session-crashed-bubble \
--start-fullscreen \
--kiosk
```

**Critical flags:**
- `--window-size="1280,400"` - Directly sets landscape window size
- `--force-device-scale-factor=1` - Prevents scaling issues
- `--start-fullscreen` - Ensures fullscreen mode

## Display Chain Summary

1. **Framebuffer (FB0):** 400x1280 portrait (from `cmdline.txt` video parameter)
2. **Kernel rotation:** `rotate=90` in cmdline rotates FB0 to 1280x400 landscape
3. **DRM/KMS:** Exposes 1280x400 landscape to X11
4. **X11/xrandr:** Sets mode to 400x1280, then rotates left → 1280x400 landscape
5. **Chromium:** Launched with `--window-size=1280,400` → renders at landscape size

## Why This Works

The "Forum solution" approach:
- Hardware is portrait (400x1280) - set in boot config as portrait
- Software rotation (xrandr rotate left) converts to landscape (1280x400)
- Chromium is told to render at landscape size (1280,400) directly
- SCREEN_RES is forced to landscape (1280,400) before Chromium launches

This ensures all layers are synchronized:
- Framebuffer: 1280x400 (after kernel rotation)
- DRM plane: 1280x400 (after xrandr rotation)
- X11 display: 1280x400
- Chromium window: 1280x400
- Chromium viewport: 1280x400

## Troubleshooting Notes

- **If only 1/3 is visible:** SCREEN_RES was likely still set to "400,1280" - must be "1280,400"
- **If display is upside down:** Check xrandr rotation (should be "left", not "right")
- **If window is wrong size:** Ensure `--window-size="1280,400"` is set correctly
- **If content is scaled wrong:** Ensure `--force-device-scale-factor=1` is present

## Files Modified

1. `/boot/firmware/config.txt` - HDMI mode configuration
2. `/boot/firmware/cmdline.txt` - Kernel video mode and rotation
3. `/home/andre/.xinitrc` - X11 rotation and Chromium launch
4. moOde database - `hdmi_scn_orient` = 'portrait'

## Verification Commands

```bash
# Check X11 display size
DISPLAY=:0 xdpyinfo | grep dimensions

# Check xrandr output
DISPLAY=:0 xrandr --query | grep "HDMI-1 connected"

# Check Chromium window size
DISPLAY=:0 xwininfo -root -tree | grep "moOde Player"

# Check Chromium process args
ps aux | grep chromium | grep window-size
```

**Expected output:**
- X11 dimensions: `1280x400`
- xrandr: `HDMI-1 connected primary 1280x400+0+0 left`
- Window: `1279x399+0+0` (1px difference is normal)
- Chromium args: `--window-size=1280,400 --force-device-scale-factor=1`

