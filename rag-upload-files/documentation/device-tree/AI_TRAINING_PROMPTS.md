# Device Tree AI Training Prompts

**Date:** 2026-01-18
**Purpose:** Training prompts and test questions for AI assistants learning device tree concepts

## Overview

These prompts test AI understanding of device tree concepts at various levels:
1. **Basic Understanding** - Fundamental concepts
2. **Parameter Knowledge** - What exists vs doesn't exist
3. **Layer Separation** - Hardware vs software
4. **Troubleshooting** - Practical problem-solving
5. **Best Practices** - Recommended approaches

---

## Category 1: Basic Understanding

### Q1: What is device tree?

**Expected Answer:**
Device tree is a hardware description format used by Linux to initialize hardware at boot time. It describes:
- Hardware devices (I2C, SPI, GPIO, etc.)
- Device addresses and properties
- Interrupt routing
- Clock sources
- Power supplies

Device tree is compiled from `.dts` (source) to `.dtbo` (compiled overlay) files and loaded by the bootloader before the kernel starts.

**Key points to include:**
- Hardware initialization only
- Boot-time configuration
- Not for software/runtime configuration

### Q2: What's the difference between dtoverlay and dtparam?

**Expected Answer:**
- **dtoverlay** - Loads a device tree overlay file (`.dtbo`) that adds or modifies hardware device tree nodes
  - Example: `dtoverlay=hifiberry-amp100`
- **dtparam** - Sets simple on/off parameters in the base device tree
  - Example: `dtparam=i2c_arm=on`

dtoverlay is for loading hardware device descriptions, dtparam is for enabling/disabling built-in features.

### Q3: What does the vc4-kms-v3d-pi5 overlay do?

**Expected Answer:**
Enables Kernel Mode Setting (KMS) for display on Raspberry Pi 5. It:
- Enables HDMI controllers (hdmi0, hdmi1)
- Enables display pipeline (HVS, pixel valves, V3D graphics)
- Provides display functionality for X11/Wayland

It does NOT control display rotation or resolution - those are handled by cmdline.txt (boot) and xrandr (runtime).

---

## Category 2: Parameter Knowledge

### Q4: What parameters exist for hifiberry-dacplus overlay?

**Expected Answer:**
Upstream hifiberry-dacplus overlay has:
- `24db_digital_gain` (boolean) - Enable 24dB digital gain in PCM5122
- `slave` (boolean) - Switch to clock producer mode
- `leds_off` (boolean) - Disable status LEDs

Custom Pi 5 variants add:
- `auto_mute` (boolean) - Enable auto-mute on silence
- `mute_ext_ctl` (value) - GPIO for external mute control

**Must NOT say:** Parameters like `disable_iec958`, `volume`, `rotation` - these don't exist.

### Q5: Can I use dtoverlay=hifiberry-amp100,disable_iec958?

**Expected Answer:**
NO. The parameter `disable_iec958` does not exist in any HiFiBerry overlay.

IEC958 (S/PDIF) is configured in the ALSA software layer, not in device tree. To disable IEC958:

```bash
# Use ALSA control
amixer sset 'IEC958' off

# Or configure in /etc/asound.conf
```

Device tree only initializes the PCM5122 DAC hardware. ALSA handles audio routing.

### Q6: What does the noaudio parameter do in vc4-kms-v3d-pi5?

**Expected Answer:**
The `noaudio` parameter disables HDMI audio on both HDMI ports by removing DMA channels from the HDMI controllers.

Usage: `dtoverlay=vc4-kms-v3d-pi5,noaudio`

This is commonly used when using an external DAC (like HiFiBerry AMP100) to prevent HDMI audio from interfering with I2S audio.

It does NOT disable the onboard audio chip - that's done with `dtparam=audio=off`.

---

## Category 3: Layer Separation

### Q7: User says "Display is showing in portrait mode but I want landscape. How do I fix it in device tree?"

**Expected Answer:**
You CANNOT fix display orientation in device tree. Display orientation is controlled at two different layers:

1. **Boot screen** (before X11): `cmdline.txt` video parameter
   ```
   video=HDMI-A-1:1280x400@60
   ```

2. **Runtime screen** (X11): `xrandr` command
   ```bash
   xrandr --output HDMI-2 --rotate normal  # or left, right, inverted
   ```

