# TOUCH BEHAVIOR

**Date:** 2025-12-04  
**Status:** Fixed - Touch closes both PeppyMeter and Chromium

---

## ✅ CURRENT BEHAVIOR

### **On Touch:**
1. ✅ PeppyMeter service stops
2. ✅ Chromium process is killed (`pkill -f chromium-browser`)
3. ✅ Chromium restarts (web player returns)

---

## 🔄 COMPLETE FLOW

1. **After 10 minutes inactivity:**
   - PeppyMeter starts
   - Chromium is hidden

2. **On touch:**
   - PeppyMeter stops ✅
   - Chromium is closed ✅
   - Chromium restarts (web player returns) ✅

---

## 📝 SCRIPT LOCATION

- `/usr/local/bin/peppymeter-screensaver.sh`
- Service: `peppymeter-screensaver.service`
- Log: `/tmp/peppymeter_screensaver.log`

---

**Status:** Touch now closes both PeppyMeter and Chromium, then restarts Chromium

