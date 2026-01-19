# Phase 4 Hardware Validation Results

**Date:** 2026-01-18
**System:** Ghettoblaster - Raspberry Pi 5 with moOde
**User:** andre

## Critical Discovery: Actual Working Configuration

### Config.txt (Actual Working Setup)

```ini
dtoverlay=vc4-kms-v3d,noaudio          # ⚠️ NOT pi5 version!
dtparam=i2c_arm=on
dtparam=i2s=on
dtparam=audio=off
dtparam=fan_temp0=50000,fan_temp0_hyst=5000,fan_temp0_speed=75
dtoverlay=hifiberry-amp100
dtoverlay=ft6236                        # Touch overlay loaded at boot
```

### Key Findings

#### 1. Display Overlay - UNEXPECTED

**Expected:** `dtoverlay=vc4-kms-v3d-pi5,noaudio` (Pi 5 version)
**Actually Using:** `dtoverlay=vc4-kms-v3d,noaudio` (Pi 4 version)

**Status:** ✅ Working despite using "wrong" overlay
**Conclusion:** Pi 5 can use Pi 4 overlay (backwards compatible)

#### 2. Audio - WORKING PERFECTLY

**I2C Detection:**
```
40: -- -- -- -- -- -- -- -- -- -- -- -- UU -- --
```
- `0x4d` showing as `UU` = Driver actively using PCM5122 DAC ✅

**Sound Card:**
```
1 [sndrpihifiberry]: HifiberryDacp - snd_rpi_hifiberry_dacplus
```

**Drivers Loaded:**
- `snd_soc_hifiberry_dacplus` ✅
- `clk_hifiberry_dacpro` ✅
- `snd_soc_pcm512x` ✅

**Status:** ✅ Audio fully functional

#### 3. Touch Controller - MYSTERIOUS

**Config shows:** `dtoverlay=ft6236` (loaded at boot)
**I2C scan:** No 0x38 detected
**Driver loaded:** NO ft6236 driver in lsmod
**User report:** Touch IS working

**Possible explanations:**
1. Touch driver built into kernel (not a module)
2. Touch uses different I2C bus
3. Touch detected via different mechanism (not FT6236 overlay)

**Need to check:**
```bash
# Check if touch is actually working
xinput list

# Check touch driver in kernel
dmesg | grep -i touch

# Check all input devices
cat /proc/bus/input/devices | grep -A 5 "touchscreen\|touch"
```

#### 4. I2C Bus Speed

**Boot messages show:** `@97500hz` (97.5kHz)
**Not the expected:** 100kHz

**Actual I2C clock:** ~97.5kHz (slightly under 100kHz - normal variance)

#### 5. Boot Sequence (I2C Timing Issue)

User mentioned: "touchscreen wants to initialize before display = I2C failures"

**Current solution:** Touch overlay IN config.txt (not systemd service)
**But:** Touch driver not showing as loaded module
**Result:** No I2C timing conflict (touch not actually probing at boot?)

## Hardware Validation Summary

### ✅ Working Components

| Component | Status | Evidence |
|-----------|--------|----------|
| Display (VC4 KMS) | ✅ Working | vc4 driver loaded, DRM devices present |
| PCM5122 DAC | ✅ Working | I2C 0x4d detected (UU), driver loaded |
| HiFiBerry Sound Card | ✅ Working | sndrpihifiberry card present |
| I2S Audio | ✅ Working | designware_i2s loaded |
| I2C Bus | ✅ Working | @97500hz, detecting devices |

### ⚠️ Unclear/Need More Info

| Component | Status | Question |
|-----------|--------|----------|
| FT6236 Touch | ⚠️ Works but how? | Overlay loaded, but no driver module, no I2C detection |
| Display Overlay | ⚠️ Using "wrong" one | Pi 4 overlay works on Pi 5? |

### ❌ Expected But Not Found

- FT6236 at I2C address 0x38
- ft6236 kernel module
- vc4-kms-v3d-pi5 overlay (using pi4 version instead)

## Device Tree Parameters Analysis

### Parameters Actually Used

Based on config.txt:

1. **vc4-kms-v3d:** `noaudio` parameter
   - ✅ Confirmed working (HDMI audio disabled)
   - Evidence: `'dmas' DT property is missing or empty, no HDMI audio`

