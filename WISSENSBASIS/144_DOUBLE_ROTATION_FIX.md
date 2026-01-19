# Double Rotation Bug - Cmdline + Xinitrc Conflict

**Date**: 2026-01-19  
**Issue**: Two-thirds of screen black (only 400px visible out of 1280px)  
**Root Cause**: ✅ Double rotation - kernel cmdline AND xrandr both rotating

## The Problem - Confirmed by User

**Two rotation mechanisms were conflicting:**

### 1. Kernel Cmdline Rotation (Hardware Level)

**File:** `/boot/firmware/cmdline.txt`
```bash
video=HDMI-A-1:400x1280M@60,rotate=90
```

**Effect:**
- Sets framebuffer to 400x1280 (portrait) at kernel boot
- Physical display: 1280x400 (landscape)
- Rotated 90° by kernel: becomes 400x1280 (portrait)
- This happens BEFORE X11 starts

### 2. X11 Rotation (Software Level)

**File:** `/home/andre/.xinitrc`
```bash
if [ "$HDMI_SCN_ORIENT" = "portrait" ]; then
    xrandr --output HDMI-2 --rotate left  ← PROBLEM!
```

**Effect:**
- Tried to rotate display again at X11 level
- But kernel already rotated it!
- Created mismatch between X11 and framebuffer

## The Conflict

**What happened:**

```
Boot sequence:
1. Kernel loads with video=...rotate=90
   → Framebuffer: 400x1280 ✅
   
2. X11 starts
   → X11 thinks display is 1280x400 (reads physical size)
   
3. xinitrc runs xrandr --rotate left
   → Tries to rotate 1280x400 → should become 400x1280
   → But framebuffer already 400x1280!
   → Mismatch: X11 screen = 1280x400, framebuffer = 400x1280
   
4. Chromium window: 400x1280
   → Only 400 pixels visible on 1280x400 X11 screen
   → 2/3 of window extends beyond screen = BLACK
```

**Evidence:**
```bash
$ xrandr --query
HDMI-2 connected 1280x400+0+0 left  ← X11 thinks landscape, rotated left

$ xwininfo -root
Width: 1280   ← X11 root window landscape
Height: 400

$ fbset -s
mode "400x1280"  ← Framebuffer portrait!
```

**Result:** Mismatch = only 400 pixels visible, 2/3 black!

## The Solution

**Key insight:** When kernel cmdline has `rotate=90`, DON'T use xrandr rotation!

**Fixed xinitrc:**

```bash
# NOTE: Display rotation is handled by kernel cmdline (rotate=90)
# No xrandr rotation needed!

# Force xrandr to normal (no rotation)
xrandr --output HDMI-2 --rotate normal

# Set dimensions for portrait (kernel already rotated)
SCREEN_WIDTH=400
SCREEN_HEIGHT=1280
SCREEN_RES="400,1280"
```

**Why this works:**
1. Kernel cmdline rotates framebuffer: 400x1280
2. X11 detects this and creates 400x1280 screen
3. xrandr --rotate normal ensures no double rotation
4. Chromium window: 400x1280 matches perfectly ✅

## Verification After Fix

**Before:**
```bash
X11 Screen: 1280x400 (landscape)
Framebuffer: 400x1280 (portrait)
Window: 400x1280
Visible: Only 400 pixels → 2/3 BLACK ❌
```

**After:**
```bash
$ xrandr --query
HDMI-2 connected 400x1280+0+0 (normal)  ← Correct!

$ xwininfo -root
Width: 400    ← Matches framebuffer!
Height: 1280

$ xdotool getwindowgeometry
Geometry: 400x1280  ← Matches screen!

Visible: Full screen → No black areas ✅
```

## Key Learning

**Rule:** Choose ONE rotation method, not both!

### Option 1: Kernel Cmdline Rotation (Recommended)
```bash
cmdline.txt: video=HDMI-A-1:400x1280M@60,rotate=90
xinitrc: xrandr --output HDMI-2 --rotate normal
```
**Pros:** Hardware-level, works before X11 starts, boot messages rotated

### Option 2: X11 Rotation Only
```bash
cmdline.txt: video=HDMI-A-1:1280x400M@60 (no rotate)
xinitrc: xrandr --output HDMI-2 --rotate left
```
**Pros:** Can change rotation without reboot

### ❌ DON'T: Both Rotations
```bash
cmdline.txt: video=HDMI-A-1:400x1280M@60,rotate=90
xinitrc: xrandr --output HDMI-2 --rotate left
```
**Result:** Double rotation = mismatch = display broken!

## Why Database `hdmi_scn_orient` Was Confusing

The database had:
```sql
hdmi_scn_orient = 'portrait'
```

This caused xinitrc to use xrandr rotation, but:
- Kernel cmdline ALREADY set portrait mode with rotate=90
- No need for xrandr rotation
- Database value was misleading

**Solution:** Removed database-based rotation logic from xinitrc since kernel cmdline handles it.

## Files Modified

### 1. `/home/andre/.xinitrc` (FIXED)

**Before:**
```bash
if [ "$HDMI_SCN_ORIENT" = "portrait" ]; then
    xrandr --output HDMI-2 --rotate left  ← Caused double rotation
    SCREEN_RES="400,1280"
else
    xrandr --output HDMI-2 --rotate normal
    SCREEN_RES="1280,400"
fi
```

**After:**
```bash
# NOTE: Display rotation is handled by kernel cmdline (rotate=90)
# Always use normal (no rotation) at X11 level
xrandr --output HDMI-2 --rotate normal

# Dimensions match kernel cmdline rotation
SCREEN_WIDTH=400
SCREEN_HEIGHT=1280
SCREEN_RES="400,1280"
```

### 2. `/boot/firmware/cmdline.txt` (No change needed)

**Already correct:**
```bash
video=HDMI-A-1:400x1280M@60,rotate=90
```
- This sets portrait mode at kernel level
- No need to change

## Status

**✅ FIXED** - Display now shows full screen  
**✅ ROOT CAUSE** - Double rotation (cmdline + xrandr)  
**✅ SOLUTION** - Use ONLY kernel cmdline rotation  
**✅ PERMANENT** - xinitrc updated to not use xrandr rotation

## Commands for Future Reference

**Check for double rotation:**
```bash
# Check kernel cmdline
cat /boot/firmware/cmdline.txt | grep rotate

# Check framebuffer
fbset -s

# Check X11 screen
xrandr --query
xwininfo -root | grep -E 'Width|Height'

# If mismatch → double rotation problem!
```

**Fix double rotation:**
```bash
# Force xrandr to normal
DISPLAY=:0 xrandr --output HDMI-2 --rotate normal
```

**Verify fix:**
```bash
# All should match:
fbset -s | grep geometry
xwininfo -root | grep Width
xdotool getwindowgeometry
```
