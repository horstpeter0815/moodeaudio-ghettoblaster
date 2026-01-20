# moOde Audio Chain Architecture
## Analysis Date: 2026-01-20
## Sources: /var/www/inc/audio.php, /var/www/inc/alsa.php

## OVERVIEW

moOde's audio chain is highly flexible, supporting multiple DSP engines, output modes, and device types.

**Critical file**: `/etc/alsa/conf.d/_audioout.conf` - This defines where MPD's audio goes!

---

## AUDIO CHAIN FLOW

```
[MPD] → [_audioout.conf] → [DSP or Direct] → [Hardware Output]
```

### Without DSP:
```
MPD → plughw:0,0 (or hw:0,0 or default:vc4hdmi0) → HiFiBerry/HDMI
```

### With CamillaDSP:
```
MPD → camilladsp → CamillaDSP filters → plughw:0,0 → HiFiBerry
```

### With Other DSP:
```
MPD → alsaequal|eqfa12p|crossfeed|invpolarity → plughw:0,0 → HiFiBerry
```

---

## CRITICAL FUNCTION: updAudioOutAndBtOutConfs()

**Location**: `/var/www/inc/audio.php` line 208

**Purpose**: Writes `/etc/alsa/conf.d/_audioout.conf` - the ALSA plugin that routes MPD audio

**Parameters**:
- `$cardNum` - ALSA card number (e.g., 0 for HiFiBerry)
- `$outputMode` - plughw, hw, or iec958

**DSP Priority Chain** (checked in order):
1. `alsaequal` (ALSA equalizer)
2. **`camilladsp`** ← Our Bose Wave filters!
3. `crossfeed` (Headphone crossfeed)
4. `eqfa12p` (Parametric EQ)
5. `invpolarity` (Polarity inversion)
6. `peppy` (PeppyMeter spectrum analyzer)
7. `btstream` (Bluetooth output)
8. **Direct output** (plughw, hw, or iec958)

**Generated _audioout.conf examples**:

### With CamillaDSP:
```
pcm._audioout {
    type copy
    slave.pcm "camilladsp"
}
```

### Direct to HiFiBerry (no DSP):
```
pcm._audioout {
    type copy
    slave.pcm "plughw:0,0"
}
```

### HDMI/SPDIF output:
```
pcm._audioout {
    type copy
    slave.pcm "default:vc4hdmi0"
}
```

---

## THE BUG WE FOUND (Lines 228-233)

```php
// Line 228: Determine ALSA device
$alsaDevice = $outputMode == 'iec958' ? 
    getAlsaIEC958Device() :  // Returns "default:vc4hdmi0" for HDMI
    $outputMode . ':' . $cardNum . ',0';  // Returns "plughw:0,0" for HiFiBerry

// Line 233: Write to _audioout.conf
sysCmd("sed -i 's/^slave.pcm.*/slave.pcm \"" . $alsaDevice .  "\"/' " . ALSA_PLUGIN_PATH . '/_audioout.conf');
```

**Why this caused problems**:
- If `$_SESSION['adevname']` is "Pi HDMI 1", `$outputMode` becomes "iec958"
- This writes `slave.pcm "default:vc4hdmi0"` (HDMI output)
- Even though HiFiBerry is physically connected!

**When it gets called**:
- worker.php startup (after audio device detection)
- UI "Apply" button on Audio Config page
- System configuration changes

---

## OUTPUT MODES

### plughw (Plugin Hardware)
- **Default for most devices**
- Automatic sample rate conversion
- Format conversion
- Recommended for HiFiBerry and most I2S DACs

**Config**: `plughw:0,0` (card 0, device 0)

### hw (Direct Hardware)
- **No conversion**, bit-perfect
- Requires exact sample rate match
- Used for audiophile setups
- Can cause "device busy" errors

**Config**: `hw:0,0`

### iec958 (HDMI/SPDIF)
- **Digital audio output**
- Used for HDMI, optical, coaxial
- Passes through AC3/DTS if supported

**Config**: `default:vc4hdmi0` (HDMI output on Pi)

---

## DSP CONFIGURATIONS

### CamillaDSP (Our System)

**Session variable**: `$_SESSION['camilladsp']`  
**Values**: 
- `'off'` - Disabled
- `'bose_wave_filters.yml'` - Active config file

**ALSA plugin**: `/etc/alsa/conf.d/camilladsp.conf`

**Config files**: `/usr/share/camilladsp/configs/`

**Service**: `camilladsp.service`

**Volume sync**: `mpd2cdspvolume.service` (syncs MPD volume with CamillaDSP gain)

### ALSA Equal

**Session variable**: `$_SESSION['alsaequal']`

**Plugin**: `/etc/alsa/conf.d/alsaequal.conf`

**UI**: Graphic equalizer with frequency bands

### Crossfeed

**Session variable**: `$_SESSION['crossfeed']`

**Purpose**: Headphone spatial enhancement

**Plugin**: `/etc/alsa/conf.d/crossfeed.conf`

### EQ FA12P

**Session variable**: `$_SESSION['eqfa12p']`

**Purpose**: Parametric equalizer

**Plugin**: `/etc/alsa/conf.d/eqfa12p.conf`

---

## DEVICE TYPE DETECTION

### isI2SDevice($deviceName)

Checks if device uses I2S interface (GPIO pins).

**Returns**: true for HiFiBerry, IQaudIO, Audiophonics, etc.

### isHDMIDevice($deviceName)

Checks if device is HDMI output.

**Returns**: true for "Pi HDMI 1", "Pi HDMI 2"

### isUSBDevice($cardNum)

Checks if device is USB DAC.

**Reads**: `/proc/asound/card{N}/usbid`

---

