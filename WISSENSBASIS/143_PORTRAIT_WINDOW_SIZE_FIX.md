# Portrait Mode - Window Size Bug Fix

**Date**: 2026-01-19  
**Issue**: Two-thirds of screen black on left side in portrait mode  
**Root Cause**: ✅ Chromium window sized for landscape (1280x400) but display rotated to portrait (400x1280)

## The Problem

**Screen Setup:**
- Physical display: 1280x400 (landscape)
- Rotation: Left (for portrait mode)
- Logical resolution after rotation: 400x1280

**What was wrong:**
```bash
xrandr: HDMI-2 connected 1280x400+0+0 left  ← Display rotated left
Chromium window: 1280x400                    ← WRONG SIZE!
Result: Only 400 pixels visible (1/3 of window), 2/3 black
```

**Visual representation:**
```
Portrait display (400x1280):
┌────┐
│    │ ← 400 wide
│    │
│    │
│    │ ← 1280 tall
│    │
└────┘

Chromium window (1280x400 - WRONG):
┌──────────────┐ ← 1280 wide (too wide!)
│ visible│BLACK│ ← Only 400px visible
└──────────────┘   400 tall (too short!)
```

## Root Cause Analysis

**The xdotool workaround in `.xinitrc` was hardcoded:**

```bash
# WRONG - hardcoded for landscape only:
DISPLAY=:0 xdotool windowsize $WINDOW_ID 1280 400
```

**This worked for landscape but broke portrait mode because:**
1. Portrait mode sets `$SCREEN_RES="400,1280"`
2. Chromium tries to honor this
3. But xdotool immediately resizes back to `1280 400`
4. Display is rotated left, expects 400x1280
5. Only 400 pixels width visible, rest black

## The Fix

**Use variables instead of hardcoded values:**

```bash
# Apply screen rotation
if [ "$HDMI_SCN_ORIENT" = "portrait" ]; then
    xrandr --output HDMI-2 --rotate left
    SCREEN_RES="400,1280"
    SCREEN_WIDTH=400      ← ADD THIS
    SCREEN_HEIGHT=1280    ← ADD THIS
else
    xrandr --output HDMI-2 --rotate normal
    SCREEN_RES="1280,400"
    SCREEN_WIDTH=1280     ← ADD THIS
    SCREEN_HEIGHT=400     ← ADD THIS
fi

# Workaround: Force Chromium window size after launch
(
    sleep 3
    WINDOW_ID=$(DISPLAY=:0 xdotool search --class chromium | head -1)
    if [ -n "$WINDOW_ID" ]; then
        # CORRECT - uses variables:
        DISPLAY=:0 xdotool windowsize $WINDOW_ID $SCREEN_WIDTH $SCREEN_HEIGHT
        DISPLAY=:0 xdotool windowmove $WINDOW_ID 0 0
    fi
) &
```

## Verification

**Before fix:**
```bash
$ xrandr --query
HDMI-2 connected 1280x400+0+0 left
$ xdotool getwindowgeometry
Geometry: 1280x400  ← WRONG for left rotation
```

**After fix:**
```bash
$ xrandr --query
HDMI-2 connected 1280x400+0+0 left
$ xdotool getwindowgeometry  
Geometry: 400x1280  ← CORRECT! ✅
```

## Why This Matters

**For rotated displays:**
- **Left rotation**: Physical 1280x400 → Logical 400x1280
- **Right rotation**: Physical 1280x400 → Logical 400x1280  
- **Normal (no rotation)**: Physical 1280x400 → Logical 1280x400
- **Inverted rotation**: Physical 1280x400 → Logical 1280x400

**Window must match logical resolution, not physical!**

## Manual Fix (Current Session)

**Already applied:**
```bash
DISPLAY=:0 xdotool search --class chromium windowsize 400 1280
```

**Result:** Display now showing full screen in portrait mode ✅

## Permanent Fix (Future Boots)

**File:** `/home/andre/.xinitrc`  
**Change:** Use `$SCREEN_WIDTH` and `$SCREEN_HEIGHT` variables instead of hardcoded `1280 400`

**On next boot:**
1. Script reads `hdmi_scn_orient` from database
2. Sets correct `SCREEN_WIDTH` and `SCREEN_HEIGHT` for orientation
3. xdotool uses these variables to resize window correctly
4. Works for both landscape AND portrait modes ✅

## Status

**✅ CURRENT SESSION** - Window resized manually to 400x1280  
**✅ PERMANENT FIX** - xinitrc updated with variable resolution  
**✅ LANDSCAPE** - Will work (1280x400)  
**✅ PORTRAIT** - Will work (400x1280)  

## Commands

**Check current orientation and size:**
```bash
xrandr --query | grep HDMI-2
DISPLAY=:0 xdotool search --class chromium getwindowgeometry
```

**Fix manually if needed:**
```bash
# Portrait:
DISPLAY=:0 xdotool search --class chromium windowsize 400 1280

# Landscape:
DISPLAY=:0 xdotool search --class chromium windowsize 1280 400
```

**Verify fix in xinitrc:**
```bash
cat /home/andre/.xinitrc | grep -A5 'SCREEN_WIDTH'
```
