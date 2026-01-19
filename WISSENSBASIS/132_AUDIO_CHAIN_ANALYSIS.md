# Audio Chain Analysis - PeppyMeter vs Normal Playback

**Date**: 2026-01-19  
**System**: moOde Audio Player 10.0.3 on Raspberry Pi 5  
**Audio Hardware**: HiFiBerry AMP100 (card 1)

## Overview

The audio chain is **DIFFERENT** depending on whether PeppyMeter is active or not. This is controlled by the database parameter `enable_peppyalsa` and managed by `/var/www/inc/audio.php`.

## Audio Chain Comparison

### Normal Playback (PeppyMeter OFF)

```
MPD
 ↓ (outputs to _audioout)
ALSA: _audioout
 ↓ (type: copy, slave.pcm: camilladsp)
CamillaDSP
 ↓ (bose_wave_filters.yml applied)
 ↓ (outputs to hw:1,0 - HiFiBerry)
HiFiBerry AMP100
 ↓
Speakers
```

**Key characteristics:**
- Audio passes through **CamillaDSP** for DSP processing
- **Bose Wave filters** are applied (EQ/room correction)
- Direct path to hardware with DSP processing

### PeppyMeter Active (PeppyMeter ON)

```
MPD
 ↓ (outputs to _audioout)
ALSA: _audioout  
 ↓ (slave.pcm changes to "peppy")
PeppyALSA Plugin
 ├─→ FIFO: /tmp/peppymeter (for visualization)
 │    ↓
 │   PeppyMeter reads FIFO
 │    ↓
 │   Displays VU meters
 │
 └─→ slave.pcm: hw:1,0 (HiFiBerry)
      ↓
     HiFiBerry AMP100
      ↓
     Speakers
```

**Key characteristics:**
- Audio is intercepted by **PeppyALSA plugin**
- Audio is **TEE'd** (split):
  - Copy to `/tmp/peppymeter` FIFO for visualization
  - Original to hardware output
- **BYPASSES CamillaDSP** - no Bose Wave filters!
- Direct path to hardware WITHOUT DSP processing

## Critical Code Analysis

### audio.php - Device Selection Logic

Located in `/var/www/inc/audio.php`:

```php
function updAudioOutAndBtOutConfs($cardNum, $outputMode) {
    // Determine ALSA device based on peppy_display or enable_peppyalsa
    if ($_SESSION['peppy_display'] == '1' || $_SESSION['enable_peppyalsa'] == '1') {
        $alsaDevice = 'peppy';
    } else if ($_SESSION['audioout'] == 'Bluetooth') {
        $alsaDevice = 'btstream';
    } else {
        $alsaDevice = $outputMode == 'iec958' ? getAlsaIEC958Device() : $outputMode . ':' . $cardNum . ',0';
    }
    
    // Update _audioout.conf to use selected device
    sysCmd("sed -i 's/^slave.pcm.*/slave.pcm \"" . $alsaDevice .  "\"/' " . ALSA_PLUGIN_PATH . '/_audioout.conf');
}
```

**What this does:**
1. Checks if PeppyMeter is active OR PeppyALSA is enabled
2. If yes: Sets `_audioout` slave to `peppy` (PeppyALSA plugin)
3. If no: Sets `_audioout` slave to `camilladsp` (DSP processing)

### _audioout.conf - Dynamic Routing

File: `/etc/alsa/conf.d/_audioout.conf`

**When PeppyMeter OFF:**
```
pcm._audioout {
    type copy
    slave.pcm "camilladsp"
}
```

**When PeppyMeter ON:**
```
pcm._audioout {
    type copy
    slave.pcm "peppy"
}
```

This file is **dynamically modified** by moOde's audio.php when display mode changes!

### _peppyout.conf - Hardware Output

File: `/etc/alsa/conf.d/_peppyout.conf`

```
pcm._peppyout {
    type hw
    card 1
    device 0
    subdevice 0
}
ctl._peppyout {
    type hw
    card 1
}
```

**Purpose:** Defines the **final hardware output** for PeppyALSA - directly to HiFiBerry (card 1).

### peppy.conf.hide - PeppyALSA Plugin

File: `/etc/alsa/conf.d/peppy.conf.hide` (needs to be checked)

This file contains the **PeppyALSA plugin configuration** which:
1. Tees the audio stream to `/tmp/peppymeter` FIFO
2. Passes audio through to `_peppyout` (hardware)

## CamillaDSP Configuration

