# Touchscreen Working Solution - Pi 5 HDMI

**CRITICAL: This must actually work, not just be documented!**

---

## HARDWARE CONFIRMED

### Touchscreen Details:
- **USB Device:** WaveShare WaveShare
- **USB ID:** 0712:000a
- **Type:** USB HID Multitouch
- **Event Device:** `/dev/input/event7` (varies)
- **X11 Device ID:** 12 (varies)

### Display Details:
- **Resolution:** 1280x400 (Landscape)
- **Current Rotation:** left (90° from Portrait)
- **Framebuffer:** 400x1280 (Portrait base, rotated)

---

## THE PROBLEM

### Current State:
1. Display starts in Portrait (400x1280) via `video=HDMI-A-2:400x1280M@60,rotate=90`
2. xrandr rotates to Landscape (1280x400)
3. Touchscreen coordinates are WRONG because:
   - Touchscreen reports coordinates for Portrait orientation
   - Display is rotated to Landscape
   - Transformation matrix is NOT applied correctly

### Why Peppy Doesn't Work:
- Peppy expects correct display orientation
- Touchscreen coordinates don't match display
- Everything is misaligned

---

## THE SOLUTION

### Step 1: Fix Display First (Remove Rotation Workaround)

**Current cmdline.txt:**
```
video=HDMI-A-2:400x1280M@60,rotate=90
```

**Should be:**
```
# NO video parameter - let config.txt handle it
```

**config.txt must have:**
```ini
hdmi_cvt 1280 400 60 6 0 0 0
display_rotate=0
```

**Result:** Display starts directly in Landscape (1280x400)

---

### Step 2: Fix Touchscreen Coordinates

**For Landscape 1280x400 (no rotation):**
- Touchscreen should report coordinates directly
- Transformation matrix: `1 0 0 0 1 0 0 0 1` (identity)

**BUT:** If touchscreen is still reporting Portrait coordinates:
- Need to calculate correct transformation
- Or calibrate touchscreen

---

### Step 3: Complete Configuration

#### X11 Configuration: `/etc/X11/xorg.conf.d/99-touchscreen.conf`
```
Section "InputClass"
    Identifier "WaveShare Touchscreen"
    MatchUSBID "0712:000a"
    MatchIsTouchscreen "on"
    Driver "libinput"
    Option "TransformationMatrix" "1 0 0 0 1 0 0 0 1"
EndSection
```

#### xinitrc Integration:
```bash
# After X11 starts, configure touchscreen
sleep 2

TOUCH_DEVICE=$(xinput list | grep -i "WaveShare" | head -1 | grep -oP 'id=\K[0-9]+')
if [ ! -z "$TOUCH_DEVICE" ]; then
    # For Landscape 1280x400 - identity matrix
    xinput set-prop "$TOUCH_DEVICE" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1
    
    # Verify
    echo "Touchscreen configured: Device $TOUCH_DEVICE"
    xinput list-props "$TOUCH_DEVICE" | grep Transformation
else
    echo "WARNING: Touchscreen not found!"
fi
```

---

## VERIFICATION STEPS

### 1. Check Touchscreen Detection:
```bash
# USB device
lsusb | grep 0712:000a

# Input device
ls -la /dev/input/ | grep event

# X11 device
DISPLAY=:0 xinput list | grep -i waveshare
```

### 2. Check Current Matrix:
```bash
TOUCH_ID=$(xinput list | grep -i waveshare | grep -oP 'id=\K[0-9]+')
xinput list-props "$TOUCH_ID" | grep Transformation
```

### 3. Test Coordinates:
```bash
# Touch corners and verify:
# Top-left: (0, 0)
# Top-right: (1280, 0)
# Bottom-left: (0, 400)
# Bottom-right: (1280, 400)
xinput test "$TOUCH_ID"
```

### 4. Test with Actual Application:
- Open Chromium
- Touch buttons
- Verify clicks register correctly
- Test Peppy Meter

---

## IF TOUCHSCREEN COORDINATES ARE STILL WRONG

### Scenario 1: Touchscreen reports Portrait coordinates
**If touching top-left shows (0, 400) instead of (0, 0):**
- Touchscreen is rotated 90°
- Use matrix: `0 1 0 -1 0 1 0 0 1` (90° counter-clockwise)

