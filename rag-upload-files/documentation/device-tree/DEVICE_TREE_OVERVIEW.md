# Device Tree Overview

**Purpose:** High-level introduction to device tree overlays for Ghettoblaster system

---

## What Are Device Tree Overlays?

Device Tree Overlays (DTO) are configuration files that tell the Raspberry Pi how to initialize hardware at boot time, before the operating system starts.

### Analogy

Think of device tree as a "hardware instruction manual" that the Pi reads during boot:

```
Power On → Firmware reads config.txt → Loads overlays → Initializes hardware → Boots Linux
```

### File Formats

**Source files (.dts):**
- Human-readable text
- Written by developers
- Contains hardware descriptions

**Compiled files (.dtbo):**
- Binary format
- Created by `dtc` compiler
- Loaded by Pi firmware

**Location:** `/boot/firmware/overlays/`

---

## Hardware vs Software Layers

### Device Tree Layer (Hardware)

**What it controls:**
- I2C devices (DAC, touch controller)
- I2S audio interfaces
- GPIO pins
- Clock sources
- Interrupts
- Power supplies

**Configuration file:** `/boot/firmware/config.txt`

**Example:**
```ini
dtoverlay=hifiberry-amp100
dtparam=auto_mute
```

### Software Layer

**What device tree does NOT control:**
- ALSA audio routing
- Volume levels
- MPD configuration
- moOde settings
- Display rotation (X11)
- Application settings

**Configuration files:**
- ALSA: `/etc/alsa/conf.d/`
- moOde: `/var/local/www/db/moode-sqlite3.db`
- X11: `/home/andre/.xinitrc`

---

## Ghettoblaster Overlays

The system uses 3 main overlays:

### 1. vc4-kms-v3d (Display)

**Purpose:** Enable modern display pipeline

**Usage:**
```ini
dtoverlay=vc4-kms-v3d,noaudio
```

**Parameter:**
- `noaudio` - Disable HDMI audio (required with audio HAT)

### 2. hifiberry-amp100 (Audio)

**Purpose:** Configure PCM5122 DAC for audio output

**Usage:**
```ini
dtoverlay=hifiberry-amp100
dtparam=auto_mute
```

**Parameters:**
- `auto_mute` - Mute amplifier when no audio
- `24db_digital_gain` - Boost digital gain
- `leds_off` - Disable LEDs

### 3. ft6236 (Touch)

**Purpose:** Configure capacitive touch controller

**Usage:**
```ini
dtoverlay=ft6236
```

**No parameters** - Fixed configuration for 1280x400 landscape

---

## Common Use Cases

### Enable Auto-Mute on Amplifier

**Problem:** Amplifier stays on even when no audio

**Solution:**
```ini
dtoverlay=hifiberry-amp100
dtparam=auto_mute
```

**Effect:** Amplifier mutes after ~3 seconds of silence

### Disable HDMI Audio for Audio HAT

**Problem:** Both HDMI and HAT trying to output audio

**Solution:**
```ini
dtoverlay=vc4-kms-v3d,noaudio
dtparam=audio=off
```

**Effect:** Only audio HAT outputs audio

### Configure Touch for Landscape Display

**Problem:** Touch coordinates don't match screen

**Solution:** Use ft6236 overlay (preconfigured)

```ini
dtoverlay=ft6236
```

**Effect:** Touch matches 1280x400 landscape orientation

---

## How to Check Loaded Overlays

### On Pi:

```bash
# List all loaded overlays
vcgencmd get_config dtoverlay

# Check device tree status
ls -la /sys/kernel/config/device-tree/overlays/

# Verify I2C devices
i2cdetect -y 1
```

### Expected Output:

**I2C devices:**
```
     0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
00:          -- -- -- -- -- -- -- -- -- -- -- -- -- 
10:          -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
20:          -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- -- 
30:          -- -- -- -- -- -- -- -- 38 -- -- -- -- -- -- -- 
40:          -- -- -- -- -- -- -- -- -- -- -- -- -- 4d -- --
```

- `0x38` = FT6236 touch controller
- `0x4d` = PCM5122 DAC

---

## Common Mistakes

### 1. Trying to Fix Software with Device Tree

**Wrong:**
```ini
dtparam=disable_iec958  # Does not exist!
```

**Why:** IEC958 is ALSA software, not hardware

**Correct:**
```sql
-- Fix in moOde database
UPDATE cfg_system SET value='plughw' WHERE param='alsa_output_mode';
```

### 2. Expecting Display Rotation from Device Tree

**Wrong:** Assuming `dtoverlay=vc4-kms-v3d` rotates display

**Correct:** Display rotation requires:
- Boot: `cmdline.txt` with `video=` parameter
- Runtime: `xrandr` in X11

### 3. Making Up Parameters

**Wrong:**
```ini
dtparam=automute  # Wrong spelling
dtparam=mute_on_silence  # Does not exist
```

**Correct:** Check `__overrides__` in .dts source:
```ini
dtparam=auto_mute  # Correct spelling with underscore
```

---

## Further Reading

- **Master Reference:** [DEVICE_TREE_MASTER_REFERENCE.md](../../../WISSENSBASIS/DEVICE_TREE_MASTER_REFERENCE.md)
- **HiFiBerry Details:** [HIFIBERRY_AMP100_DTO.md](HIFIBERRY_AMP100_DTO.md)
- **Touch Details:** [FT6236_DTO.md](FT6236_DTO.md)
- **Display Details:** [VC4_KMS_DTO.md](VC4_KMS_DTO.md)
- **Common Mistakes:** [COMMON_MISTAKES.md](COMMON_MISTAKES.md)

---

**Key Takeaway:** Device tree configures hardware only. Software configuration (ALSA, moOde, X11) is separate and must be configured in appropriate software configuration files.
