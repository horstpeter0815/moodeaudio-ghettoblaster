# moOde Output Device Cache System

**Date:** 2026-01-20  
**Purpose:** Understanding the cfg_outputdev table and device-specific settings

## Overview

moOde maintains a **cache table** (`cfg_outputdev`) that stores device-specific audio settings. This allows moOde to remember the preferred configuration for each audio device when switching between them.

## Table Schema

```sql
CREATE TABLE cfg_outputdev (
    id INTEGER PRIMARY KEY,
    device_name CHAR(64),       -- Device name (e.g., "HiFiBerry Amp2/4")
    mpd_volume_type CHAR(32),   -- Volume control type (hardware/software/null/none)
    alsa_output_mode CHAR(32),  -- ALSA mode (plughw/hw/iec958)
    alsa_max_volume CHAR(32)    -- Maximum volume percentage (e.g., "100")
);
```

## Purpose

**Problem:** Different audio devices have different optimal configurations:
- USB DACs: Often need `plughw` mode, software volume
- HiFiBerry DACs: Often need `plughw` mode, hardware volume
- HDMI outputs: Need `iec958` mode, software volume
- Some devices: Can't handle direct `hw` mode

**Solution:** Store per-device settings so moOde automatically applies the right config when switching devices.

---

## Functions

### readOutputDeviceCache() (audio.php lines 359-376)

**Purpose:** Retrieve cached settings for a device

```php
function readOutputDeviceCache($deviceName) {
    $dbh = sqlConnect();
    
    $result = sqlRead('cfg_outputdev', $dbh, $deviceName);
    if ($result === true) {
        // Not in table
        $values = 'device not found';
    } else {
        // In table
        $values = array(
            'device_name' => $result[0]['device_name'],
            'mpd_volume_type' => $result[0]['mpd_volume_type'],
            'alsa_output_mode' => $result[0]['alsa_output_mode'],
            'alsa_max_volume' => $result[0]['alsa_max_volume']
        );
    }
    
    return $values;
}
```

### updOutputDeviceCache() (audio.php lines 379-398)

**Purpose:** Save current settings for the active device

```php
function updOutputDeviceCache($deviceName) {
    $dbh = sqlConnect();
    
    $result = sqlRead('cfg_outputdev', $dbh, $deviceName);
    if ($result === true) {
        // Not in table, INSERT new row
        $values =
            "'" . $deviceName . "'," .
            "'" . $_SESSION['mpdmixer'] . "'," .
            "'" . $_SESSION['alsa_output_mode'] . "'," .
            "'" . $_SESSION['alsavolume_max'] . "'";
        $result = sqlInsert('cfg_outputdev', $dbh, $values);
    } else {
        // In table, UPDATE existing row
        $value = array(
            'mpd_volume_type' => $_SESSION['mpdmixer'],
            'alsa_output_mode' => $_SESSION['alsa_output_mode'],
            'alsa_max_volume' => $_SESSION['alsavolume_max']
        );
        $result = sqlUpdate('cfg_outputdev', $dbh, $deviceName, $value);
    }
}
```

### checkOutputDeviceCache() (audio.php lines 400-424)

**Purpose:** Get settings to apply when switching TO a device

```php
function checkOutputDeviceCache($deviceName, $cardNum) {
    $cachedDev = readOutputDeviceCache($deviceName);
    
    if ($cachedDev == 'device not found') {
        // No cached settings - use defaults
        $volumeType = 'software';
        $alsaOutputMode = getAudioOutputIface($cardNum) == AO_HDMI ? 'iec958' : 'plughw';
        $alsaMaxVolume = $_SESSION['alsavolume_max'];
    } else {
        // Use cached settings (with CamillaDSP override)
        if ($_SESSION['camilladsp'] == 'off') {
            if ($cachedDev['mpd_volume_type'] == 'null') {
                // Was using CamillaDSP, revert to hardware or software
                $volumeType = $_SESSION['alsavolume'] != 'none' ? 'hardware' : 'software';
            } else {
                $volumeType = $cachedDev['mpd_volume_type'];
            }
        } else {
            // CamillaDSP active - always use null mixer
            $volumeType = 'null';
        }
        $alsaOutputMode = $cachedDev['alsa_output_mode'];
        $alsaMaxVolume = $cachedDev['alsa_max_volume'];
    }
    
    return array(
        'mpd_volume_type' => $volumeType,
        'alsa_output_mode' => $alsaOutputMode,
        'alsa_max_volume' => $alsaMaxVolume
    );
}
```

