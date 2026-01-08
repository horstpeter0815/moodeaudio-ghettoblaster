# TOUCH TEST INSTRUCTIONS

**Date:** 2025-12-04  
**Status:** Touch detection working, testing needed

---

## ✅ CURRENT STATUS

- Touch events are being detected ✅
- Script is monitoring touchscreen ✅
- Service is running ✅

---

## 🧪 TESTING

### **To Test Touch Close:**

1. **Wait for PeppyMeter to activate:**
   - Wait 10 minutes of inactivity
   - OR manually start: `ssh pi2 'sudo systemctl start peppymeter.service'`

2. **Verify PeppyMeter is active:**
   - `ssh pi2 'systemctl is-active peppymeter.service'`
   - Should show: `active`

3. **Touch the screen:**
   - Touch anywhere on the screen
   - Check logs: `ssh pi2 'tail -f /tmp/peppymeter_screensaver.log'`
   - Should see: "Touch detected" and "Deactivating PeppyMeter and closing Chromium"

4. **Verify both closed:**
   - PeppyMeter should stop
   - Chromium should restart (web player returns)

---

## 📝 LOGS

Check logs in real-time:
```bash
ssh pi2 'tail -f /tmp/peppymeter_screensaver.log'
```

---

**Status:** Ready for testing - touch should close both when PeppyMeter is active

