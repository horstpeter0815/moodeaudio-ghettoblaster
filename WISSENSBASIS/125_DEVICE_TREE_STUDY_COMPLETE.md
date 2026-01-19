# Device Tree Overlay Study - Complete Analysis

## Executive Summary

This document contains the complete analysis of all device tree overlays (DTOs) used in the Ghettoblaster system. This study was conducted to understand exactly what device tree controls vs what must be configured in software layers (ALSA, moOde database, X11).

**Date:** 2026-01-18
**System:** Raspberry Pi 5 with HiFiBerry AMP100, FT6236 Touch, Waveshare 7.9" Display

## Key Findings

### 1. Overlays Actually Used in v1.0 Working Config

From `/v1.0-config-export/config.txt.working`:

```
dtoverlay=vc4-kms-v3d-pi5,noaudio    # Display/video (line 13)
dtoverlay=hifiberry-amp100            # Audio HAT (line 48)
dtoverlay=vc4-kms-v3d-pi5,noaudio    # Duplicate (line 49)
```

**Note:** The `vc4-kms-v3d-pi5` overlay is loaded twice (lines 13 and 49). This is redundant but harmless.

### 2. Touch Controller Overlay

The FT6236 touch controller is **NOT loaded via config.txt** in the working config. It may be:
- Loaded via systemd service (as mentioned in documentation)
- Built into kernel/initramfs
- Not needed (touch working through other means)

### 3. Critical Layer Separation

**Device Tree Controls (Hardware Layer):**
- I2C device initialization (PCM5122 at 0x4d, FT6236 at 0x38)
- I2S interface enabling
- GPIO assignments
- Clock sources
- Power supply connections

