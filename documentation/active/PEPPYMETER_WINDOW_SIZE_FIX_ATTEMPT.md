# PEPPYMETER WINDOW SIZE FIX ATTEMPT

**Date:** 2025-12-04  
**Status:** TESTING - Fixing window size issue

---

## ISSUE IDENTIFIED

- **Problem:** PeppyMeter showing only half of picture
- **Root Cause:** Window 511 has geometry 1280x480 instead of 1280x400
- **Display:** HDMI-2 is 1280x400 (correct)
- **Window:** 1280x480 (wrong - 80 pixels too tall)

---

## FIX ATTEMPTED

1. Resize window 511 from 1280x480 to 1280x400
2. Move window to position 0,0
3. Verify all PeppyMeter windows are correct size

---

## DISPLAY BUTTON

**DO NOT press button yet** - this is likely for input selection (HDMI1/HDMI2).

The issue is software (window size), not hardware.

---

## TESTING REQUIRED

- User verification: Is PeppyMeter now showing full picture?
- If still cut off, may need to restart PeppyMeter service

---

**Status:** Fix attempted - user verification needed

