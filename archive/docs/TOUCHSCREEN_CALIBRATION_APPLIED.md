# TOUCHSCREEN CALIBRATION APPLIED

**Date:** 2025-12-04  
**System:** Pi 5 (moOde Audio)  
**Status:** ✅ Calibration Found and Applied

---

## ✅ CALIBRATION FOUND

### **Calibration Matrix:**
```
0 -1 1 1 0 0 0 0 1
```

**Source:** moOde Audio (270° rotation)  
**Reference:** `WISSENSBASIS/99_TOUCHSCREEN_MOODE_CALIBRATION_ANGEWENDET.md`

---

## 🔧 APPLIED CONFIGURATION

### **1. Current Status:**
- ✅ Matrix already set: `0 -1 1 1 0 0 0 0 1`
- ✅ Device: WaveShare (ID: 6)
- ✅ Send Events Mode: Enabled

### **2. Persistence:**
- ✅ Added to `.xinitrc` for automatic application on boot
- ✅ Will be applied after X server starts
- ✅ Before Chromium launch

---

## 📋 CALIBRATION DETAILS

### **Matrix Format:**
```
0  -1  1
1   0  0
0   0  1
```

**Meaning:**
- 270° rotation (counter-clockwise)
- X-axis: inverted and shifted
- Y-axis: normal
- Translation: (1, 0)

### **moOde Reference:**
- **X11 Format:** `0 -1 1 1 0 0 0 0 1`
- **libinput Format:** `0 1 0 -1 0 1` (for Wayland/Weston)
- **Rotation:** 270° (portrait to landscape)

---

## ✅ VERIFICATION

**Check calibration:**
```bash
export DISPLAY=:0
xinput list-props 6 | grep "Coordinate Transformation Matrix"
```

**Expected output:**
```
Coordinate Transformation Matrix (152): 0.000000, -1.000000, 1.000000, 1.000000, 0.000000, 0.000000, 0.000000, 0.000000, 1.000000
```

---

## 🎯 STATUS

- ✅ Calibration matrix found in project documentation
- ✅ Matrix already active on device
- ✅ Persistence added to `.xinitrc`
- ✅ Will survive reboots

---

**Status: Touchscreen calibration restored and persistent!**