### Active Configuration
- **Config file**: `bose_wave_filters.yml`
- **Status**: Active when PeppyMeter is OFF
- **Function**: Room correction / speaker EQ for Bose Wave speakers

### Bypass Behavior
When PeppyMeter is active:
- CamillaDSP is **bypassed completely**
- Audio goes directly from PeppyALSA plugin to hardware
- **No room correction applied**

## Sound Difference Explanation

### Why Sound Changes

When PeppyMeter activates, the user hears a **different sound** because:

1. **Bose Wave Filters Disabled**
   - These filters compensate for the speaker's acoustic characteristics
   - Without them, frequency response changes
   - Bass/treble balance may sound different

2. **No Room Correction**
   - CamillaDSP can apply room correction
   - Bypassing it removes any acoustic treatment

3. **Different Signal Path**
   - PeppyALSA plugin adds a "tee" operation
   - Slight processing difference (though should be transparent)

### Expected Behavior

**This is BY DESIGN** in moOde:
- PeppyMeter requires real-time audio stream access via FIFO
- PeppyALSA plugin provides this by intercepting the audio
- Tradeoff: Lose DSP processing for visualization capability

## Configuration Files Summary

| File | Purpose | Changes When Toggle |
|------|---------|-------------------|
| `/etc/alsa/conf.d/_audioout.conf` | Main audio output routing | ✅ Yes - slave.pcm changes |
| `/etc/alsa/conf.d/_peppyout.conf` | PeppyALSA hardware target | ❌ No - always hw:1,0 |
| `/etc/alsa/conf.d/peppy.conf.hide` | PeppyALSA plugin config | ❌ No - static config |
| `/etc/alsa/conf.d/camilladsp.conf` | CamillaDSP plugin config | ❌ No - but bypassed |
| `/usr/share/camilladsp/working_config.yml` | Active DSP filters | ❌ No - but not used |

## Database Parameters

```sql
-- Controls audio routing
enable_peppyalsa = 1  -- Enables PeppyALSA plugin in audio chain

-- Controls display mode  
peppy_display = 0     -- PeppyMeter display off
local_display = 1     -- moOde UI display on

-- DSP configuration
camilladsp = bose_wave_filters.yml  -- Active DSP config
cdsp_fix_playback = Yes             -- CamillaDSP enabled
```

## Audio Flow Decision Tree

```
Is peppy_display=1 OR enable_peppyalsa=1?
│
├─ YES → Route to "peppy" (PeppyALSA)
│         └─→ Bypass CamillaDSP
│             └─→ Audio to HiFiBerry directly
│                 └─→ Copy to /tmp/peppymeter FIFO
│
└─ NO → Route to "camilladsp"
         └─→ Apply Bose Wave filters
             └─→ Audio to HiFiBerry with DSP
```

## Potential Solutions (For Future)

### Option 1: Insert PeppyALSA After CamillaDSP

```
MPD → _audioout → CamillaDSP → PeppyALSA → HiFiBerry
                      ↓
                 Bose Filters    ↓
                              FIFO → PeppyMeter
```

**Pros:** Maintains DSP processing  
**Cons:** Requires ALSA config modification

### Option 2: Use CamillaDSP's Built-in Visualizer

CamillaDSP can output visualization data. Could potentially:
- Keep audio path through CamillaDSP
- Get visualization data from CamillaDSP instead of PeppyALSA
- Maintain consistent sound

**Pros:** Single audio path  
**Cons:** Would require PeppyMeter modification to read CamillaDSP data

### Option 3: Duplicate Filters in PeppyALSA Path

Apply the same Bose Wave filters when PeppyALSA is active:
- Load equivalent ALSA plugin filters before PeppyALSA
- Maintain similar frequency response

**Pros:** Consistent sound between modes  
**Cons:** Duplicated configuration, potential latency

## Current Status

**System is working as designed:**
- ✅ Toggle function works correctly
- ✅ PeppyMeter displays when activated
- ✅ moOde UI returns when deactivated
- ⚠️ Sound changes because DSP is bypassed (expected behavior)

**User has Bose Wave filters applied** - these make a significant difference in sound quality, which is why the difference is noticeable when toggling PeppyMeter.

## Next Investigation Steps

1. Read `/etc/alsa/conf.d/peppy.conf.hide` to understand exact PeppyALSA configuration
2. Check if PeppyALSA plugin can be inserted AFTER CamillaDSP in the chain
3. Consider if user wants consistent sound (requires ALSA chain modification)
4. Document the exact Bose Wave filter settings being applied
