# HiFiBerry AMP100 Device Tree Overlay Analysis

## Overview

The HiFiBerry AMP100 uses the **same overlay as HiFiBerry DAC+** (`hifiberry-dacplus`). Both use the PCM5122 DAC chip. The only difference is the AMP100 has an integrated amplifier.

**Overlay name in config.txt:** `hifiberry-amp100` or `hifiberry-dacplus`

**Upstream source:** https://github.com/raspberrypi/linux/blob/rpi-6.6.y/arch/arm/boot/dts/overlays/hifiberry-dacplus-overlay.dts

## Hardware Components

### 1. PCM5122 DAC (Texas Instruments)

- **Chip:** PCM5122 - 32-bit, 384kHz Audio Stereo DAC
- **I2C Address:** 0x4d
- **Interface:** I2S (Inter-IC Sound)
- **Data sheet:** https://www.ti.com/product/PCM5122

**Capabilities:**
- 32-bit audio processing
- Sample rates: 8kHz - 384kHz
- THD+N: -100dB (typical)
- DNR: 112dB (typical)

### 2. AMP100 Amplifier

- **Power:** 2x 30W @ 4Ω
- **Class:** Class D
- **Features:** Auto-mute, thermal protection, short circuit protection

## Overlay Structure Analysis

### Fragment 0: Clock Generator

```dts
fragment@0 {
    target-path = "/";
    __overlay__ {
        dacpro_osc: dacpro_osc {
            compatible = "hifiberry,dacpro-clk";
            #clock-cells = <0>;
        };
    };
};
```

**Purpose:** Creates a clock source for the PCM5122 DAC.

**Why needed:** The PCM5122 needs a master clock (MCLK) to generate audio sample rates. The HiFiBerry boards have an onboard oscillator that provides this clock.

**Driver:** `hifiberry,dacpro-clk` - Custom HiFiBerry clock driver

### Fragment 1: I2S Controller

```dts
frag1: fragment@1 {
    target = <&i2s_clk_consumer>;
    __overlay__ {
        status = "okay";
    };
};
```

**Purpose:** Enables the I2S controller in "clock consumer" mode.

**Clock consumer vs producer:**
- **Consumer mode (slave):** DAC generates clocks (BCK, LRCK), Pi receives them
- **Producer mode (master):** Pi generates clocks, DAC receives them

**HiFiBerry AMP100 uses consumer mode** because the DAC generates its own clocks from the oscillator.

**On Pi 5:** `i2s_clk_consumer` resolves to `/axi/pcie@1000120000/rp1/i2s@a4000`

### Fragment 2: I2C Configuration

```dts
fragment@2 {
    target = <&i2c1>;
    __overlay__ {
        #address-cells = <1>;
        #size-cells = <0>;
        status = "okay";

        pcm5122@4d {
            #sound-dai-cells = <0>;
            compatible = "ti,pcm5122";
            reg = <0x4d>;
            clocks = <&dacpro_osc>;
            AVDD-supply = <&vdd_3v3_reg>;
            DVDD-supply = <&vdd_3v3_reg>;
            CPVDD-supply = <&vdd_3v3_reg>;
            status = "okay";
        };
        
        hpamp: hpamp@60 {
            compatible = "ti,tpa6130a2";
            reg = <0x60>;
            status = "disabled";
        };
    };
};
```

**Purpose:** Configures the PCM5122 DAC on I2C bus 1.

**Key properties:**

| Property | Value | Description |
|----------|-------|-------------|
| `compatible` | `ti,pcm5122` | Linux driver to use |
| `reg` | `0x4d` | I2C slave address |
| `clocks` | `<&dacpro_osc>` | Clock source (from fragment@0) |
| `AVDD-supply` | `<&vdd_3v3_reg>` | Analog power supply (3.3V) |
| `DVDD-supply` | `<&vdd_3v3_reg>` | Digital power supply (3.3V) |
| `CPVDD-supply` | `<&vdd_3v3_reg>` | Charge pump power supply (3.3V) |

**Headphone amplifier (hpamp@60):**
- Disabled by default
- Used on HiFiBerry DAC+ Pro (has headphone output)
- Not used on AMP100 (no headphone jack)

### Fragment 3: Sound Card

```dts
fragment@3 {
    target = <&sound>;
    hifiberry_dacplus: __overlay__ {
        compatible = "hifiberry,hifiberry-dacplus";
        i2s-controller = <&i2s_clk_consumer>;
        status = "okay";
    };
};
```

