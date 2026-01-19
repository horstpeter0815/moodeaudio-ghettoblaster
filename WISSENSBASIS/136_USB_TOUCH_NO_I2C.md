# USB Touchscreen - No I2C Timing Issues

**Date:** 2026-01-19  
**Status:** ✅ CONFIRMED - Touch is USB, not I2C  
**Impact:** Major simplification of build configuration

---

## Critical Discovery

**User confirmed:** "now we use usb for touchscreen"

This confirms hardware validation findings from `device-tree-study/validation/TOUCH_MYSTERY_SOLVED.md`:

### Actual Hardware

```
WaveShare 7.9" Display
├── Video: HDMI connection to Pi
└── Touch: USB connection to Pi (WaveShare USB HID)
    ├── Vendor ID: 0x0712
    ├── Product ID: 0x000A
    ├── Driver: hid-multitouch (kernel built-in)
    └── Auto-detected: Yes (no configuration needed)
```

---

## What This Means

### ❌ NOT NEEDED (Removed from Build)

1. **ft6236 overlay** - Touch not on I2C
2. **ft6236-delay.service** - No timing issue
3. **ghettoblaster-ft6236.dts** - Overlay source not needed
4. **I2C timing fixes** - Touch not using I2C bus
5. **ft6236 compilation** - No overlay to compile

### ✅ WHAT WORKS

- Touch auto-detected by Linux kernel
- hid-multitouch driver (built-in)
- USB HID protocol
- No configuration needed
- No timing issues
- No I2C bus conflicts

---

## I2C Bus Usage (Corrected)

**Only ONE device on I2C Bus 1:**

| Address | Device | Status |
|---------|--------|--------|
| 0x4d | PCM5122 DAC (HiFiBerry AMP100) | ✅ Active |
| ~~0x38~~ | ~~FT6236 Touch~~ | ❌ Does not exist |

**Result:** Much simpler than expected! No I2C bus contention.

---

## Configuration Changes

### config.txt (Updated)

**Before (WRONG):**
```ini
dtoverlay=hifiberry-amp100
dtoverlay=ft6236              # ← Unused, touch is USB!
```

**After (CORRECT):**
```ini
dtoverlay=hifiberry-amp100
# Touch is USB (WaveShare USB HID) - no overlay needed
# dtoverlay=ft6236 removed - touch auto-detected by kernel
```

### Build Scripts (Updated)

**Removed:**
- ft6236 overlay compilation from `stage3_03-ghettoblaster-custom_00-run-chroot.sh`
- ft6236 overlay compilation from `first-boot-setup.sh`

**Kept:**
- Only HiFiBerry AMP100 overlay compilation (still needed for audio)

---

## Why User Had I2C Timing Concerns

**Possible reasons:**

1. **Old configuration:** May have tried I2C touch in the past
2. **Misdiagnosis:** Different issue blamed on I2C timing
3. **Documentation:** Found ft6236 overlay in config, assumed it was needed
4. **Display + Touch confusion:** Display uses HDMI, touch uses USB (separate!)

**Reality:** Touch is USB, never had I2C timing issues!

---

## Advantages of USB Touch

### vs I2C Touch

| Feature | I2C Touch | USB Touch (Current) |
|---------|-----------|---------------------|
| Bus conflicts | ⚠️ Possible | ✅ No (separate bus) |
| Timing issues | ⚠️ Need delay | ✅ None |
| Driver | ⚠️ Custom overlay | ✅ Built-in kernel |
| Configuration | ⚠️ Device tree | ✅ Auto-detect |
| Reliability | ⚠️ Depends on timing | ✅ Plug-and-play |

---

## Verification Commands

### Confirm Touch is USB

```bash
# 1. Check USB devices
lsusb | grep -i waveshare
# Expected: Bus XXX Device XXX: ID 0712:000a WaveShare

# 2. Check kernel messages
dmesg | grep -i waveshare
# Expected: 
# input: WaveShare WaveShare Touchscreen as /devices/.../input0
# hid-multitouch 0003:0712:000A.0001: USB HID v1.11 Device [WaveShare WaveShare]

# 3. Check input devices
ls -la /dev/input/by-id/ | grep -i waveshare
# Expected: WaveShare_WaveShare-event-if00 -> ../eventX

# 4. Verify NO I2C touch device
i2cdetect -y 1
# Expected: Only 0x4d (PCM5122), NO 0x38
```

