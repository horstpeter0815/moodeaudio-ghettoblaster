# Display Rotation Master Guide

**Last Updated:** January 13, 2026  
**System:** Ghetto Blaster (Raspberry Pi 5)  
**Display:** Waveshare 7.9" HDMI Touchscreen (400x1280 native portrait → 1280x400 landscape)

## Overview

This document explains the complete mechanics of display rotation on Raspberry Pi 5 with moOde Audio. Understanding these mechanics is critical for proper display configuration.

---

## Display System Architecture

The display system has **two separate layers** that need rotation:

1. **Boot Screen (Framebuffer/Console)**
   - Low-level framebuffer (`/dev/fb0`)
   - Console text output
   - Controlled at boot time via `config.txt` and `cmdline.txt`
   - **Separate from X11**

2. **X11 Display (Graphical Interface)**
   - X Window System (Xorg)
   - moOde web interface, PeppyMeter, Chromium
   - Controlled at X11 startup via `.xinitrc`
   - **Separate from framebuffer**

**Key Insight:** These are **independent systems**. Boot rotation does NOT automatically affect X11, and vice versa. Both must be configured separately.

---

## Boot Screen Rotation (Framebuffer)

### Purpose
Rotates the boot console and framebuffer so boot messages and login screen appear in landscape orientation.

### Configuration Files

#### `/boot/firmware/config.txt`
```bash
# Framebuffer rotation (90° clockwise = portrait to landscape)
display_rotate=1
```

**Values:**
- `0` = No rotation (default)
- `1` = 90° clockwise (portrait → landscape)
- `2` = 180° (upside down)
- `3` = 270° clockwise (landscape → portrait)

#### `/boot/firmware/cmdline.txt`
```bash
# Console text rotation (90° clockwise)
fbcon=rotate:1
```

**Values:**
- `0` = No rotation
- `1` = 90° clockwise
- `2` = 180°
- `3` = 270° clockwise

### How It Works
- `display_rotate=1` rotates the framebuffer device (`/dev/fb0`)
- `fbcon=rotate:1` rotates console text output
- Both work together to rotate the entire boot screen
- **Takes effect immediately at boot** (before X11 starts)

### Verification
```bash
# Check framebuffer size (should show rotated dimensions)
cat /sys/class/graphics/fb0/virtual_size
# Expected: 1280,400 (if rotated from 400x1280)
```

---

## X11 Display Rotation (Graphical Interface)

### Purpose
Rotates the X11 display so moOde web interface, PeppyMeter, and Chromium appear in landscape orientation.

### Configuration File

#### `/home/andre/.xinitrc`
This is the **moOde Forum Solution** - the proven working method.

**Key Logic:**
1. Wait for X server to be ready (up to 30 seconds)
2. Detect HDMI output (HDMI-1 for Pi 4, HDMI-2 for Pi 5)
3. Read `hdmi_scn_orient` from moOde database
4. If `portrait`, apply rotation sequence:
   - Reset rotation to `normal`
   - Set mode to `400x1280` (native portrait)
   - Rotate **LEFT** to get `1280x400` (landscape)
5. Set `SCREEN_RES="1280,400"` for Chromium window size

**Critical Code Sequence:**
```bash
if [ "$HDMI_SCN_ORIENT" = "portrait" ]; then
    # FORUM SOLUTION: Reset, set mode, rotate LEFT
    DISPLAY=:0 xrandr --output "$HDMI_OUTPUT" --rotate normal 2>/dev/null || true
    sleep 1
    DISPLAY=:0 xrandr --output "$HDMI_OUTPUT" --mode 400x1280 2>/dev/null || true
    sleep 1
    DISPLAY=:0 xrandr --output "$HDMI_OUTPUT" --rotate left 2>/dev/null || true
    sleep 1
    # SCREEN_RES must match rotated dimensions
    SCREEN_RES="1280,400"
fi
```

### Why This Sequence Works
1. **Reset to normal first:** Clears any previous rotation state
2. **Set native mode (400x1280):** Ensures display is in its native resolution
3. **Rotate LEFT:** Rotates 90° counter-clockwise to get 1280x400 landscape
4. **Set SCREEN_RES correctly:** Chromium window size must match rotated dimensions

### moOde Database Setting
```bash
# Must be set to 'portrait' for rotation logic to trigger
sqlite3 /var/local/www/db/moode-sqlite3.db \
  "UPDATE cfg_system SET value='portrait' WHERE param='hdmi_scn_orient';"
```

**Why 'portrait'?** The display hardware is 400x1280 (portrait). Setting the database to 'portrait' tells xinitrc to rotate it to landscape.

### Verification
```bash
# Check X11 screen dimensions
DISPLAY=:0 xdpyinfo | grep dimensions
# Expected: 1280x400 pixels

# Check xrandr output
DISPLAY=:0 xrandr --query | grep HDMI
# Expected: HDMI-2 connected 1280x400+0+0 left
```

---

## How Boot and X11 Rotation Work Together

### The Relationship

**Important:** Boot rotation and X11 rotation are **independent** but can affect each other:

