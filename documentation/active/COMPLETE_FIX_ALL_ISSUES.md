# Complete Fix - All Issues (Display + Touchscreen + Peppy)

**ROOT CAUSE:** Display rotation workaround breaks everything!

---

## THE REAL PROBLEM

### Current Broken State:
1. **Display:** Starts Portrait (400x1280) → rotated to Landscape (1280x400)
2. **Touchscreen:** Reports Portrait coordinates → doesn't match rotated display
3. **Peppy Meter:** Expects correct orientation → gets confused by rotation
4. **Everything:** Misaligned because of the workaround

### Why Nothing Works:
- Display and touchscreen are out of sync
- Applications expect one orientation, get another
- Workarounds compound the problem

---

## THE COMPLETE FIX

### Fix 1: Display - Remove Rotation Workaround

**Current cmdline.txt (BROKEN):**
```
video=HDMI-A-2:400x1280M@60,rotate=90
```

**Fixed cmdline.txt:**
```
# Remove video parameter - let config.txt handle resolution
console=serial0,115200 console=tty1 root=PARTUUID=47dfe65d-02 rootfstype=ext4 fsck.repair=yes rootwait cfg80211.ieee80211_regdom=DE
```

**config.txt (FIXED):**
```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0

[all]
dtoverlay=vc4-kms-v3d
hdmi_group=2
hdmi_mode=87
hdmi_cvt 1280 400 60 6 0 0 0
hdmi_force_hotplug=1
hdmi_drive=2
display_rotate=0
hdmi_blanking=0
```

**Result:** Display starts DIRECTLY in Landscape (1280x400) - NO ROTATION!

---

### Fix 2: xinitrc - Remove Forced Rotation

**Current xinitrc (BROKEN):**
```bash
DISPLAY=:0 xrandr --output HDMI-2 --rotate left  # FORCED ROTATION
```

**Fixed xinitrc:**
```bash
# NO forced rotation - display is already Landscape
# Let Moode handle orientation based on settings
HDMI_SCN_ORIENT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'")
if [ "$HDMI_SCN_ORIENT" = "portrait" ]; then
    DISPLAY=:0 xrandr --output HDMI-2 --rotate left
else
    # Display is already Landscape, no rotation needed
    DISPLAY=:0 xrandr --output HDMI-2 --rotate normal
fi
```

**Result:** No forced rotation, display stays Landscape!

---

### Fix 3: Touchscreen - Match Display Orientation

**Since display is now Landscape (no rotation):**
- Touchscreen should report Landscape coordinates
- Transformation matrix: `1 0 0 0 1 0 0 0 1` (identity)

**X11 Config:**
```
Section "InputClass"
    Identifier "WaveShare Touchscreen"
    MatchUSBID "0712:000a"
    MatchIsTouchscreen "on"
    Driver "libinput"
    Option "TransformationMatrix" "1 0 0 0 1 0 0 0 1"
EndSection
```

**xinitrc:**
```bash
# Configure touchscreen for Landscape
sleep 2
TOUCH_DEVICE=$(xinput list | grep -i "WaveShare" | head -1 | grep -oP 'id=\K[0-9]+' || echo "")
if [ ! -z "$TOUCH_DEVICE" ]; then
    xinput set-prop "$TOUCH_DEVICE" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1
fi
```

**Result:** Touchscreen coordinates match display!

---

### Fix 4: Chromium - Use Correct Resolution

**Current (BROKEN):**
```bash
--window-size="1280,400"  # Hardcoded
```

**Fixed:**
```bash
# Get actual screen resolution
SCREEN_RES=$(xrandr | grep " connected" | head -1 | awk '{print $3}' | cut -d+ -f1 | tr 'x' ',')
chromium --window-size="$SCREEN_RES" ...
```

**Or if SCREEN_RES is wrong:**
```bash
# Use explicit Landscape resolution
chromium --window-size="1280,400" ...
```

**Result:** Chromium uses correct resolution!

---

### Fix 5: Peppy Meter - Correct Configuration

**Peppy needs:**
- Correct display resolution (1280x400)
- Correct orientation (Landscape)
- Touchscreen coordinates matching display

**After fixes 1-4, Peppy should work!**

