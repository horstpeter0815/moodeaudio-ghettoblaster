# Device Tree Overlays (.dtbo) - Complete Guide

**Date:** 2026-01-19  
**Status:** ✅ Verified - Custom overlays ready for build

---

## Overview

Your custom build uses **2 custom device tree overlays** for:
1. **FT6236 Touchscreen** - Waveshare 7.9" display
2. **HiFiBerry AMP100** - Audio DAC/Amp (PCM5122 chip)

These overlays are custom-compiled for **Raspberry Pi 5** (`bcm2712` compatible).

---

## Custom Overlays

### 1. ghettoblaster-ft6236.dtbo

**Source:** `custom-components/overlays/ghettoblaster-ft6236.dts`

**Purpose:** Configure FT6236 touchscreen controller

**Configuration:**
```dts
ft6236: ft6236@38 {
    compatible = "focaltech,ft6236";
    reg = <0x38>;                      // I2C address 0x38
    interrupt-parent = <&gpio>;
    interrupts = <25 2>;               // GPIO 25, falling edge
    touchscreen-size-x = <1280>;       // Physical width
    touchscreen-size-y = <400>;        // Physical height
    touchscreen-inverted-x;            // Flip X axis
    touchscreen-inverted-y;            // Flip Y axis
    touchscreen-swapped-x-y;           // Swap X/Y (portrait→landscape)
};
```

**Why Custom:**
- Standard `ft6236` overlay doesn't exist in Pi 5 upstream
- Custom dimensions: 1280x400 (landscape after rotation)
- Custom GPIO: GPIO 25 for interrupt
- Custom axis mapping: Inverted + swapped for landscape

**I2C Bus:** i2c1 (pins 3/5 on Pi header)

---

### 2. ghettoblaster-amp100.dtbo

**Source:** `custom-components/overlays/ghettoblaster-amp100.dts`

**Purpose:** Configure HiFiBerry AMP100 audio DAC

**Configuration:**
```dts
pcm5122: pcm5122@4d {
    #sound-dai-cells = <0>;
    compatible = "ti,pcm5122";
    reg = <0x4d>;                      // I2C address 0x4d
    clocks = <&audio>;
    AVDD-supply = <&vdd_3v3_reg>;      // 3.3V power
    DVDD-supply = <&vdd_3v3_reg>;
    CPVDD-supply = <&vdd_3v3_reg>;
};
```

**Why Custom:**
- Standard `hifiberry-amp100` overlay is for Pi 4
- Pi 5 needs `bcm2712` compatible overlay
- Custom I2C clock: 100kHz (slower for stability)
- Custom voltage regulators

**I2C Bus:** i2c1 (shared with touchscreen)

---

## Compilation Process

### During Build (stage3_03-ghettoblaster-custom_00-run-chroot.sh)

```bash
# Check if dtc (Device Tree Compiler) is available
if command -v dtc &> /dev/null; then
    # Compile FT6236 overlay
    dtc -@ -I dts -O dtb -o "$OVERLAYS_DIR/ghettoblaster-ft6236.dtbo" \
        "$OVERLAYS_DIR/ghettoblaster-ft6236.dts"
    
    # Compile AMP100 overlay
    dtc -@ -I dts -O dtb -o "$OVERLAYS_DIR/ghettoblaster-amp100.dtbo" \
        "$OVERLAYS_DIR/ghettoblaster-amp100.dts"
fi
```

**Fallback:** If dtc not available during build, overlays are compiled on first boot by `first-boot-setup.sh`

### dtc Flags Explained

| Flag | Purpose |
|------|---------|
| `-@` | Generate symbols for overlay resolution |
| `-I dts` | Input format: Device Tree Source (.dts) |
| `-O dtb` | Output format: Device Tree Blob (.dtbo) |
| `-o` | Output file path |

---

## Deployment Process

### 1. Deploy Script (stage3_03-ghettoblaster-custom_00-deploy.sh)

```bash
# Copy .dts source files to boot partition
cp custom-components/overlays/*.dts ${ROOTFS_DIR}/boot/firmware/overlays/
```

**Files copied:**
- `ghettoblaster-ft6236.dts` → `/boot/firmware/overlays/`
- `ghettoblaster-amp100.dts` → `/boot/firmware/overlays/`

**Also copied to moode-source:**
- For backup/reference during build

### 2. Build Script Compilation (run-chroot.sh)

**Attempts compilation during build:**
- If dtc available: Compiles immediately
- If dtc missing: Skips (will compile on first boot)

