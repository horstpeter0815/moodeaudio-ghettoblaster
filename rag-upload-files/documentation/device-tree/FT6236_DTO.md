# FT6236 Touch Controller Device Tree Overlay

**Overlay Name:** `ft6236`  
**Purpose:** Configure Focaltech FT6236 capacitive touch controller for 1280x400 landscape display

---

## Hardware Overview

### FT6236 Specifications

**Touch Controller:**
- Chip: Focaltech FT6236
- Interface: I2C
- Max Touch Points: 2 (multi-touch)
- I2C Address: 0x38
- Interrupt-driven

**Display:**
- Waveshare 7.9" HDMI Touchscreen
- Physical Resolution: 400x1280 (portrait)
- Configured for: 1280x400 (landscape)

---

## Device Tree Configuration

### I2C Device

**Address:** `0x38` on I2C1 bus

**Driver:** `ft6236` kernel module

**Configuration:**
```dts
ft6236: ft6236@38 {
    compatible = "focaltech,ft6236";
    reg = <0x38>;
    interrupt-parent = <&gpio>;
    interrupts = <25 2>; /* GPIO 25, falling edge */
    touchscreen-size-x = <1280>;
    touchscreen-size-y = <400>;
    touchscreen-inverted-x;
    touchscreen-inverted-y;
    touchscreen-swapped-x-y;
};
```

### GPIO Interrupt

**Pin:** GPIO 25  
**Mode:** Falling edge trigger  
**Flag:** 2 (IRQF_TRIGGER_FALLING)

**Purpose:**
- Touch controller signals CPU when touch detected
- Reduces CPU polling overhead
- Enables power-efficient operation

---

## Touch Parameters Explained

### Physical vs Logical Orientation

**Physical Display:**
```
Width:  400 pixels
Height: 1280 pixels
Orientation: Portrait (tall)
```

**Desired Orientation:**
```
Width:  1280 pixels
Height: 400 pixels
Orientation: Landscape (wide)
```

### Parameter Mapping

**`touchscreen-size-x = <1280>`**
- Logical width in landscape mode
- Maps to physical height (rotated 90°)

**`touchscreen-size-y = <400>`**
- Logical height in landscape mode
- Maps to physical width (rotated 90°)

**`touchscreen-inverted-x`**
- Flip X axis coordinates
- Compensates for cable routing

**`touchscreen-inverted-y`**
- Flip Y axis coordinates
- Compensates for mounting orientation

**`touchscreen-swapped-x-y`**
- Swap X and Y axes
- Converts portrait to landscape

### Coordinate Transformation

**Before transformation (portrait):**
```
Top-left:     (0, 0)
Top-right:    (400, 0)
Bottom-left:  (0, 1280)
Bottom-right: (400, 1280)
```

**After transformation (landscape):**
```
Top-left:     (0, 0)
Top-right:    (1280, 0)
Bottom-left:  (0, 400)
Bottom-right: (1280, 400)
```

---

## Fragment Breakdown

### Source: `ghettoblaster-ft6236.dts`

**fragment@0: I2C Configuration**
```dts
target = <&i2c1>;
__overlay__ {
    #address-cells = <1>;
    #size-cells = <0>;
    status = "okay";
    
    ft6236: ft6236@38 {
        compatible = "focaltech,ft6236";
        reg = <0x38>;
        interrupt-parent = <&gpio>;
        interrupts = <25 2>;
        touchscreen-size-x = <1280>;
        touchscreen-size-y = <400>;
        touchscreen-inverted-x;
        touchscreen-inverted-y;
        touchscreen-swapped-x-y;
    };
};
```

**No `__overrides__` section:**
- Parameters are fixed
- Cannot be changed via `dtparam`
- Must edit source and recompile to modify

---

## Verification

### Check if Loaded

```bash
# List loaded overlays
vcgencmd get_config dtoverlay | grep ft6236

# Check I2C device
i2cdetect -y 1
# Should show: 0x38

# Check input devices
cat /proc/bus/input/devices | grep -A 10 "ft6236"

# Check event device
ls -la /dev/input/event*
```

### Test Touch Input

```bash
# Install evtest
sudo apt install evtest

# Test touch events
sudo evtest /dev/input/eventX
# (replace X with correct event number)

# Touch screen and verify coordinates
# Should show values 0-1280 for X, 0-400 for Y
```

### Verify Orientation

**Test procedure:**
1. Touch top-left corner
   - Should report: X ≈ 0, Y ≈ 0
2. Touch top-right corner
   - Should report: X ≈ 1280, Y ≈ 0