**Purpose:** Creates an ALSA sound card device.

**Properties:**
- `compatible = "hifiberry,hifiberry-dacplus"` - Loads HiFiBerry DAC+ sound driver
- `i2s-controller = <&i2s_clk_consumer>` - Links to I2S interface

**This creates the ALSA card:**
```bash
$ cat /proc/asound/cards
 0 [sndrpihifiberry]: HifiberryDacp - snd_rpi_hifiberry_dacplus
                      snd_rpi_hifiberry_dacplus
```

## Available Parameters (__overrides__)

### 1. 24db_digital_gain

**Type:** Boolean
**Default:** Off (disabled)
**Usage:** `dtoverlay=hifiberry-amp100,24db_digital_gain`

**What it does:**
- Enables 24dB digital gain in PCM5122
- Increases digital signal level before DAC conversion
- Useful if input signal is too quiet

**When to use:**
- When you need more volume headroom
- When source material is mastered at low levels

**When NOT to use:**
- With normal/loud source material (can cause clipping)
- If you have sufficient volume without it

### 2. slave

**Type:** Boolean + Retargeting
**Default:** Off (consumer mode)
**Usage:** `dtoverlay=hifiberry-amp100,slave`

**What it does:**
```dts
slave = <&hifiberry_dacplus>,"hifiberry-dacplus,slave?",
        <&frag1>,"target:0=",<&i2s_clk_producer>,
        <&hifiberry_dacplus>,"i2s-controller:0=",<&i2s_clk_producer>;
```

- Switches I2S to producer mode (Pi generates clocks)
- Retargets fragment@1 to `i2s_clk_producer` instead of `i2s_clk_consumer`
- Sets `hifiberry-dacplus,slave` property on sound card

**When to use:**
- When using external master clock
- When chaining multiple DACs
- Advanced use cases only

**Standard HiFiBerry AMP100 does NOT need this parameter** (uses consumer mode).

### 3. leds_off

**Type:** Boolean
**Default:** Off (LEDs enabled)
**Usage:** `dtoverlay=hifiberry-amp100,leds_off`

**What it does:**
- Disables status LEDs on HiFiBerry board
- Sets `hifiberry-dacplus,leds_off` property

**When to use:**
- When you don't want LED light pollution
- In dark environments (home theater)
- To save minimal power

## Parameters That Do NOT Exist in Upstream Overlay

### auto_mute (Custom Addition)

**NOT in upstream `hifiberry-dacplus-overlay.dts`**

**Where it exists:**
- `hifiberry-amp100-pi5-dsp-reset.dts` (custom)
- `hifiberry-amp100-pi5-overlay.dts` (custom)
- `ghettoblaster-unified.dts` (custom)

**Usage:** `dtoverlay=hifiberry-amp100-custom,auto_mute`

**What it does:**
- Enables automatic muting of amplifier after silence period
- Reduces noise and saves power
- Typically triggers after 2-3 seconds of silence

**Implementation in custom overlays:**
```dts
__overrides__ {
    auto_mute = <&sound>,"hifiberry-dacplus,auto_mute?";
};
```

### mute_ext_ctl (Custom Addition)

**NOT in upstream overlay**

**Where it exists:**
- `hifiberry-amp100-pi5-dsp-reset.dts` (custom)
- `hifiberry-amp100-pi5-overlay.dts` (custom)
- `ghettoblaster-unified.dts` (custom)

**Usage:** `dtoverlay=hifiberry-amp100-custom,mute_ext_ctl=4`

**What it does:**
- Sets GPIO pin for external mute control
- Allows hardware mute via GPIO

**Example:**
```dts
__overrides__ {
    mute_ext_ctl = <&sound>,"hifiberry-dacplus,mute_ext_ctl:0";
};
```

## Pi 5 Compatibility

### Upstream Overlay (Works on Pi 5)

The upstream `hifiberry-dacplus` overlay uses symbolic references that work across Pi models:

```dts
target = <&i2s_clk_consumer>;
target = <&i2c1>;
target = <&sound>;
```

These are resolved by `__fixups__` at boot time to the correct hardware paths for each Pi model.

**On Pi 5:**
- `i2s_clk_consumer` → `/axi/pcie@1000120000/rp1/i2s@a4000`
- `i2c1` → `/axi/pcie@1000120000/rp1/i2c@74000`

