# PI 5 DISPLAY SPECIFICS - Important Differences

**Date:** 2025-12-04  
**System:** System 2 - moOde Pi 5 (GhettoPi4)  
**Hardware:** Raspberry Pi 5 Model B Rev 1.1 (8GB)

---

## ⚠️ CRITICAL: PI 5 IS NOT PI 4!

### **Hardware Differences:**
- **Pi 4:** BCM2711 SoC, VideoCore VI
- **Pi 5:** BCM2712 SoC, VideoCore VII (different!)
- **Kernel:** Pi 5 requires 6.x kernel (currently 6.12.47+rpt-rpi-2712)
- **Display Controller:** Different HDMI controller on Pi 5

---

## 🔧 PI 5 SPECIFIC DISPLAY CONFIGURATION

### **X11 Issues on Pi 5:**
1. **Different video driver:**
   - Pi 5 uses newer Mesa/DRM drivers
   - May need different X11 configuration

2. **HDMI Controller:**
   - Pi 5 has updated HDMI hardware
   - Different resolution handling

3. **Permissions:**
   - X server may run differently
   - Different user/group permissions needed

### **Current Problem:**
- **Chromium won't start on Pi 5**
- X server runs, but Chromium can't connect
- Error: "Missing X server or $DISPLAY"
- This may be Pi 5 specific issue

---

## 🛠️ PI 5 SPECIFIC FIXES NEEDED

### **1. X Server Configuration:**
```bash
# Pi 5 may need:
- Different xorg.conf settings
- Updated DRM/KMS configuration
- VideoCore VII specific settings
```

### **2. Display Resolution:**
```bash
# Pi 5 HDMI controller handles resolutions differently
# May need different xrandr commands
# Different mode calculation
```

### **3. X Permissions:**
```bash
# Pi 5 X server may need:
- Different xauth configuration
- Different user permissions
- Wayland vs X11 considerations
```

---

## 📋 VERIFICATION FOR PI 5

### **Check Pi 5 specific settings:**
```bash
# 1. Kernel version (must be 6.x)
uname -r  # Should show: 6.12.47+rpt-rpi-2712

# 2. Hardware model
cat /proc/device-tree/model  # Should show: Raspberry Pi 5 Model B

# 3. Video driver
lsmod | grep -E 'vc4|drm|mesa'  # Check available drivers

# 4. X server logs
tail /var/log/Xorg.0.log  # Check for Pi 5 specific errors
```

---

## 🎯 NEXT STEPS

1. **Fix X permissions for Pi 5:**
   - May need Pi 5 specific xauth setup
   - Check video group membership
   - Verify X server runs correctly

2. **Test Chromium on Pi 5:**
   - May need Pi 5 specific Chromium flags
   - Check if hardware acceleration works
   - Verify display output

3. **Document Pi 5 differences:**
   - All fixes must be Pi 5 compatible
   - Don't assume Pi 4 fixes work on Pi 5

---

**Status:** Pi 5 specific issues identified. Need to address Pi 5 hardware differences.

