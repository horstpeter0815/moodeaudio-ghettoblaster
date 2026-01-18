# PROPER FIX - Device Tree + Software Configuration

## What I Learned from Device Tree Analysis:

### Device Tree Source Files Studied:
1. `ghettoblaster-amp100.dts` - Basic AMP100 overlay
2. `hifiberry-amp100-pi5-overlay.dts` - Pi 5 specific with overrides
3. `ghettoblaster-ft6236.dts` - Touch controller
4. `hifiberry-amp100-pi5-gpio14-active-low.dts` - GPIO reset configuration

### Hardware Understanding:
- **PCM5122 DAC** at I2C address `0x4d`
- **I2S interface** for digital audio
- **FT6236 touch** at I2C address `0x38`
- **I2C clock** must be 100kHz for stability
- **Auto-mute** is a device tree parameter, NOT a separate dtoverlay
- **IEC958 doesn't exist in hardware** - it's an ALSA software plugin

### What Device Tree CAN Control:
✅ Audio hardware (PCM5122 DAC)
✅ I2S interface enable
✅ I2C clock speed
✅ Touch controller
✅ Auto-mute feature (via parameter)
✅ GPIO assignments

### What Device Tree CANNOT Control:
❌ ALSA routing (software)
❌ CamillaDSP filters (userspace)
❌ moOde database settings (application)
❌ MPD configuration (application)
❌ Display rotation (X11/software)
❌ IEC958 plugin (ALSA software layer)

---

## PROPER FIX IMPLEMENTATION

### 1. Device Tree Level (Hardware) - `/boot/firmware/config.txt`:

```ini
# Audio: HiFiBerry AMP100 with auto-mute
dtoverlay=hifiberry-dacplus
dtparam=auto_mute

# OR use unified overlay (if compiled):
# dtoverlay=ghettoblaster-unified,auto_mute

# Display: KMS without audio
dtoverlay=vc4-kms-v3d-pi5,noaudio

# Audio: Disable onboard audio
dtparam=audio=off

# Performance
arm_boost=1

# HDMI settings
hdmi_force_hotplug=1
hdmi_group=2
hdmi_mode=87
hdmi_timings=400 0 220 32 110 1280 0 10 10 10 0 0 0 60 0 59510000 0

# Console
fbcon=rotate:1
```

### 2. moOde Database (Software) - SQLite updates:

```sql
-- CRITICAL: Use plughw, NOT iec958 for I2S devices
UPDATE cfg_system SET value='plughw' WHERE param='alsa_output_mode';

-- Hardware volume control for HiFiBerry
UPDATE cfg_system SET value='hardware' WHERE param='volume_type';

-- MPD routes through _audioout (for CamillaDSP chain)
UPDATE cfg_mpd SET value='_audioout' WHERE param='device';

-- Device identification
UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='adevname';
UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='i2sdevice';
UPDATE cfg_system SET value='1' WHERE param='cardnum';

-- Enable CamillaDSP
UPDATE cfg_system SET value='on' WHERE param='camilladsp';
```

### 3. ALSA Configuration - `/etc/alsa/conf.d/_audioout.conf`:

```alsa
pcm._audioout {
    type copy
    slave.pcm "camilladsp"
}
```

### 4. CamillaDSP Configuration - `/usr/share/camilladsp/working_config.yml`:

```yaml
devices:
  samplerate: 96000
  chunksize: 4096
  capture:
    type: Stdin
    channels: 2
    format: S32LE
  playback:
    type: Alsa
    channels: 2
    device: "plughw:1,0"  # Direct to HiFiBerry, card 1
    format: S32LE
```

---

## What Was Wrong with My Previous "Fixes":

### ❌ Script-based fixes:
- Created 20+ shell scripts
- Each fixed symptoms, not root cause
- Didn't understand hardware vs software layers
- Made up parameters that don't exist (`disable_iec958`)

### ❌ Misunderstanding device tree:
- Thought IEC958 was hardware (it's not - it's ALSA plugin)
- Didn't read actual dtoverlay source code
- Assumed parameters exist without verification

### ✅ Proper fix approach:
1. **Read device tree source** to understand hardware
2. **Separate hardware (DT) from software (config)**
3. **Use existing parameters** (`auto_mute` exists, `disable_iec958` doesn't)
4. **Fix root cause** (moOde's `alsa_output_mode` setting)

---

## Complete Audio Chain (Correct):

```
MPD → _audioout (ALSA) → camilladsp → plughw:1,0 → PCM5122 DAC → AMP100 → Speakers
```

**NOT:**
```
MPD → iec958 ❌ (Wrong - this is for S/PDIF digital output)
```

---

## Files to Deploy:

### On Pi:
1. `/boot/firmware/config.txt` - Device tree configuration
2. `/var/local/www/db/moode-sqlite3.db` - Update via SQL
3. `/etc/alsa/conf.d/_audioout.conf` - ALSA routing
4. `/usr/share/camilladsp/working_config.yml` - Bose Wave filters

### Compile overlay (if using custom):
```bash
dtc -@ -I dts -O dtb -o ghettoblaster-unified.dtbo ghettoblaster-unified.dts
sudo cp ghettoblaster-unified.dtbo /boot/firmware/overlays/
```

---

## Lessons Learned:

1. **Device tree is hardware configuration** - CPU, I2C, GPIO, clocks
2. **ALSA is software layer** - routing, plugins, mixing
3. **moOde is application layer** - user settings, MPD config
4. **Read the source** before assuming parameters exist
5. **Scripts are band-aids** - fix root cause in proper layer
6. **IEC958 is for S/PDIF** - not for I2S devices like HiFiBerry

---

## Next: Apply Proper Fix

Run on Pi:
```bash
# 1. Update config.txt
sudo nano /boot/firmware/config.txt
# Add: dtparam=auto_mute after hifiberry-dacplus line

# 2. Fix moOde database
sudo sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='plughw' WHERE param='alsa_output_mode';"

# 3. Reboot
sudo reboot
```

After reboot, Audio Info should show:
- Device: _audioout
- NO IEC958
- Volume control working
- Auto-mute active
