# moOde Volume Control - Complete Architecture

**Date:** 2026-01-21  
**Status:** Research Complete - Ready for Enhancement  
**Context:** Preparing for future audio quality improvements

---

## Executive Summary

moOde Audio has **three independent volume control layers** that work together:

1. **MPD Volume** (Software/Hardware/CamillaDSP)
2. **ALSA Hardware Volume** (DAC chip control)
3. **CamillaDSP Volume** (Digital volume with dynamic range mapping)

Understanding this architecture is critical for implementing high-quality audio enhancements.

---

## Volume Control Flow

```
USER KNOB (Web UI)
      ↓
playback.php (command/playback.php)
      ↓
   Decision:
      ├→ Hardware Mixer → amixer (HiFiBerry "Digital" control)
      ├→ Software Mixer → MPD setvol (internal DSP)
      └→ CamillaDSP Sync → MPD + CamillaDSP volume sync
```

---

## 1. MPD Volume Control

**Location:** `command/playback.php` lines 22-37

### Implementation

```php
case 'upd_volume':
    phpSession('write', 'volknob', $_POST['volknob']);
    
    if ($_SESSION['mpdmixer'] == 'hardware') {
        // Hardware: Control ALSA mixer directly
        sysCmd('amixer -M -c ' . $_SESSION['cardnum'] . ' sset "' . 
               $_SESSION['amixname'] . '" ' . $_POST['volknob'] . '%');
    } else {
        // Software: Control MPD internal volume
        sendMpdCmd($sock, 'setvol ' . $_POST['volknob']);
    }
```

### Mixer Types

| Type | Control Point | Quality | Use Case |
|------|--------------|---------|----------|
| `software` | MPD internal DSP | Good | No hardware control available |
| `hardware` | ALSA amixer | Best | DAC has hardware volume |
| `none` | Fixed 0dB | Transparent | External preamp/volume control |

**Configuration:** `cfg_mpd.mixer_type` + session variable `$_SESSION['mpdmixer']`

---

## 2. ALSA Hardware Volume

**Location:** `inc/alsa.php` lines 15-106

### HiFiBerry DAC+ Pro Controls

Our system uses **HiFiBerry DAC+ Pro** with PCM512x chip.

**Available ALSA controls:**
```bash
Simple mixer control 'Digital',0      ← VOLUME CONTROL
Simple mixer control 'Analogue',0     ← Analog gain
Simple mixer control 'Auto Mute',0
Simple mixer control 'Deemphasis',0
```

**Primary volume control:** `Digital` (0-207 range, -103.5dB to 24dB)

### Mixer Name Detection

```php
function getAlsaMixerName($deviceName) {
    // HiFiBerry DAC+ Pro uses: "Digital"
    // Parsed from: amixer output
    $result = sysCmd('/var/www/util/sysutil.sh get-mixername');
    
    if (in_array('(' . ALSA_DEFAULT_MIXER_NAME_I2S . ')', $result)) {
        $mixerName = ALSA_DEFAULT_MIXER_NAME_I2S; // "Digital"
    }
    
    return $mixerName;
}
```

**Constants:**
- `ALSA_DEFAULT_MIXER_NAME_I2S` = `"Digital"`
- Defined in: `inc/constants.php`

### Volume Read/Write Functions

```php
function getAlsaVolume($mixerName) {
    // Returns volume as percentage (0-100)
    $result = sysCmd('/var/www/util/sysutil.sh get-alsavol "' . $mixerName . '"');
    return str_replace('%', '', $result[0]);
}

function getAlsaVolumeDb($mixerName) {
    // Returns volume in dB
    $result = sysCmd('/var/www/util/sysutil.sh get-alsavol-db "' . $mixerName . '"');
    return rtrim($result[0], 'dB');
}
```

---

## 3. CamillaDSP Volume Control

**Location:** `inc/cdsp.php` lines 620-645

### Volume Sync Architecture

CamillaDSP can **sync with MPD volume** for unified control:

**Enable condition:** `CamillaDSP::isMPD2CamillaDSPVolSyncEnabled()`

**Effect:**
- MPD volume changes → automatically mapped to CamillaDSP filters
- Uses **non-linear mapping** for better perceived volume curve
- Maintains digital headroom for DSP processing

### Dynamic Range Mapping

**Function:** `calcMappedDbVol($volume, $dynamic_range)`

```php
static function calcMappedDbVol($volume, $dynamic_range) {
    // $volume: 0-100 (MPD volume)
    // $dynamic_range: dB range (default 60dB)
    
    $x = $volume / 100.0;           // Normalize to 0-1
    $y = pow(10, $dynamic_range / 20);
    $a = 1/$y;
    $b = log($y);
    $y = $a * exp($b * $x);
    
    // Special handling for low volumes (< 10%)
    if ($x < 0.1) {
        $y = $x * 10 * $a * exp(0.1 * $b);
    }
    
    // Prevent zero (would be -inf dB)
    if ($y == 0) {
        $y = 0.000001;
    }
    
    return 20 * log10($y);  // Convert to dB
}
```

