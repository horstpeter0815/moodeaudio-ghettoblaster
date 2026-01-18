# Device Tree Overlay Master Reference

**System:** Ghettoblaster (Raspberry Pi 5)  
**Date:** January 18, 2026  
**Status:** Complete Phase 1 & 2 Analysis

---

## Table of Contents

1. [Overview](#overview)
2. [Layers: Hardware vs Software](#layers-hardware-vs-software)
3. [Overlays In Use](#overlays-in-use)
4. [Detailed Analysis](#detailed-analysis)
5. [Parameter Reference](#parameter-reference)
6. [Common Mistakes](#common-mistakes)
7. [Validation Results](#validation-results)

---

## Overview

This document provides a complete technical reference for all Device Tree Overlays (DTOs) used in the Ghettoblaster system. Device Tree Overlays are binary files (.dtbo) compiled from source (.dts) that configure hardware at boot time.

### What Are Device Tree Overlays?

**Purpose:** Initialize hardware without kernel modifications

**Format:**
```ini
dtoverlay=<overlay-name>,<param1>=<value1>,<param2>=<value2>
dtparam=<parameter>=<value>
```

**Location:** `/boot/firmware/overlays/` (compiled .dtbo files)

**Loaded by:** Raspberry Pi firmware during boot (before kernel starts)

---

## Layers: Hardware vs Software

Understanding the correct layer for each configuration is critical to avoid common mistakes.

### What Device Tree CONTROLS (Hardware Layer)

- I2C devices (addresses, drivers, power supplies)
- I2S audio interfaces
- GPIO assignments
- Clock sources and frequencies
- Hardware interrupts
- Device power supplies (AVDD, DVDD, CPVDD)
- Hardware features (auto-mute on amplifier)

### What Device Tree DOES NOT CONTROL (Software Layer)

- ALSA audio routing (software plugins)
- ALSA device names (iec958, camilladsp, etc.)
- MPD configuration
- moOde database settings
- X11 display rotation (xrandr)
- Chromium browser settings
- Volume levels
- CamillaDSP filters

### Layer Diagram

```
Boot Time (Device Tree):
├── config.txt → loads overlays
├── Overlays → initialize hardware
└── Hardware → ready for drivers

Runtime (Software):
├── Kernel drivers → use initialized hardware
├── ALSA → audio routing
├── moOde → settings management
└── Applications → MPD, X11, etc.
```

---

## Overlays In Use

### Verified Working Configuration (v1.0)

From git commit `84aa8c2` (January 8, 2026):

```ini
# Display
dtoverlay=vc4-kms-v3d,noaudio

# Audio
dtoverlay=hifiberry-amp100

# Touch
dtoverlay=ft6236

# I2C Configuration
dtparam=i2c_arm=on
dtparam=i2s=on
dtparam=audio=off
```

**Note:** `vc4-kms-v3d-pi5` and `vc4-kms-v3d` both work on Pi 5. Working config uses `vc4-kms-v3d` without `-pi5` suffix.

---

## Detailed Analysis

### 1. HiFiBerry AMP100 Audio Overlay

**Overlay Name:** `hifiberry-amp100`

**Purpose:** Configure PCM5122 DAC and I2S interface for HiFiBerry AMP100 amplifier (2x50W Class D)

#### Hardware Configured

**I2C Device:**
- **Chip:** TI PCM5122 DAC
- **I2C Address:** 0x4d (on I2C1)
- **Compatible String:** `ti,pcm5122`
- **Driver:** `snd-soc-pcm512x` (kernel module)

**I2S Interface:**
- **Pi 5 Path:** `/axi/pcie@1000120000/rp1/i2s@a4000`
- **Controller:** DesignWare I2S (RP1 chip on Pi 5)
- **Format:** I2S standard

**Power Supplies:**
- **AVDD:** Analog power (3.3V from `vdd_3v3_reg`)
- **DVDD:** Digital power (3.3V from `vdd_3v3_reg`)
- **CPVDD:** Charge pump power (3.3V from `vdd_3v3_reg`)

**Clock Source:**
- Custom clock generator: `dacpro_osc`
- Compatible: `hifiberry,dacpro-clk`

#### Fragment Breakdown

**Custom Overlay:** `custom-components/overlays/ghettoblaster-amp100.dts`

```dts
fragment@0:
  Target: &i2c1
  Purpose: Configure PCM5122 on I2C1
  - Sets I2C clock to 100kHz
  - Defines PCM5122 at address 0x4d
  - Assigns power supplies
  
fragment@1:
  Target: &sound
  Purpose: Create sound card
  - Compatible: "hifiberry,hifiberry-amp"
  - Links to I2S controller
```

**Advanced Overlay:** `hifiberry-amp100-pi5-dsp-reset.dts` (not currently used)

This version includes `__overrides__` section with configurable parameters:

```dts
fragment@0:
  Target: "/" (root)
  Purpose: Create clock source
  - dacpro_osc clock generator

fragment@1:
  Target: /axi/pcie@1000120000/rp1/i2s@a4000
  Purpose: Enable Pi 5 I2S controller
  
fragment@2:
  Target: &i2c1
  Purpose: Configure PCM5122
  - Uses dacpro_osc clock
  
fragment@3:
  Target: /axi
  Purpose: Create sound node
  - Compatible: "hifiberry,hifiberry-dacplus"
  - No GPIO reset (avoids conflicts)
```

#### Available Parameters

From `__overrides__` section (in advanced overlay):

| Parameter | Type | Default | Description | Example Usage |
|-----------|------|---------|-------------|---------------|
| `auto_mute` | boolean | false | Enable auto-mute when no audio signal | `dtparam=auto_mute` |
| `24db_digital_gain` | boolean | false | Enable 24dB digital gain boost | `dtoverlay=hifiberry-amp100,24db_digital_gain` |
| `leds_off` | boolean | false | Disable status LEDs | `dtoverlay=hifiberry-amp100,leds_off` |
| `mute_ext_ctl` | integer | none | GPIO for external mute control | `dtoverlay=hifiberry-amp100,mute_ext_ctl=14` |

**Important:** The simple `ghettoblaster-amp100.dts` does NOT have `__overrides__` section, so these parameters won't work unless using the advanced overlay.

#### ALSA Configuration (Software Layer)

Device tree creates hardware, but ALSA configuration is separate:

**ALSA Card Name:** `sndrpihifiberry`  
**ALSA Device:** `plughw:0,0` or `plughw:1,0` (depends on card number)  
**NOT configured by device tree:** IEC958, camilladsp routing

---

### 2. FT6236 Touch Controller Overlay

**Overlay Name:** `ft6236`

**Purpose:** Configure Focaltech FT6236 capacitive touch controller for 1280x400 landscape touchscreen

#### Hardware Configured

**I2C Device:**
- **Chip:** Focaltech FT6236
- **I2C Address:** 0x38 (on I2C1)
- **Compatible String:** `focaltech,ft6236`
- **Driver:** `ft6236` (kernel module)

**GPIO Interrupt:**
- **GPIO Pin:** 25
- **Mode:** Falling edge (interrupt flag: 2)
- **Purpose:** Notify CPU of touch events

**Touch Parameters:**
- **Physical Display:** 400x1280 (portrait)
- **Touchscreen Size:** 1280x400 (landscape - swapped)
- **Inversions:** X and Y inverted
- **Swap:** X-Y axes swapped

#### Fragment Breakdown

**Source:** `custom-components/overlays/ghettoblaster-ft6236.dts`

```dts
fragment@0:
  Target: &i2c1
  Purpose: Configure FT6236 touch controller
  - I2C address: 0x38
  - Interrupt on GPIO 25
  - Touch parameters for landscape orientation
```

#### Touch Parameters Explained

The Waveshare 7.9" display is physically 400x1280 (portrait), but we want landscape orientation:

```
Physical Display: 400x1280 (tall)
Desired Orientation: 1280x400 (wide)

Touch Configuration:
- touchscreen-size-x = 1280  (width in landscape)
- touchscreen-size-y = 400   (height in landscape)
- touchscreen-inverted-x     (flip X axis)
- touchscreen-inverted-y     (flip Y axis)
- touchscreen-swapped-x-y    (swap axes for rotation)
```

This converts portrait touch coordinates to landscape screen coordinates.

#### No Override Parameters

This overlay has no `__overrides__` section - all configuration is fixed.

**To modify:** Must edit .dts source and recompile.

#### Integration Note

According to documentation, this overlay may be loaded via systemd service (`ft6236-delay.service`) rather than directly in config.txt. This allows delayed loading after I2C bus is stable.

---

### 3. VC4 KMS Display Overlay

**Overlay Name:** `vc4-kms-v3d` or `vc4-kms-v3d-pi5`

**Purpose:** Enable Kernel Mode Setting (KMS) for modern display pipeline with hardware acceleration

#### Hardware Configured

**Display Controller:**
- **VC4 (VideoCore IV):** GPU display controller
- **KMS:** Kernel Mode Setting (modern display driver)
- **DRM:** Direct Rendering Manager
- **V3D:** 3D graphics acceleration

**HDMI Output:**
- Enables HDMI display detection
- Configures framebuffer
- Handles resolution and timing

#### Pi 5 vs Pi 4 Variants

**`vc4-kms-v3d-pi5`:**
- Pi 5 specific version
- Uses updated RP1 I/O controller
- Optimized for Pi 5 hardware

**`vc4-kms-v3d`:**
- Generic version
- Works on Pi 4 and Pi 5
- Used in verified v1.0 config

**Recommendation:** Both work on Pi 5. Use `vc4-kms-v3d` for compatibility unless Pi 5-specific features needed.

#### Available Parameters

| Parameter | Type | Default | Description | Example Usage |
|-----------|------|---------|-------------|---------------|
| `noaudio` | boolean | false | Disable HDMI audio output | `dtoverlay=vc4-kms-v3d,noaudio` |
| `audio` | boolean | false | Enable HDMI audio (conflicts with HAT) | `dtoverlay=vc4-kms-v3d,audio` |

**Critical:** Use `noaudio` when using audio HAT (HiFiBerry) to prevent HDMI audio conflicts.

#### Display Rotation

**Device tree does NOT control display rotation.**

Display rotation requires:
1. **Boot framebuffer:** `cmdline.txt` with `video=` parameter
2. **X11 runtime:** `xrandr` commands in `.xinitrc`

**Incorrect:** Expecting `dtoverlay` to rotate display  
**Correct:** Use `cmdline.txt` for boot, `xrandr` for X11

---

## Parameter Reference

### Quick Reference Table

Complete list of all available parameters across all overlays:

| Overlay | Parameter | Type | Purpose | Usage |
|---------|-----------|------|---------|-------|
| hifiberry-amp100 | auto_mute | bool | Auto-mute amplifier | `dtparam=auto_mute` |
| hifiberry-amp100 | 24db_digital_gain | bool | Boost digital gain | `dtoverlay=hifiberry-amp100,24db_digital_gain` |
| hifiberry-amp100 | leds_off | bool | Disable LEDs | `dtoverlay=hifiberry-amp100,leds_off` |
| hifiberry-amp100 | mute_ext_ctl | int | External mute GPIO | `dtoverlay=hifiberry-amp100,mute_ext_ctl=14` |
| vc4-kms-v3d | noaudio | bool | Disable HDMI audio | `dtoverlay=vc4-kms-v3d,noaudio` |
| vc4-kms-v3d | audio | bool | Enable HDMI audio | `dtoverlay=vc4-kms-v3d,audio` |
| ft6236 | *(none)* | - | No parameters | Fixed configuration |

### dtparam vs dtoverlay

**dtparam:**
- Sets individual parameters
- Affects most recent overlay
- Example: `dtparam=auto_mute`

**dtoverlay:**
- Loads entire overlay
- Can include parameters inline
- Example: `dtoverlay=hifiberry-amp100,auto_mute`

**Equivalent:**
```ini
# Method 1: inline parameter
dtoverlay=hifiberry-amp100,auto_mute

# Method 2: separate dtparam
dtoverlay=hifiberry-amp100
dtparam=auto_mute
```

---

## Common Mistakes

### 1. Making Up Parameters That Don't Exist

**Mistake:** `dtparam=disable_iec958`

**Why it's wrong:**
- IEC958 is NOT a device tree parameter
- IEC958 is an ALSA software plugin (S/PDIF digital audio)
- Device tree only configures hardware (I2S interface)
- ALSA routing is software layer

**Correct approach:**
- Device tree: Configure I2S hardware
- ALSA: Route audio through correct plugins
- moOde: Set `alsa_output_mode=plughw` (not iec958)

### 2. Expecting Device Tree to Control Software

**Mistake:** Trying to fix ALSA routing with device tree parameters

**Why it's wrong:**
- Device tree: Hardware initialization only
- ALSA: Software configuration files (`/etc/alsa/conf.d/`)
- MPD: Application settings
- moOde: Database settings

**Correct layering:**
```
Hardware Problem → Device Tree Solution
Software Problem → Software Configuration Solution
```

### 3. Confusing Display Rotation Layers

**Mistake:** Expecting `dtoverlay=vc4-kms-v3d` to rotate display

**Why it's wrong:**
- Device tree enables display controller
- Rotation requires:
  - Boot: `cmdline.txt` with `video=HDMI-A-1:400x1280M@60,rotate=90`
  - X11: `xrandr --output HDMI-2 --rotate left`

**Layer breakdown:**
- Device tree: Enable HDMI hardware
- cmdline.txt: Set kernel framebuffer resolution/rotation
- X11: Runtime display rotation

### 4. Not Checking if Parameters Exist

**Mistake:** Using parameters without verifying they exist in `__overrides__`

**Correct approach:**
1. Read the .dts source file
2. Look for `__overrides__` section
3. Verify parameter exists
4. Check parameter syntax (boolean vs integer)

**Example verification:**
```bash
# Find overlay source
cat /boot/firmware/overlays/README | grep -A 20 "hifiberry-amp100"

# Check parameter in source
grep "__overrides__" hifiberry-amp100.dts
```

### 5. Using Wrong Compatible Strings

**Mistake:** Mixing Pi 4 and Pi 5 overlays

**Why it matters:**
- Pi 5: `compatible = "brcm,bcm2712"`
- Pi 4: `compatible = "brcm,bcm2711"`
- I2S paths are different
- Device tree structure changed

**Correct approach:**
- Check Pi model: `cat /proc/device-tree/compatible`
- Use matching overlays
- Pi 5 I2S: `/axi/pcie@1000120000/rp1/i2s@a4000`

---

## Validation Results

### Phase 4: Hardware Testing

**Status:** Pending - requires Pi access

**Tests to perform:**

#### 1. Auto-Mute Parameter Test

**Procedure:**
```bash
# Add to config.txt
dtparam=auto_mute

# Reboot
sudo reboot

# Test
1. Play audio
2. Stop audio
3. Observe amplifier behavior
4. Measure GPIO states with multimeter
```

**Expected result:** Amplifier mutes after ~3 seconds of silence

#### 2. I2C Device Detection

**Procedure:**
```bash
# Check I2C bus
i2cdetect -y 1

# Expected devices:
# 0x4d - PCM5122 DAC
# 0x38 - FT6236 Touch
```

#### 3. Sound Card Verification

**Procedure:**
```bash
# Check ALSA cards
cat /proc/asound/cards
aplay -l

# Expected:
# card 0 or 1: sndrpihifiberry [HifiberryDacp]
```

#### 4. Touch Input Verification

**Procedure:**
```bash
# Check input devices
cat /proc/bus/input/devices | grep -A 5 "ft6236"

# Test touch events
evtest /dev/input/eventX

# Verify coordinates match 1280x400 landscape
```

#### 5. Display Output

**Procedure:**
```bash
# Check framebuffer
cat /sys/class/graphics/fb0/virtual_size

# Check X11 display
DISPLAY=:0 xrandr | grep connected

# Expected: 1280x400 landscape
```

---

## Summary

### Overlays Used in Ghettoblaster v1.0

1. **vc4-kms-v3d,noaudio** - Display controller with HDMI audio disabled
2. **hifiberry-amp100** - PCM5122 DAC and I2S audio
3. **ft6236** - Capacitive touch controller

### Critical Learnings

1. Device tree configures **hardware only**
2. Software (ALSA, moOde) is **separate layer**
3. Display rotation needs **cmdline.txt + X11**
4. Always **verify parameters exist** in `__overrides__`
5. IEC958 is **ALSA software**, not device tree

### Files Created

- This master reference: `WISSENSBASIS/DEVICE_TREE_MASTER_REFERENCE.md`
- Individual overlay docs: (Phase 5 - to be created)
- RAG upload files: (Phase 6 - to be created)

---

**Next Steps:**
- Phase 3: Compare with stock Raspberry Pi overlays
- Phase 4: Validate on actual Pi hardware
- Phase 5: Create individual overlay documentation
- Phase 6: Integrate to Ghetto AI knowledge base

**Document Status:** Phase 1 & 2 Complete  
**Last Updated:** January 18, 2026