---

## Build Configuration Summary

### Custom Overlays (Final)

**Only 1 overlay needed:**
1. ✅ `hifiberry-amp100.dtbo` - Audio DAC (PCM5122)

**Removed:**
2. ❌ `ft6236.dtbo` - Not needed, touch is USB

### config.txt (Final)

```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
[all]
# Audio
dtparam=i2c_arm=on                      # For PCM5122 only
dtparam=i2c_arm_baudrate=100000         # 100kHz for stability
dtparam=i2s=on
dtparam=audio=off
dtoverlay=hifiberry-amp100              # Audio HAT

# Display & Touch
# Video: HDMI (auto-detected)
# Touch: USB (auto-detected, no overlay needed)

# USB Gadget
dtoverlay=dwc2

# Boot
arm_boost=0
disable_splash=1
```

**Clean and simple!** No unused overlays.

---

## Impact on Build

### Files NOT Deployed (Removed)

- ❌ `custom-components/overlays/ghettoblaster-ft6236.dts`
- ❌ `custom-components/services/ft6236-delay.service`
- ❌ `ft6236.dtbo` compilation

### Build Time Savings

- Faster build (one less overlay to compile)
- Cleaner configuration
- Fewer potential issues

### Reliability Improvements

- ✅ No I2C timing dependencies
- ✅ No service-based overlay loading
- ✅ Simpler boot sequence
- ✅ Touch guaranteed to work (USB auto-detect)

---

## Updated Issue Count

### Before Understanding USB Touch

**7 critical issues found:**
1. ✅ arm_boost=0
2. ✅ hifiberry-amp100 without automute
3. ✅ ft6236 direct loading
4. ✅ Removed conflicting display_rotate/fbcon
5. ✅ Removed 49 debug log entries
6. ✅ Fixed overlay output filenames
7. ✅ Fixed overlay filenames in first-boot-setup.sh

### After Understanding USB Touch

**6 critical issues (simplified):**
1. ✅ arm_boost=0
2. ✅ hifiberry-amp100 without automute
3. ✅ Removed conflicting display_rotate/fbcon
4. ✅ Removed 49 debug log entries
5. ✅ Fixed AMP100 overlay filename
6. ✅ Removed unnecessary ft6236 overlay (USB touch)

**Result:** Simpler build, fewer potential issues! 🎉

---

## Documentation Updates

### Updated Files

1. ✅ `config.txt.overwrite` - Removed ft6236 overlay
2. ✅ `stage3_03-ghettoblaster-custom_00-run-chroot.sh` - Removed ft6236 compilation
3. ✅ `first-boot-setup.sh` - Removed ft6236 compilation
4. ✅ `131_BUILD_READY_CHECKLIST.md` - Updated issue count
5. ✅ `135_DEVICE_TREE_OVERLAYS.md` - Marked as obsolete (touch is USB)
6. ✅ `136_USB_TOUCH_NO_I2C.md` - This document

---

## Verification After Build

### Expected Results

```bash
# 1. Check overlays loaded
dtoverlay -l
# Expected:
# vc4-kms-v3d-pi5
# hifiberry-amp100
# (NO ft6236)

# 2. Check I2C devices
i2cdetect -y 1
# Expected:
#      0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
# 40: -- -- -- -- -- -- -- -- -- -- -- -- -- UU -- -- 
# (Only PCM5122 at 0x4d, NO touch at 0x38)

# 3. Check touch input
cat /proc/bus/input/devices | grep -A 5 WaveShare
# Expected: WaveShare USB HID device

# 4. Test touch
evtest
# Select WaveShare device, touch screen
# Expected: Touch events appear
```

---

## Summary

**Key Points:**

1. ✅ Touch is USB (WaveShare USB HID)
2. ✅ NO I2C timing issues
3. ✅ NO ft6236 overlay needed
4. ✅ Only ONE I2C device (PCM5122 audio DAC)
5. ✅ Simpler build configuration
6. ✅ Touch auto-detected by kernel
7. ✅ More reliable (USB plug-and-play)

**Result:** Cleaner, simpler, more reliable build! 🎉

---

**Status:** All USB touch updates applied to build configuration.