### Custom Pi 5 Overlays (Explicit Paths)

Custom overlays for Pi 5 use explicit hardware paths:

```dts
compatible = "brcm,bcm2712";  // Pi 5 only

target-path = "/axi/pcie@1000120000/rp1/i2s@a4000";  // Explicit I2S path
target-path = "/axi/pcie@1000120000/rp1/i2c@74000";  // Explicit I2C path
```

**Advantages of explicit paths:**
- No dependency on symbolic references
- Guaranteed to work on Pi 5
- Clear what hardware is being configured

**Disadvantages:**
- Won't work on other Pi models
- Less flexible
- More maintenance if hardware changes

## Comparison: Upstream vs Custom Overlays

| Feature | Upstream (hifiberry-dacplus) | Custom Pi 5 Variants |
|---------|------------------------------|----------------------|
| **Compatible with** | All Pi models | Pi 5 only |
| **I2S targeting** | Symbolic (`<&i2s_clk_consumer>`) | Explicit path |
| **I2C targeting** | Symbolic (`<&i2c1>`) | Explicit path |
| **24db_digital_gain** | ✅ Yes | ✅ Yes |
| **slave** | ✅ Yes | ❌ No (some variants) |
| **leds_off** | ✅ Yes | ✅ Yes (some variants) |
| **auto_mute** | ❌ No | ✅ Yes |
| **mute_ext_ctl** | ❌ No | ✅ Yes |
| **reset-gpio** | ❌ No | ✅ Yes (some variants) |
| **mute-gpio** | ❌ No | ✅ Yes (some variants) |
| **Headphone amp** | ✅ Yes (hpamp@60) | ❌ No |

## Custom Overlay Variants

### 1. ghettoblaster-amp100.dts (Simple)

**Characteristics:**
- Minimal overlay
- No parameters (`__overrides__` section missing)
- Hardcoded for Pi 5
- No GPIO control

**When to use:**
- When you don't need any parameters
- Simplest possible configuration

### 2. hifiberry-amp100-pi5-dsp-reset.dts

**Characteristics:**
- Parameters: 24db_digital_gain, leds_off, mute_ext_ctl, auto_mute
- Explicit I2S path
- Creates sound node under `/axi`
- No GPIO hardcoded (controlled via parameters)

**When to use:**
- When you need auto_mute
- When you want flexible GPIO control via parameters

### 3. hifiberry-amp100-pi5-gpio14-active-low.dts

**Characteristics:**
- Hardcoded `reset-gpio = <&gpio 14 1>` (GPIO 14, Active Low)
- No parameters (`__overrides__` missing)
- Explicit I2C path: `/axi/pcie@1000120000/rp1/i2c@74000`

**When to use:**
- When you need GPIO 14 for DSP reset
- Not recommended (conflicts with other uses of GPIO 14)

### 4. hifiberry-amp100-pi5-overlay.dts

**Characteristics:**
- Hardcoded GPIOs:
  - `mute-gpio = <&gpio 4 0>`
  - `reset-gpio = <&gpio 17 0x11>`
- Parameters: 24db_digital_gain, leds_off, mute_ext_ctl, auto_mute

**When to use:**
- When you need both mute and reset GPIOs
- Check GPIO conflicts first!

### 5. ghettoblaster-unified.dts

**Characteristics:**
- Combines AMP100 + FT6236 touch in one overlay
- Stable I2C: `clock-frequency = <100000>` (100kHz)
- Parameters: auto_mute, 24db_digital_gain, leds_off, mute_ext_ctl
- No GPIO conflicts (no reset-gpio)

**When to use:**
- When you want audio + touch in single overlay
- Recommended for Ghettoblaster

## Verification Commands

### Check I2C Detection

```bash
i2cdetect -y 1
```

**Expected output:**
```
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
...
40:          -- -- -- -- -- -- -- -- -- -- -- -- -- 4d -- --
...
```

**0x4d = PCM5122 detected**

### Check Sound Card

```bash
cat /proc/asound/cards
```

**Expected output:**
```
 0 [sndrpihifiberry]: HifiberryDacp - snd_rpi_hifiberry_dacplus
                      snd_rpi_hifiberry_dacplus
```

```bash
aplay -l
```

**Expected output:**
```
card 0: sndrpihifiberry [snd_rpi_hifiberry_dacplus], device 0: HiFiBerry DAC+ HiFi pcm5122-hifi-0 []
  Subdevices: 1/1
  Subdevice #0: subdevice #0
```

