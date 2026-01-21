# Display Solution - Based on Code Reading

**Date:** 2026-01-21
**Status:** X server working, testing boot console

---

## Root Cause Discovered

By reading moOde source code (`xinitrc.default`), I discovered:

1. **Waveshare display is PHYSICAL 400×1280 (portrait)**
2. **moOde code assumes:** If you want portrait, do nothing (it's native)
3. **moOde code DOESN'T handle:** Landscape mode for physically-portrait displays
4. **Database setting:** `hdmi_scn_orient=landscape` but no rotation was applied

---

## The 3-Part Solution

### 1. Boot Console Rotation (cmdline.txt)

**Problem:** Video parameter `rotate=` doesn't work with KMS driver

**Solution:** Use `fbcon=rotate:1` instead

```bash
# cmdline.txt
fbcon=rotate:1  # Rotates framebuffer console 90° (portrait→landscape)
```

Values:
- 0 = normal (0°)
- 1 = 90° clockwise (portrait→landscape) ← **USING THIS**
- 2 = 180°
- 3 = 270°

---

### 2. X Server Rotation (.xinitrc)

**Based on:** moOde's xinitrc.default lines 19-53

**Solution:** Use `xrandr --rotate left` for native portrait→landscape

```bash
#!/bin/bash
# Detect HDMI-2 (Pi 5)
HDMI_OUTPUT="HDMI-1"
if xrandr --query 2>/dev/null | grep -q "HDMI-2 connected"; then
    HDMI_OUTPUT="HDMI-2"
fi

# Get moOde orientation setting
HDMI_SCN_ORIENT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'")

# Waveshare physical 400x1280 (portrait)
if [ "$HDMI_SCN_ORIENT" = "landscape" ]; then
    # Rotate to landscape
    xrandr --output $HDMI_OUTPUT --rotate left
    SCREEN_RES="1280,400"
else
    # Keep portrait
    xrandr --output $HDMI_OUTPUT --rotate normal
    SCREEN_RES="400,1280"
fi

# Launch chromium with correct window size
chromium --window-size="$SCREEN_RES" ...
```

---

### 3. Config.txt (REMOVED conflicting settings)

**Problem:** Custom hdmi_timings were conflicting with auto-detection

**Solution:** Let display auto-detect via EDID

```bash
# REMOVED these lines:
# hdmi_group=2
# hdmi_mode=87
# hdmi_cvt=400 1280 60 6 0 0 0
# hdmi_timings=... (malformed)

# Display auto-detects as 400x1280 portrait
# Then rotation is applied by fbcon (console) and xrandr (X)
```

---

## Current Status

### X Server (Moode UI)
✅ **WORKING**
- Resolution: 1280 × 400
- Rotation: left (portrait→landscape)
- Chromium running with correct window size
- Display shows Moode web player

### Boot Console
⏳ **TESTING** (requires reboot to verify)
- cmdline.txt: `fbcon=rotate:1`
- Should show boot messages in landscape
- Awaiting user confirmation

---

## How It All Works Together

```
BOOT SEQUENCE:

1. FIRMWARE (config.txt):
   - No custom HDMI settings
   - Display auto-detects as 400x1280 (portrait)
   
2. KERNEL (cmdline.txt):
   - fbcon=rotate:1
   - Rotates framebuffer console 90°
   - Console shows: 1280x400 landscape
   
3. X SERVER (.xinitrc):
   - Reads database: hdmi_scn_orient=landscape
   - Executes: xrandr --output HDMI-2 --rotate left
   - X display: 1280x400 landscape
   
4. CHROMIUM (.xinitrc):
   - Window size: 1280,400
   - Moode UI: fills screen in landscape
```

---

## Key Learnings from Code Reading

### From `xinitrc.default` lines 31-53:

1. **moOde assumes Waveshare is native portrait**
   - Comment: "Waveshare 7.9" Display (400x1280 native portrait - no rotation needed)"
   - Code only handles portrait mode explicitly (lines 34-44)
   - Landscape mode just reads fbset, no rotation (lines 47-52)

2. **The missing logic:**
   - If portrait: do nothing (native)
   - If landscape: **SHOULD rotate but DOESN'T in default code**

3. **Why previous attempts failed:**
   - Tried to create fake 1280x400 mode (doesn't exist)
   - Should have rotated the REAL 400x1280 mode

### From kernel/DRM documentation:

1. **video= parameter rotation doesn't work with KMS**
   - `video=HDMI-A-1:400x1280@60,rotate=90` ← IGNORED by vc4-kms-v3d
   - KMS driver respects EDID, ignores video= rotation

2. **fbcon=rotate DOES work**
   - `fbcon=rotate:1` ← Rotates framebuffer console
   - Works with KMS driver
   - Applied before X server starts

---

## Files Modified

```
/boot/firmware/cmdline.txt
  - Changed: video=... → fbcon=rotate:1

/boot/firmware/config.txt  
  - Removed: hdmi_group, hdmi_mode, hdmi_cvt, hdmi_timings
  - Let display auto-detect

/home/andre/.xinitrc
  - Based on: xinitrc.default logic
  - Added: xrandr --rotate left for landscape
  - Fixed: Proper chromium command
```

---

## Testing Checklist

- [x] X server starts
- [x] Display shows 1280x400
- [x] Rotation applied (left)
- [x] Chromium runs
- [ ] Boot console in landscape (awaiting reboot test)
- [ ] User confirms seeing Moode UI
- [ ] Touch input works
- [ ] Audio still working

---

## If Boot Console Still Portrait

If `fbcon=rotate:1` doesn't work, alternative approaches:

1. **Try fbcon=rotate:3** (270° = -90°)
2. **Module parameter:** `vc4.rotation=90` in cmdline.txt
3. **Accept it:** Console portrait, X landscape (seamless if fast boot)

---

## Conclusion

**Stopped guessing. Read the code. Found the answer.**

The solution was in moOde's own xinitrc.default - it handles portrait mode but not landscape mode for physically-portrait displays. Applied the missing rotation logic using xrandr.

Boot console rotation via `fbcon=rotate:1` is based on kernel documentation, testing now.