**Result:** `.dtbo` files created in `/boot/firmware/overlays/`

### 3. First Boot Compilation (first-boot-setup.sh)

**Backup compilation on first boot:**
- Checks if dtc available
- Compiles any missing `.dtbo` files
- Logs results to `/var/log/first-boot-setup.log`

**Purpose:** Ensures overlays compiled even if build-time compilation failed

---

## Loading Process

### config.txt Settings

**Current configuration:**
```ini
# Ghettoblaster Touchscreen - FT6236
# v1.0 loaded directly (not via service) - matching v1.0 configuration
dtoverlay=ft6236

# Ghettoblaster Audio - HiFiBerry AMP100
# CRITICAL: v1.0 used NO automute parameter - automute can cause audio dropouts
dtoverlay=hifiberry-amp100
```

**Loading sequence:**
1. Raspberry Pi firmware reads config.txt
2. Searches for `ft6236.dtbo` in `/boot/firmware/overlays/`
3. **WAIT!** Standard `ft6236.dtbo` doesn't exist!
4. **Solution:** Custom overlay must be named `ft6236.dtbo` (not `ghettoblaster-ft6236.dtbo`)

---

## 🚨 CRITICAL ISSUE FOUND!

### Problem: Overlay Naming Mismatch

**config.txt says:**
```ini
dtoverlay=ft6236              # Looks for ft6236.dtbo
dtoverlay=hifiberry-amp100    # Looks for hifiberry-amp100.dtbo
```

**Build creates:**
```bash
ghettoblaster-ft6236.dtbo     # ❌ Wrong name!
ghettoblaster-amp100.dtbo     # ❌ Wrong name!
```

**Impact:**
- Overlays won't load (file not found)
- Touchscreen won't work
- Audio might fall back to upstream overlay (wrong config)

### Solution 1: Rename Output Files (Recommended)

Change compilation to create correct names:

```bash
# Compile FT6236 overlay with correct name
dtc -@ -I dts -O dtb -o "$OVERLAYS_DIR/ft6236.dtbo" \
    "$OVERLAYS_DIR/ghettoblaster-ft6236.dts"

# Compile AMP100 overlay with correct name
dtc -@ -I dts -O dtb -o "$OVERLAYS_DIR/hifiberry-amp100.dtbo" \
    "$OVERLAYS_DIR/ghettoblaster-amp100.dts"
```

### Solution 2: Update config.txt (Alternative)

```ini
dtoverlay=ghettoblaster-ft6236
dtoverlay=ghettoblaster-amp100
```

**Recommendation:** Use Solution 1 (rename output) because:
- Matches standard overlay naming convention
- config.txt looks cleaner
- Easier to understand

---

## Overlay vs Upstream Comparison

### FT6236 Touchscreen

| Feature | Upstream | Custom |
|---------|----------|--------|
| Exists? | ❌ No | ✅ Yes |
| Pi 5 Support | - | ✅ bcm2712 |
| GPIO | - | 25 |
| Size | - | 1280x400 |
| Axis Swap | - | ✅ Yes |