---

## COMPLETE IMPLEMENTATION SCRIPT

### `fix_everything.sh`

```bash
#!/bin/bash
# Complete fix for all issues

set -e

echo "=========================================="
echo "Complete Fix - All Issues"
echo "=========================================="
echo ""

# Backup
echo "Step 1: Backing up..."
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup.$(date +%Y%m%d_%H%M%S)
sudo cp /boot/firmware/cmdline.txt /boot/firmware/cmdline.txt.backup.$(date +%Y%m%d_%H%M%S)
cp ~/.xinitrc ~/.xinitrc.backup.$(date +%Y%m%d_%H%M%S)
echo "✓ Backups created"
echo ""

# Fix 1: cmdline.txt - Remove video parameter
echo "Step 2: Fixing cmdline.txt..."
sudo sed -i 's/video=HDMI-A-2:400x1280M@60,rotate=90//' /boot/firmware/cmdline.txt
sudo sed -i 's/  / /g' /boot/firmware/cmdline.txt  # Clean up double spaces
echo "✓ Removed video parameter"
echo ""

# Fix 2: config.txt - Ensure correct settings
echo "Step 3: Fixing config.txt..."
# Add display_rotate=0 if not present
if ! grep -q "display_rotate=0" /boot/firmware/config.txt; then
    echo "display_rotate=0" | sudo tee -a /boot/firmware/config.txt
fi
# Ensure hdmi_cvt is correct
sudo sed -i 's/hdmi_cvt.*1280.*400.*/hdmi_cvt 1280 400 60 6 0 0 0/' /boot/firmware/config.txt
echo "✓ Config.txt fixed"
echo ""

# Fix 3: xinitrc - Remove forced rotation
echo "Step 4: Fixing xinitrc..."
# Remove forced rotation line
sed -i '/xrandr --output HDMI-2 --rotate left/d' ~/.xinitrc
# Add proper rotation logic
if ! grep -q "HDMI_SCN_ORIENT" ~/.xinitrc; then
    # Add before Chromium
    sed -i '/chromium/i\
# HDMI Orientation (no forced rotation)\
HDMI_SCN_ORIENT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='\''hdmi_scn_orient'\''" 2>/dev/null || echo "landscape")\
if [ "$HDMI_SCN_ORIENT" = "portrait" ]; then\
    DISPLAY=:0 xrandr --output HDMI-2 --rotate left\
else\
    DISPLAY=:0 xrandr --output HDMI-2 --rotate normal\
fi\
' ~/.xinitrc
fi
echo "✓ xinitrc fixed"
echo ""

# Fix 4: Touchscreen configuration
echo "Step 5: Configuring touchscreen..."
./fix_touchscreen_complete.sh
echo "✓ Touchscreen configured"
echo ""

# Summary
echo "=========================================="
echo "All Fixes Applied!"
echo "=========================================="
echo ""
echo "Changes made:"
echo "  1. Removed video parameter from cmdline.txt"
echo "  2. Fixed config.txt (display_rotate=0)"
echo "  3. Removed forced rotation from xinitrc"
echo "  4. Configured touchscreen"
echo ""
echo "NEXT: Reboot and test!"
echo "  sudo reboot"
echo ""
```

---

## VERIFICATION AFTER FIX

### Test 1: Display
```bash
xrandr
# Should show: HDMI-2 connected 1280x400+0+0 (normal) [not rotated]
```

### Test 2: Framebuffer
```bash
fbset -s
# Should show: geometry 1280 400 [not 400 1280]
```

### Test 3: Touchscreen
```bash
./test_touchscreen.sh
# Touch corners, verify coordinates match display
```

### Test 4: Chromium
- Open Chromium
- Verify full screen works
- No cut-off issues

### Test 5: Peppy Meter
- Start Peppy
- Verify it displays correctly
- Verify touch works
- Verify it works!

---

## SUCCESS = ALL WORK:

✅ Display starts Landscape (1280x400)  
✅ No rotation workaround  
✅ Touchscreen coordinates correct  
✅ Chromium works  
✅ Peppy Meter works  
✅ Everything aligned  

---

**This fixes the ROOT CAUSE - not just symptoms!**

