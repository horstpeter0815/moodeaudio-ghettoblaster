# Device Tree Common Mistakes

**Purpose:** Document common mistakes when working with device tree overlays and how to avoid them

---

## 1. Making Up Parameters That Don't Exist

### The Mistake

**Example:**
```ini
dtparam=disable_iec958
dtparam=remove_hdmi_audio
dtparam=enable_stereo
```

### Why It's Wrong

Parameters must exist in the overlay's `__overrides__` section to work. You cannot invent parameters.

**How to verify a parameter exists:**
1. Find the .dts source file
2. Look for `__overrides__` section
3. Check if parameter is listed

**Example of valid `__overrides__`:**
```dts
__overrides__ {
    auto_mute = <&sound>,"hifiberry-dacplus,auto_mute?";
    24db_digital_gain = <&sound>,"hifiberry,24db_digital_gain?";
};
```

### The Fix

**Wrong:**
```ini
dtparam=disable_iec958  # Does not exist!
```

**Correct:**
```ini
# IEC958 is ALSA software, not device tree hardware
# Fix in moOde database:
UPDATE cfg_system SET value='plughw' WHERE param='alsa_output_mode';
```

---

## 2. Confusing Hardware and Software Layers

### The Mistake

Trying to fix software problems with device tree parameters, or vice versa.

### Examples

**Mistake: Trying to configure ALSA routing in device tree**
```ini
dtparam=use_camilladsp  # Does not exist
dtparam=alsa_device=iec958  # Wrong layer
```

**Why:** Device tree configures hardware (I2C, I2S, GPIO). ALSA routing is software configuration.

**Correct approach:**
- Device tree: Initialize PCM5122 DAC hardware
- ALSA config: Route audio through CamillaDSP plugin
- File: `/etc/alsa/conf.d/_audioout.conf`

**Mistake: Expecting device tree to set volume**
```ini
dtparam=volume=50  # Does not exist
```

**Why:** Volume is controlled by ALSA (amixer) or MPD, not hardware initialization.

**Correct approach:**
```bash
# ALSA volume
amixer -c 0 sset Digital 50%

# MPD volume
mpc volume 50
```

### Layer Breakdown

**Device Tree (Hardware):**
- I2C devices and addresses
- I2S interface enable
- GPIO assignments
- Clock sources
- Power supplies

**ALSA (Software - Audio Routing):**
- Device names (_audioout, camilladsp, iec958)
- Plugin chains
- Sample rate conversion
- Volume control

**moOde (Application):**
- Database settings
- User preferences
- MPD configuration

---

## 3. Expecting Display Rotation from Device Tree

### The Mistake

```ini
dtoverlay=vc4-kms-v3d,rotate=90  # Parameter doesn't exist
dtparam=display_rotate=1  # Wrong place
```

### Why It's Wrong

Display rotation requires THREE separate configurations:

1. **Boot framebuffer** (cmdline.txt)
2. **X11 runtime** (.xinitrc)
3. **Console** (fbcon parameter)

Device tree only **enables** display controller, it doesn't rotate.

### The Fix

**Boot screen rotation:**
```bash
# /boot/firmware/cmdline.txt
video=HDMI-A-1:400x1280M@60,rotate=90 fbcon=rotate:1
```

**X11 rotation:**
```bash
# /home/andre/.xinitrc
DISPLAY=:0 xrandr --output HDMI-2 --rotate left
```

**Device tree (only enables hardware):**
```ini
dtoverlay=vc4-kms-v3d,noaudio
```

---

## 4. Wrong Spelling or Syntax

### Common Spelling Mistakes

**Wrong:**
```ini
dtparam=automute          # Missing underscore
dtparam=auto-mute         # Wrong separator
dtparam=AUTOMUTE          # Wrong case
```

**Correct:**
```ini
dtparam=auto_mute         # Underscore, lowercase
```

### Syntax Mistakes

**Wrong:**
```ini
dtoverlay=hifiberry-amp100:auto_mute    # Wrong separator
dtoverlay=hifiberry-amp100 auto_mute    # Missing comma
dtparam = auto_mute                      # Extra spaces
```

**Correct:**
```ini
dtoverlay=hifiberry-amp100,auto_mute    # Comma separator
# or
dtparam=auto_mute                       # No spaces around =
```

---

## 5. Not Checking If Overlay Has Parameters

### The Mistake

Assuming an overlay has configurable parameters when it doesn't.

**Example:**
```ini
dtoverlay=ft6236,touchscreen-size-x=1920  # No parameters!
```

### Why It's Wrong

The `ft6236` overlay has no `__overrides__` section. All configuration is fixed in the source.

**Check the source:**
```dts
// ghettoblaster-ft6236.dts
/ {
    fragment@0 {
        target = <&i2c1>;
        __overlay__ {
            ft6236: ft6236@38 {
                touchscreen-size-x = <1280>;  // FIXED
                // ...
            };
        };
    };
    // NO __overrides__ section!
};
```

### The Fix

**To change parameters:**
1. Edit the .dts source file
2. Recompile to .dtbo
3. Replace overlay in `/boot/firmware/overlays/`
4. Reboot

---

## 6. Using Wrong Compatible String

### The Mistake

Using Pi 4 overlays on Pi 5, or vice versa.

**Example:**
```dts
compatible = "brcm,bcm2711";  // Pi 4
// But running on Pi 5 (bcm2712)
```

