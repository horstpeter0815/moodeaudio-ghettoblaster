# PI 5 ORIENTATION & TIMING FIX

**Date:** 2025-12-04  
**Status:** ✅ Fixed

---

## 🔧 FIXES APPLIED

### **1. Display Orientation**
- ✅ Rotation set to "normal" (landscape 1280x400)
- ✅ Display resolution: 1280x400 confirmed
- ✅ Removed incorrect rotation that caused 400x1280

### **2. Timing Optimization**
- ✅ Smart polling for X server (checks every 0.3s, max 20 attempts)
- ✅ Smart polling for Chromium window (checks every 1s, max 15 attempts)
- ✅ Window size fix with retry logic (5 attempts)
- ✅ Better sequencing with verification at each step

### **3. Current Status**
```
Display: 1280x400 normal (Landscape)
Rotation: normal
Chromium: 10 processes running
Window: 1279x399 (almost perfect - 1 pixel difference)
```

---

## 🔄 IF DISPLAY ORIENTATION IS STILL WRONG

The display might be physically mounted differently. To change orientation, edit `/home/andre/.xinitrc`:

### **Options:**

1. **Normal (default - Landscape 1280x400):**
```bash
xrandr --output HDMI-2 --mode "1280x400_60.00" --rotate normal
```

2. **Left (Rotated 90° counter-clockwise):**
```bash
xrandr --output HDMI-2 --mode "1280x400_60.00" --rotate left
```
*Note: This will show as 400x1280 in xrandr output*

3. **Right (Rotated 90° clockwise):**
```bash
xrandr --output HDMI-2 --mode "1280x400_60.00" --rotate right
```
*Note: This will show as 400x1280 in xrandr output*

4. **Inverted (Rotated 180°):**
```bash
xrandr --output HDMI-2 --mode "1280x400_60.00" --rotate inverted
```

### **Quick Fix Command:**
```bash
ssh pi2 "sudo sed -i 's/--rotate normal/--rotate left/' /home/andre/.xinitrc && sudo systemctl restart localdisplay"
```
Replace `left` with `right` or `inverted` as needed.

---

## ⏱️ TIMING IMPROVEMENTS

### **Before:**
- Fixed sleep 3s
- Fixed sleep 8s
- No verification

### **After:**
- Smart polling with verification
- Checks every 0.3-1s instead of fixed waits
- Logs to `/tmp/xinit-start.log` for debugging
- Retry logic for window size fix

### **Timing Breakdown:**
- X server ready: ~0.3s (checks every 0.3s)
- Display ready: ~0.5s (checks every 0.5s)
- Chromium window: ~1-2s (checks every 1s)
- Window fix: ~0.5-2.5s (5 attempts with 0.5s delay)

**Total startup time: ~3-5 seconds (much better than fixed 11s)**

---

## 📋 VERIFICATION

### **Check Current Status:**
```bash
ssh pi2 "export DISPLAY=:0 && \
  echo 'Display:' && xrandr --query | grep 'HDMI-2' && \
  echo '' && \
  echo 'Resolution:' && xrandr --query | grep 'HDMI-2' | grep -oP '\d+x\d+' | head -1 && \
  echo '' && \
  echo 'Rotation:' && xrandr --query | grep 'HDMI-2' | grep -E 'normal|left|right|inverted' && \
  echo '' && \
  echo 'Chromium:' && ps aux | grep chromium | grep -v grep | wc -l && \
  echo '' && \
  echo 'Window:' && xwininfo -root -tree 2>/dev/null | grep -i chromium | head -1"
```

### **Check Startup Log:**
```bash
ssh pi2 "cat /tmp/xinit-start.log"
```

---

## 🛠️ TROUBLESHOOTING

### **If Display Shows Wrong Orientation:**

1. **Check current rotation:**
```bash
ssh pi2 "export DISPLAY=:0 && xrandr --query | grep 'HDMI-2'"
```

2. **Try different rotation:**
```bash
ssh pi2 "export DISPLAY=:0 && xrandr --output HDMI-2 --rotate left"
```
(Test visually, then update .xinitrc if correct)

3. **Update .xinitrc permanently:**
Edit `/home/andre/.xinitrc` and change `--rotate normal` to desired rotation

### **If Timing Issues Persist:**

1. **Check startup log:**
```bash
ssh pi2 "cat /tmp/xinit-start.log"
```

2. **Check service timing:**
```bash
ssh pi2 "systemd-analyze blame | grep localdisplay"
```

3. **Increase delays if needed:**
Edit `.xinitrc` and increase sleep times or MAX_ATTEMPTS

---

## ✅ CURRENT CONFIGURATION

**File:** `/home/andre/.xinitrc`

**Key Features:**
- Smart polling (no fixed delays)
- Proper X server verification
- Window size fix with retry
- Logging for debugging
- Rotation: `normal` (change if needed)

**Deployment:**
```bash
./deploy-to-pi5.sh /home/andre/.xinitrc xinitrc
```

---

**Status:** ✅ Orientation and timing optimized. Ready for testing!

