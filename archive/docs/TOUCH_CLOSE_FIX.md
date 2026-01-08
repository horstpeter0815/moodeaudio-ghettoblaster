# TOUCH CLOSE FIX

**Date:** 2025-12-04  
**Issue:** Touch should close both PeppyMeter and Chromium (web player)

---

## ✅ FIX APPLIED

### **PeppyMeter Screensaver Updated:**
- Touch detection: Working ✅
- On touch: Closes PeppyMeter ✅
- On touch: Closes Chromium (web player) ✅
- On touch: Restarts Chromium (web player) ✅

---

## 🔄 BEHAVIOR

1. **After 10 minutes inactivity:**
   - PeppyMeter starts
   - Chromium is hidden

2. **On touch:**
   - PeppyMeter stops
   - Chromium is closed completely
   - Chromium restarts (web player returns)

---

## 📝 SCRIPT CHANGES

- `hide_peppymeter()` function updated:
  - Stops PeppyMeter service
  - Kills Chromium process (`pkill -f chromium-browser`)
  - Restarts Chromium via xinit

---

**Status:** Fix applied - touch now closes both PeppyMeter and Chromium

