# CONFIGURATION COMPARISON: HiFiBerry Pi 4 vs Pi 5

**Date:** 2025-12-04

---

## 📊 SIDE-BY-SIDE COMPARISON

### **HiFiBerry Pi 4 (WORKING):**

```
dtoverlay=vc4-kms-v3d
max_framebuffers=2
display_auto_detect=1
hdmi_drive=2
hdmi_blanking=1
hdmi_force_hotplug=1
hdmi_group=0                    # Standard HDMI, no custom mode
display_rotate=3                # 270° rotation!
# NO hdmi_cvt settings
# NO custom resolution
```

**X11 Status:**
- Mode: 400x1280 (Portrait)
- Framebuffer: 400,1280
- **Display working!**

---

### **Pi 5 (ISSUES):**

```
dtoverlay=vc4-kms-v3d-pi5,noaudio
max_framebuffers=2
display_rotate=0                # No rotation!
hdmi_force_hotplug=1
hdmi_group=2                    # Custom HDMI mode group
hdmi_mode=87                    # Custom mode
hdmi_cvt=1280 400 60 6 0 0 0   # Custom resolution!
hdmi_drive=2
framebuffer_width=1280
framebuffer_height=400
```

**X11 Status:**
- Mode: 1280x400 (Landscape)
- Framebuffer: 400,1280
- **Display showing only backlight**

---

## 🔍 KEY DIFFERENCES

### **1. Video Driver:**
- **Pi 4:** `vc4-kms-v3d` (generic)
- **Pi 5:** `vc4-kms-v3d-pi5,noaudio` (Pi 5 specific)

### **2. Display Rotation:**
- **Pi 4:** `display_rotate=3` (270° - rotates Portrait to Landscape)
- **Pi 5:** `display_rotate=0` (no rotation)

### **3. HDMI Mode:**
- **Pi 4:** `hdmi_group=0` (standard, auto-detect)
- **Pi 5:** `hdmi_group=2` + `hdmi_mode=87` + `hdmi_cvt` (custom)

### **4. Resolution Approach:**
- **Pi 4:** Uses standard Portrait mode (400x1280) + rotation
- **Pi 5:** Tries to force custom Landscape mode (1280x400)

---

## 💡 ANALYSIS

**HiFiBerry Pi 4 approach:**
- Accepts Portrait framebuffer (400x1280)
- Rotates display 270° to get Landscape view
- Uses standard HDMI modes
- **This works!**

**Pi 5 approach:**
- Tries to force Landscape resolution (1280x400)
- Uses custom video timings (hdmi_cvt)
- Framebuffer still Portrait (400x1280)
- **This causes mismatch and issues!**

---

## 🎯 HYPOTHESIS

**The custom resolution (hdmi_cvt) may be causing issues:**
- Custom timings might be incompatible
- Mismatch between framebuffer and X11 resolution
- May cause display controller problems

**Solution might be:**
- Use same approach as Pi 4: Portrait + rotation
- OR fix framebuffer to match X11 resolution
- OR test if displays work on Pi 4 with current setup

---

## ✅ NEXT STEPS

1. Test "damaged" displays on HiFiBerry Pi 4
2. If they work: Problem is Pi 5 configuration
3. If they don't: Displays may actually be damaged
4. Compare video driver differences (pi4 vs pi5)