Device tree only initializes the display hardware. Orientation is a software framebuffer/window system configuration.

**Must NOT say:** Use a device tree parameter like `rotation` - it doesn't exist.

### Q8: What layer controls IEC958 (S/PDIF)?

**Expected Answer:**
IEC958 is controlled at the **ALSA software layer**, not device tree.

**Layer breakdown:**
- **Device Tree** - Initializes PCM5122 DAC hardware
- **PCM5122 Driver** - Creates ALSA device
- **ALSA** - Provides IEC958 control (on/off, routing)
- **Applications** - Use ALSA API

To configure IEC958:
```bash
# Check current state
amixer sget 'IEC958'

# Disable
amixer sset 'IEC958' off

# Configure in /etc/asound.conf for persistence
```

### Q9: User asks "How do I set volume in device tree?"

**Expected Answer:**
You CANNOT set volume in device tree. Volume is controlled at the software layer:

1. **ALSA layer**:
   ```bash
   amixer -c 0 sset 'Digital' 80%
   ```

2. **MPD layer**:
   ```bash
   mpc volume 50
   ```

3. **moOde UI**: Use the volume slider

Device tree only initializes the DAC hardware. Volume control is a software feature implemented in ALSA and applications.

---

## Category 4: Troubleshooting

### Q10: User reports "PCM5122 not detected on I2C bus"

**Expected Answer:**
Debug steps:

1. **Verify I2C enabled:**
   ```bash
   grep "dtparam=i2c_arm" /boot/firmware/config.txt
   # Should show: dtparam=i2c_arm=on
   ```

2. **Check I2C detection:**
   ```bash
   i2cdetect -y 1
   # Should show device at 0x4d
   ```

3. **Check overlay loaded:**
   ```bash
   vcgencmd get_config dtoverlay
   # Should show hifiberry overlay
   ```

4. **Check kernel messages:**
   ```bash
   dmesg | grep pcm5122
   dmesg | grep i2c
   ```

5. **Try slower I2C clock:**
   ```ini
   dtparam=i2c_arm=on,i2c_arm_baudrate=100000
   ```

Common causes:
- I2C not enabled
- Overlay not loaded
- Hardware not connected
- I2C clock too fast

### Q11: User says "Sound card not appearing after loading hifiberry overlay"

**Expected Answer:**
Check these requirements:

1. **I2S enabled:**
   ```bash
   grep "dtparam=i2s" /boot/firmware/config.txt
   # Must show: dtparam=i2s=on
   ```

2. **Onboard audio disabled:**
   ```bash
   grep "dtparam=audio" /boot/firmware/config.txt
   # Must show: dtparam=audio=off
   ```

3. **Overlay loaded:**
   ```bash
   vcgencmd get_config dtoverlay
   ```

4. **Check sound cards:**
   ```bash
   cat /proc/asound/cards
   aplay -l
   ```

5. **Check kernel messages:**
   ```bash
   dmesg | grep hifiberry
   dmesg | grep snd
   ```

All three (overlay + i2s + audio=off) are required for HiFiBerry to work.

### Q12: User on Pi 5 says "Using vc4-kms-v3d but display not working"

**Expected Answer:**
On Pi 5, you MUST use `vc4-kms-v3d-pi5`, not `vc4-kms-v3d`.

Pi 5 has different hardware:
- Different compatible string (brcm,bcm2712 vs brcm,bcm2835)
- Dual HDMI ports (hdmi0, hdmi1)
- Different display pipeline

Fix:
```ini
# Wrong (Pi 4 overlay):
dtoverlay=vc4-kms-v3d

# Correct (Pi 5 overlay):
dtoverlay=vc4-kms-v3d-pi5
```

After changing, reboot and verify:
```bash
vcgencmd get_config dtoverlay
```

---

## Category 5: Best Practices

### Q13: Should I use custom or upstream overlays?

**Expected Answer:**
**Recommendation: Start with upstream overlays.**

Upstream overlays (from Raspberry Pi):
- ✅ Well-maintained and tested
- ✅ Receive automatic updates
- ✅ Work across Pi models
- ✅ Documented in `/boot/firmware/overlays/README`

Use custom overlays only if you need:
- Features not in upstream (like auto_mute)
- Pi-specific optimizations
- Specific GPIO configurations

