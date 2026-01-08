# Touchscreen Configuration Guide - Pi 5 HDMI

**For Waveshare 7.9" HDMI LCD with touchscreen**

---

## TOUCHSCREEN TYPES

### USB Touchscreen
- Connected via USB
- Shows as `/dev/input/event*`
- Configured via `xinput` or `libinput`

### I2C Touchscreen
- Connected via I2C bus
- May need device tree overlay
- Configured via `xinput` or `libinput`

---

## IDENTIFY TOUCHSCREEN TYPE

### Check USB Devices:
```bash
lsusb | grep -i touch
# Or
ls -la /dev/input/ | grep -i touch
```

### Check I2C Devices:
```bash
i2cdetect -y 1
# Look for touchscreen addresses (often 0x14, 0x38, etc.)
```

### Check Input Devices:
```bash
cat /proc/bus/input/devices | grep -A 5 -i touch
```

---

## USB TOUCHSCREEN CONFIGURATION

### Step 1: Identify Device
```bash
xinput list
# Find touchscreen device (e.g., "Goodix Touchscreen")
```

### Step 2: Get Current Properties
```bash
xinput list-props "Device Name"
# Or use device ID
xinput list-props 10
```

### Step 3: Configure Coordinate Transformation

**For Landscape (1280x400):**
```bash
# Get device ID
DEVICE_ID=$(xinput list | grep -i touch | grep -oP 'id=\K[0-9]+')

# Set transformation matrix for Landscape
# Matrix: [a b c; d e f; g h i]
# For 1280x400 Landscape (no rotation):
xinput set-prop $DEVICE_ID "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1

# For rotated (if needed):
# xinput set-prop $DEVICE_ID "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1
```

### Step 4: Test Touchscreen
```bash
# Test with evtest
sudo evtest

# Or test with xinput
xinput test "Device Name"
```

### Step 5: Make Permanent

**Create:** `/etc/X11/xorg.conf.d/99-touchscreen.conf`
```
Section "InputClass"
    Identifier "Touchscreen"
    MatchIsTouchscreen "on"
    MatchDevicePath "/dev/input/event*"
    Driver "libinput"
    Option "TransformationMatrix" "1 0 0 0 1 0 0 0 1"
EndSection
```

**Or add to xinitrc:**
```bash
# Wait for X11
sleep 2

# Configure touchscreen
DEVICE_ID=$(xinput list | grep -i touch | grep -oP 'id=\K[0-9]+')
if [ ! -z "$DEVICE_ID" ]; then
    xinput set-prop $DEVICE_ID "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1
fi
```

---

## I2C TOUCHSCREEN CONFIGURATION

### Step 1: Check Device Tree Overlay
```bash
# Check if overlay is loaded
dmesg | grep -i touch
dmesg | grep -i i2c
```

### Step 2: Verify I2C Connection
```bash
i2cdetect -y 1
# Should show touchscreen address
```

### Step 3: Configure via xinput
- Same as USB touchscreen
- Use xinput to set transformation matrix

---

## COORDINATE TRANSFORMATION MATRICES

### No Rotation (Landscape 1280x400):
```
1 0 0
0 1 0
0 0 1
```

### 90° Clockwise:
```
0 1 0
-1 0 1
0 0 1
```

### 90° Counter-clockwise:
```
0 -1 1
1 0 0
0 0 1
```

### 180°:
```
-1 0 1
0 -1 1
0 0 1
```

---

## CALIBRATION

### Using xinput_calibrator:
```bash
sudo apt-get install xinput-calibrator
xinput_calibrator
# Follow on-screen instructions
# Copy output to xorg.conf.d
```

### Manual Calibration:
```bash
# Test touch points
xinput test "Device Name"

# Adjust matrix if coordinates are off
# Example: If X and Y are swapped
xinput set-prop $DEVICE_ID "Coordinate Transformation Matrix" 0 1 0 1 0 0 0 0 1
```

---

## TROUBLESHOOTING

### Touchscreen Not Detected:
```bash
# Check if device exists
ls -la /dev/input/

# Check dmesg
dmesg | grep -i touch

# Check xinput
xinput list
```

### Wrong Coordinates:
```bash
# Get current matrix
xinput list-props "Device Name" | grep Transformation

# Test different matrices
# Start with identity matrix: 1 0 0 0 1 0 0 0 1
```

### Touchscreen Not Working After Rotation:
- Recalculate transformation matrix
- Test with xinput test
- Adjust matrix values

---

## MOODE INTEGRATION

### Moode Touchscreen Settings:
- Moode may have touchscreen settings in UI
- Check Moode documentation
- May need to configure separately

### xinitrc Integration:
```bash
# In xinitrc, after X11 starts:
sleep 2

# Configure touchscreen
TOUCH_DEVICE=$(xinput list | grep -i touch | head -1 | grep -oP 'id=\K[0-9]+')
if [ ! -z "$TOUCH_DEVICE" ]; then
    # Landscape matrix
    xinput set-prop $TOUCH_DEVICE "Coordinate Transformation Matrix" 1 0 0 0 1 0 0 0 1
    echo "Touchscreen configured: Device $TOUCH_DEVICE"
else
    echo "Touchscreen not found"
fi
```

---

## TESTING

### Test Touch Points:
```bash
# Visual test
xinput test "Device Name"
# Touch screen, see coordinates

# Or use evtest for raw data
sudo evtest /dev/input/eventX
```

### Verify Coordinates:
- Touch top-left corner → should be (0, 0)
- Touch top-right → should be (1280, 0)
- Touch bottom-left → should be (0, 400)
- Touch bottom-right → should be (1280, 400)

---

## RECOMMENDED SETUP

1. **Identify touchscreen type** (USB or I2C)
2. **Get device ID** via xinput
3. **Test current behavior**
4. **Calculate correct matrix** for Landscape
5. **Apply transformation**
6. **Test coordinates**
7. **Make permanent** (xorg.conf.d or xinitrc)

---

**Touchscreen configuration ready!**