**Example mapping (60dB range):**
- Volume 100% → 0dB
- Volume 50% → -20dB
- Volume 10% → -48dB
- Volume 1% → -60dB

**Configuration:**
- `$_SESSION['camilladsp_volume_range']` (default: 60dB)
- Stored in: `cfg_system.camilladsp_volume_range`

### Volume State Persistence

**State file:** `/var/lib/cdsp/statefile.yml`

```yaml
volume:
  - -12.5  # Channel 0 volume in dB
  - -12.5  # Channel 1 volume in dB
```

**Read function:**
```php
static function getCDSPVol() {
    $result = sysCmd("cat /var/lib/cdsp/statefile.yml | grep 'volume' -A1 | grep -e '- ' | awk '/- /{print $2}'")[0];
    return (intval($result * 100) / 100);
}
```

---

## 4. Frontend (JavaScript)

**Location:** `js/playerlib.js` + `js/scripts-panels.js`

### Volume Knob Component

**jQuery Knob Plugin:**
```javascript
$('.volumeknob').knob({
    // Configuration for visual knob control
});
```

**Session variables:**
- `SESSION.json['volknob']` - Current volume (0-100)
- `SESSION.json['volmute']` - Mute state (0/1)
- `SESSION.json['mpdmixer']` - Mixer type

### Volume Update Function

**Location:** `js/playerlib.js` (called from knob change event)

```javascript
function setVolume(volume) {
    // Update session
    SESSION.json['volknob'] = volume;
    
    // Send to backend
    $.post('command/playback.php?cmd=upd_volume', {
        'volknob': volume,
        'event': 'change'
    });
    
    // Update display
    $('.volume-display div').text(volume);
}
```

### MPD Status Sync

**Auto-sync from MPD status:**
```javascript
if ((SESSION.json['volknob'] != MPD.json['volume']) && SESSION.json['volmute'] == '0') {
    SESSION.json['volknob'] = MPD.json['volume']
    $.post('command/cfg-table.php?cmd=upd_cfg_system', {'volknob': SESSION.json['volknob']});
}
```

This ensures UI stays in sync if volume changed externally (e.g., `mpc volume 50`)

---

## 5. Worker Daemon Initialization

**Location:** `daemon/worker.php` lines 869-902

### Mixer Detection at Boot

```php
// MPD mixer type determination
$mixerType = ucfirst($_SESSION['mpdmixer']);
$mixerType = CamillaDSP::isMPD2CamillaDSPVolSyncEnabled() ? 'CamillaDSP' : $mixerType;
$mixerType = $mixerType == 'None' ? 'Fixed (0dB)' : $mixerType;
workerLog('worker: MPD mixer      ' . $mixerType);

// ALSA mixer detection
phpSession('write', 'amixname', getAlsaMixerName($_SESSION['adevname']));
workerLog('worker: ALSA mixer:    ' . ($_SESSION['amixname'] == 'none' ? 'none exists' : $_SESSION['amixname']));

// CamillaDSP volume
workerLog('worker: CDSP volume:   ' . CamillaDSP::getCDSPVol() . 'dB');
workerLog('worker: CDSP volrange: ' . $_SESSION['camilladsp_volume_range'] . 'dB');
```

### Mixer Array (All Cards)

**Lines 727-740:**
```php
$mixers = array();
for ($card = 0; $card < ALSA_MAX_CARDS; $card++) {
    $result = sysCmd('amixer -c ' . $card . ' | awk \'BEGIN{FS="\n"; RS="Simple mixer control"} $0 ~ "pvolume" {print $1}\' | awk -F"\'" \'{print "(" $2 ")";}\'');
    
    if (in_array('(' . ALSA_DEFAULT_MIXER_NAME_I2S . ')', $result)) {
        $mixerName = '(' . ALSA_DEFAULT_MIXER_NAME_I2S . ')';
    } else {
        $mixerName = empty($result) ? 'none' : $result[0];
    }
    
    array_push($mixers, $mixerName);
}
```

---

## Current System Configuration

**Our HiFiBerry DAC+ Pro Setup:**

```
Audio Device: HiFiBerry DAC+ Pro (card 0)
ALSA Mixer:   Digital
MPD Mixer:    null (needs configuration)
CamillaDSP:   Enabled (auto-launch via ALSA cdsp plugin)
Config:       bose_wave_physics_optimized.yml
Volume Range: 60dB (default)
```

**Database values:**
```sql
cfg_system.mpdmixer          → null (needs setting)
cfg_system.alsavolume        → 100
cfg_system.volknob           → Current UI volume
cfg_mpd.mixer_type           → null (needs setting)
```

---

## Recommendations for Audio Quality Enhancement

### 1. **Optimal Volume Configuration**

**Recommended setup:**
```
MPD Mixer:        software (or CamillaDSP sync)
ALSA Volume:      Fixed at 100% (0dB digital)
CamillaDSP:       Volume control with 60dB range
```