### Scenario 2: X and Y are swapped
**If touching right side moves cursor up:**
- Swap X and Y
- Use matrix: `0 1 0 1 0 0 0 0 1`

### Scenario 3: Coordinates are inverted
**If touching top moves cursor down:**
- Invert Y
- Use matrix: `1 0 0 0 -1 1 0 0 1`

### Scenario 4: Need calibration
**If coordinates are close but not exact:**
- Use xinput_calibrator
- Or manually adjust matrix values

---

## COMPLETE WORKING SETUP

### Files to Create/Modify:

#### 1. `/etc/X11/xorg.conf.d/99-touchscreen.conf`
```
Section "InputClass"
    Identifier "WaveShare Touchscreen"
    MatchUSBID "0712:000a"
    MatchIsTouchscreen "on"
    Driver "libinput"
    Option "TransformationMatrix" "1 0 0 0 1 0 0 0 1"
EndSection
```

#### 2. `~/.xinitrc` (add touchscreen config)
```bash
# Touchscreen configuration
sleep 2  # Wait for X11

TOUCH_DEVICE=$(xinput list | grep -i "WaveShare" | head -1 | grep -oP 'id=\K[0-9]+')
if [ ! -z "$TOUCH_DEVICE" ]; then
    xinput set-prop "$TOUCH_DEVICE" "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1
    echo "Touchscreen configured: Device $TOUCH_DEVICE"
fi
```

#### 3. Test Script: `test_touchscreen_coords.sh`
```bash
#!/bin/bash
export DISPLAY=:0

TOUCH_ID=$(xinput list | grep -i waveshare | grep -oP 'id=\K[0-9]+')
if [ -z "$TOUCH_ID" ]; then
    echo "ERROR: Touchscreen not found!"
    exit 1
fi

echo "Touchscreen ID: $TOUCH_ID"
echo "Touch the screen corners:"
echo "  Top-left, Top-right, Bottom-left, Bottom-right"
echo "Press Ctrl+C to stop"
xinput test "$TOUCH_ID"
```

---

## TESTING PROCEDURE

### Phase 1: Verify Detection
```bash
./setup_touchscreen.sh
# Should detect touchscreen
# Should create config files
# Should apply matrix
```

### Phase 2: Test Coordinates
```bash
./test_touchscreen.sh
# Touch corners
# Verify coordinates match display
```

### Phase 3: Test Applications
- Open Chromium
- Touch UI elements
- Verify clicks work
- Test Peppy Meter
- Verify everything works

### Phase 4: Reboot Test
```bash
sudo reboot
# After reboot:
# - Touchscreen should work automatically
# - Coordinates should be correct
# - Peppy should work
```

---

## TROUBLESHOOTING

### Touchscreen Not Detected:
1. Check USB connection
2. Check `lsusb | grep 0712`
3. Check `dmesg | grep -i touch`
4. Check `/dev/input/event*`

### Wrong Coordinates:
1. Get current matrix: `xinput list-props <id> | grep Transformation`
2. Test coordinates: `xinput test <id>`
3. Calculate correct matrix
4. Apply and test again

### Peppy Still Doesn't Work:
1. Verify display resolution: `xrandr`
2. Verify touchscreen coordinates
3. Check Peppy configuration
4. Check Peppy logs

---

## SUCCESS CRITERIA

✅ Touchscreen detected in USB  
✅ Touchscreen detected in X11  
✅ Transformation matrix applied  
✅ Coordinates match display  
✅ Touch works in Chromium  
✅ Touch works in Peppy Meter  
✅ Works after reboot  
✅ No manual intervention needed  

---

## FINAL CHECKLIST

- [ ] Touchscreen USB device detected
- [ ] Touchscreen input device exists
- [ ] Touchscreen in xinput list
- [ ] Transformation matrix applied
- [ ] Coordinates tested and correct
- [ ] Chromium touch works
- [ ] Peppy Meter touch works
- [ ] Configuration persists after reboot
- [ ] No errors in logs

---

**This must actually work, not just be documented!**

