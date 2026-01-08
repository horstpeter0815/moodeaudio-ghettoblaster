# URGENT: PI 5 DESTROYING DISPLAYS

**Date:** 2025-12-04  
**Status:** CRITICAL - Two factory-new displays destroyed

---

## 🚨 WHAT HAPPENED

**Two factory-new displays were destroyed by Pi 5 within short time!**

This is NOT a normal failure - **Pi 5 is damaging/disabling displays!**

---

## ⚠️ ROOT CAUSE ANALYSIS

### **Likely Cause: Custom 1280x400 Resolution**

The custom `hdmi_cvt=1280 400 60 6 0 0 0` resolution may have:
- **Sent wrong video timings** to displays
- **Overdriven display controllers** with non-standard signals
- **Caused voltage spikes** through HDMI port
- **Damaged display electronics**

### **Additional Factors:**
- Pi 5 HDMI port may have hardware defect
- Power supply issues on Pi 5
- Incompatibility between Pi 5 and display hardware

---

## ✅ IMMEDIATE ACTIONS TAKEN

1. **✅ Removed dangerous custom resolution from Pi 5**
2. **✅ Removed hdmi_cvt settings**
3. **✅ Removed hdmi_mode=87 (custom mode)**
4. **✅ Removed video parameter from cmdline**
5. **✅ Created safe configuration with standard HDMI only**

---

## 🔧 DISPLAY RESET OPTIONS

### **1. Power Cycle (24 hours):**
```
- Disconnect display completely
- Remove all power sources
- Wait 24 hours
- Reconnect and test on KNOWN-GOOD device (NOT Pi 5!)
```

### **2. Factory Reset:**
- Check display menu/buttons for "Reset" or "Factory Reset"
- Some displays have hidden reset procedures
- Check manufacturer instructions

### **3. EDID Reset:**
- Displays store EDID (Extended Display Identification Data)
- May be corrupted by Pi 5
- Some displays can reset EDID

### **4. Test on Other Devices:**
- Test displays on Pi 4 (working)
- Test on laptop/computer
- If work elsewhere: Pi 5 problem
- If don't work: Displays permanently damaged

---

## ⚠️ CRITICAL WARNINGS

### **DO NOT:**
- ❌ Connect any more displays to Pi 5
- ❌ Use custom resolutions on Pi 5
- ❌ Use Pi 5 HDMI ports until issue is resolved

### **DO:**
- ✅ Test displays on other devices first
- ✅ Use Pi 4 for displays if needed
- ✅ Check if displays can be reset
- ✅ Consider Pi 5 may have hardware defect

---

## 📋 NEXT STEPS

### **For Displays:**
1. **Try 24-hour power cycle**
2. **Test on Pi 4 or laptop**
3. **Check manufacturer reset instructions**
4. **May be permanently damaged if Pi 5 sent wrong signals**

### **For Pi 5:**
1. **DO NOT use with displays until issue resolved**
2. **Check HDMI port with multimeter (if possible)**
3. **Consider Pi 5 may have hardware defect**
4. **Use only standard HDMI modes (no custom resolutions)**

---

## 🎯 RECOMMENDATION

**Use Pi 4 for displays instead of Pi 5!**

- Pi 4 works correctly with displays
- Pi 5 appears to have issues damaging displays
- Safety first - don't risk more displays

---

**Status:** Dangerous configuration removed. Pi 5 should NOT be used with displays until issue is resolved.

