# Device Tree Validation Test Suite

**Date:** 2026-01-18
**Purpose:** Automated validation scripts for testing device tree overlays and parameters

## Overview

This test suite provides automated validation of device tree configuration on Raspberry Pi hardware.

## Test Scripts

### 1. validate-overlays.sh

**Purpose:** Complete validation of device tree overlay configuration

**What it tests:**
- I2C bus enabled
- I2S interface enabled
- Onboard audio disabled
- Display overlay loaded (vc4-kms-v3d-pi5)
- Audio overlay loaded (hifiberry)
- I2C devices detected (PCM5122 at 0x4d, FT6236 at 0x38)
- ALSA sound card created
- ALSA playback device available
- DRM display devices
- Framebuffer device
- Kernel messages (device tree errors)
- Kernel messages (I2C errors)
- PCM5122 driver loaded
- HiFiBerry driver loaded
- VC4 display driver loaded

**Usage:**
```bash
./validate-overlays.sh
```

**Output:**
```
================================
Device Tree Overlay Validation
================================

Test 1: I2C Bus Enabled
✓ PASS: I2C enabled in config.txt

Test 2: I2S Interface Enabled
✓ PASS: I2S enabled in config.txt

...

================================
Summary
================================
Passed:  13
Warnings: 2
Failed:  0

✓ All critical tests passed!
```

**Exit codes:**
- 0: All tests passed
- 1: Some tests failed

### 2. test-parameter.sh

**Purpose:** Test specific device tree parameters safely

**What it does:**
1. Backs up current config.txt
2. Checks if overlay file exists
3. Shows current configuration
4. Adds parameter to config.txt
5. Prompts for reboot

**Usage:**
```bash
# Test boolean parameter
./test-parameter.sh hifiberry-dacplus 24db_digital_gain

# Test value parameter
./test-parameter.sh hifiberry-amp100-pi5 mute_ext_ctl 4

# Test noaudio parameter
./test-parameter.sh vc4-kms-v3d-pi5 noaudio
```

**Safety features:**
- Always backs up config.txt before changes
- Validates overlay file exists
- Shows current state before modification
- Prompts before rebooting

**Example session:**
```bash
$ ./test-parameter.sh hifiberry-dacplus auto_mute

================================
Device Tree Parameter Test
================================

Overlay:   hifiberry-dacplus
Parameter: auto_mute

Step 1: Backing up config.txt...
✓ Backup created

Step 2: Checking if overlay file exists...
✓ Overlay file found: /boot/firmware/overlays/hifiberry-dacplus.dtbo

Step 3: Checking current configuration...
Current: dtoverlay=hifiberry-dacplus

Step 4: Adding parameter to config.txt...
✓ Added: dtoverlay=hifiberry-dacplus,auto_mute

Step 5: Reboot required

The system needs to reboot to apply the parameter.
After reboot, run: ./test-parameter.sh verify hifiberry-dacplus auto_mute

Reboot now? (y/n)
```

## Verification After Changes

After rebooting with new parameters, use validate-overlays.sh to verify:

```bash
# Run full validation
./validate-overlays.sh

# Check specific device tree properties
cat /sys/firmware/devicetree/base/axi/sound/hifiberry-dacplus,auto_mute
# If file exists, parameter is active

# Check kernel messages
dmesg | grep -i hifiberry
dmesg | grep -i pcm5122
```

## Manual Verification Commands

### Check Overlays Loaded
```bash
vcgencmd get_config dtoverlay
```

### Check I2C Devices
```bash
i2cdetect -y 1
```

### Check Sound Cards
```bash
cat /proc/asound/cards
aplay -l
```

### Check Display Devices
```bash
ls -la /dev/dri/
```

### Check Loaded Drivers
```bash
lsmod | grep -E "pcm|hifiberry|vc4"
```

### Check Device Tree Nodes
```bash
# List all device tree nodes
ls -la /sys/firmware/devicetree/base/

# Check specific node
cat /sys/firmware/devicetree/base/axi/sound/compatible
```

### Check Kernel Messages
```bash
# Device tree related
dmesg | grep -i "device tree"

# I2C related
dmesg | grep -i "i2c"

# Audio related
dmesg | grep -i "pcm5122\|hifiberry"

# Display related
dmesg | grep -i "vc4\|drm"
```

## Test Plan: auto_mute Parameter

### Objective
Verify that the `auto_mute` parameter actually mutes the amplifier after silence.

### Prerequisites
- Custom overlay with auto_mute support (hifiberry-amp100-pi5-dsp-reset)
- AMP100 amplifier connected
- Speakers connected
- Audio playing capability (MPD/moOde)

### Test Procedure

1. **Apply parameter:**
   ```bash
   ./test-parameter.sh hifiberry-amp100-pi5-dsp-reset auto_mute
   # Reboot
   ```

2. **Verify parameter applied:**
   ```bash
   vcgencmd get_config dtoverlay | grep hifiberry
   # Should show: dtoverlay=hifiberry-amp100-pi5-dsp-reset,auto_mute
   
   cat /sys/firmware/devicetree/base/axi/sound/hifiberry-dacplus,auto_mute
   # File should exist (empty is normal)
   ```

3. **Test auto-mute behavior:**
   ```bash
   # Set safe volume
   mpc volume 20
   
   # Play audio
   mpc play
   
   # Listen: Audio should play normally
   
   # Stop audio
   mpc stop
   
   # Observe: Amplifier should mute after 2-3 seconds
   # You may hear a relay click
   ```

4. **Verify with ALSA control:**
   ```bash
   # Check if Auto Mute control exists
   amixer scontrols | grep "Auto Mute"
   
   # Get auto mute status
   amixer sget 'Auto Mute'
   ```

