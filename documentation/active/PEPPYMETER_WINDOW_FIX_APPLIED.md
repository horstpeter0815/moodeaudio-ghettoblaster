# PEPPYMETER WINDOW FIX APPLIED

**Date:** 2025-12-04  
**Status:** TESTING - Fix applied

---

## ISSUE

- **Problem:** PeppyMeter window at position -216,40 (off-screen, showing only half)
- **Root Cause:** PeppyMeter sets window position to -216,40 on startup
- **Solution:** Continuous window position fix service

---

## FIX APPLIED

1. ✅ Created window fix script: `/usr/local/bin/peppymeter-window-fix.sh`
2. ✅ Created systemd service: `peppymeter-window-fix.service`
3. ✅ Service continuously moves window to 0,0 and sets size to 1280x400

---

## DISPLAY BUTTON

**DO NOT press the button** - this is a software issue, not hardware.

The button is likely for input selection and won't fix the window position.

---

## TESTING REQUIRED

- User verification: Is PeppyMeter now showing full picture?
- Window should be at position 0,0 with size 1280x400

---

**Status:** Fix applied - user verification needed