### Why It Matters

- Different I2S controller paths
- Different device tree structure
- May not load or work incorrectly

**Check Pi model:**
```bash
cat /proc/device-tree/compatible
# Pi 5: brcm,bcm2712
# Pi 4: brcm,bcm2711
```

### The Fix

**Pi 5 I2S path:**
```dts
target-path = "/axi/pcie@1000120000/rp1/i2s@a4000";
```

**Pi 4 I2S path:**
```dts
target-path = "/soc/i2s@7e203000";  // Different!
```

**Use correct compatible string:**
```dts
compatible = "brcm,bcm2712";  // For Pi 5
```

---

## 7. Loading Conflicting Overlays

### The Mistake

Loading multiple overlays that use the same resources.

**Example:**
```ini
dtoverlay=hifiberry-amp100
dtoverlay=hifiberry-dac
dtoverlay=iqaudio-dacplus
```

### Why It's Wrong

- All three try to configure I2S and I2C
- Causes device conflicts
- System may not boot or audio won't work

### The Fix

**Use only ONE audio overlay:**
```ini
dtoverlay=hifiberry-amp100  # Only this one
```

**Check for conflicts:**
```bash
# List loaded overlays
vcgencmd get_config dtoverlay

# Check for duplicate devices
i2cdetect -y 1  # Should see ONLY one DAC
```

---

## 8. Duplicate dtoverlay Lines

### The Mistake

Having the same overlay loaded multiple times.

**Example:**
```ini
dtoverlay=vc4-kms-v3d-pi5,noaudio
# ... other settings ...
dtoverlay=vc4-kms-v3d-pi5,noaudio   # Duplicate!
```

### Why It's Wrong

- Wastes resources
- May cause initialization conflicts
- Can lead to unexpected behavior

### The Fix

**Check config.txt for duplicates:**
```bash
grep "^dtoverlay=" /boot/firmware/config.txt | sort | uniq -d
```

**Remove duplicates:**
```bash
# Edit config.txt and keep only one instance
dtoverlay=vc4-kms-v3d,noaudio  # Keep this
# dtoverlay=vc4-kms-v3d,noaudio  # Remove duplicate
```

---

## 9. Forgetting to Enable I2C

### The Mistake

Loading overlay that needs I2C without enabling I2C bus.

**Example:**
```ini
dtoverlay=hifiberry-amp100  # Needs I2C
# Missing: dtparam=i2c_arm=on
```

### Why It's Wrong

- DAC can't be configured without I2C
- Device won't be detected
- Audio won't work

### The Fix

**Always enable I2C for HATs:**
```ini
dtparam=i2c_arm=on
dtparam=i2s=on
dtoverlay=hifiberry-amp100
```

**Verify:**
```bash
ls -la /dev/i2c-*
# Should show: /dev/i2c-1

i2cdetect -y 1
# Should show device at 0x4d
```

---

## 10. Not Understanding dtparam vs dtoverlay

### The Mistake

Confusing when to use `dtparam` vs `dtoverlay`.

**Confused usage:**
```ini
dtoverlay=auto_mute           # Wrong - not an overlay
dtparam=hifiberry-amp100      # Wrong - not a parameter
```

### The Difference

**dtoverlay:**
- Loads a complete overlay (.dtbo file)
- Can include inline parameters
- Example: `dtoverlay=hifiberry-amp100,auto_mute`

**dtparam:**
- Sets a single parameter
- Affects most recent overlay
- Example: `dtparam=auto_mute`

### Equivalent Syntax

```ini
# Method 1: Inline parameter
dtoverlay=hifiberry-amp100,auto_mute

# Method 2: Separate parameter
dtoverlay=hifiberry-amp100
dtparam=auto_mute

# Both do the same thing
```

---

## Summary: How to Avoid Mistakes

### Before Adding a Parameter:

1. **Find the overlay source** (.dts file)
2. **Check for `__overrides__` section**
3. **Verify parameter exists**
4. **Check correct syntax** (boolean, integer, etc.)
5. **Understand what layer it affects** (hardware vs software)

### Debugging Checklist:

```bash
# 1. Check loaded overlays
vcgencmd get_config dtoverlay

# 2. Check I2C devices
i2cdetect -y 1

# 3. Check sound cards
cat /proc/asound/cards

# 4. Check for errors
dmesg | grep -i error
dmesg | grep -i i2c
dmesg | grep -i sound

# 5. Check device tree status
dtoverlay -l
```

### When Things Don't Work:

1. **Don't guess** - read the source
2. **Don't invent parameters** - check `__overrides__`
3. **Don't mix layers** - hardware vs software
4. **Don't assume** - verify with commands
5. **Check git history** - find working configs

---

## Related Documentation

- [Device Tree Overview](DEVICE_TREE_OVERVIEW.md)
- [HiFiBerry AMP100](HIFIBERRY_AMP100_DTO.md)
- [FT6236 Touch](FT6236_DTO.md)
- [Master Reference](../../../WISSENSBASIS/DEVICE_TREE_MASTER_REFERENCE.md)

---

**Key Takeaway:** Most device tree mistakes come from not understanding what layer (hardware vs software) controls what, and from inventing parameters without checking if they exist in the overlay's `__overrides__` section. Always read the source first, then verify on hardware.