For Ghettoblaster:
```ini
# Standard (recommended):
dtoverlay=hifiberry-dacplus

# Custom (if auto-mute needed):
dtoverlay=hifiberry-amp100-pi5-dsp-reset,auto_mute
```

### Q14: How do I verify a device tree parameter exists before using it?

**Expected Answer:**
Always check the overlay source for the `__overrides__` section:

**Method 1: View upstream source**
```bash
curl -s https://raw.githubusercontent.com/raspberrypi/linux/rpi-6.6.y/arch/arm/boot/dts/overlays/hifiberry-dacplus-overlay.dts | grep -A 10 "__overrides__"
```

**Method 2: Check local compiled overlay**
```bash
dtc -I dtb -O dts /boot/firmware/overlays/hifiberry-dacplus.dtbo | grep -A 10 "__overrides__"
```

**Method 3: Read documentation**
```bash
cat /boot/firmware/overlays/README | grep -A 50 "hifiberry-dacplus"
```

Only use parameters listed in `__overrides__`. Don't make up parameters.

### Q15: User wants to make changes to config.txt. What's the safe process?

**Expected Answer:**
Safe configuration change process:

1. **Backup current config:**
   ```bash
   sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.backup
   ```

2. **Make changes:**
   ```bash
   sudo nano /boot/firmware/config.txt
   ```

3. **Verify syntax:**
   ```bash
   grep "dtoverlay" /boot/firmware/config.txt
   # Check for typos
   ```

4. **Reboot:**
   ```bash
   sudo reboot
   ```

5. **Verify changes applied:**
   ```bash
   vcgencmd get_config dtoverlay
   i2cdetect -y 1
   aplay -l
   ```

6. **If issues, revert:**
   ```bash
   sudo cp /boot/firmware/config.txt.backup /boot/firmware/config.txt
   sudo reboot
   ```

Always backup before changes and verify after reboot.

---

## Category 6: Advanced Concepts

### Q16: How does the bootloader apply device tree overlays?

**Expected Answer:**
Device tree overlay loading process:

1. **Bootloader reads config.txt** and finds `dtoverlay=` lines
2. **Loads base device tree** for Pi model (e.g., bcm2712-rpi-5-b.dtb)
3. **For each overlay:**
   - Loads compiled `.dtbo` file
   - Parses parameters (if provided)
   - Resolves `__fixups__` (symbolic references)
   - Applies `__overrides__` (parameters)
   - Merges fragments into base device tree
4. **Passes final merged device tree** to kernel
5. **Kernel parses device tree** and loads drivers

Overlays are applied in order listed in config.txt.

### Q17: What's the difference between clock consumer and producer mode for I2S?

**Expected Answer:**
I2S has two clock modes:

**Consumer mode (default for HiFiBerry):**
- DAC generates clocks (BCK, LRCK)
- Pi receives clocks
- DAC uses its own oscillator (dacpro_osc)
- Used when: DAC has better clock than Pi

**Producer mode (slave parameter):**
- Pi generates clocks
- DAC receives clocks
- Used when: External master clock or chaining DACs

For HiFiBerry AMP100, use consumer mode (default). The `slave` parameter switches to producer mode (advanced use only).

### Q18: Why does vc4-kms-v3d-pi5 have a noaudio parameter?

**Expected Answer:**
The `noaudio` parameter disables HDMI audio DMA channels. This prevents HDMI audio hardware from interfering with external audio (like HiFiBerry).

Without `noaudio`:
- HDMI audio is enabled by default
- Can cause conflicts with I2S audio
- Both audio subsystems compete

With `noaudio`:
- HDMI audio DMA disabled
- I2S audio has exclusive access
- Clean audio routing

Common configuration:
```ini
dtoverlay=vc4-kms-v3d-pi5,noaudio  # Disable HDMI audio
dtoverlay=hifiberry-dacplus         # Enable I2S audio
dtparam=audio=off                   # Disable onboard audio
```

This ensures only the external DAC provides audio.

---

## Category 7: Common Mistakes

### Q19: User tried "dtoverlay=hifiberry-amp100,automute" but it didn't work

**Expected Answer:**
The parameter is `auto_mute` (with underscore), not `automute`.

However, `auto_mute` only exists in **custom Pi 5 overlays**, not the upstream `hifiberry-dacplus` overlay.

