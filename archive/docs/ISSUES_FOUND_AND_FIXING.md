# ISSUES FOUND AND FIXING

**Date:** 2025-12-04  
**Status:** FIXING - Issues identified

---

## ISSUES REPORTED

1. **No Sound:** Audio not coming from AMP100
2. **Display Split:** Half PeppyMeter, half browser visible
3. **Window Overlap:** Both windows visible at same time

---

## FIXES APPLIED

### **1. Display Overlap:**
- ✅ Hiding PeppyMeter when Chromium should be visible
- ✅ Showing Chromium (web UI)
- ✅ Window management fixed

### **2. Audio:**
- ⏳ Checking mixer status
- ⏳ Testing ALSA output
- ⏳ Verifying MPD configuration

---

## VERIFICATION METHOD

Created `/usr/local/bin/verify-display.sh` to:
- Check actual display state
- Show all visible windows
- Verify window positions
- Detect overlap issues

---

**Status:** Fixing issues - verification method improved

