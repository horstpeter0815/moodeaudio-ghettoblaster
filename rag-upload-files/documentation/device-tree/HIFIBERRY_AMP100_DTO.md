# HiFiBerry AMP100 Device Tree Overlay

**Overlay Name:** `hifiberry-amp100`  
**Purpose:** Configure PCM5122 DAC and I2S interface for 2x50W Class D amplifier

---

## Hardware Overview

### HiFiBerry AMP100 Specifications

**Audio DAC:**
- Chip: Texas Instruments PCM5122
- Sample rates: 44.1kHz - 384kHz
- Bit depth: 16-32 bit
- SNR: 112dB

**Amplifier:**
- Output: 2x50W @ 4Ω
- Class D (high efficiency)
- Auto-mute capability

**Interface:**
- I2S digital audio
- I2C control (address 0x4d)
- GPIO control (optional)

---

## Device Tree Configuration

### I2C Device (PCM5122 DAC)

**Address:** `0x4d` on I2C1 bus

**Driver:** `snd-soc-pcm512x` kernel module

**Power Supplies:**
```dts
AVDD-supply = <&vdd_3v3_reg>;  // Analog power
DVDD-supply = <&vdd_3v3_reg>;  // Digital power
CPVDD-supply = <&vdd_3v3_reg>; // Charge pump power
```

**Clock Source:**
```dts
dacpro_osc: dacpro_osc {
    compatible = "hifiberry,dacpro-clk";
    #clock-cells = <0>;
};
```

### I2S Interface

**Pi 5 Path:** `/axi/pcie@1000120000/rp1/i2s@a4000`

**Pi 4 Path:** Different (uses different I2S controller)

**Configuration:**
```dts
i2s-controller = <&i2s>;
status = "okay";
```

### Sound Card

**Compatible String:** `hifiberry,hifiberry-amp` or `hifiberry,hifiberry-dacplus`

**ALSA Card Name:** `sndrpihifiberry`

**Device Number:** Typically `card 0` or `card 1`

---

## Available Parameters

### 1. auto_mute

**Type:** Boolean  
**Default:** false  
**Purpose:** Automatically mute amplifier when no audio signal

**Usage:**
```ini
dtoverlay=hifiberry-amp100
dtparam=auto_mute
```

**Behavior:**
- Monitors audio signal
- Mutes after ~3 seconds of silence
- Unmutes when audio starts
- Reduces idle power and noise

**Hardware Implementation:**
- Controlled by PCM5122 internal logic
- No external GPIO required
- Affects amplifier enable signal

### 2. 24db_digital_gain

**Type:** Boolean  
**Default:** false  
**Purpose:** Enable 24dB digital gain boost

**Usage:**
```ini
dtoverlay=hifiberry-amp100,24db_digital_gain
```

**Caution:** Can cause clipping with high-level sources

### 3. leds_off

**Type:** Boolean  
**Default:** false  
**Purpose:** Disable status LEDs

**Usage:**
```ini
dtoverlay=hifiberry-amp100,leds_off
```

### 4. mute_ext_ctl

**Type:** Integer (GPIO number)  
**Default:** none  
**Purpose:** Use external GPIO for mute control

**Usage:**
```ini
dtoverlay=hifiberry-amp100,mute_ext_ctl=14
```

**Note:** Can conflict with other devices using same GPIO

---

## Fragment Breakdown

### Simple Overlay (`ghettoblaster-amp100.dts`)

**fragment@0: I2C Configuration**
```dts
target = <&i2c1>;
```
- Sets I2C clock to 100kHz (stable)
- Configures PCM5122 at address 0x4d
- Assigns power supplies

**fragment@1: Sound Card**
```dts
target = <&sound>;
```
- Creates sound card
- Links to I2S controller
- Sets compatible string

**Limitations:**
- No `__overrides__` section
- Parameters not configurable
- Fixed configuration only

### Advanced Overlay (`hifiberry-amp100-pi5-dsp-reset.dts`)

**fragment@0: Clock Generator**
```dts
target-path = "/";
```
- Creates `dacpro_osc` clock source
- Required for DAC operation

**fragment@1: I2S Enable**
```dts
target-path = "/axi/pcie@1000120000/rp1/i2s@a4000";
```
- Pi 5 specific I2S path
- Enables DesignWare I2S controller

**fragment@2: I2C Device**
```dts
target = <&i2c1>;
```
- Same as simple overlay
- Uses `dacpro_osc` clock

**fragment@3: Sound Node Creation**
```dts
target-path = "/axi";
```
- Creates sound node under /axi
- Pi 5 device tree structure
- Avoids `<&sound>` reference issues