---

## Usage Flow

### Scenario 1: User Switches Output Device

**Example:** User switches from "HiFiBerry Amp2/4" to "USB DAC"

```
1. User selects "USB DAC" in Audio Config
   ↓
2. snd-config.php line 43: checkOutputDeviceCache('USB DAC', 2)
   ↓
3. Cache miss (device not in cfg_outputdev)
   ↓
4. Defaults applied: volumeType='software', alsaOutputMode='plughw', maxVol='100'
   ↓
5. Configuration updated:
   - $_SESSION['cardnum'] = 2
   - $_SESSION['adevname'] = 'USB DAC'
   - $_SESSION['mpdmixer'] = 'software'
   - $_SESSION['alsa_output_mode'] = 'plughw'
   - $_SESSION['alsavolume_max'] = '100'
   ↓
6. submitJob('mpdcfg') → worker processes
   ↓
7. mpd.php::updMpdConf() line 243: updOutputDeviceCache('USB DAC')
   ↓
8. Settings saved to cfg_outputdev for next time
```

### Scenario 2: User Switches Back

**Example:** User switches back to "HiFiBerry Amp2/4"

```
1. User selects "HiFiBerry Amp2/4" in Audio Config
   ↓
2. snd-config.php line 43: checkOutputDeviceCache('HiFiBerry Amp2/4', 0)
   ↓
3. Cache hit! (device IS in cfg_outputdev)
   ↓
4. Cached settings restored:
   - volumeType = 'null' (was using CamillaDSP)
   - alsaOutputMode = 'plughw'
   - maxVol = '80'
   ↓
5. Configuration updated with cached values
   ↓
6. Audio works immediately with previous settings!
```

---

## Interaction with CamillaDSP

### CamillaDSP Active

When CamillaDSP is enabled globally:

```php
if ($_SESSION['camilladsp'] == 'off') {
    // Use cached mixer type
    $volumeType = $cachedDev['mpd_volume_type'];
} else {
    // Override: Always use null mixer for CamillaDSP
    $volumeType = 'null';
}
```

**Reason:** CamillaDSP requires `mixer_type='null'` to take over volume control.

### CamillaDSP Disabled

When switching away from CamillaDSP:

```php
if ($cachedDev['mpd_volume_type'] == 'null') {
    // Was using CamillaDSP, revert to appropriate mixer
    $volumeType = $_SESSION['alsavolume'] != 'none' ? 'hardware' : 'software';
}
```

**Reason:** Can't use `null` mixer without CamillaDSP, so revert to hardware/software.

---

## Default Settings (No Cache)

### Audio Output Interface Detection

```php
function getAudioOutputIface($cardNum) {
    $deviceName = getAlsaDeviceNames()[$cardNum];
    
    if ($_SESSION['multiroom_tx'] == 'On') {
        return AO_TRXSEND;
    } else if (isI2SDevice($deviceName)) {
        return AO_I2S;        // ← HiFiBerry, Allo, IQaudIO
    } else if ($deviceName == PI_HEADPHONE) {
        return AO_HEADPHONE;
    } else if ($deviceName == PI_HDMI1 || $deviceName == PI_HDMI2) {
        return AO_HDMI;       // ← HDMI outputs
    } else {
        return AO_USB;        // ← USB DACs
    }
}
```

### Default ALSA Output Mode

