# Device Tree Overview for Ghettoblaster

## What is Device Tree?

Device Tree is a hardware description format used by Linux to initialize hardware at boot time. It describes:

- Hardware devices (I2C, SPI, GPIO, etc.)
- Device addresses and properties
- Interrupt routing
- Clock sources
- Power supplies

## Device Tree vs Software Layers

This is the most critical concept to understand:

### What Device Tree Controls (Hardware Layer)

✅ **Device tree initializes hardware:**
- I2C devices (PCM5122 DAC, FT6236 touch controller)
- I2S audio interface
- GPIO pin functions
- Clock sources and frequencies
- Hardware reset lines
- Power supply connections

### What Device Tree Does NOT Control (Software Layers)

❌ **Device tree does NOT configure:**
- ALSA audio routing (that's `/etc/asound.conf`)
- IEC958/SPDIF settings (that's ALSA software)
- MPD configuration (that's `/etc/mpd.conf`)
- moOde database settings (that's SQLite)
- X11 display rotation (that's `xrandr` in `.xinitrc`)
- Volume levels (that's ALSA/MPD)
- Audio formats (that's ALSA/MPD)
- Boot screen orientation (that's `cmdline.txt` video parameter)

## Layer Architecture

```
Boot Time:
┌─────────────────┐
│  Device Tree    │ ← Initializes hardware (I2C, I2S, GPIO)
└────────┬────────┘
         ↓
┌─────────────────┐
│ Kernel Drivers  │ ← PCM5122 driver, FT6236 driver, etc.
└────────┬────────┘
         ↓
Runtime:
┌─────────────────┐
│  ALSA           │ ← Audio routing, IEC958, volume
└────────┬────────┘
         ↓
┌─────────────────┐
│  moOde/MPD      │ ← Application settings, playback
└─────────────────┘
```

## Overlays vs dtparam

### Device Tree Overlays (dtoverlay)

Overlays **add or modify** hardware device tree nodes. They load `.dtbo` (compiled device tree blob overlay) files.

**Example:**
```ini
dtoverlay=hifiberry-amp100
dtoverlay=vc4-kms-v3d-pi5,noaudio
```

### Device Tree Parameters (dtparam)

Parameters **set simple on/off switches** for built-in features.

**Example:**
```ini
dtparam=i2c_arm=on
dtparam=i2s=on
dtparam=audio=off
```

## How Overlays Work

1. **Raspberry Pi bootloader** reads `/boot/firmware/config.txt`
2. **Loads base device tree** for Pi model (e.g., `bcm2712-rpi-5-b.dtb` for Pi 5)
3. **Applies overlays** listed in `dtoverlay=` lines
4. **Applies parameters** listed in `dtparam=` lines
5. **Passes final device tree** to Linux kernel
6. **Kernel loads drivers** for devices described in device tree

## Overlay Files Location

### Compiled Overlays (.dtbo)

**Location:** `/boot/firmware/overlays/`

**Example:**
```bash
/boot/firmware/overlays/hifiberry-amp100.dtbo
/boot/firmware/overlays/vc4-kms-v3d-pi5.dtbo
```

### Source Overlays (.dts)

**Upstream:** https://github.com/raspberrypi/linux/tree/rpi-6.6.y/arch/arm/boot/dts/overlays

**Custom (Ghettoblaster):**
- `custom-components/overlays/ghettoblaster-amp100.dts`
- `custom-components/overlays/ghettoblaster-ft6236.dts`
- `ghettoblaster-unified.dts`

## Device Tree Syntax Basics

### Fragment Structure

```dts
fragment@0 {
    target = <&i2c1>;           // Target existing device tree node
    __overlay__ {
        pcm5122@4d {            // Add device at I2C address 0x4d
            compatible = "ti,pcm5122";
            reg = <0x4d>;
            // ... properties ...
        };
    };
};
```

### Parameters (__overrides__)

```dts
__overrides__ {
    auto_mute = <&sound>,"hifiberry-dacplus,auto_mute?";
    // Usage: dtoverlay=hifiberry-amp100,auto_mute
};
```

- **Boolean parameter** (ends with `?`): Set by presence of parameter name
- **Value parameter** (ends with `:0`): Set by parameter=value

## Common Mistakes

### Mistake 1: Trying to Fix Software Problems with Device Tree

❌ **Wrong:**
```ini
dtoverlay=hifiberry-amp100,disable_iec958
```

✅ **Correct:**
```bash
# IEC958 is ALSA software, configure in /etc/asound.conf
amixer sset 'IEC958' off
```

### Mistake 2: Making Up Parameters

❌ **Wrong:**
```ini
dtoverlay=hifiberry-amp100,automute  # Typo
dtoverlay=hifiberry-amp100,gain=24    # Wrong parameter name
```

✅ **Correct:**
```ini
dtoverlay=hifiberry-amp100,auto_mute  # Correct (if overlay supports it)
dtoverlay=hifiberry-amp100,24db_digital_gain  # Correct parameter name
```

**Always check the overlay source for available parameters!**

### Mistake 3: Wrong Overlay for Pi Model

❌ **Wrong (Pi 5):**
```ini
dtoverlay=vc4-kms-v3d  # This is for Pi 4 and earlier
```

✅ **Correct (Pi 5):**
```ini
dtoverlay=vc4-kms-v3d-pi5  # Pi 5 has different hardware
```

## How to Verify What's Loaded

### Check Loaded Overlays

```bash
vcgencmd get_config dtoverlay
```

**Expected output:**
```
dtoverlay=vc4-kms-v3d-pi5
dtoverlay=hifiberry-amp100
```

### Check Device Tree Status

```bash
ls -la /sys/kernel/config/device-tree/overlays/
```

### Decompile Loaded Overlay

```bash
dtc -I fs -O dts /sys/kernel/config/device-tree/overlays/hifiberry-amp100
```

### Check I2C Devices

```bash
i2cdetect -y 1
```

**Expected for Ghettoblaster:**
- `0x38` = FT6236 touch controller
- `0x4d` = PCM5122 DAC

### Check Sound Card

```bash
cat /proc/asound/cards
aplay -l
```

**Expected:**
- Card 0: `sndrpihifiberry`
- Device 0: `HiFiBerry DAC+`

## Debugging Device Tree Issues

### Step 1: Verify Overlay File Exists

```bash
ls -la /boot/firmware/overlays/hifiberry-amp100.dtbo
```

### Step 2: Check config.txt Syntax

```bash
grep dtoverlay /boot/firmware/config.txt
```

Common errors:
- Typos in overlay name
- Wrong parameter syntax
- Missing comma between overlay name and parameters

### Step 3: Check Kernel Messages

```bash
dmesg | grep -i "device tree"
dmesg | grep -i "overlay"
```

### Step 4: Verify Hardware Detection

```bash
# I2C devices
i2cdetect -y 1

# Sound cards
cat /proc/asound/cards

# GPIO state
cat /sys/kernel/debug/gpio
```

## Best Practices

### 1. Use Stock Overlays When Possible

Stock Raspberry Pi overlays are well-tested and maintained. Only use custom overlays when you need features not available in stock.

### 2. Check Parameters Before Using

Always read the overlay source (`.dts` file) to see what parameters exist:

```bash
# View overlay source from GitHub
curl -s https://raw.githubusercontent.com/raspberrypi/linux/rpi-6.6.y/arch/arm/boot/dts/overlays/hifiberry-dacplus-overlay.dts | grep -A 20 "__overrides__"
```

### 3. Don't Duplicate Overlays

Loading the same overlay twice is harmless but wasteful:

❌ **Redundant:**
```ini
dtoverlay=vc4-kms-v3d-pi5,noaudio
dtoverlay=hifiberry-amp100
dtoverlay=vc4-kms-v3d-pi5,noaudio  # Duplicate
```

✅ **Clean:**
```ini
dtoverlay=vc4-kms-v3d-pi5,noaudio
dtoverlay=hifiberry-amp100
```

### 4. Document Custom Overlays

If you create custom overlays, document:
- Why they were created
- What they change vs stock
- What parameters they support
- How to compile them

### 5. Keep Overlays in Version Control

Store `.dts` source files in git along with compiled `.dtbo` files. This allows:
- Tracking changes over time
- Rolling back if issues arise
- Understanding why customizations were made

## Summary

**Device Tree = Hardware Initialization**

- Use device tree to describe and initialize hardware
- Use ALSA/software layers to configure audio routing and processing
- Check overlay source for available parameters
- Don't make up parameters that don't exist
- Use stock overlays when possible
- Understand the layer separation: Hardware (DT) → Driver → ALSA → Application

## See Also

- [HIFIBERRY_AMP100_DTO.md](HIFIBERRY_AMP100_DTO.md) - Detailed HiFiBerry AMP100 overlay analysis
- [VC4_KMS_DTO.md](VC4_KMS_DTO.md) - Display overlay analysis
- [PARAMETERS_REFERENCE.md](PARAMETERS_REFERENCE.md) - All available parameters
- [COMMON_MISTAKES.md](COMMON_MISTAKES.md) - What NOT to do
