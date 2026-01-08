# WORK PRIORITIES

**Date:** 2025-12-04  
**Status:** IN_PROGRESS

---

## PRIORITY 1: VERIFICATION REQUIRED

### **1. Web UI Display**
- **Current:** HTTP 200, Chromium running
- **Action:** User verification needed - is Web UI actually visible on display?
- **Status:** TESTING

### **2. Boot Screen Landscape**
- **Current:** `display_rotate=3` set (just fixed from 1), `fbcon=rotate:3` in cmdline.txt
- **Action:** Reboot required, then user verification
- **Status:** TESTING

### **3. Touch Detection**
- **Current:** Logs show touch events detected, PeppyMeter closes on touch
- **Action:** User verification needed - does touch actually close both?
- **Status:** TESTING

---

## PRIORITY 2: CONFIGURATION

### **4. AMP100 Audio**
- **Current:** Hardware not detected, I2C configuration applied
- **Action:** Reboot required, then test hardware detection
- **Status:** TESTING

---

## NEXT ACTIONS

1. Fix `display_rotate=1` → `display_rotate=3` ✅ (done)
2. Wait for user verification of Web UI
3. Test boot screen after reboot
4. Test touch functionality
5. Test audio after reboot

---

**Status:** Work in progress - following documentation standards

