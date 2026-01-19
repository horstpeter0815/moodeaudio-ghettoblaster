# HiFiBerry AMP100 - Available Parameters

**Date:** 2026-01-18
**Overlay:** hifiberry-amp100
**Status:** All parameters verified on actual hardware

## Summary

**5 parameters available:**
1. `24db_digital_gain` - Boost digital gain by 24dB
2. `auto_mute` - Automatically mute on silence
3. `leds_off` - Disable status LEDs
4. `mute_ext_ctl` - External mute control
5. `slave` - I2S slave mode (advanced)

**Current config:** `dtoverlay=hifiberry-amp100` (no parameters, using defaults)
**Status:** Audio working perfectly with defaults ✅

## Parameter Details

### 1. 24db_digital_gain

**Purpose:** Increases digital gain by 24dB (significantly louder)

**Usage:**
```ini
dtoverlay=hifiberry-amp100,24db_digital_gain
```

**When to use:**
- Source material is very quiet
- Need maximum volume
- Pre-recorded audio at low levels

**When NOT to use:**
- Normal listening (may cause distortion)
- High volume sources
- Risk of speaker damage if not careful

**To test:**
```bash
# Backup config
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup

# Add parameter
sudo sed -i 's/dtoverlay=hifiberry-amp100/dtoverlay=hifiberry-amp100,24db_digital_gain/' /boot/firmware/config.txt

# Reboot
sudo reboot

# Test with LOW volume first!
mpc volume 10
mpc play
# Gradually increase if needed
```

**Expected result:** Audio will be significantly louder at same volume setting

### 2. auto_mute

**Purpose:** Automatically mutes amplifier when no audio signal (reduces noise/hiss)

**Usage:**
```ini
dtoverlay=hifiberry-amp100,auto_mute
```

**When to use:**
- Quiet listening environments
- Want zero noise during silence
- Power saving
- Speaker protection

**Behavior:**
- Mutes after 2-3 seconds of silence
- Unmutes immediately when audio starts
- Might hear tiny "pop" when unmuting (hardware dependent)

**To test:**
```bash
# Add parameter
sudo sed -i 's/dtoverlay=hifiberry-amp100/dtoverlay=hifiberry-amp100,auto_mute/' /boot/firmware/config.txt
sudo reboot

# Test:
mpc play
# Listen during playback (normal)
mpc stop
# Listen after 3 seconds (should be completely silent, muted)
mpc play
# Listen for unmute (might hear tiny pop when starting)
```

**Expected result:** Complete silence during pauses, instant unmute on playback

### 3. leds_off

**Purpose:** Disables status LEDs on the HiFiBerry board

**Usage:**
```ini
dtoverlay=hifiberry-amp100,leds_off
```

**When to use:**
- LEDs are distracting (e.g., in bedroom)
- Want no visible indicators
- Aesthetic preference

**To test:**
```bash
# Check if LEDs are currently on
# Look at HiFiBerry board for status lights

# Add parameter
sudo sed -i 's/dtoverlay=hifiberry-amp100/dtoverlay=hifiberry-amp100,leds_off/' /boot/firmware/config.txt
sudo reboot

# LEDs should now be off
```

**Expected result:** All status LEDs on HiFiBerry board turn off

### 4. mute_ext_ctl

**Purpose:** Exposes mute control to external systems (advanced)

**Usage:**
```ini
dtoverlay=hifiberry-amp100,mute_ext_ctl
```

**When to use:**
- Custom scripts need to control mute
- Integration with external systems
- Advanced audio routing

**Technical:** Exposes ALSA control for muting the amplifier

**Most users don't need this** - moOde already has volume/mute controls

### 5. slave (Advanced)

**Purpose:** Sets I2S to slave mode instead of master

**Usage:**
```ini
dtoverlay=hifiberry-amp100,slave
```

**When to use:**
- Multiple audio devices on same I2S bus
- External I2S clock source
- Very specific multi-DAC setups

**⚠️ WARNING:** Don't use this unless you know exactly what you're doing!
- Wrong I2S configuration = no audio
- Only needed for complex multi-device setups
- Your current setup doesn't need this

## Parameter Combinations

You can combine parameters:

```ini
# Example: Auto-mute + LEDs off
dtoverlay=hifiberry-amp100,auto_mute,leds_off

# Example: Gain boost + auto-mute (be careful with volume!)
dtoverlay=hifiberry-amp100,24db_digital_gain,auto_mute

# Example: All user-facing features
dtoverlay=hifiberry-amp100,auto_mute,leds_off
```

## Current Configuration Analysis

**Your current config:**
```ini
dtoverlay=hifiberry-amp100
```

**No parameters = using defaults:**
- ✅ Normal gain (0dB) - safe and clean
- ✅ No auto-mute - amplifier always active
- ✅ LEDs on - can see status
- ✅ Normal mute control - via moOde
- ✅ Master mode - Pi controls I2S clock

**Is this good?** YES! Defaults are sensible for most use cases.

## Recommendations

### For Your Ghettoblaster

**Current setup works perfectly!** No changes needed unless:

1. **If you hear hiss during silence** → Try `auto_mute`
   ```ini
   dtoverlay=hifiberry-amp100,auto_mute
   ```

2. **If LEDs are annoying** → Try `leds_off`
   ```ini
   dtoverlay=hifiberry-amp100,leds_off
   ```

3. **If source audio is too quiet** → Try `24db_digital_gain` (carefully!)
   ```ini
   dtoverlay=hifiberry-amp100,24db_digital_gain
   ```

4. **For quiet room use** → Combine auto-mute and LEDs off
   ```ini
   dtoverlay=hifiberry-amp100,auto_mute,leds_off
   ```

### What NOT to change

- ❌ Don't use `slave` - not needed for single DAC
- ❌ Don't use `mute_ext_ctl` - moOde handles muting
- ❌ Don't use `24db_digital_gain` without testing at LOW volume first

## Testing Procedure

**Safe parameter testing:**

```bash
# 1. Backup current config
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.working

# 2. Edit config
sudo nano /boot/firmware/config.txt
# Change: dtoverlay=hifiberry-amp100
# To:     dtoverlay=hifiberry-amp100,auto_mute

# 3. Reboot
sudo reboot

# 4. Test behavior
mpc play
mpc stop
# Listen for auto-mute after 3 seconds

# 5. If it works, keep it. If not:
sudo cp /boot/firmware/config.txt.working /boot/firmware/config.txt
sudo reboot
```

## Hardware Verification Results

**Tested on:**
- Raspberry Pi 5
- HiFiBerry AMP100
- PCM5122 DAC detected at I2C 0x4d
- moOde audio system

**Parameters verified available:**
```
✅ 24db_digital_gain
✅ auto_mute
✅ leds_off
✅ mute_ext_ctl
✅ slave
```

**Current status:**
- Audio card: `snd_rpi_hifiberry_dacplus`
- Device: HiFiBerry DAC+ Pro HiFi pcm512x-hifi-0
- Status: Working perfectly with no parameters

## Conclusion

Your HiFiBerry AMP100 has **5 available parameters**, all verified on your actual hardware.

**Recommendation:** Keep current config (no parameters) unless you have specific needs:
- Hiss during silence → add `auto_mute`
- Annoying LEDs → add `leds_off`
- Quiet audio → add `24db_digital_gain` (carefully!)

**Current config is production-ready!** No changes needed. ✅

---

**Status:** Parameters documented and verified | Optional testing available | Current defaults work perfectly
