# Display Framebuffer-DRM Connection - Complete Understanding

## Problem Solved ✅

The display was showing black screen or incorrect content because of a mismatch between the framebuffer configuration and the DRM/KMS plane configuration.

## Root Cause - The Connection Point

### The Three-Layer System

1. **Framebuffer (fb0)**: `1280x400` 
   - Set by `config.txt` (`hdmi_cvt=1280 400 60 6 0 0 0`)
   - Set by `cmdline.txt` (`video=HDMI-A-1:1280x400M@60,rotate=0`)
   - Location: `/sys/class/graphics/fb0/virtual_size` = `1280,400`

2. **DRM/KMS Plane**: Defaults to `400x1280` (portrait)
   - Read from display EDID (display reports native mode as `400x1280`)
   - Location: `kmsprint` shows `FB 400x1280` initially
   - This is the **hardware plane** that actually outputs to the display

3. **X11 xrandr**: Can switch between modes
   - Controls the DRM/KMS plane via X11 RandR extension
   - Can set mode to `1280x400` or `400x1280`
   - Location: `DISPLAY=:0 xrandr --query`

### The "Twist" - Where They Connect

**The connection point is `xrandr`:**

- `xrandr` is the bridge between X11 and DRM/KMS
- When `xrandr --mode 1280x400` is executed, it:
  1. Tells DRM/KMS to reconfigure the plane to `1280x400`
  2. Updates X11's understanding of the screen size
  3. Synchronizes the DRM plane with the framebuffer

**The problem:**
- Framebuffer starts as `1280x400` (from boot config)
- DRM/KMS plane defaults to `400x1280` (from EDID)
- **Mismatch causes black screen or incorrect rendering**
- Chromium creates a `1280x400` window, but DRM plane is `400x1280` → content doesn't match display

**The solution:**
- Force `xrandr --mode 1280x400 --rotate normal` **BEFORE** Chromium starts
- This synchronizes DRM plane with framebuffer
- All components then match: FB=1280x400, DRM=1280x400, X11=1280x400, Chromium=1280x400

## Complete Understanding

### Boot Sequence

1. **Kernel boot**: Reads `config.txt` and `cmdline.txt`
   - Sets framebuffer to `1280x400`
   - Creates `/dev/fb0` with `1280x400` resolution

2. **DRM/KMS initialization**: Reads display EDID
   - Display reports native mode: `400x1280` (portrait)
   - DRM plane defaults to `400x1280`
   - **Mismatch with framebuffer!**

3. **X11 startup**: Reads current DRM state
   - X11 sees DRM plane as `400x1280`
   - X11 screen is `400x1280`
   - **Still mismatched with framebuffer!**

4. **xrandr synchronization** (in `.xinitrc`):
   - `xrandr --mode 1280x400` forces DRM plane to `1280x400`
   - DRM plane now matches framebuffer
   - X11 screen updates to `1280x400`
   - **All synchronized!**

5. **Chromium startup**:
   - Creates `1280x400` window
   - Window matches DRM plane (`1280x400`)
   - Content renders correctly

### Why It Works Now

The `.xinitrc` script now:
1. Waits for X server (`sleep 2`)
2. Forces `xrandr --mode 1280x400 --rotate normal` **before** Chromium starts
3. Verifies synchronization (logs DRM vs FB)
4. Launches Chromium with `--window-size="1280,400"`

**Key insight:** The timing is critical. `xrandr` must run AFTER X11 is ready but BEFORE Chromium starts. If Chromium starts before `xrandr` synchronizes the DRM plane, it creates a window that doesn't match the DRM plane, causing black screen or incorrect rendering.

## Final Configuration

### `/home/andre/.xinitrc`

```bash
# Wait for X server
sleep 2

# CRITICAL: Force DRM/KMS plane to match framebuffer (1280x400 landscape)
DISPLAY=:0 xrandr --output HDMI-1 --mode 1280x400 --rate 59.97 --rotate normal 2>/dev/null || true
sleep 1

# Verify synchronization
KMS_RES=$(kmsprint 2>/dev/null | grep "FB" | awk "{print \$3}" || echo "")
FB_RES=$(cat /sys/class/graphics/fb0/virtual_size 2>/dev/null | tr "," "x" || echo "")

# Launch Chromium with matching window size
chromium --app="http://localhost/" --window-size="1280,400" ...
```

### Verification Commands

```bash
# Check framebuffer
cat /sys/class/graphics/fb0/virtual_size
# Should show: 1280,400

# Check DRM plane
kmsprint | grep "FB"
# Should show: FB 1280x400

# Check X11
DISPLAY=:0 xrandr --query | grep "HDMI-1 connected"
# Should show: HDMI-1 connected primary 1280x400+0+0

# Check Chromium window
DISPLAY=:0 xwininfo -root -tree | grep "moOde Player"
# Should show: 1280x400+0+0 (or close, like 1279x399)
```

## Summary

**Problem:** Mismatch between framebuffer (`1280x400`) and DRM/KMS plane (`400x1280` from EDID) caused black screen.

**Root Cause:** DRM/KMS plane defaults to display's native EDID mode (`400x1280`), but framebuffer is configured as `1280x400` from boot config.

**Solution:** Force `xrandr --mode 1280x400` BEFORE Chromium starts to synchronize DRM plane with framebuffer.

**Connection Point:** `xrandr` is the bridge that synchronizes DRM/KMS plane with framebuffer configuration.

