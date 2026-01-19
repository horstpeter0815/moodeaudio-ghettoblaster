# vc4-kms-v3d-pi5 Display Overlay Analysis

## Overview

The `vc4-kms-v3d-pi5` overlay enables Kernel Mode Setting (KMS) for display on Raspberry Pi 5. It's required for any graphical output.

**Overlay name:** `vc4-kms-v3d-pi5`
**Upstream source:** https://github.com/raspberrypi/linux/blob/rpi-6.6.y/arch/arm/boot/dts/overlays/vc4-kms-v3d-pi5-overlay.dts

## What is KMS?

**Kernel Mode Setting (KMS)** = Modern Linux display management where the kernel (not X11) controls display hardware.

**Benefits:**
- Faster boot (no flickering mode changes)
- Smoother graphics
- Better multi-monitor support
- Required for Wayland compositors

## Hardware Components Enabled

The overlay enables the entire display pipeline:

1. **HDMI Controllers** (hdmi0, hdmi1) - Two HDMI ports
2. **DDC I2C Buses** - For reading display EDID
3. **HVS** (Hardware Video Scaler) - Scales and composites video
4. **MOP/Moplet** (Memory-to-Pixel) - DMA engines for display
5. **Pixel Valves** - Timing generators for displays
6. **V3D** - 3D graphics accelerator
7. **VC4** - Display controller with IOMMU

## Available Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `audio` | bool | true | Enable HDMI audio on port 0 |
| `audio1` | bool | true | Enable HDMI audio on port 1 |
| `noaudio` | bool | false | Disable HDMI audio on both ports |
| `composite` | bool | false | Enable composite video output |
| `nohdmi0` | bool | false | Disable HDMI port 0 |
| `nohdmi1` | bool | false | Disable HDMI port 1 |
| `nohdmi` | bool | false | Disable both HDMI ports |

## Critical Parameter: noaudio

**Usage:** `dtoverlay=vc4-kms-v3d-pi5,noaudio`

**What it does:**
```dts
noaudio = <0>,"=14", <0>,"=15";
```
- Activates dormant fragments 14 and 15
- Removes DMA channels from hdmi0 and hdmi1
- Disables HDMI audio hardware

**Why use it:**
- When using external DAC (like HiFiBerry AMP100)
- Prevents HDMI audio from interfering with I2S audio
- Required for Ghettoblaster configuration

**Common in config.txt with:**
```ini
dtoverlay=vc4-kms-v3d-pi5,noaudio
dtparam=audio=off                    # Disables onboard audio
hdmi_force_edid_audio=0               # Prevents HDMI audio detection
```

## What This Overlay Does NOT Do

❌ **Does NOT control display orientation**
- Boot screen orientation: `cmdline.txt` video parameter
- Runtime orientation: `xrandr` in `.xinitrc`

❌ **Does NOT set display resolution**
- Boot: `cmdline.txt` video parameter or `hdmi_timings` in config.txt
- Runtime: X11/Wayland handles resolution

❌ **Does NOT configure touch input**
- Touch is separate overlay (ft6236, etc.)

## Pi 5 vs Pi 4 Differences

| Feature | Pi 4 (vc4-kms-v3d) | Pi 5 (vc4-kms-v3d-pi5) |
|---------|-------------------|------------------------|
| Compatible | `brcm,bcm2835` | `brcm,bcm2712` |
| HDMI ports | Single (hdmi) | Dual (hdmi0, hdmi1) |
| Audio control | Single `audio` param | Separate `audio`, `audio1` |
| Display engine | VC4 | VC4 + RP1 enhancements |
| IOMMU | Basic | Enhanced (fragment@17) |

**CRITICAL:** On Pi 5, you MUST use `vc4-kms-v3d-pi5`, not `vc4-kms-v3d`.

## Verification

### Check if Loaded

```bash
vcgencmd get_config dtoverlay
# Should show: dtoverlay=vc4-kms-v3d-pi5
```

### Check HDMI Detection

```bash
vcgencmd get_config hdmi_force_hotplug
# Should be 1 if HDMI enabled

tvservice -s
# Shows current HDMI mode
```

### Check DRM Devices

```bash
ls -la /dev/dri/
# Expected: card0, card1, renderD128
```

### Check Kernel Messages

```bash
dmesg | grep -i vc4
dmesg | grep -i drm
```

## Common Issues

### Issue 1: Black Screen

**Symptom:** No display output after boot

**Causes:**
1. Overlay not loaded
2. Wrong overlay (using vc4-kms-v3d on Pi 5)
3. HDMI cable issue
4. Display not detected

**Debug:**
```bash
# Check if overlay loaded
vcgencmd get_config dtoverlay

# Force HDMI detection
# Add to config.txt:
hdmi_force_hotplug=1
```

### Issue 2: White Screen at Boot

**Symptom:** White screen during boot, then moOde UI appears

**Cause:** Framebuffer resolution doesn't match display

**Fix:** Set correct video parameter in cmdline.txt:
```
video=HDMI-A-1:1280x400@60
```

**Not a device tree issue!** This is cmdline.txt + X11.

## Summary

- **vc4-kms-v3d-pi5** enables display on Pi 5
- **noaudio parameter** disables HDMI audio (needed for external DAC)
- **Does NOT control orientation** (that's cmdline.txt + xrandr)
- **Does NOT set resolution** (that's cmdline.txt or hdmi_timings)
- **Must use Pi 5 version** on Pi 5 (not Pi 4 version)

## See Also

- [DEVICE_TREE_OVERVIEW.md](DEVICE_TREE_OVERVIEW.md)
- [COMMON_MISTAKES.md](COMMON_MISTAKES.md)