1. **Boot rotation affects framebuffer only:**
   - Rotates `/dev/fb0` (framebuffer device)
   - Does NOT automatically rotate X11
   - X11 starts with its own rotation state

2. **X11 rotation affects X11 only:**
   - Rotates X Window System display
   - Does NOT affect framebuffer
   - Framebuffer remains in boot rotation state

3. **Both must be configured:**
   - Boot rotation: `display_rotate=1` + `fbcon=rotate:1`
   - X11 rotation: xinitrc forum solution (`--rotate left`)

### Why Both Are Needed

- **Boot rotation:** Makes boot screen and console readable in landscape
- **X11 rotation:** Makes moOde interface and applications display correctly in landscape
- **Together:** Complete system is in landscape from boot to desktop

### Potential Conflicts

If boot rotation and X11 rotation conflict:
- X11 rotation (xinitrc) will override boot rotation for X11 display
- Framebuffer remains in boot rotation state
- This is why xinitrc must explicitly set rotation (forum solution)

---

## Complete Working Configuration

### `/boot/firmware/config.txt`
```bash
# KMS (Kernel Mode Setting) - required for proper display handling
dtoverlay=vc4-kms-v3d,noaudio
hdmi_force_hotplug=1
display_auto_detect=1

# Boot framebuffer rotation (90° clockwise = portrait to landscape)
display_rotate=1
```

### `/boot/firmware/cmdline.txt`
```bash
# Console text rotation (90° clockwise)
# ... other parameters ...
fbcon=rotate:1
```

### `/home/andre/.xinitrc`
```bash
#!/bin/bash
# ... (full forum solution code as documented above) ...
```

### moOde Database
```bash
# Set to 'portrait' so xinitrc rotation logic triggers
hdmi_scn_orient = 'portrait'
```

---

## Troubleshooting

### Boot Screen Still Portrait
**Symptoms:** Boot messages and login screen are still in portrait orientation.

**Solutions:**
1. Verify `display_rotate=1` in `config.txt`
2. Verify `fbcon=rotate:1` in `cmdline.txt`
3. **Reboot required** - boot rotation only takes effect on boot

### X11 Display Still Portrait
**Symptoms:** moOde interface is still in portrait orientation.

**Solutions:**
1. Verify xinitrc has forum solution (rotate left sequence)
2. Verify `hdmi_scn_orient='portrait'` in moOde database
3. Check X11 is running: `pgrep -x Xorg`
4. Check xrandr output: `DISPLAY=:0 xrandr --query`
5. Restart X session: `pkill -u andre Xorg; startx`

### Display Shows Black Bars or Cut Off
**Symptoms:** Display shows black borders or content is cut off.

**Solutions:**
1. Verify `SCREEN_RES="1280,400"` in xinitrc (not "400,1280")
2. Verify Chromium `--window-size` matches rotated dimensions
3. Check xrandr mode: Should be `1280x400` (not `400x1280`)

### Boot Rotation Affects X11 Incorrectly
**Symptoms:** X11 display is wrong after boot rotation is applied.

**Solutions:**
1. xinitrc forum solution should handle this automatically
2. xinitrc explicitly resets and reapplies rotation
3. If still wrong, check xinitrc rotation sequence is correct

---

## Key Learnings

### What We Learned

1. **Two Separate Systems:**
   - Boot screen (framebuffer) ≠ X11 display
   - Both need separate rotation configuration
   - They work independently but should be coordinated

2. **Boot Rotation:**
   - `display_rotate=1` in `config.txt` (framebuffer)
   - `fbcon=rotate:1` in `cmdline.txt` (console)
   - Takes effect at boot time
   - Affects framebuffer only

3. **X11 Rotation:**
   - moOde Forum Solution in `.xinitrc`
   - Sequence: reset → set mode → rotate left
   - `SCREEN_RES="1280,400"` (swapped for rotated display)
   - Takes effect when X11 starts

4. **Why Forum Solution Works:**
   - Explicit rotation sequence (reset → mode → rotate)
   - Handles boot rotation state correctly
   - Ensures final state is always correct

5. **Common Mistakes:**
   - Using workarounds (overscan, transforms, panning) instead of proper rotation
   - Setting `SCREEN_RES="400,1280"` instead of `"1280,400"`
   - Using `--rotate normal` instead of `--rotate left`
   - Not understanding boot and X11 are separate systems

---

## References

- **moOde Forum Solution:** Proven working method for X11 rotation
- **v1.0 Documentation:** `/rag-upload-files/v1.0-docs/v1.0_display_audio_setup.md`
- **moode-source:** `/moode-source/home/xinitrc.default` (reference implementation)
- **Raspberry Pi Documentation:** `config.txt` and `cmdline.txt` parameters

---

## Version History

- **2026-01-13:** Initial master documentation
  - Documented boot screen rotation mechanics
  - Documented X11 rotation mechanics (forum solution)
  - Explained how they work together
  - Created troubleshooting guide
  - Documented key learnings from troubleshooting session

---

**Document Maintained By:** Ghetto AI (Open WebUI)  
**For Questions:** Consult this master guide or Ghetto AI knowledge base