### Check Device Tree Properties

```bash
# Check if PCM5122 is in device tree
ls -la /sys/firmware/devicetree/base/axi/*/i2c*/pcm5122@4d/

# Check clock source
cat /sys/firmware/devicetree/base/axi/*/i2c*/pcm5122@4d/clocks

# Check sound card compatible string
cat /sys/firmware/devicetree/base/axi/sound/compatible
# Expected: hifiberry,hifiberry-dacplus
```

### Check ALSA Controls

```bash
amixer -c 0 scontrols
```

**Expected controls:**
```
Simple mixer control 'DSP Program',0
Simple mixer control 'Analogue',0
Simple mixer control 'Analogue Playback Boost',0
Simple mixer control 'Auto Mute',0
Simple mixer control 'Auto Mute Mono',0
Simple mixer control 'Auto Mute Time Left',0
Simple mixer control 'Auto Mute Time Right',0
Simple mixer control 'Clock Missing Period',0
Simple mixer control 'Deemphasis',0
Simple mixer control 'Digital',0
Simple mixer control 'Max PCM Level',0
Simple mixer control 'Min PCM Level',0
```

**These controls come from the PCM5122 driver, NOT device tree!**

## Recommended Configuration

### For Standard Ghettoblaster (Stock Overlay)

```ini
# config.txt
dtoverlay=hifiberry-dacplus
dtparam=i2c_arm=on
dtparam=i2s=on
dtparam=audio=off
```

**Advantages:**
- Standard upstream overlay
- Well tested
- Parameters available: 24db_digital_gain, slave, leds_off

### For Ghettoblaster with Auto-Mute (Custom Overlay)

```ini
# config.txt
dtoverlay=ghettoblaster-unified,auto_mute
dtparam=i2c_arm=on
dtparam=i2s=on
dtparam=audio=off
```

**Advantages:**
- Auto-mute support
- Combined audio + touch
- Stable I2C (100kHz)

## Common Issues

### Issue 1: No Sound Card Detected

**Symptom:**
```bash
$ cat /proc/asound/cards
--- no soundcards ---
```

**Causes:**
1. Overlay not loaded
2. I2S not enabled (`dtparam=i2s=on` missing)
3. Hardware not connected
4. I2C address wrong

**Debug:**
```bash
# Check if overlay loaded
vcgencmd get_config dtoverlay

# Check I2C detection
i2cdetect -y 1

# Check kernel messages
dmesg | grep -i pcm5122
dmesg | grep -i hifiberry
```

### Issue 2: PCM5122 Not Detected on I2C

**Symptom:**
```bash
$ i2cdetect -y 1
# No 0x4d shown
```

**Causes:**
1. I2C not enabled (`dtparam=i2c_arm=on` missing)
2. Hardware not connected
3. Wrong I2C bus
4. I2C clock too fast (stability issue)

**Fix:**
```ini
# Slow down I2C clock
dtparam=i2c_arm=on,i2c_arm_baudrate=100000
```

### Issue 3: Auto-Mute Not Working

**Symptom:** Amplifier doesn't mute on silence

**Causes:**
1. Using upstream overlay (doesn't have auto_mute parameter)
2. Parameter not set: `dtoverlay=...,auto_mute` missing
3. ALSA control not enabled

**Fix:**
```bash
# Check if auto_mute property exists
cat /sys/firmware/devicetree/base/axi/sound/hifiberry-dacplus,auto_mute
# If file doesn't exist, overlay doesn't support auto_mute

# If property exists, check ALSA control
amixer sset 'Auto Mute' on
```

## Summary

- **HiFiBerry AMP100 = HiFiBerry DAC+ with amplifier**
- **Upstream overlay works on Pi 5** (uses symbolic references)
- **Custom overlays add auto_mute** (not in upstream)
- **Check overlay source for available parameters**
- **Don't make up parameters** - they must exist in `__overrides__`
- **Verify with i2cdetect and aplay** after loading overlay

## References

- Upstream overlay: https://github.com/raspberrypi/linux/blob/rpi-6.6.y/arch/arm/boot/dts/overlays/hifiberry-dacplus-overlay.dts
- PCM5122 datasheet: https://www.ti.com/product/PCM5122
- HiFiBerry documentation: https://www.hifiberry.com/docs/
- I2S specification: https://www.sparkfun.com/datasheets/BreakoutBoards/I2SBUS.pdf
