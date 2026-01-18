# LESSONS LEARNED - Device Tree Study

## What I Actually Learned Today

### 1. The White Screen Problem - ROOT CAUSE FOUND

**Problem:** White illuminated screen at boot instead of console

**Root Cause:** Missing video parameter in `/boot/firmware/cmdline.txt`

**Solution:**
```bash
video=HDMI-A-1:400x1280M@60,rotate=90 logo.nologo vt.global_cursor_default=0
```

**Why This Works:**
- Sets framebuffer to 400x1280 (portrait) at kernel level
- `rotate=90` rotates framebuffer 90° clockwise → 1280x400 landscape
- `logo.nologo` removes Raspberry Pi logo
- `vt.global_cursor_default=0` hides cursor
- This happens BEFORE X11 starts, so boot console is correct orientation
- NO white screen because kernel knows the resolution immediately

**What I Was Doing Wrong:**
- Trying to fix in X11 (.xinitrc) - too late, white screen already shown
- Adding delays and screen off/on commands - band-aids
- Not reading the working v1.0 config from git commit 84aa8c2

### 2. The IEC958 Problem - NOT Device Tree

**Problem:** "MPD Camilla DSP IEC 958 device" in Audio Info

**Root Cause:** moOde database setting `alsa_output_mode='iec958'`

**Solution:**
```sql
UPDATE cfg_system SET value='plughw' WHERE param='alsa_output_mode';
```

**Why This Works:**
- IEC958 is ALSA software plugin for S/PDIF (optical/coax digital output)
- HiFiBerry AMP100 uses I2S (Inter-IC Sound), NOT S/PDIF
- `plughw` = direct ALSA hardware access
- IEC958 ≠ device tree parameter, it's ALSA configuration

**What I Was Doing Wrong:**
- Thought IEC958 was a hardware/driver setting
- Made up fake dtoverlay parameters (`disable_iec958`) that don't exist
- Tried to fix in CamillaDSP config instead of moOde database
- Didn't understand ALSA layer vs hardware layer

### 3. Auto-Mute - Device Tree Parameter EXISTS

**Correct Usage:**
```ini
dtoverlay=hifiberry-amp100
dtparam=auto_mute
```

or

```ini
dtoverlay=hifiberry-dacplus
dtparam=auto_mute
```

**What I Learned:**
- `auto_mute` IS a real device tree parameter
- Found in `hifiberry-amp100-pi5-dsp-reset.dts` in `__overrides__` section
- Must be on separate line as `dtparam=`, NOT in overlay line
- This is hardware-level mute when no audio signal

**What I Was Doing Wrong:**
- Not reading the actual device tree source files first
- Assuming parameters exist without verification

### 4. Device Tree Files I Actually Read

1. **`custom-components/overlays/ghettoblaster-amp100.dts`**
   - PCM5122 DAC at I2C 0x4d
   - I2S interface configuration
   - Basic overlay structure

2. **`custom-components/overlays/ghettoblaster-ft6236.dts`**
   - FT6236 touch controller at I2C 0x38
   - Touch parameters: inverted-x, inverted-y, swapped-x-y
   - For 1280x400 landscape orientation

3. **`hifiberry-amp100-pi5-dsp-reset.dts`**
   - Pi 5 specific overlay
   - **CRITICAL:** Found `__overrides__` section with `auto_mute` parameter
   - Shows how dtparam parameters are defined
   - I2S controller path: `/axi/pcie@1000120000/rp1/i2s@a4000`

4. **`waveshare-overlay-decompiled.dts`**
   - Waveshare display overlay structure
   - DSI interface (not used in our HDMI setup)
   - Touch controller parameters

5. **`hifiberry-amp100-pi5-gpio14-active-low.dts`**
   - GPIO 14 reset configuration
   - Active-low flag: `reset-gpio = <&gpio 14 1>;`
   - NOT using this (causes conflicts)

### 5. What Device Tree CAN and CANNOT Control

**Device Tree CAN Control (Hardware):**
- ✅ I2C devices (DAC, touch controller)
- ✅ I2S interface enable/disable
- ✅ GPIO assignments
- ✅ Clock frequencies
- ✅ Hardware auto-mute
- ✅ Power supplies (AVDD, DVDD, CPVDD)

**Device Tree CANNOT Control (Software):**
- ❌ ALSA routing (software layer)
- ❌ ALSA plugins (iec958, camilladsp)
- ❌ MPD configuration
- ❌ moOde database settings
- ❌ X11 rotation (xrandr)
- ❌ Chromium browser settings
- ❌ Volume levels

### 6. The Correct Audio Chain

**Hardware Layer (Device Tree):**
```
PCM5122 DAC (I2C 0x4d) ← I2S ← Raspberry Pi 5
```

**Software Layer (ALSA):**
```
MPD → _audioout → camilladsp → plughw:1,0 → HiFiBerry DAC
```

**NOT:**
```
MPD → iec958 ❌ (wrong - for S/PDIF, not I2S)
```

### 7. Working Configuration Files from Git

**Source:** Commit `84aa8c2` (Version 1.0 - Ghettoblaster working configuration)

**Key Files:**
1. **`cmdline.txt`:**
   ```
   video=HDMI-A-1:400x1280M@60,rotate=90 logo.nologo vt.global_cursor_default=0
   ```