```php
if ($cachedDev == 'device not found') {
    $alsaOutputMode = getAudioOutputIface($cardNum) == AO_HDMI ? 'iec958' : 'plughw';
}
```

**Logic:**
- **HDMI devices:** Default to `iec958` (IEC958 digital output)
- **All others:** Default to `plughw` (ALSA plugin layer)

### Default Volume Type

```php
$volumeType = 'software';  // Always default to software mixer
```

**Reason:** Safe default that works for all devices.

---

## Audio Output Interface Constants

**File:** `constants.php`

```php
const AO_I2S = 'i2s';
const AO_USB = 'usb';
const AO_HDMI = 'hdmi';
const AO_HEADPHONE = 'headphone';
const AO_TRXSEND = 'trxsend';  // Multiroom sender
```

**Usage:** Used throughout codebase for device type detection.

---

## When Cache Gets Updated

Cache is updated whenever:

1. **User changes output device** (snd-config.php line 57 → submitJob('mpdcfg'))
2. **MPD config regenerated** (mpd.php line 243 → updOutputDeviceCache())
3. **ALSA output mode changed** (worker.php case 'alsa_output_mode' → updMpdConf() → updOutputDeviceCache())
4. **Volume max changed** (worker.php case 'alsavolume_max' → updOutputDeviceCache())

**Flow:**
```
Configuration change → updMpdConf() → updOutputDeviceCache()
```

Every time `updMpdConf()` runs, current settings are saved to cache.

---

## Current System State

### Database Query Result

```bash
$ sqlite3 moode-sqlite3.db "SELECT * FROM cfg_outputdev WHERE device_name='HiFiBerry Amp2/4'"
# Returns: (empty result)
```

**Interpretation:** No cached settings for HiFiBerry Amp2/4 yet.

**What happens:**
1. On next config change, cache will be created
2. Current settings will be saved:
   - `mpd_volume_type` = 'null' (CamillaDSP active)
   - `alsa_output_mode` = 'plughw'
   - `alsa_max_volume` = '80'

### If User Switches to USB DAC and Back

```
Switch to USB DAC:
  → Cache miss for USB DAC
  → Defaults applied: software mixer, plughw mode
  → USB DAC cache created
  → HiFiBerry cache also created (on the switch-away)

Switch back to HiFiBerry:
  → Cache hit!
  → HiFiBerry settings restored: null mixer, plughw, 80% max
  → Audio works immediately with CamillaDSP
```

---

## Benefits

1. **Device-Specific Optimization:** Each device remembers its optimal settings
2. **User Convenience:** Switching devices doesn't require reconfiguration
3. **Multi-Device Setups:** Easy to switch between multiple DACs
4. **Smart Defaults:** First-time setup uses intelligent defaults based on device type

---

## Limitations

1. **No Validation:** Cached settings might become invalid after updates
2. **Global CamillaDSP:** CamillaDSP setting is global, not per-device
3. **No Version Tracking:** Can't detect when driver/firmware changes require new settings
4. **Manual Clear:** No UI option to clear cache (must use moodeutl --odcclear)

---

## Cache Management

### Clear Cache

```bash
# Via moodeutl
sudo moodeutl --odcclear

# Manual
sqlite3 /var/local/www/db/moode-sqlite3.db "DELETE FROM cfg_outputdev"
```

### View Cache

```bash
sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT * FROM cfg_outputdev"
```

### Update Specific Device

```bash
sqlite3 /var/local/www/db/moode-sqlite3.db \
  "UPDATE cfg_outputdev SET mpd_volume_type='hardware' WHERE device_name='HiFiBerry Amp2/4'"
```

---

## Related Documentation

- `WISSENSBASIS/150_MOODE_COMPLETE_AUDIO_SYSTEM_ARCHITECTURE.md` - Audio system overview
- `WISSENSBASIS/149_MOODE_AUDIO_DEVICE_DETECTION_BUG_ROOT_CAUSE.md` - Device detection bugs