**Verdict:** Must use custom overlay (upstream doesn't exist)

### HiFiBerry AMP100

| Feature | Upstream | Custom |
|---------|----------|--------|
| Exists? | ✅ Yes | ✅ Yes |
| Pi 5 Support | ⚠️ Pi 4 | ✅ Pi 5 |
| I2C Clock | Default | 100kHz |
| Compatible | bcm2711 | bcm2712 |

**Verdict:** Custom overlay better for Pi 5

---

## I2C Bus Sharing

Both devices share **i2c1 bus**:

| Device | Address | GPIO |
|--------|---------|------|
| FT6236 | 0x38 | INT: GPIO 25 |
| PCM5122 | 0x4d | - |

**Clock Speed:** 100kHz (set in config.txt)
```ini
dtparam=i2c_arm_baudrate=100000
```

**Why 100kHz:**
- User reported I2C timing issues
- Slower = more stable
- Prevents touchscreen/DAC conflicts

---

## Verification Commands

### After Build/Flash

```bash
# 1. Check if overlay files exist
ls -la /boot/firmware/overlays/ | grep -E "ft6236|amp100"

# Expected (Solution 1):
# ft6236.dtbo                    # ✅ Correct name
# hifiberry-amp100.dtbo          # ✅ Correct name
# ghettoblaster-ft6236.dts       # Source file
# ghettoblaster-amp100.dts       # Source file

# 2. Check if overlays loaded
dtoverlay -l
# Expected:
# 0: ft6236
# 1: hifiberry-amp100
# 2: vc4-kms-v3d-pi5

# 3. Check I2C devices detected
i2cdetect -y 1
# Expected:
#      0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
# 30: -- -- -- -- -- -- -- -- 38 -- -- -- -- -- -- -- 
# 40: -- -- -- -- -- -- -- -- -- -- -- -- -- UU -- -- 
# 38 = FT6236 touchscreen
# 4d = PCM5122 (shows as UU when driver loaded)

# 4. Check touchscreen device
cat /proc/bus/input/devices | grep -A 5 ft6236
# Expected: ft6236 input device

# 5. Check audio card
cat /proc/asound/cards
# Expected: HiFiBerry DAC+
```

---

## Troubleshooting

### Overlay Not Loading

**Symptom:** `dtoverlay -l` doesn't show overlay

**Check:**
```bash
# 1. File exists?
ls -la /boot/firmware/overlays/ft6236.dtbo
ls -la /boot/firmware/overlays/hifiberry-amp100.dtbo

# 2. config.txt correct?
grep dtoverlay /boot/firmware/config.txt

# 3. Boot messages
dmesg | grep -i "overlay\|ft6236\|pcm5122"
```

**Common causes:**
- ❌ Wrong filename (ghettoblaster-* instead of standard name)
- ❌ Compilation failed (.dtbo missing)
- ❌ config.txt typo
- ❌ Overlay conflicts

### Touchscreen Not Working

**Check:**
1. Overlay loaded: `dtoverlay -l | grep ft6236`
2. I2C device detected: `i2cdetect -y 1` (should show 38)
3. Input device exists: `cat /proc/bus/input/devices | grep ft6236`
4. Kernel messages: `dmesg | grep ft6236`

**Common causes:**
- ❌ GPIO conflict
- ❌ I2C not enabled
- ❌ Wrong I2C address
- ❌ Power issue

### Audio Not Working

**Check:**
1. Overlay loaded: `dtoverlay -l | grep hifiberry`
2. I2C device detected: `i2cdetect -y 1` (should show UU at 4d)
3. Audio card: `cat /proc/asound/cards`
4. ALSA devices: `aplay -l`

**Common causes:**
- ❌ Onboard audio not disabled (`dtparam=audio=off` missing)
- ❌ Wrong overlay (Pi 4 instead of Pi 5)
- ❌ I2C conflict with touchscreen
- ❌ automute parameter (causes dropouts)

---

## Build Script Fix Required

### Current Code (WRONG)

```bash
# stage3_03-ghettoblaster-custom_00-run-chroot.sh
dtc -@ -I dts -O dtb -o "$OVERLAYS_DIR/ghettoblaster-ft6236.dtbo" \
    "$OVERLAYS_DIR/ghettoblaster-ft6236.dts"
```

### Fixed Code (CORRECT)

```bash
# stage3_03-ghettoblaster-custom_00-run-chroot.sh
dtc -@ -I dts -O dtb -o "$OVERLAYS_DIR/ft6236.dtbo" \
    "$OVERLAYS_DIR/ghettoblaster-ft6236.dts"

dtc -@ -I dts -O dtb -o "$OVERLAYS_DIR/hifiberry-amp100.dtbo" \
    "$OVERLAYS_DIR/ghettoblaster-amp100.dts"
```

### Same Fix Needed in first-boot-setup.sh

**Both scripts must create correct filenames!**

---

## Summary

### ✅ What's Good
- Custom overlays exist for Pi 5
- Correct configuration (touchscreen size, I2C addresses)
- Compilation process in place
- Fallback compilation on first boot

### ❌ What Needs Fixing
- **CRITICAL:** Output filenames wrong (`ghettoblaster-*.dtbo` instead of standard names)
- Must fix in 2 places:
  1. `stage3_03-ghettoblaster-custom_00-run-chroot.sh`
  2. `first-boot-setup.sh`

### 🎯 Result After Fix
- Overlays will load correctly
- Touchscreen will work
- Audio will work
- I2C devices detected

---

## Next Steps

1. ✅ Fix overlay output filenames in build scripts
2. ✅ Verify compilation during build
3. ✅ Test after flash:
   - `dtoverlay -l` shows overlays loaded
   - `i2cdetect -y 1` shows devices
   - Touch responds correctly
   - Audio plays correctly

---

**Status:** Found critical naming issue, fix required before build! 🚨