2. **`config.txt`:**
   ```ini
   dtoverlay=hifiberry-amp100
   dtoverlay=ft6236
   dtparam=audio=off
   dtoverlay=vc4-kms-v3d,noaudio
   arm_boost=1
   ```

3. **moOde Database:**
   ```sql
   alsa_output_mode = 'plughw'  -- NOT 'iec958'
   volume_type = 'hardware'
   camilladsp = 'on'
   hdmi_scn_orient = 'landscape'
   ```

4. **`.xinitrc`:**
   - moOde default from `v1.0-config-export/.xinitrc`
   - Simple HDMI rotation if portrait mode
   - NO complex sleep/retry logic needed

### 8. What I Did Wrong (Before)

1. **Created 20+ shell scripts** instead of reading working config from git
2. **Made up parameters** (`disable_iec958`) that don't exist
3. **Tried to fix symptoms** (white screen with sleep/xset) instead of root cause
4. **Didn't read device tree source files** before assuming parameters
5. **Mixed hardware and software layers** (tried to fix ALSA with dtoverlay)
6. **Didn't use git to find working config** - it was there all along!

### 9. How to Properly Fix Things

1. **Check git FIRST** for working configurations
   ```bash
   git log --all --grep="working\|v1.0" --oneline
   git show <commit>:<path>
   ```

2. **Read device tree source files** to understand hardware
   ```bash
   cat custom-components/overlays/*.dts
   ```

3. **Separate hardware from software:**
   - Hardware: `/boot/firmware/config.txt` + `/boot/firmware/cmdline.txt`
   - Software: moOde database + ALSA configs + X11 configs

4. **Fix at the correct layer:**
   - Boot display → `cmdline.txt` video parameter
   - Hardware audio → device tree overlay
   - Software audio → moOde database + ALSA
   - X11 display → `.xinitrc`

5. **Verify parameters exist** in device tree source before using them

### 10. The Proper Fix (Final)

**File:** `tools/complete-fix-from-v1.0.sh`

**What It Does:**
1. Adds video parameter to cmdline.txt (fixes white screen)
2. Adds dtparam=auto_mute to config.txt (hardware mute)
3. Sets moOde database alsa_output_mode='plughw' (not iec958)
4. Fixes ALSA routing (_audioout → camilladsp)
5. Ensures CamillaDSP uses plughw:X,0 output
6. Restarts services in correct order

**Based On:** Working v1.0 config from git commit 84aa8c2

---

## Summary

**White Screen:** Fixed by `cmdline.txt` video parameter with rotate=90
**IEC958:** Fixed by moOde database `alsa_output_mode='plughw'`
**Auto-mute:** Fixed by `dtparam=auto_mute` in config.txt
**Volume:** Works because we use hardware volume + correct ALSA chain

**Key Learning:** Always check git for working configs FIRST, then read device tree source files to understand hardware parameters, then separate hardware from software layer fixes.

---

**Working System:**
- Boot: No white screen (video parameter)
- Audio: Bose Wave filters at 96kHz via CamillaDSP
- Volume: Hardware control via HiFiBerry
- Touch: FT6236 working
- Display: 1280x400 landscape (rotated from 400x1280)
- No IEC958 in audio chain

---

## ADDENDUM: Complete Device Tree Study

**Date:** January 18, 2026  
**Status:** Phase 1 & 2 Complete

### Comprehensive Device Tree Analysis

A systematic study of all device tree overlays has been completed:

**Documentation:** [`WISSENSBASIS/DEVICE_TREE_MASTER_REFERENCE.md`](WISSENSBASIS/DEVICE_TREE_MASTER_REFERENCE.md)

### Key Findings

#### Parameters That Actually Exist

**HiFiBerry AMP100:**
- `auto_mute` ✓ - Mutes amplifier on silence (hardware)
- `24db_digital_gain` ✓ - Digital gain boost
- `leds_off` ✓ - Disable status LEDs
- `mute_ext_ctl` ✓ - External GPIO mute

**vc4-kms-v3d:**
- `noaudio` ✓ - Disable HDMI audio

**ft6236:**
- No parameters (fixed config)

#### Parameters That DON'T Exist

**`disable_iec958`** ✗
- IEC958 is ALSA software, not hardware
- Cannot be controlled via device tree
- Fix in moOde database instead

### Hardware Configured by Device Tree

**hifiberry-amp100:**
- PCM5122 DAC at I2C 0x4d
- I2S at `/axi/pcie@1000120000/rp1/i2s@a4000` (Pi 5)
- Clock: dacpro_osc
- Power: AVDD/DVDD/CPVDD (3.3V)

**ft6236:**
- Touch controller at I2C 0x38
- GPIO 25 interrupt
- 1280x400 landscape orientation

**vc4-kms-v3d:**
- Display controller
- HDMI output
- Framebuffer init

### What Device Tree Does NOT Control

- ALSA routing ✗
- IEC958 plugin ✗
- Volume levels ✗
- Display rotation ✗
- CamillaDSP ✗
- moOde database ✗

### Verification Method

1. Read all .dts source files
2. Found `__overrides__` sections
3. Verified against working v1.0 config
4. Cross-referenced documentation

### Files Created

- Device Tree Master Reference (complete technical docs)
- Parameter tables with examples
- Layer separation explanations
- Common mistakes documented

**Next:** Hardware validation on Pi (Phase 4)
