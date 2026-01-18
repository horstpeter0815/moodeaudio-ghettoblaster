# Touch Calibration Attempts - DO NOT USE

**Date:** 2026-01-18  
**Status:** ❌ **ALL ATTEMPTS FAILED**

## Problem

User taps right upper corner (moOde M logo) but dismiss button is triggered.

Display: 1280x400 landscape (rotated 90° left from 400x1280)  
Touchscreen: USB HID "WaveShare WaveShare Touchscreen" (not I2C FT6236 overlay)

## Attempts Made (All Failed)

1. ✅ Basic calibration only: `Calibration="0 1280 0 400"`, `SwapAxes=0` - FAILED
2. ❌ InvertX=1 - FAILED
3. ❌ InvertY=1 - FAILED
4. ❌ SwapAxes=1 - FAILED
5. ❌ SwapAxes=1, InvertY=1 - FAILED
6. ❌ TransformationMatrix "0 -1 1 1 0 0 0 0 1" - FAILED
7. ❌ No X11 config (device tree only) - FAILED
8. ❌ SwapAxes=1, InvertX=1 - FAILED
9. ❌ SwapAxes=1, InvertX=1, InvertY=1 - FAILED
10. ❌ Current: SwapAxes=1, InvertX=1, InvertY=1 - FAILED

## Root Issue

**Touchscreen detected as USB HID, not I2C overlay:**
- Device: "WaveShare WaveShare Touchscreen" via USB
- Device tree overlay (FT6236 with swapped-x-y, inverted-x, inverted-y) is NOT loaded
- Need to apply all transformations in X11, but correct combination not found

## Working Configuration (Before Changes)

From saved config:
```
Section "InputClass"
    Identifier "calibration"
    MatchProduct "FT6236|ft6236"
    Option "Calibration" "0 1280 0 400"
    Option "SwapAxes" "0"
EndSection
```

**This working config did NOT solve the dismiss button issue either.**

## What's Needed

Need to determine:
1. Where is dismiss button on screen (coordinates)?
2. Where does user tap when they see moOde M?
3. What should the actual transformation be?

**ALL ATTEMPTS FAILED - DO NOT CONTINUE THIS APPROACH**