**Why:**
- ALSA at 100% = no digital attenuation in DAC
- All volume control via CamillaDSP = consistent DSP processing
- 60dB range provides good resolution without excessive noise floor

### 2. **CamillaDSP Volume Sync**

**Enable MPD→CamillaDSP volume sync:**
- Unified volume control
- Non-linear mapping for better perceived curve
- Maintains headroom for DSP processing

### 3. **Dynamic Range Optimization**

**Current:** 60dB range (good for most systems)

**Options:**
- **80dB range:** For high-end DACs with excellent SNR
- **40dB range:** For noisier systems, improves volume resolution
- **Custom curve:** Modify `calcMappedDbVol()` for preference

### 4. **Hardware vs Software Mixer**

**Hardware Mixer (current: null, should consider):**
- ✅ Best quality (no software attenuation)
- ✅ Bit-perfect at max volume
- ❌ No volume sync with CamillaDSP

**Software Mixer + CamillaDSP sync:**
- ✅ Unified volume control
- ✅ CamillaDSP filters always active
- ✅ Better integration
- ⚠️ Software attenuation (minimal quality impact if done right)

---

## Future Enhancement Ideas

### 1. **Adaptive Volume Curve**

Implement **psychoacoustic volume curve** based on Fletcher-Munson:
- Boost bass/treble at low volumes
- Maintain flat response at high volumes
- Integrate with CamillaDSP filters

### 2. **Volume Ramping**

**Smooth volume transitions:**
- Anti-click/pop protection
- Configurable ramp time
- CamillaDSP already has: `volume_ramp_time` parameter

### 3. **Per-Source Volume Memory**

**Remember volume per input:**
- Radio: 45%
- Local files: 60%
- Bluetooth: 50%
- Automatically switch when source changes

### 4. **Volume Limiter**

**Protect speakers:**
- Hard limit at user-defined dB
- Soft clipping via CamillaDSP
- Peak detection and auto-reduction

### 5. **Integration with Room Correction**

**Volume-dependent EQ:**
- More correction at low volumes (Fletcher-Munson compensation)
- Less correction at high volumes (avoid over-EQ)
- Dynamic CamillaDSP config switching

---

## Testing Commands

### Check Current Volume State

```bash
# MPD volume
mpc volume

# ALSA volume
amixer -c 0 sget Digital

# CamillaDSP volume
cat /var/lib/cdsp/statefile.yml | grep -A2 'volume'

# Session volume
sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='volknob';"
```

### Set Volumes Manually

```bash
# MPD software volume
mpc volume 50

# ALSA hardware volume
amixer -M -c 0 sset Digital 80%

# CamillaDSP volume (via WebSocket API)
# Requires CamillaDSP running with WebSocket server
```

---

## Code Locations Reference

| Component | File | Lines | Function |
|-----------|------|-------|----------|
| Volume update handler | `command/playback.php` | 22-54 | `upd_volume` case |
| ALSA mixer detection | `inc/alsa.php` | 15-69 | `getAlsaMixerName()` |
| ALSA volume read | `inc/alsa.php` | 71-101 | `getAlsaVolume()` / `getAlsaVolumeDb()` |
| CamillaDSP volume | `inc/cdsp.php` | 620-645 | `getCDSPVol()` / `calcMappedDbVol()` |
| Frontend knob | `js/scripts-panels.js` | 648+ | `.volumeknob.knob()` |
| Volume sync | `js/playerlib.js` | 1053-1078 | MPD status update |
| Worker init | `daemon/worker.php` | 727-902 | Mixer detection + init |

---

## Database Schema

**Volume-related configuration:**

```sql
-- Session/UI state
cfg_system.volknob           INTEGER  -- Current volume (0-100)
cfg_system.volmute           TEXT     -- Mute state ('0'/'1')
cfg_system.alsavolume        TEXT     -- ALSA volume cache
cfg_system.mpdmixer          TEXT     -- Mixer type (software/hardware/none)

-- CamillaDSP
cfg_system.camilladsp        TEXT     -- Config file name
cfg_system.camilladsp_volume_range  TEXT  -- dB range (default '60')

-- MPD configuration
cfg_mpd.mixer_type           TEXT     -- MPD mixer type
cfg_mpd.device               TEXT     -- ALSA device number
```

---

## Next Steps for Enhancement

1. **Configure mixer type** (currently null)
2. **Test CamillaDSP volume sync**
3. **Implement adaptive volume curve** (optional)
4. **Optimize for Bose Wave filters** (integrate with physics model)
5. **Add volume-dependent room correction**

---

## Notes

- All volume values stored as **0-100** in database/session
- ALSA mixer uses **percentage** (0-100%)
- CamillaDSP uses **dB** (-60dB to 0dB typically)
- Conversion happens in `calcMappedDbVol()`

**Quality preservation rule:**
- Digital volume attenuation = bit depth reduction
- Hardware volume = analog attenuation (no bit depth loss)
- CamillaDSP volume = high-precision float DSP (minimal quality impact)

---

**End of Volume Control Architecture Documentation**
