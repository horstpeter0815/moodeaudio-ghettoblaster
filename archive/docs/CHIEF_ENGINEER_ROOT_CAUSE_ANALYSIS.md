# CHIEF ENGINEER - ROOT CAUSE ANALYSIS

**Date:** 2025-12-04  
**Problem:** Display cut-off wrong direction, black noise, restless/flickering

---

## 🔍 ROOT CAUSE IDENTIFIED

### **Primary Issue: Framebuffer Mismatch**

```
Display X11 Resolution: 1280x400 ✅
Framebuffer Resolution: 400,1280 ❌
```

**This is the core problem!**

The framebuffer (hardware level) is set to **Portrait (400x1280)**, but X11 is trying to display **Landscape (1280x400)**. This causes:
- **Wrong direction cut-off** - Framebuffer is Portrait, X11 expects Landscape
- **Black noise/flickering** - Mode mismatch between hardware and software
- **Restless display** - Constant conflict between framebuffer and X11 resolution

---

## 🛠️ SOLUTION REQUIRED

### **Option 1: Fix Framebuffer at Boot**
- Set framebuffer to 1280x400 in config.txt
- Use correct hdmi_cvt syntax for Pi 5
- Ensure display_rotate matches framebuffer orientation

### **Option 2: Rotate Everything**
- Accept framebuffer 400x1280
- Rotate X11 display to match
- Rotate Chromium window accordingly

### **Option 3: Force Mode**
- Use hdmi_timings instead of hdmi_cvt
- Set explicit video mode at boot
- Override framebuffer with kernel parameters

---

## 📋 NEXT STEPS

1. **Try explicit video parameter in cmdline.txt**
2. **Test different hdmi_cvt syntax**
3. **Try hdmi_timings instead**
4. **Check if Pi 5 needs different approach**

---

**Status:** Root cause identified. Implementing comprehensive fix now.

