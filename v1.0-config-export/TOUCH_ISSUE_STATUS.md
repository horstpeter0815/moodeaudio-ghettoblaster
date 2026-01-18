# Touch Calibration Issue - Current Status

**Date:** 2026-01-18  
**Status:** ❌ **UNRESOLVED**

## Problem

Touch calibration is not working correctly. User taps right upper corner (moOde M logo area) but dismiss button is triggered.

## What I Tried (All Failed)

10+ different calibration combinations - none worked.

## Current State

- **Working config restored:** `Calibration="0 1280 0 400"`, `SwapAxes=0`
- **Touchscreen:** USB HID "WaveShare WaveShare Touchscreen" (not I2C FT6236 overlay)
- **Display:** 1280x400 landscape (rotated 90° left from 400x1280)
- **Issue:** Touch coordinates do not match where user taps

## Root Cause

Touchscreen is USB HID device, not I2C overlay. Device tree overlay settings (swapped-x-y, inverted-x, inverted-y) are not applied. All transformations must be done in X11 config, but correct combination not found.

## Next Steps Needed

Requires manual testing or different approach:
1. Test actual touch coordinates with evtest or xinput
2. Determine exact coordinate mapping needed
3. Or use touch calibration tool to calibrate interactively

**DO NOT CONTINUE RANDOM CONFIGURATION CHANGES**