2. **hifiberry-amp100:** No parameters
   - Default configuration
   - No auto_mute, no 24db_digital_gain

3. **ft6236:** No parameters
   - Default configuration

### Parameters NOT Used (Available for Testing)

**For hifiberry-amp100:**
- `auto_mute` - Test muting on silence
- `24db_digital_gain` - Test gain boost
- `leds_off` - Test LED control

## Test Plan: Parameters to Validate

### Test 1: Current State Verification

**Objective:** Document baseline before any changes

**Commands to run:**
```bash
# Check ALSA controls
amixer -c 0 scontrols

# Check if auto-mute control exists
amixer sget 'Auto Mute' 2>/dev/null || echo "Auto Mute not available"

# Check current volume
mpc volume

# Check MPD status
mpc status
```

### Test 2: Touch Investigation

**Objective:** Find out how touch is actually working

**Commands to run:**
```bash
# 1. Check X11 input devices
xinput list

# 2. Check touch events
cat /proc/bus/input/devices

# 3. Check touch driver in kernel messages
dmesg | grep -i "touch\|ft6236\|focaltech"

# 4. Check device tree touch node
ls -la /sys/firmware/devicetree/base/*/ft6236* 2>/dev/null || echo "No FT6236 DT node"

# 5. Check if libinput detected it
libinput list-devices 2>/dev/null || echo "libinput not available"
```

### Test 3: Display Overlay Mystery

**Objective:** Understand why Pi 4 overlay works on Pi 5

**Check:**
```bash
# What overlay is actually loaded
ls -la /sys/kernel/config/device-tree/overlays/

# Decompile loaded overlay
dtc -I fs /sys/firmware/devicetree 2>/dev/null | grep -A 5 "vc4\|hdmi"
```

## Comparison: Documentation vs Reality

### Documentation Said

From device tree study:
- ✅ Must use `vc4-kms-v3d-pi5` on Pi 5
- ✅ Touch overlay not in config (loaded via systemd)
- ✅ I2C clock should be 100kHz

### Reality Shows

- ⚠️ Using `vc4-kms-v3d` (Pi 4 version) - works fine
- ⚠️ Touch overlay IS in config.txt
- ✅ I2C clock is ~97.5kHz (close enough)

### Why Documentation Was Wrong

**Assumption:** Pi 5 requires Pi 5-specific overlays
**Reality:** Pi 5 has backward compatibility with Pi 4 overlays (at least for vc4-kms)

**Assumption:** Touch must load via systemd to avoid I2C timing issues
**Reality:** Touch overlay in config.txt but driver doesn't probe immediately (avoids race condition)

## I2C Timing Issue - User's Solution

**Problem:** Touch initializing before display → I2C failures

**Expected solution:** Load touch via systemd service after display ready

**Actual solution:** Touch overlay in config.txt BUT:
- Overlay loads at boot
- Driver doesn't actually probe device (no module loaded)
- Touch works anyway (different mechanism?)

**This suggests:** Touch is handled by different subsystem, not FT6236 overlay/driver

## Next Steps

1. **Investigate touch mystery** - Run Test 2 commands
2. **Test auto_mute parameter** - Add to hifiberry-amp100
3. **Test 24db_digital_gain** - Verify gain increase
4. **Document why Pi 4 overlay works** - Backward compatibility
5. **Update device tree documentation** - Add Pi 5 backward compat info

## Critical Learnings

1. **Pi 5 backward compatibility** - Can use Pi 4 overlays (at least some)
2. **Touch mechanism unclear** - Working without visible driver
3. **Actual config differs from expectations** - Real hardware shows different solutions
4. **Documentation assumptions wrong** - Hardware testing reveals truth

## Status

- ✅ Phase 4.1 Complete - Hardware validated
- ⏳ Phase 4.2 Pending - Need touch investigation
- ⏳ Phase 4.3 Pending - Parameter testing (auto_mute, 24db_digital_gain)
- ⏳ Phase 4.5 In Progress - Documenting results
- ⏳ Phase 4.6 Pending - Final recommendations

**Next:** Run touch investigation commands to solve the mystery!
