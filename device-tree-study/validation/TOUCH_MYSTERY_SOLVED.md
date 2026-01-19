# Touch Controller Mystery - SOLVED

**Date:** 2026-01-18
**Critical Discovery:** Touch is USB, not I2C!

## The Mystery

**Expected:**
- FT6236 touch controller at I2C address 0x38
- Using `dtoverlay=ft6236`
- I2C timing issues at boot

**Actually Found:**
- ❌ No device at I2C 0x38
- ❌ No ft6236 driver loaded
- ✅ Touch works perfectly

## The Solution

**Kernel messages reveal:**
```
[0.861007] input: WaveShare WaveShare Touchscreen as /devices/.../usb1/1-1/1-1:1.0/.../input0
[2.441199] hid-multitouch 0003:0712:000A.0001: input,hiddev98,hidraw2: USB HID v1.11 Device [WaveShare WaveShare]
```

**THE TOUCH IS CONNECTED VIA USB, NOT I2C!**

## Hardware Architecture (CORRECTED)

### What We Thought:
```
Pi GPIO I2C1 (SDA/SCL) → FT6236 Touch Controller → Capacitive Touch Panel
```

### What's Actually There:
```
Pi USB Port → WaveShare USB Touch Controller → Capacitive Touch Panel
```

## Why This Changes Everything

### 1. No I2C Timing Issue!

**User mentioned:** "Touchscreen wants to initialize before display = I2C failures"

**Reality:** There is NO I2C touch device! The timing issue was either:
- A different problem misdiagnosed
- From an old configuration (maybe they switched from I2C to USB touch)
- Related to something else entirely

### 2. The ft6236 Overlay Does Nothing

**In config.txt:**
```ini
dtoverlay=ft6236    # ← This does NOTHING
```

**Why it's there:**
- Leftover from previous configuration attempt
- Was tried but didn't work (no FT6236 hardware)
- Forgotten to remove after switching to USB touch

**Can be removed:** Yes! It's not doing anything.

### 3. USB Touch Advantages

**Why USB touch is better:**
- ✅ No I2C bus contention
- ✅ No timing issues with display initialization
- ✅ Automatically detected by Linux (hid-multitouch driver)
- ✅ No device tree overlay needed
- ✅ Plug and play

**Device info:**
- Vendor ID: 0x0712
- Product ID: 0x000A
- Protocol: USB HID v1.11
- Driver: hid-multitouch (built into kernel)

### 4. Device Tree Simplification

**Current config.txt has:**
```ini
dtoverlay=vc4-kms-v3d,noaudio
dtparam=i2c_arm=on
dtparam=i2s=on
dtparam=audio=off
dtparam=fan_temp0=50000,fan_temp0_hyst=5000,fan_temp0_speed=75
dtoverlay=hifiberry-amp100
dtoverlay=ft6236              # ← CAN BE REMOVED
```

**Can be simplified to:**
```ini
dtoverlay=vc4-kms-v3d,noaudio
dtparam=i2c_arm=on            # Still needed for PCM5122 DAC
dtparam=i2s=on
dtparam=audio=off
dtparam=fan_temp0=50000,fan_temp0_hyst=5000,fan_temp0_speed=75
dtoverlay=hifiberry-amp100
# dtoverlay=ft6236 removed - not needed, touch is USB
```

## Why This Matters for Device Tree Study

### Documentation Correction Needed

**Device tree study assumed:**
- Touch controller on I2C
- Need to manage I2C timing
- Touch overlay loading strategy important

**Reality:**
- Touch controller on USB
- No I2C involvement
- Device tree overlay irrelevant for touch

### I2C Bus Usage (CORRECTED)

**Actually on I2C Bus 1:**
- 0x4d: PCM5122 DAC (HiFiBerry AMP100) ✅
- 0x38: ~~FT6236 touch~~ **NOT PRESENT**

**Only one I2C device!** Much simpler.

## Hardware Bill of Materials (CORRECTED)

### Display
- **Model:** WaveShare 7.9" 400x1280 LCD
- **Video:** HDMI connection
- **Touch:** USB connection (NOT I2C!)
- **Touch Controller:** WaveShare USB HID device
- **Touch Driver:** hid-multitouch (kernel built-in)

### Audio
- **HAT:** HiFiBerry AMP100
- **DAC:** PCM5122 at I2C 0x4d
- **Interface:** I2S
- **Driver:** snd_rpi_hifiberry_dacplus

### Raspberry Pi 5
- **Model:** Raspberry Pi 5
- **I2C Bus 1:** Only used for audio (PCM5122)
- **USB:** Used for touch controller
- **HDMI:** Used for display video

## Testing Touch

To verify touch is working:

```bash
# 1. Check USB devices
lsusb | grep -i waveshare

# 2. Check input events
ls -la /dev/input/by-id/ | grep -i waveshare

# 3. Test touch events (move finger on screen)
sudo evtest /dev/input/event0  # (or whichever event device)
```

## Implications

### Good News
1. ✅ Touch works perfectly (USB, no issues)
2. ✅ No I2C timing problems to solve
3. ✅ Simpler device tree (can remove ft6236 overlay)
4. ✅ One less thing to configure

### Device Tree Study Updates Needed
1. Remove references to I2C touch controller
2. Document that touch is USB (out of scope for device tree)
3. Update diagrams to show USB touch, not I2C
4. Remove I2C timing issue from documentation

## Recommendation

**Remove the unused ft6236 overlay:**

```bash
# Edit config.txt
sudo nano /boot/firmware/config.txt

# Remove this line:
# dtoverlay=ft6236

# Reboot and verify touch still works
sudo reboot
```

Touch will continue to work because it's USB (automatically detected).

## Lesson Learned

**Always check dmesg and actual hardware!**

We spent time documenting I2C touch, timing issues, and overlay loading strategies for a device that doesn't exist!

The actual hardware (USB touch) is much simpler and more reliable.

**Device tree study principle:** Understand the actual hardware first, don't assume based on documentation or overlay names in config.txt!

---

**Status:** Mystery solved - Touch is USB, not I2C. No device tree involvement needed.