5. **Document results:**
   - Does amplifier mute? (Yes/No)
   - Time delay before mute? (seconds)
   - Audible relay click? (Yes/No)
   - Any issues? (describe)

### Expected Results
- ✅ Parameter applied in device tree
- ✅ ALSA 'Auto Mute' control exists
- ✅ Amplifier mutes after 2-3 seconds of silence
- ✅ Audio resumes normally when playback starts

### Rollback if Issues
```bash
# Restore backup
sudo cp /boot/firmware/config.txt.param-test-backup /boot/firmware/config.txt
sudo reboot
```

## Test Plan: 24db_digital_gain Parameter

### Objective
Verify that the `24db_digital_gain` parameter increases digital gain.

### Test Procedure

1. **Baseline measurement:**
   ```bash
   # Set known volume
   mpc volume 50
   amixer sset 'Digital' 80%
   
   # Play test tone
   mpc play
   
   # Note volume level (subjective or use meter)
   ```

2. **Apply parameter:**
   ```bash
   ./test-parameter.sh hifiberry-dacplus 24db_digital_gain
   # Reboot
   ```

3. **Test with parameter:**
   ```bash
   # Same volume settings
   mpc volume 50
   amixer sset 'Digital' 80%
   
   # Play same test tone
   mpc play
   
   # Compare volume level
   # Should be noticeably louder with 24db_digital_gain
   ```

4. **Verify ALSA control:**
   ```bash
   amixer scontrols | grep -i "boost\|gain"
   # Should show 'Analogue Playback Boost' control
   ```

### Expected Results
- ✅ Audio noticeably louder with same volume settings
- ✅ 'Analogue Playback Boost' control available
- ✅ No distortion at normal listening levels

## Test Plan: noaudio Parameter (vc4-kms)

### Objective
Verify that `noaudio` parameter disables HDMI audio.

### Test Procedure

1. **Without noaudio:**
   ```bash
   # config.txt:
   dtoverlay=vc4-kms-v3d-pi5
   
   # Reboot
   
   # Check ALSA devices
   aplay -l
   # Should show HDMI audio device
   ```

2. **With noaudio:**
   ```bash
   ./test-parameter.sh vc4-kms-v3d-pi5 noaudio
   # Reboot
   
   # Check ALSA devices
   aplay -l
   # Should NOT show HDMI audio device
   ```

3. **Verify DMA disabled:**
   ```bash
   # Check kernel messages
   dmesg | grep -i "hdmi.*audio"
   # Should show HDMI audio disabled
   ```

### Expected Results
- ✅ HDMI audio devices not in aplay -l
- ✅ Only HiFiBerry device shown
- ✅ No HDMI audio interference

## Troubleshooting

### Issue: validate-overlays.sh reports failures

1. **Check config.txt syntax:**
   ```bash
   grep "dtoverlay\|dtparam" /boot/firmware/config.txt
   # Look for typos
   ```

2. **Check overlay files exist:**
   ```bash
   ls -la /boot/firmware/overlays/hifiberry*.dtbo
   ls -la /boot/firmware/overlays/vc4*.dtbo
   ```

3. **Check kernel messages:**
   ```bash
   dmesg | grep -i "error\|fail" | grep -i "device tree\|overlay"
   ```

4. **Verify hardware connections:**
   - HiFiBerry AMP100 properly seated on GPIO header
   - Display connected to correct HDMI port
   - Touch controller I2C cable connected

### Issue: Parameter doesn't seem to have effect

1. **Verify parameter applied:**
   ```bash
   vcgencmd get_config dtoverlay
   # Check parameter is in output
   ```

2. **Check device tree property:**
   ```bash
   # For auto_mute example:
   cat /sys/firmware/devicetree/base/axi/sound/hifiberry-dacplus,auto_mute
   # File should exist if parameter applied
   ```

3. **Check if parameter exists in overlay:**
   ```bash
   dtc -I dtb -O dts /boot/firmware/overlays/hifiberry-dacplus.dtbo | grep -A 10 "__overrides__"
   # Verify parameter is listed
   ```

4. **Try without other parameters:**
   ```bash
   # Test parameter in isolation
   dtoverlay=hifiberry-dacplus,auto_mute
   # (remove other parameters temporarily)
   ```

## Safety Guidelines

1. **Always backup config.txt before changes**
2. **Test one parameter at a time**
3. **Document baseline behavior before testing**
4. **Have rollback plan ready**
5. **Test with safe volume levels first**
6. **Don't test parameters that don't exist** (check overlay source first)

## Results Documentation Template

```markdown
## Parameter Test: <parameter_name>

**Date:** YYYY-MM-DD
**Overlay:** <overlay_name>
**Parameter:** <parameter_name>
**Value:** <value if applicable>

### Configuration
- Pi Model: Raspberry Pi 5
- OS: Raspberry Pi OS / moOde
- Kernel: <uname -r>
- Overlay version: <if known>

### Baseline (before parameter)
- <describe behavior>

### With Parameter Applied
- <describe behavior with parameter>

### Observable Changes
- <what changed?>
- <measurements if any>

### ALSA Controls
- <amixer output>

### Device Tree Properties
- <cat /sys/firmware/devicetree/base/...>

### Kernel Messages
- <relevant dmesg output>

### Conclusion
- ✅ Parameter works as expected
- OR ❌ Parameter has issues: <describe>

### Recommendations
- <use/don't use, when to use>
```

## Summary

This test suite provides:
- ✅ Automated validation of device tree configuration
- ✅ Safe parameter testing with backup
- ✅ Verification commands and procedures
- ✅ Detailed test plans for specific parameters
- ✅ Troubleshooting guidelines
- ✅ Results documentation template

**Status:** Validation test suite complete - Ready for hardware testing