**Advantages:**
- Has `__overrides__` section
- Parameters configurable
- More flexible

---

## Verification

### Check if Loaded

```bash
# List loaded overlays
vcgencmd get_config dtoverlay | grep hifiberry

# Check I2C device
i2cdetect -y 1
# Should show: 0x4d

# Check ALSA card
cat /proc/asound/cards
# Should show: sndrpihifiberry

aplay -l
# Should show: HifiberryDacp
```

### Test Audio Output

```bash
# Direct hardware test
speaker-test -c 2 -t sine -f 1000 -D plughw:CARD=sndrpihifiberry,DEV=0

# Check volume
amixer -c 0 sget Digital
# or
amixer -c 1 sget Digital
```

### Verify Auto-Mute (if enabled)

```bash
# 1. Play audio
aplay test.wav

# 2. Stop audio

# 3. Wait 3 seconds

# 4. Check amplifier mute status
# (requires multimeter or oscilloscope)
# Measure GPIO or amplifier enable pin
```

---

## Integration with ALSA

### ALSA Device Names

**Hardware device:**
```
hw:CARD=sndrpihifiberry,DEV=0
plughw:CARD=sndrpihifiberry,DEV=0
plughw:0,0  (or plughw:1,0)
```

**NOT in device tree:**
```
default
_audioout
camilladsp
iec958  (ALSA plugin, not hardware)
```

### ALSA Configuration Files

**Device tree creates hardware:**
- I2C device (DAC)
- I2S interface
- Sound card registration

**ALSA configures routing:**
- `/etc/alsa/conf.d/_audioout.conf`
- `/etc/alsa/conf.d/camilladsp.conf`

**Separate layers:**
```
Device Tree → Hardware Init
ALSA Config → Software Routing
MPD Config → Application Settings
```

---

## Troubleshooting

### Problem: No Audio Output

**Check:**
1. Is overlay loaded? `vcgencmd get_config dtoverlay`
2. Is I2C device detected? `i2cdetect -y 1` (should show 0x4d)
3. Is sound card present? `cat /proc/asound/cards`
4. Is volume unmuted? `amixer -c 0 sget Digital`

**Common causes:**
- Wrong I2C address
- I2C bus not enabled (`dtparam=i2c_arm=on`)
- Conflicting overlays
- Missing power supply references

### Problem: Device Not Detected on I2C

**Check:**
```bash
# Is I2C enabled?
dtparam=i2c_arm=on

# Check I2C bus
ls -la /dev/i2c-*

# Scan bus
i2cdetect -y 1
```

**Fix:**
- Enable I2C in config.txt
- Check cable connections
- Verify HAT is seated properly

### Problem: Parameters Not Working

**Cause:** Simple overlay has no `__overrides__` section

**Solution:** Use advanced overlay or compile custom overlay with parameters

---

## Comparison: Simple vs Advanced

| Feature | Simple (`ghettoblaster-amp100.dts`) | Advanced (`hifiberry-amp100-pi5-dsp-reset.dts`) |
|---------|-------------------------------------|------------------------------------------------|
| I2C Device | ✓ | ✓ |
| I2S Interface | ✓ | ✓ |
| Sound Card | ✓ | ✓ |
| Clock Source | External `<&audio>` | Internal `dacpro_osc` |
| Parameters | ✗ None | ✓ auto_mute, 24db_digital_gain, etc. |
| Pi 5 Specific | Partial | Full |
| `__overrides__` | ✗ | ✓ |

**Recommendation:** Use advanced overlay if parameters are needed, simple overlay for fixed configuration.

---

## Source Files

**Custom overlays:**
- [`custom-components/overlays/ghettoblaster-amp100.dts`](../../../custom-components/overlays/ghettoblaster-amp100.dts)
- [`hifiberry-amp100-pi5-dsp-reset.dts`](../../../hifiberry-amp100-pi5-dsp-reset.dts)

**Stock overlay:**
- Check `/boot/firmware/overlays/hifiberry-amp100.dtbo`
- Source: https://github.com/raspberrypi/linux/tree/rpi-6.6.y/arch/arm/boot/dts/overlays

---

## Related Documentation

- [Device Tree Overview](DEVICE_TREE_OVERVIEW.md)
- [Master Reference](../../../WISSENSBASIS/DEVICE_TREE_MASTER_REFERENCE.md)
- [Common Mistakes](COMMON_MISTAKES.md)

---

**Key Takeaway:** HiFiBerry AMP100 overlay configures PCM5122 DAC hardware via I2C and I2S. Parameters like `auto_mute` exist in advanced overlays but not in simple versions. ALSA routing is separate from device tree configuration.
