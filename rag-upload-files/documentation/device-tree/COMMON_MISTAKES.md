# Device Tree Common Mistakes

## Mistake 1: Trying to Configure IEC958 in Device Tree

### ❌ Wrong

```ini
dtoverlay=hifiberry-amp100,disable_iec958
```

### Why It's Wrong

IEC958 (S/PDIF) is **ALSA software configuration**, not hardware initialization. Device tree initializes the PCM5122 DAC hardware. ALSA then routes audio through it.

### ✅ Correct

Configure IEC958 in ALSA layer:

```bash
# Disable IEC958 via ALSA control
amixer sset 'IEC958' off

# Or in /etc/asound.conf
pcm.!default {
    type plug
    slave.pcm "noiec958"
}

pcm.noiec958 {
    type hw
    card 0
}
```

### Layer Understanding

```
Device Tree → PCM5122 Hardware → ALSA → IEC958 Routing
(Initializes I2C/I2S)            (Software routing)
```

## Mistake 2: Expecting Device Tree to Rotate Display

### ❌ Wrong

```ini
dtoverlay=vc4-kms-v3d-pi5,rotation=90
```

**This parameter doesn't exist!**

### Why It's Wrong

Display rotation happens at TWO different layers:

1. **Boot screen** (before X11): `cmdline.txt` video parameter
2. **Runtime screen** (X11): `xrandr` rotation

Device tree only **initializes display hardware**, not framebuffer orientation.

### ✅ Correct

**For boot screen:**

```bash
# /boot/firmware/cmdline.txt
video=HDMI-A-1:1280x400@60
```

**For runtime (moOde UI):**

```bash
# ~/.xinitrc reads from moOde database
HDMI_SCN_ORIENT=$(moodeutl -q "SELECT value FROM cfg_system WHERE param='hdmi_scn_orient'")
if [ "$HDMI_SCN_ORIENT" = "portrait" ]; then
    xrandr --output HDMI-2 --rotate left
fi
```

### Layer Understanding

```
Boot Time:
cmdline.txt → Framebuffer orientation (1280x400 landscape)
    ↓
Runtime:
.xinitrc → xrandr → X11 rotation (landscape or portrait)
```

## Mistake 3: Making Up Parameters

### ❌ Wrong

```ini
dtoverlay=hifiberry-amp100,automute      # Typo
dtoverlay=hifiberry-amp100,gain=24       # Wrong name
dtoverlay=hifiberry-amp100,volume=50     # Doesn't exist
```

### Why It's Wrong

Parameters MUST be defined in the overlay's `__overrides__` section. You can't make them up!

### ✅ Correct

**Always check the overlay source first:**

```bash
# View upstream overlay
curl -s https://raw.githubusercontent.com/raspberrypi/linux/rpi-6.6.y/arch/arm/boot/dts/overlays/hifiberry-dacplus-overlay.dts | grep -A 10 "__overrides__"
```

