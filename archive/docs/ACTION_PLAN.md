# ACTION PLAN - Using Pi 4 Approach

**Date:** 2025-12-04

---

## ✅ ANALYSIS COMPLETE

### **Key Finding:**
- **HiFiBerry Pi 4 (WORKING):** Uses `display_rotate=3` + standard HDMI
- **Pi 5 (ISSUES):** Uses custom `hdmi_cvt` + no rotation

---

## 🎯 SOLUTION APPROACH

### **Option 1: Test Displays First (Recommended)**
1. Test "damaged" displays on HiFiBerry Pi 4
2. If they work → Problem is Pi 5 config
3. Then apply Pi 4 approach to Pi 5

### **Option 2: Apply Pi 4 Approach Directly**
1. Remove custom resolution from Pi 5
2. Use `display_rotate=3` like Pi 4
3. Use standard HDMI (`hdmi_group=0`)
4. Test result

---

## 📋 IMPLEMENTATION

### **Changes to Pi 5:**

**Remove:**
- `hdmi_cvt=1280 400 60 6 0 0 0`
- `hdmi_mode=87`
- `hdmi_group=2`
- `framebuffer_width=1280`
- `framebuffer_height=400`
- `display_rotate=0`

**Add:**
- `hdmi_group=0` (standard)
- `display_rotate=3` (270° rotation)

**Update .xinitrc:**
- Use Portrait mode (400x1280)
- Window size: 400x1280
- Rotation handled by `display_rotate=3`

---

## 🔄 PROCESS

1. ✅ Analyze configurations (DONE)
2. ⏳ Test displays on HiFiBerry Pi 4 (OPTIONAL)
3. ⏳ Apply Pi 4 approach to Pi 5
4. ⏳ Reboot and verify
5. ⏳ Check display visually

---

**Status:** Ready to implement!