**Device Tree Does NOT Control:**
- ALSA routing (no IEC958/SPDIF in device tree)
- MPD configuration
- moOde database settings
- X11 display rotation (that's .xinitrc + xrandr)
- Volume levels
- Audio formats (PCM vs compressed)

## Detailed Overlay Analysis

### A. HiFiBerry AMP100 (hifiberry-amp100)

**Source:** Upstream Raspberry Pi kernel (`hifiberry-dacplus-overlay.dts`)

**Note:** The `hifiberry-amp100` overlay is actually the same as `hifiberry-dacplus`. The AMP100 uses the same PCM5122 DAC chip as DAC+.

#### Hardware Configured

1. **Clock Generator (fragment@0)**
   ```dts
   dacpro_osc: dacpro_osc {
       compatible = "hifiberry,dacpro-clk";
       #clock-cells = <0>;
   };
   ```
   - Creates clock source for PCM5122 DAC

2. **I2S Controller (fragment@1)**
   ```dts
   target = <&i2s_clk_consumer>;
   status = "okay";
   ```
   - Enables I2S controller in clock consumer mode (DAC generates clock)

3. **PCM5122 DAC (fragment@2)**
   ```dts
   pcm5122@4d {
       compatible = "ti,pcm5122";
       reg = <0x4d>;
       clocks = <&dacpro_osc>;
       AVDD-supply = <&vdd_3v3_reg>;
       DVDD-supply = <&vdd_3v3_reg>;
       CPVDD-supply = <&vdd_3v3_reg>;
   };
   ```
   - I2C address: 0x4d
   - Clock source: dacpro_osc (from fragment@0)
   - Power supplies: All 3.3V (AVDD, DVDD, CPVDD)

4. **Sound Card (fragment@3)**
   ```dts
   compatible = "hifiberry,hifiberry-dacplus";
   i2s-controller = <&i2s_clk_consumer>;
   ```
   - Creates ALSA sound card
   - Links to I2S controller

#### Available Parameters (__overrides__)

| Parameter | Type | Default | Description | Usage Example |
|-----------|------|---------|-------------|---------------|
| `24db_digital_gain` | bool | false | Enable 24dB digital gain | `dtoverlay=hifiberry-amp100,24db_digital_gain` |
| `slave` | bool | false | Use external clock (slave mode) | `dtoverlay=hifiberry-amp100,slave` |
| `leds_off` | bool | false | Disable LEDs | `dtoverlay=hifiberry-amp100,leds_off` |

**IMPORTANT:** The parameter `auto_mute` does **NOT** exist in the upstream overlay. It was added in custom variants:
- `hifiberry-amp100-pi5-dsp-reset.dts` (line 68): `auto_mute = <&sound>,"hifiberry-dacplus,auto_mute?";`
- `hifiberry-amp100-pi5-overlay.dts` (line 69): `auto_mute = <&sound>,"hifiberry-dacplus,auto_mute?";`
- `ghettoblaster-unified.dts` (line 94): `auto_mute = <&sound>,"hifiberry-dacplus,auto_mute?";`

#### Pi 5 Compatibility

The upstream overlay uses `i2s_clk_consumer` which is resolved via `__fixups__`. On Pi 5, this resolves to:
- `/axi/pcie@1000120000/rp1/i2s@a4000` (DesignWare I2S controller in RP1 chip)

Custom Pi 5 variants explicitly target this path:
```dts
target-path = "/axi/pcie@1000120000/rp1/i2s@a4000";
```

### B. vc4-kms-v3d-pi5 (Display/Video)

**Source:** Upstream Raspberry Pi kernel (`vc4-kms-v3d-pi5-overlay.dts`)

**Purpose:** Enable Kernel Mode Setting (KMS) for display on Raspberry Pi 5.

#### Hardware Configured

Enables multiple display subsystem components:

1. **AON Interrupt Controller (fragment@2)**
2. **DDC I2C buses (fragment@3, @4)** - For EDID reading
3. **HDMI Controllers (fragment@5, @6)** - hdmi0, hdmi1
4. **HVS (fragment@7)** - Hardware Video Scaler
5. **MOP (fragment@8, @9)** - Memory-to-Pixel engines
6. **Pixel Valves (fragment@10, @11)** - Timing generators
7. **V3D (fragment@12)** - 3D graphics
8. **VC4 (fragment@17)** - Display controller with IOMMU

#### Available Parameters (__overrides__)

| Parameter | Type | Default | Description | Usage Example |
|-----------|------|---------|-------------|---------------|
| `audio` | bool | true | Enable HDMI audio on HDMI0 | `dtoverlay=vc4-kms-v3d-pi5,audio` |
| `audio1` | bool | true | Enable HDMI audio on HDMI1 | `dtoverlay=vc4-kms-v3d-pi5,audio1` |
| `noaudio` | bool | false | Disable HDMI audio on both ports | `dtoverlay=vc4-kms-v3d-pi5,noaudio` |
| `composite` | bool | false | Enable composite video output | `dtoverlay=vc4-kms-v3d-pi5,composite` |
| `nohdmi0` | bool | false | Disable HDMI port 0 | `dtoverlay=vc4-kms-v3d-pi5,nohdmi0` |
| `nohdmi1` | bool | false | Disable HDMI port 1 | `dtoverlay=vc4-kms-v3d-pi5,nohdmi1` |
| `nohdmi` | bool | false | Disable both HDMI ports | `dtoverlay=vc4-kms-v3d-pi5,nohdmi` |

#### How `noaudio` Works

```dts
__overrides__ {
    noaudio = <0>,"=14", <0>,"=15";
};
```

This activates dormant fragments:
- fragment@14: Removes DMA from hdmi0 (disables audio)
- fragment@15: Removes DMA from hdmi1 (disables audio)

**Critical Understanding:** The `noaudio` parameter disables HDMI audio DMA channels. It does **NOT**:
- Disable the DAC (that's controlled by `dtparam=audio=off`)
- Configure ALSA routing
- Control IEC958/SPDIF (that's ALSA software)

#### Display Orientation

**Device tree does NOT control display orientation.**

Orientation is controlled by:
1. **Boot screen:** `cmdline.txt` video parameter: `video=HDMI-A-1:1280x400@60`
2. **Runtime (moOde UI):** `~/.xinitrc` reads database and applies `xrandr --rotate`

### C. FT6236 Touch Controller

**Source:** Custom overlay (`custom-components/overlays/ghettoblaster-ft6236.dts`)

**Status:** This overlay exists in source but is **NOT loaded in working v1.0 config.txt**.

#### Hardware Configured

```dts
ft6236@38 {
    compatible = "focaltech,ft6236";
    reg = <0x38>;
    interrupt-parent = <&gpio>;
    interrupts = <25 2>; /* GPIO 25, falling edge */
    touchscreen-size-x = <1280>;
    touchscreen-size-y = <400>;
    touchscreen-inverted-x;
    touchscreen-inverted-y;
    touchscreen-swapped-x-y;
};
```

- **I2C Address:** 0x38
- **Interrupt:** GPIO 25, falling edge
- **Screen Size:** 1280x400 (landscape)
- **Transformations:** inverted-x, inverted-y, swapped-x-y

#### Parameters

**No `__overrides__` section** - all parameters are hardcoded.

#### Why Not Loaded?

Touch may be working through:
1. Kernel built-in driver
2. Systemd service loading overlay dynamically
3. libinput detecting touch automatically

## Custom Overlays Analysis

### 1. ghettoblaster-amp100.dts (Simple Version)

**Differences from upstream:**
- Hardcoded for Pi 5: `compatible = "brcm,bcm2712"`
- No `__overrides__` section (no parameters)
- No hpamp@60 (headphone amplifier) support
- Simpler structure

**When to use:** When you don't need parameters (24db_digital_gain, slave, leds_off).

### 2. hifiberry-amp100-pi5-dsp-reset.dts

**Key features:**
- Pi 5 compatible
- Adds `auto_mute` parameter
- Adds `mute_ext_ctl` parameter
- Explicitly targets Pi 5 I2S path
- Creates sound node under `/axi` (Pi 5 structure)

**Parameters:**
- `24db_digital_gain`
- `leds_off`
- `mute_ext_ctl` - External mute control GPIO
- `auto_mute` - Enable automatic muting on silence

### 3. hifiberry-amp100-pi5-gpio14-active-low.dts

**Key features:**
- Adds `reset-gpio = <&gpio 14 1>` (GPIO 14, Active Low)
- Hardcoded I2C path: `/axi/pcie@1000120000/rp1/i2c@74000`
- No `__overrides__` (no parameters)

**Use case:** When you need GPIO 14 for DSP reset.

**WARNING:** GPIO conflicts possible with touch (GPIO 25).

### 4. hifiberry-amp100-pi5-overlay.dts

**Key features:**
- Adds both mute-gpio and reset-gpio:
  - `mute-gpio = <&gpio 4 0>`
  - `reset-gpio = <&gpio 17 0x11>`
- Has `__overrides__` (parameters: 24db_digital_gain, leds_off, mute_ext_ctl, auto_mute)

### 5. ghettoblaster-unified.dts

**Purpose:** Unified overlay combining AMP100 + FT6236 touch.

**Features:**
- Both PCM5122 and FT6236 in same overlay
- Clock frequency: 100kHz (stable I2C)
- Touch parameters hardcoded (1280x400, inverted, swapped)
- Auto-mute parameter available

**Advantages:**
- Single overlay loads both devices
- Guaranteed I2C stability (100kHz)
- No GPIO conflicts (no reset-gpio)

**Disadvantages:**
- If one device fails, both are affected
- Less modular

## Comparison: Custom vs Upstream

### HiFiBerry Overlays

| Feature | Upstream | Custom Pi 5 Variants |
|---------|----------|----------------------|
| Compatible string | `brcm,bcm2835` (all Pis) | `brcm,bcm2712` (Pi 5 only) |
| I2S target | `<&i2s_clk_consumer>` (resolved via fixup) | Explicit path: `/axi/pcie@1000120000/rp1/i2s@a4000` |
| auto_mute parameter | ❌ Does NOT exist | ✅ Added |
| reset-gpio | ❌ Not in standard DAC+ | ✅ Added in some variants |
| mute-gpio | ❌ Not in standard DAC+ | ✅ Added in some variants |
| Headphone amp support | ✅ hpamp@60 | ❌ Removed |

**Conclusion:** For Pi 5 with AMP100, you can use:
1. **Upstream `hifiberry-dacplus`** - Works on Pi 5, parameters: 24db_digital_gain, slave, leds_off
2. **Custom Pi 5 variants** - Adds auto_mute, explicit I2S paths, optional GPIO control

### vc4-kms Overlays

| Feature | Pi 4 (vc4-kms-v3d) | Pi 5 (vc4-kms-v3d-pi5) |
|---------|-------------------|------------------------|
| Compatible | `brcm,bcm2835` | `brcm,bcm2712` |
| HDMI controllers | hdmi | hdmi0, hdmi1 |
| noaudio parameter | ✅ Disables HDMI audio | ✅ Disables both HDMI audio |
| Separate audio control | ❌ Single audio parameter | ✅ audio, audio1 parameters |

**Conclusion:** For Pi 5, MUST use `vc4-kms-v3d-pi5` (not `vc4-kms-v3d`).

## Parameters That Do NOT Exist

These parameters were attempted in past fixes but **DO NOT EXIST** in device tree:

1. **`disable_iec958`** - IEC958 is ALSA software, not hardware
2. **Display rotation parameters** - Rotation is cmdline.txt + X11, not device tree
3. **Volume parameters** - Volume is ALSA/MPD, not hardware
4. **Audio format parameters** - PCM vs compressed is ALSA, not hardware

## Common Mistakes Explained

### Mistake 1: Trying to Configure IEC958 in Device Tree

**Wrong:**
```bash
dtoverlay=hifiberry-amp100,disable_iec958
```

**Why wrong:** IEC958 (S/PDIF) is configured in ALSA software layer:
- `/etc/asound.conf`
- ALSA controls: `amixer sset 'IEC958' off`
- Not a hardware device tree property

### Mistake 2: Expecting DTO to Rotate Display

**Wrong:**
```bash
dtoverlay=vc4-kms-v3d-pi5,rotation=90
```

**Why wrong:** Display rotation happens at two layers:
1. **Boot screen:** `cmdline.txt`: `video=HDMI-A-1:1280x400@60`
2. **X11 runtime:** `xrandr --rotate left` (read from moOde database)

Device tree only initializes the display hardware, not the framebuffer orientation.

### Mistake 3: Making Up Parameters

**Wrong:**
```bash
dtoverlay=hifiberry-amp100,automute  # Typo: should be auto_mute
dtoverlay=hifiberry-amp100,gain=24   # Wrong: should be 24db_digital_gain (boolean)
```

**How to verify parameters:**
1. Read the `.dts` source file
2. Look for `__overrides__` section
3. Only use parameters listed there
4. Check if parameter is boolean (`?`) or value (`:0`)

## Validation on Pi Hardware

### Commands to Check Loaded Overlays

```bash
# List all loaded overlays
vcgencmd get_config dtoverlay

# Check device tree overlay directory
ls -la /sys/kernel/config/device-tree/overlays/

# Decompile loaded overlay
dtc -I fs -O dts /sys/kernel/config/device-tree/overlays/hifiberry-amp100

# Check I2C devices detected
i2cdetect -y 1

# Expected output for Ghettoblaster:
#      0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
# 00:          -- -- -- -- -- -- -- -- -- -- -- -- -- 
# 10:          -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
# 20:          -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
# 30:          -- -- -- -- -- -- -- -- 38 -- -- -- -- -- -- -- 
# 40:          -- -- -- -- -- -- -- -- -- -- -- -- -- 4d -- -- 
# 50:          -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
# 60:          -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
# 70:          -- -- -- -- -- -- -- --
# 0x38 = FT6236 touch controller
# 0x4d = PCM5122 DAC

# Check sound cards
cat /proc/asound/cards
# Expected: card 0: sndrpihifiberry [snd_rpi_hifiberry_dacplus]

aplay -l
# Expected: card 0: sndrpihifiberry, device 0: HiFiBerry DAC+ HiFi pcm5122-hifi-0 []
```

### Testing auto_mute Parameter

**Test plan:**

1. Verify current overlay supports `auto_mute` (custom variants only)
2. Add to config.txt: `dtoverlay=hifiberry-amp100,auto_mute`
3. Reboot
4. Play audio
5. Stop audio
6. Observe if amplifier mutes after silence period

**Expected behavior:**
- Auto-mute should trigger after ~2-3 seconds of silence
- Amplifier relay should click off (audible)
- Reduces noise and saves power

**How to verify in kernel:**
```bash
# Check device tree property
cat /sys/firmware/devicetree/base/axi/sound/hifiberry-dacplus,auto_mute
# If auto_mute enabled, this file should exist
```

## Hardware Initialization Layers

```
┌─────────────────────────────────────────────────────────────┐
│ Layer 1: Device Tree (Boot Time)                            │
│ - Initialize I2C devices (PCM5122 at 0x4d, FT6236 at 0x38) │
│ - Enable I2S controller                                     │
│ - Set GPIO functions                                        │
│ - Create sound card                                         │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 2: Kernel Drivers (Runtime)                           │
│ - PCM5122 driver (ti,pcm5122)                              │
│ - FT6236 driver (focaltech,ft6236)                         │
│ - HiFiBerry sound driver (hifiberry-dacplus)               │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 3: ALSA (Audio Software)                              │
│ - /etc/asound.conf                                          │
│ - ALSA controls (amixer)                                    │
│ - IEC958 routing                                            │
│ - Volume controls                                           │
└─────────────────────────────────────────────────────────────┘
                            ↓
┌─────────────────────────────────────────────────────────────┐
│ Layer 4: moOde (Application)                                │
│ - Database settings                                         │
│ - Web UI controls                                           │
│ - MPD configuration                                         │
└─────────────────────────────────────────────────────────────┘
```

**Critical principle:** Each layer configures different aspects. Don't try to configure Layer 3 (ALSA) in Layer 1 (device tree).

## Recommended Configuration for Ghettoblaster

Based on this study, the recommended configuration is:

### Option A: Use Upstream Overlays (Simplest)

**config.txt:**
```ini
# Display
dtoverlay=vc4-kms-v3d-pi5,noaudio

# Audio
dtoverlay=hifiberry-dacplus

# Other settings
dtparam=i2c_arm=on
dtparam=i2s=on
dtparam=audio=off
```

**Advantages:**
- Standard Raspberry Pi overlays
- Well tested and maintained
- Parameters: 24db_digital_gain, slave, leds_off

**Disadvantages:**
- No auto_mute parameter
- No touch overlay (but touch may work anyway)

### Option B: Use Custom Unified Overlay

**config.txt:**
```ini
# Display
dtoverlay=vc4-kms-v3d-pi5,noaudio

# Audio + Touch (unified)
dtoverlay=ghettoblaster-unified,auto_mute

# Other settings
dtparam=i2c_arm=on
dtparam=i2s=on
dtparam=audio=off
```

**Advantages:**
- Single overlay for audio + touch
- Stable I2C (100kHz)
- auto_mute support
- No GPIO conflicts

**Disadvantages:**
- Custom overlay (needs maintenance)
- Less modular

### Option C: Use Separate Custom Overlays

**config.txt:**
```ini
# Display
dtoverlay=vc4-kms-v3d-pi5,noaudio

# Audio
dtoverlay=hifiberry-amp100-pi5-dsp-reset,auto_mute

# Touch
dtoverlay=ghettoblaster-ft6236

# Other settings
dtparam=i2c_arm=on
dtparam=i2s=on
dtparam=audio=off
```

**Advantages:**
- Modular (can disable touch independently)
- auto_mute support
- Full parameter control

**Disadvantages:**
- Two custom overlays to maintain
- Potential I2C clock conflicts

## What the v1.0 Working Config Actually Uses

```ini
# From v1.0-config-export/config.txt.working:
dtoverlay=vc4-kms-v3d-pi5,noaudio    # Line 13
dtoverlay=hifiberry-amp100            # Line 48
dtoverlay=vc4-kms-v3d-pi5,noaudio    # Line 49 (duplicate)
```

**Analysis:**
- Uses stock `hifiberry-amp100` (which is actually `hifiberry-dacplus`)
- No touch overlay in config.txt (touch working through other means)
- Duplicate `vc4-kms-v3d-pi5` (harmless but redundant)
- No custom parameters (no auto_mute)

**Why it works:**
- Stock overlays are sufficient for basic functionality
- Touch driver may be loaded via other means
- Auto-mute not critical for operation

## Conclusion

This study provides complete understanding of device tree overlays in the Ghettoblaster system. Key learnings:

1. **Device tree initializes hardware, not software:** Don't try to configure ALSA, MPD, or X11 in device tree.

2. **Parameters must exist in `__overrides__`:** Check the source `.dts` file before using any parameter.

3. **Pi 5 needs Pi 5-specific overlays:** Use `vc4-kms-v3d-pi5`, not `vc4-kms-v3d`.

4. **Custom overlays add features:** `auto_mute`, explicit I2S paths, GPIO control - but need maintenance.

5. **Working config uses stock overlays:** The v1.0 config proves stock overlays work fine.

## References

- Upstream overlays: https://github.com/raspberrypi/linux/tree/rpi-6.6.y/arch/arm/boot/dts/overlays
- Device tree specification: https://www.devicetree.org/
- Raspberry Pi overlay documentation: https://github.com/raspberrypi/firmware/blob/master/boot/overlays/README
- PCM5122 datasheet: https://www.ti.com/product/PCM5122
- FT6236 datasheet: https://www.buydisplay.com/download/ic/FT6236-FT6336-FT6436L-FT6436_Datasheet.pdf