**Upstream hifiberry-dacplus has:**
- `24db_digital_gain` (not "gain")
- `slave`
- `leds_off`
- **NOT** `auto_mute` (that's in custom variants only)

### How to Verify Parameters

1. Read the `.dts` source file
2. Find the `__overrides__` section
3. Only use parameters listed there
4. Check if boolean (`?`) or value (`:0`)

## Mistake 4: Using Wrong Overlay for Pi Model

### ❌ Wrong (Pi 5)

```ini
dtoverlay=vc4-kms-v3d  # This is for Pi 4 and earlier!
```

### Why It's Wrong

Pi 5 has different hardware:
- Different compatible string: `brcm,bcm2712` (vs `brcm,bcm2835`)
- Different I2S controller path
- Different HDMI controller structure (hdmi0, hdmi1)

### ✅ Correct (Pi 5)

```ini
dtoverlay=vc4-kms-v3d-pi5
```

### Detection

The overlay checks compatible string:

```dts
/ {
    compatible = "brcm,bcm2712";  // Pi 5
}
```

If you use Pi 4 overlay on Pi 5, it won't match and won't load properly.

## Mistake 5: Confusing dtoverlay vs dtparam

### ❌ Wrong

```ini
dtparam=hifiberry-amp100  # dtparam is for simple on/off only!
```

### ✅ Correct

```ini
dtoverlay=hifiberry-amp100  # Loads overlay
dtparam=i2c_arm=on          # Enables I2C
dtparam=i2s=on              # Enables I2S
```

### Understanding

- **dtoverlay** = Load device tree overlay (`.dtbo` file)
- **dtparam** = Set simple on/off parameter in base device tree

## Mistake 6: Duplicating Overlays

### ❌ Redundant

```ini
dtoverlay=vc4-kms-v3d-pi5,noaudio
dtoverlay=hifiberry-amp100
dtoverlay=vc4-kms-v3d-pi5,noaudio  # Duplicate!
```

### Why It's Wrong

Loading the same overlay twice is wasteful. The second load is ignored (no error, but no benefit).

### ✅ Correct

```ini
dtoverlay=vc4-kms-v3d-pi5,noaudio
dtoverlay=hifiberry-amp100
```

### Check for Duplicates

```bash
grep "^dtoverlay=" /boot/firmware/config.txt | sort | uniq -d
```

## Mistake 7: Expecting Device Tree to Control Volume

### ❌ Wrong

```ini
dtoverlay=hifiberry-amp100,volume=50
```

**This parameter doesn't exist!**

### Why It's Wrong

Volume is controlled by:
1. **ALSA** - `amixer sset 'Digital' 80%`
2. **MPD** - MPD volume control
3. **moOde** - moOde UI volume slider

Device tree only initializes the DAC hardware.

### ✅ Correct

```bash
# Set volume via ALSA
amixer -c 0 sset 'Digital' 80%

# Or via MPD
mpc volume 50
```

## Mistake 8: Not Checking I2C After Overlay Load

### ❌ Wrong Workflow

```
1. Add dtoverlay=hifiberry-amp100 to config.txt
2. Reboot
3. Assume it works
4. Wonder why no sound
```

### ✅ Correct Workflow

```bash
# 1. Add overlay to config.txt
sudo nano /boot/firmware/config.txt
# dtoverlay=hifiberry-amp100

# 2. Reboot
sudo reboot

# 3. VERIFY I2C detection
i2cdetect -y 1
# Should show 0x4d = PCM5122

# 4. VERIFY sound card
cat /proc/asound/cards
aplay -l

# 5. Check kernel messages
dmesg | grep pcm5122
```

## Mistake 9: Mixing Hardware and Software Fixes

### ❌ Wrong Approach

```
Problem: IEC958 showing in ALSA
Wrong fix: Try to disable in device tree
Result: Doesn't work (IEC958 is software!)
```

### ✅ Correct Approach

**Identify the layer:**

| Layer | Controls What | Configured Where |
|-------|---------------|------------------|
| Hardware | I2C, I2S, GPIO | Device tree |
| Driver | PCM5122 features | Kernel module |
| ALSA | Audio routing | /etc/asound.conf |
| Application | Playback | MPD, moOde |

**Fix at the correct layer:**

```bash
# IEC958 problem? → Fix in ALSA layer
amixer sset 'IEC958' off

# Display orientation? → Fix in cmdline.txt + xrandr
# Volume issue? → Fix in ALSA/MPD
# Playback issue? → Fix in MPD config
```

## Mistake 10: Not Reading Overlay Source

### ❌ Wrong

```
Guessing parameters based on forum posts or old documentation
```

### ✅ Correct

**Always read the actual overlay source:**

```bash
# View local overlay
cat /boot/firmware/overlays/hifiberry-dacplus.dts

# View upstream overlay
curl -s https://raw.githubusercontent.com/raspberrypi/linux/rpi-6.6.y/arch/arm/boot/dts/overlays/hifiberry-dacplus-overlay.dts

# Check what parameters exist
grep -A 20 "__overrides__" <overlay-file>
```

**Trust the source, not random internet advice!**

## Summary of Key Principles

1. ✅ **Device tree = Hardware initialization only**
2. ✅ **Check overlay source for available parameters**
3. ✅ **Use correct overlay for Pi model (Pi 5 needs -pi5 variants)**
4. ✅ **Fix problems at the correct layer (hardware vs software)**
5. ✅ **Verify with i2cdetect and aplay after changes**
6. ✅ **Don't make up parameters - they must exist in __overrides__**
7. ✅ **Understand dtoverlay (loads overlay) vs dtparam (simple on/off)**

## Quick Reference: What Layer?

| Problem | Layer | Fix Where |
|---------|-------|-----------|
| DAC not detected | Hardware | Device tree |
| No sound card | Hardware/Driver | Device tree + kernel |
| IEC958 appearing | Software | ALSA (asound.conf) |
| Wrong volume | Software | ALSA/MPD |
| Display orientation | Boot/X11 | cmdline.txt + xrandr |
| No display | Hardware | Device tree + config.txt |
| Touch not working | Hardware | Device tree (touch overlay) |
| Touch mapping wrong | Software | X11 (xinput) |

## See Also

- [DEVICE_TREE_OVERVIEW.md](DEVICE_TREE_OVERVIEW.md)
- [HIFIBERRY_AMP100_DTO.md](HIFIBERRY_AMP100_DTO.md)
- [VC4_KMS_DTO.md](VC4_KMS_DTO.md)
- [PARAMETERS_REFERENCE.md](PARAMETERS_REFERENCE.md)