Correct usage:
```ini
# If using custom overlay:
dtoverlay=hifiberry-amp100-pi5-dsp-reset,auto_mute

# Upstream doesn't have this parameter:
dtoverlay=hifiberry-dacplus  # No auto_mute available
```

Check the overlay source to see available parameters:
```bash
grep "__overrides__" hifiberry-amp100-pi5-dsp-reset.dts
```

### Q20: User asks "Why is my boot screen white but moOde UI appears correctly after boot?"

**Expected Answer:**
Boot screen and runtime screen use different configurations:

**Boot screen (white/wrong orientation):**
- Controlled by `cmdline.txt` video parameter
- Framebuffer resolution issue

**Fix:**
```bash
# /boot/firmware/cmdline.txt
# Add: video=HDMI-A-1:1280x400@60
```

**Runtime screen (correct orientation):**
- Controlled by X11 + xrandr
- Set in `~/.xinitrc` based on moOde database

This is NOT a device tree issue. Device tree only initializes display hardware. The white screen is a framebuffer configuration problem in cmdline.txt.

---

## Training Success Metrics

An AI assistant properly trained on this documentation should:

### ✅ Correct Behaviors
1. Know which parameters exist vs don't exist
2. Direct users to correct layer for each problem
3. Not suggest non-existent parameters
4. Explain layer separation clearly
5. Provide accurate troubleshooting steps
6. Recommend upstream overlays first
7. Understand Pi 5 vs Pi 4 differences

### ❌ Behaviors to Avoid
1. Making up parameters
2. Trying to fix software problems with device tree
3. Confusing device tree with ALSA/X11
4. Suggesting `rotation` or `disable_iec958` parameters
5. Recommending custom overlays without explaining trade-offs
6. Not checking parameter existence before suggesting

---

## Test Scenarios

### Scenario 1: IEC958 Problem

**User:** "IEC958 is showing up in ALSA and causing problems. How do I disable it in device tree?"

**Correct Response:**
"You cannot disable IEC958 in device tree - it's configured in the ALSA software layer, not hardware.

IEC958 (S/PDIF) is a software routing feature. Device tree only initializes the PCM5122 DAC hardware.

To disable IEC958:
```bash
amixer sset 'IEC958' off
```

Or configure permanently in `/etc/asound.conf`."

**Incorrect Response:**
"Try adding `disable_iec958` parameter..." (Parameter doesn't exist)

### Scenario 2: Display Orientation

**User:** "My display is in portrait but I need landscape. What device tree parameter should I use?"

**Correct Response:**
"Display orientation is not controlled by device tree. You need to configure it at two layers:

1. Boot screen: `cmdline.txt` video parameter:
   ```
   video=HDMI-A-1:1280x400@60
   ```

2. Runtime (X11): xrandr in `~/.xinitrc`:
   ```bash
   xrandr --output HDMI-2 --rotate normal
   ```

Device tree only initializes the display hardware, not orientation."

**Incorrect Response:**
"Use `dtoverlay=vc4-kms-v3d-pi5,rotation=90`..." (Parameter doesn't exist)

### Scenario 3: Parameter Verification

**User:** "Does hifiberry-amp100 support the auto_mute parameter?"

**Correct Response:**
"The `auto_mute` parameter exists in custom Pi 5 variants but NOT in the upstream `hifiberry-dacplus` overlay.

Upstream has: `24db_digital_gain`, `slave`, `leds_off`

Custom Pi 5 overlays add: `auto_mute`, `mute_ext_ctl`

If you're using the standard overlay, auto_mute is not available. You'd need to use a custom Pi 5 overlay like `hifiberry-amp100-pi5-dsp-reset`."

**Incorrect Response:**
"Yes, just use `dtoverlay=hifiberry-amp100,auto_mute`..." (Without clarifying it's custom-only)

---

## Summary

These training prompts cover:
- ✅ Basic concepts and terminology
- ✅ Parameter existence and usage
- ✅ Layer separation (hardware vs software)
- ✅ Practical troubleshooting
- ✅ Best practices
- ✅ Common mistakes and corrections

An AI trained on these prompts will:
- Provide accurate device tree guidance
- Not suggest non-existent parameters
- Direct users to the correct layer for each problem
- Follow best practices
- Avoid common mistakes

**Status:** Training prompts complete - Ready for AI RAG integration