3. Touch bottom-left corner
   - Should report: X ≈ 0, Y ≈ 400
4. Touch bottom-right corner
   - Should report: X ≈ 1280, Y ≈ 400

---

## Delayed Loading via Systemd

### Why Delay Loading?

**Problem:** Touch controller may not be ready when device tree loads

**Solution:** Load overlay after I2C bus stabilizes

**Service:** `ft6236-delay.service`

**Location:** `/etc/systemd/system/ft6236-delay.service`

**Example service:**
```ini
[Unit]
Description=Load FT6236 Touch Overlay (Delayed)
After=local-fs.target
Before=localdisplay.service

[Service]
Type=oneshot
ExecStart=/usr/bin/dtoverlay ft6236
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
```

**Benefit:**
- Ensures I2C bus is ready
- Prevents race conditions
- More reliable initialization

---

## Integration with X11

### Touch Driver Stack

```
Hardware Layer:
├── FT6236 chip (I2C 0x38)
├── Device tree overlay
└── ft6236 kernel driver

Input Layer:
├── Linux input subsystem
├── /dev/input/eventX
└── evdev kernel module

X11 Layer:
├── libinput (modern) or evdev (legacy)
├── X11 input drivers
└── Touch coordinate mapping
```

### X11 Configuration

**Automatic:** libinput usually detects touch devices automatically

**Manual configuration (if needed):**

**File:** `/etc/X11/xorg.conf.d/40-libinput.conf`

```conf
Section "InputClass"
    Identifier "FT6236 Touchscreen"
    MatchProduct "ft6236"
    Driver "libinput"
    Option "TransformationMatrix" "1 0 0 0 1 0 0 0 1"
EndSection
```

---

## Troubleshooting

### Problem: Touch Not Working

**Check:**
1. Is overlay loaded? `vcgencmd get_config dtoverlay | grep ft6236`
2. Is I2C device detected? `i2cdetect -y 1` (should show 0x38)
3. Is input device present? `ls /dev/input/event*`
4. Is X11 detecting touch? `xinput list`

**Common causes:**
- I2C bus not enabled
- Wrong I2C address
- GPIO 25 conflict
- Cable not connected
- Display not powered

### Problem: Inverted Touch Coordinates

**Symptom:** Touch point in top-left registers as bottom-right

**Cause:** Incorrect inversion parameters in device tree

**Fix:** Modify .dts source:
```dts
# Remove or add these as needed:
touchscreen-inverted-x;
touchscreen-inverted-y;
```

### Problem: Swapped X/Y Axes

**Symptom:** Horizontal touch moves cursor vertically

**Cause:** Missing or incorrect swap parameter

**Fix:**
```dts
# Add this line:
touchscreen-swapped-x-y;
```

### Problem: Touch Offset or Scaling

**Symptom:** Touch point doesn't match cursor position

**Possible causes:**
1. Incorrect `touchscreen-size-x` or `touchscreen-size-y`
2. X11 transformation matrix needed
3. Display resolution mismatch

**Check:**
```bash
# Verify display resolution
DISPLAY=:0 xrandr | grep connected

# Should match touchscreen-size values
```

---

## No Override Parameters

**Important:** This overlay has NO configurable parameters.

**Cannot change:**
- I2C address (fixed at 0x38)
- Touch resolution (fixed at 1280x400)
- Inversion or swap settings

**To modify:**
1. Edit `ghettoblaster-ft6236.dts` source
2. Recompile with `dtc` compiler
3. Replace .dtbo file in `/boot/firmware/overlays/`
4. Reboot

**Compile command:**
```bash
dtc -@ -I dts -O dtb -o ft6236.dtbo ghettoblaster-ft6236.dts
sudo cp ft6236.dtbo /boot/firmware/overlays/
sudo reboot
```

---

## Source Files

**Custom overlay:**
- [`custom-components/overlays/ghettoblaster-ft6236.dts`](../../../custom-components/overlays/ghettoblaster-ft6236.dts)

**Stock overlay:**
- May not exist in standard Raspberry Pi firmware
- Custom overlay may be required

---

## Related Documentation

- [Device Tree Overview](DEVICE_TREE_OVERVIEW.md)
- [Master Reference](../../../WISSENSBASIS/DEVICE_TREE_MASTER_REFERENCE.md)
- [Common Mistakes](COMMON_MISTAKES.md)

---

**Key Takeaway:** FT6236 overlay configures capacitive touch for landscape orientation with coordinate transformation. No configurable parameters - all settings are fixed in device tree source. Touch coordinates are transformed from portrait (400x1280) to landscape (1280x400) using inversion and swap parameters.