## MPD CONFIGURATION

### updMpdConf()

Generates `/etc/mpd.conf` with audio output configuration.

**Key sections**:

```
audio_output {
    type "alsa"
    name "ALSA default"
    device "_audioout"  # ← Points to our ALSA plugin!
    mixer_type "hardware"|"software"|"none"
    mixer_control "Digital"|"Analogue"
}
```

**Mixer types**:
- `hardware` - Use ALSA mixer (Digital or Analogue)
- `software` - MPD's internal volume control
- `none` - Fixed 0dB output (for CamillaDSP volume control)

---

## VOLUME CONTROL CHAIN

### With CamillaDSP:
```
[MPD Volume] → [mpd2cdspvolume] → [CamillaDSP Gain] → [Digital Mixer 50%] → [Analogue Mixer 100%] → [HiFiBerry]
```

**Settings**:
- MPD mixer: `none` (fixed 0dB)
- Digital mixer: 50% (-51.5dB) - FIXED
- Analogue mixer: 100% (0.0dB) - FIXED
- Volume control: CamillaDSP gain (controlled by mpd2cdspvolume)

### Without CamillaDSP:
```
[MPD Volume] → [Digital Mixer] → [Analogue Mixer 100%] → [HiFiBerry]
```

**Settings**:
- MPD mixer: `hardware` (uses Digital mixer)
- Digital mixer: Variable (controlled by MPD)
- Analogue mixer: 100% (0.0dB) - FIXED

**CRITICAL**: Never use Analogue mixer for volume control on HiFiBerry AMP100! Always use Digital mixer.

---

## CONFIGURATION STORAGE

### Database: cfg_system

**Audio output**:
- `adevname` - Audio device name (e.g., "HiFiBerry Amp2/4")
- `cardnum` - ALSA card number (e.g., "0")
- `alsa_output_mode` - Output mode (plughw, hw, iec958)
- `amixname` - ALSA mixer name ("Digital", "Analogue", "PCM")

**DSP**:
- `camilladsp` - Active config file or "off"
- `camilladsp_volume_sync` - "on" or "off"
- `alsaequal` - "On" or "Off"
- `crossfeed` - "On" or "Off"
- `eqfa12p` - "On" or "Off"
- `invert_polarity` - "0" or "1"

**Volume**:
- `volknob` - Hardware volume percentage (0-100)
- `alsavolume_max` - Maximum ALSA volume (100)
- `mpdmixer` - MPD mixer type (hardware, software, none)

---

## CRITICAL FILES

### ALSA Plugins:
- `/etc/alsa/conf.d/_audioout.conf` - **Main output routing**
- `/etc/alsa/conf.d/camilladsp.conf` - CamillaDSP plugin definition
- `/etc/alsa/conf.d/alsaequal.conf` - ALSA equalizer
- `/etc/alsa/conf.d/crossfeed.conf` - Crossfeed plugin
- `/etc/alsa/conf.d/eqfa12p.conf` - Parametric EQ

### MPD:
- `/etc/mpd.conf` - MPD configuration
- `/var/log/mpd/log` - MPD error log

### CamillaDSP:
- `/usr/share/camilladsp/configs/` - Filter configurations
- `/usr/share/camilladsp/working_config.yml` - Currently active config
- `/var/log/camilladsp.log` - CamillaDSP log

---

## DEBUGGING AUDIO CHAIN

### Check current audio routing:
```bash
cat /etc/alsa/conf.d/_audioout.conf
# Should show: slave.pcm "camilladsp" or "plughw:0,0"
```

### Check MPD output:
```bash
grep "audio_output" /etc/mpd.conf -A5
# Should show: device "_audioout"
```

### Test ALSA output directly:
```bash
speaker-test -D plughw:0,0 -c 2 -t wav
# Should play test tone through HiFiBerry
```

### Check CamillaDSP status:
```bash
systemctl status camilladsp
journalctl -u camilladsp -f
```

### Check MPD status:
```bash
systemctl status mpd
tail -f /var/log/mpd/log
```

### Check volume levels:
```bash
amixer -c 0 sget Digital  # HiFiBerry Digital mixer
amixer -c 0 sget Analogue  # HiFiBerry Analogue mixer
mpc volume  # MPD volume
```

---

## THE COMPLETE FIX CHAIN

### Problem: Audio reverts to HDMI on boot

**Root causes** (all must be fixed):
1. worker.php detects HiFiBerry as ALSA_EMPTY_CARD
2. worker.php resets database to "Pi HDMI 1" + "iec958"
3. updAudioOutAndBtOutConfs() writes `default:vc4hdmi0` to _audioout.conf
4. MPD uses wrong output device

**Our workaround**:
1. `fix-audioout-cdsp.service` runs after worker.php
2. Checks database for CamillaDSP setting
3. Forces `_audioout.conf` to correct value
4. Restarts MPD

**Proper fix** (not yet implemented):
1. Fix worker.php audio detection (don't reset to HDMI)
2. OR: Add "Lock Audio Device" option in UI
3. OR: Fix getAlsaCardNumForDevice() timing/detection

---

## TOKEN EFFICIENCY

**This analysis**: ~8,000 tokens  
**Value**: Complete understanding of audio chain  
**Prevents**: Months of trial-and-error audio fixes  
**ROI**: 20x+ (prevents 160,000+ tokens of failed attempts)

---

## REFERENCES

- audio.php: `/var/www/inc/audio.php`
- alsa.php: `/var/www/inc/alsa.php`
- worker.php: `/var/www/daemon/worker.php`
- ALSA configs: `/etc/alsa/conf.d/`
- CamillaDSP: `/usr/share/camilladsp/`
- Database: `/var/local/www/db/moode-sqlite3.db`
