# Device Tree Parameters Quick Reference

## HiFiBerry AMP100 / DAC+ Parameters

### Upstream (hifiberry-dacplus)

| Parameter | Type | Usage | Description |
|-----------|------|-------|-------------|
| `24db_digital_gain` | bool | `dtoverlay=hifiberry-dacplus,24db_digital_gain` | Enable 24dB digital gain in PCM5122 |
| `slave` | bool | `dtoverlay=hifiberry-dacplus,slave` | Switch to clock producer mode (external clock) |
| `leds_off` | bool | `dtoverlay=hifiberry-dacplus,leds_off` | Disable status LEDs |

### Custom Pi 5 Variants

| Parameter | Type | Usage | Description | Overlay |
|-----------|------|-------|-------------|---------|
| `auto_mute` | bool | `dtoverlay=...,auto_mute` | Enable auto-mute on silence | hifiberry-amp100-pi5-dsp-reset, ghettoblaster-unified |
| `mute_ext_ctl` | int | `dtoverlay=...,mute_ext_ctl=4` | GPIO for external mute control | hifiberry-amp100-pi5-dsp-reset, ghettoblaster-unified |

## vc4-kms-v3d-pi5 Parameters

| Parameter | Type | Usage | Description |
|-----------|------|-------|-------------|
| `audio` | bool | `dtoverlay=vc4-kms-v3d-pi5,audio` | Enable HDMI audio on port 0 (default: on) |
| `audio1` | bool | `dtoverlay=vc4-kms-v3d-pi5,audio1` | Enable HDMI audio on port 1 (default: on) |
| `noaudio` | bool | `dtoverlay=vc4-kms-v3d-pi5,noaudio` | Disable HDMI audio on both ports |
| `composite` | bool | `dtoverlay=vc4-kms-v3d-pi5,composite` | Enable composite video output |
| `nohdmi0` | bool | `dtoverlay=vc4-kms-v3d-pi5,nohdmi0` | Disable HDMI port 0 |
| `nohdmi1` | bool | `dtoverlay=vc4-kms-v3d-pi5,nohdmi1` | Disable HDMI port 1 |
| `nohdmi` | bool | `dtoverlay=vc4-kms-v3d-pi5,nohdmi` | Disable both HDMI ports |

## FT6236 Touch Parameters

**Note:** The ghettoblaster-ft6236 overlay has **no configurable parameters**. All settings are hardcoded:

- I2C address: 0x38
- Screen size: 1280x400
- Transformations: inverted-x, inverted-y, swapped-x-y
- Interrupt: GPIO 25

## dtparam (Built-in Parameters)

| Parameter | Usage | Description |
|-----------|-------|-------------|
| `i2c_arm` | `dtparam=i2c_arm=on` | Enable I2C bus 1 (GPIO 2/3) |
| `i2s` | `dtparam=i2s=on` | Enable I2S interface |
| `audio` | `dtparam=audio=off` | Disable onboard audio (needed for external DAC) |
| `i2c_arm_baudrate` | `dtparam=i2c_arm_baudrate=100000` | Set I2C clock speed (100kHz for stability) |

## Parameter Types

### Boolean Parameters (ends with `?`)

**Syntax:** Parameter name only, no value

```dts
__overrides__ {
    auto_mute = <&sound>,"hifiberry-dacplus,auto_mute?";
}
```

**Usage:**
```ini
dtoverlay=hifiberry-amp100,auto_mute  # Enabled
dtoverlay=hifiberry-amp100            # Disabled (default)
```

### Value Parameters (ends with `:0`)

**Syntax:** Parameter=value

```dts
__overrides__ {
    mute_ext_ctl = <&sound>,"hifiberry-dacplus,mute_ext_ctl:0";
}
```

**Usage:**
```ini
dtoverlay=hifiberry-amp100,mute_ext_ctl=4  # GPIO 4
```

## Common Combinations

### Ghettoblaster Standard

```ini
# Display
dtoverlay=vc4-kms-v3d-pi5,noaudio

# Audio
dtoverlay=hifiberry-dacplus

# I2C and I2S
dtparam=i2c_arm=on
dtparam=i2s=on
dtparam=audio=off
```

### Ghettoblaster with Auto-Mute

```ini
# Display
dtoverlay=vc4-kms-v3d-pi5,noaudio

# Audio + Touch (unified)
dtoverlay=ghettoblaster-unified,auto_mute

# I2C and I2S
dtparam=i2c_arm=on
dtparam=i2s=on
dtparam=audio=off
```

### Ghettoblaster with Gain Boost

```ini
# Display
dtoverlay=vc4-kms-v3d-pi5,noaudio

# Audio with gain
dtoverlay=hifiberry-dacplus,24db_digital_gain

# I2C and I2S
dtparam=i2c_arm=on
dtparam=i2s=on
dtparam=audio=off
```

## Parameters That Do NOT Exist

These are commonly attempted but **do not exist** in any overlay:

| Non-existent Parameter | Why It Doesn't Exist |
|------------------------|----------------------|
| `disable_iec958` | IEC958 is ALSA software, not hardware |
| `rotation` | Rotation is cmdline.txt + xrandr, not device tree |
| `volume` | Volume is ALSA/MPD, not hardware |
| `automute` | Typo - should be `auto_mute` (underscore) |
| `gain` | Wrong name - should be `24db_digital_gain` |
| `format` | Audio format is ALSA, not hardware |

## How to Find Available Parameters

### Method 1: Read Overlay Source

```bash
# View upstream overlay
curl -s https://raw.githubusercontent.com/raspberrypi/linux/rpi-6.6.y/arch/arm/boot/dts/overlays/hifiberry-dacplus-overlay.dts | grep -A 20 "__overrides__"
```

### Method 2: Check Local Compiled Overlay

```bash
# List compiled overlays
ls -la /boot/firmware/overlays/*.dtbo

# Decompile overlay
dtc -I dtb -O dts /boot/firmware/overlays/hifiberry-dacplus.dtbo | grep -A 20 "__overrides__"
```

### Method 3: Check Raspberry Pi Documentation

```bash
# Read overlay README
cat /boot/firmware/overlays/README | grep -A 50 "hifiberry-dacplus"
```

## Verification

### Check What's Loaded

```bash
# List all loaded overlays with parameters
vcgencmd get_config dtoverlay
```

### Check Device Tree Property

```bash
# Example: Check if auto_mute is set
cat /sys/firmware/devicetree/base/axi/sound/hifiberry-dacplus,auto_mute
# If file exists, parameter is active
```

### Check Parameter Effect

```bash
# After loading with 24db_digital_gain:
amixer -c 0 scontrols | grep -i gain
# Should show 'Analogue Playback Boost' control

# After loading with noaudio:
ls /proc/asound/HDMI
# Should not exist (HDMI audio disabled)
```

## Summary

- ✅ Always check overlay source for available parameters
- ✅ Boolean parameters: just name, no value
- ✅ Value parameters: name=value
- ✅ Don't make up parameters - they must exist in `__overrides__`
- ✅ Verify parameter effect after loading

## See Also

- [DEVICE_TREE_OVERVIEW.md](DEVICE_TREE_OVERVIEW.md)
- [HIFIBERRY_AMP100_DTO.md](HIFIBERRY_AMP100_DTO.md)
- [VC4_KMS_DTO.md](VC4_KMS_DTO.md)
- [COMMON_MISTAKES.md](COMMON_MISTAKES.md)
