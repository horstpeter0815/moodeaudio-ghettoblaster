# Comprehensive Research Notes - Waveshare 7.9" DSI LCD

**Research Date:** 2025-11-25 18:45 CET  
**Status:** In-depth investigation while user experiments

---

## Problem Statement

**Both Pi 4 AND Pi 5** show **identical I2C timeout errors** with Waveshare 7.9" DSI LCD.
- This suggests **configuration error**, not hardware defect
- Same symptoms across different hardware generations = software/config issue

---

## Key Observations

### What We Know:
1. **Hardware:**
   - Waveshare 7.9" DSI LCD (1280x400)
   - Single power supply to Panel USB-C
   - Panel powers Pi via DSI cable
   - 4-pin connector (5V, GND, SDA, SCL)
   - DIP switches set to "I2C1"

2. **Symptoms:**
   - I2C timeouts (-110 ETIMEDOUT or -5 EIO)
   - Panel LED blinks briefly on boot then off
   - No display output
   - Driver loads and binds correctly
   - vc4 initializes successfully
   - No DSI connector in /sys/class/drm/
   - Framebuffer reported but doesn't exist

3. **What Works:**
   - Panel device recognized
   - Driver loads without crash
   - vc4 DRM initializes
   - DSI interface binds
   - Backlight device created (brightness=255)

4. **What Fails:**
   - I2C communication (all writes timeout)
   - Panel initialization
   - Display output
   - Framebuffer access

---

## Research Findings

### From Web Search Results:

1. **I2C Activation Required:**
   - Some sources mention I2C must be explicitly enabled
   - Command: `sudo raspi-config` → Interfacing Options → I2C
   - OR: `dtparam=i2c_arm=on` in config.txt (WE HAVE THIS ✓)

2. **Display Detection:**
   - Check with `dmesg | grep -i ft5406` for touch
   - Our panel uses different chip (goodix,gt911)

3. **Config.txt Settings:**
   - `ignore_lcd=0` vs `ignore_lcd=1`
   - We have `ignore_lcd=1` (ignores LCD!)
   - This might be the problem! ⚠️

4. **Power Management:**
   - `WAKE_ON_GPIO=1` and `POWER_OFF_ON_HALT=0` for DSI displays
   - Prevents USB power interruption on reboot
   - We don't have these! ⚠️

5. **vc4 Overlay Issues:**
   - Some displays don't work with `dtoverlay=vc4-kms-v3d`
   - Need to comment it out
   - We use `vc4-kms-v3d-pi4` - might conflict! ⚠️

6. **Firmware Regressions:**
   - GitHub issue mentions DSI displays broke after `apt upgrade`
   - Might need firmware rollback or specific version

---

## Potential Configuration Errors

### 1. ignore_lcd=1 (SUSPICIOUS!)

**Current config.txt:**
```
ignore_lcd=1
```

**This tells the system to IGNORE the LCD!**

Should probably be:
```
ignore_lcd=0
```

OR removed entirely.

### 2. Missing Power Management

**Should add:**
```
WAKE_ON_GPIO=1
POWER_OFF_ON_HALT=0
```

### 3. Conflicting KMS Overlays

**Current:**
```
[pi4]
dtoverlay=vc4-kms-v3d-pi4,noaudio

[all]
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,disable_touch,i2c1
```

**Potential conflict:** Both vc4-kms-v3d-pi4 and vc4-kms-dsi-waveshare-panel loading

**Try:**
- Remove vc4-kms-v3d-pi4 entirely
- OR: Use only vc4-fkms-v3d (fake KMS)

### 4. DIP Switch vs. Overlay Mismatch

**DIP switches:** I2C1  
**Overlay parameter:** i2c1  
**But:** This should map panel to GPIO I2C (bus 1)

**Question:** Should DIP switches be on I2C0 for DSI-I2C?

---

## Moode Audio Specific Considerations

From the Moode Audio forum link provided earlier (thread 6416):
- Moode has specific display configurations
- May have custom overlays or settings
- Need to check Moode-specific config files

**Files to check:**
- `/boot/firmware/config.txt` (we've seen this)
- `/etc/moode.conf` or similar
- Moode-specific display settings

---

## Waveshare GitHub Repository Analysis

**Official repo:** github.com/waveshare/7.9inch-DSI-LCD

**Should contain:**
- Device tree overlays (.dts files)
- Installation scripts
- Working config.txt examples
- DIP switch documentation
- I2C address tables

**Need to:**
1. Clone the repo
2. Compare their overlay with ours
3. Check their config.txt examples
4. Verify DIP switch settings
5. Look for known issues

---

## Action Plan

### Immediate Tests:

1. **Change ignore_lcd=1 to ignore_lcd=0**
   - This is highly suspicious
   - Might be preventing LCD detection

2. **Add Power Management Settings**
   ```
   WAKE_ON_GPIO=1
   POWER_OFF_ON_HALT=0
   ```

3. **Try WITHOUT vc4-kms-v3d-pi4**
   - Comment out in [pi4] section
   - Let only waveshare overlay handle KMS

4. **Verify DIP Switch Settings**
   - Should they be I2C0 or I2C1?
   - Does i2c1 parameter match hardware?

5. **Check Waveshare Official Config**
   - Download from GitHub
   - Compare line-by-line with ours

### Deep Investigation:

1. **Clone Waveshare Repository**
   ```bash
   git clone https://github.com/waveshare/7.9inch-DSI-LCD.git
   ```

2. **Examine Their Device Tree**
   - Compare with our patched driver
   - Check for missing properties

3. **Test With Stock Raspberry Pi OS**
   - Eliminate Moode-specific issues
   - If works there, problem is Moode config

4. **Firmware Version Check**
   - May need specific firmware version
   - Check GitHub issues for compatible versions

---

## Questions for User

When user returns, ask:

1. **What did you try in the 30 minutes?**
2. **Did display show anything at all?**
3. **Can you test with stock Raspberry Pi OS temporarily?**
4. **Do you have access to the official Waveshare config.txt example?**
5. **Have you verified the DIP switches are physically on I2C1?**

---

## Hypothesis

**Most likely cause:** `ignore_lcd=1` is preventing display detection!

**Second likely:** Missing power management settings for DSI

**Third likely:** vc4 overlay conflict

**Fourth likely:** Wrong DIP switch setting

---

## Next Steps When User Returns

1. Ask what they discovered
2. Implement ignore_lcd=0 change
3. Add power management settings
4. Test systematically
5. If still fails, try without vc4-kms-v3d-pi4

---

**Status:** Waiting for user feedback...  
**Research continuing...**

