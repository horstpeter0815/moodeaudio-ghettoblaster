# Base Filter Implementation Plan - Always-Active Offset Filters

**Date**: 2026-01-19  
**Goal**: Create a layered filter architecture with base filters ALWAYS active  
**Status**: Analysis Complete - Ready for Implementation Planning

## Your Requirement

You want:
1. **Base/Offset Filters** - ALWAYS active, no matter what (even with PeppyMeter)
2. **Room EQ** (CamillaDSP) - Additional layer on top
3. **PeppyMeter** - Must work with both filter layers active

## Solution Architecture

### Current Broken Flow
```
               ┌─→ camilladsp → Bose Filters → HiFiBerry ✓ (has filters)
MPD → _audioout┤
               └─→ peppy → HiFiBerry ✗ (NO filters - sounds different!)
```

### Proposed Fixed Flow
```
                           ┌─→ camilladsp → Room EQ → HiFiBerry ✓✓ (base + room)
MPD → _audioout → BASE ────┤
              FILTERS      └─→ peppy → HiFiBerry ✓ (base filters only)
           (ALWAYS ACTIVE)            ↓
                                  FIFO → PeppyMeter
```

## Implementation Approach

### Step 1: Create Base Filter Layer

**New File:** `/etc/alsa/conf.d/_base_filter.conf`

```
# Base speaker compensation filters - ALWAYS ACTIVE
pcm._base_filter {
    type plug
    slave.pcm "_base_eq"
}

# Use eqfa12p for 12-band parametric EQ
pcm._base_eq {
    type ladspa
    slave.pcm "_routing"
    path "/usr/lib/ladspa"
    plugins [ {
        id 2611
        label EqFA12p
        input {
            # Configure your offset/base filters here
            # Format: Enable Freq Bandwidth Gain (repeat 12x) + Master Gain
            controls [ 
                1 63 1 3      # Band 1: 63Hz, Q=1, +3dB
                1 125 1 3     # Band 2: 125Hz, Q=1, +3dB
                1 250 1 0     # Band 3: 250Hz, Q=1, 0dB
                0 400 1 0     # Band 4: disabled
                0 630 1 0     # Band 5: disabled
                0 1000 1 0    # Band 6: disabled
                0 1600 1 0    # Band 7: disabled
                0 2500 1 0    # Band 8: disabled
                0 4000 1 0    # Band 9: disabled
                0 6300 1 0    # Band 10: disabled
                0 10000 1 0   # Band 11: disabled
                0 16000 1 0   # Band 12: disabled
                0             # Master gain: 0dB
            ]
        }
    } ]
}

# This is what moOde will modify dynamically
pcm._routing {
    type copy
    slave.pcm "camilladsp"  # moOde changes this to "peppy" when needed
}
```

### Step 2: Modify _audioout to Use Base Filter

**File:** `/etc/alsa/conf.d/_audioout.conf`

**Change from:**
```
pcm._audioout {
    type copy
    slave.pcm "camilladsp"  # moOde modifies this - PROBLEM!
}
```

**Change to:**
```
pcm._audioout {
    type copy
    slave.pcm "_base_filter"  # FIXED - never modified by moOde
}
```

### Step 3: Update moOde's audio.php

**File:** `/var/www/inc/audio.php`

**Find this line:**
```php
sysCmd("sed -i 's/^slave.pcm.*/slave.pcm \"" . $alsaDevice .  "\"/' " . ALSA_PLUGIN_PATH . '/_audioout.conf');
```

**Change to:**
```php
sysCmd("sed -i 's/^slave.pcm.*/slave.pcm \"" . $alsaDevice .  "\"/' " . ALSA_PLUGIN_PATH . '/_base_filter.conf');
```

**This makes moOde modify `_routing` inside `_base_filter.conf` instead of `_audioout.conf`**

## Audio Flow After Implementation

### Normal Playback (PeppyMeter OFF)
```
MPD (plays music)
 ↓ outputs to ALSA device
_audioout (fixed device name)
 ↓ slave.pcm "_base_filter"
_base_filter (always active)
 ↓ applies eqfa12p base EQ
_routing (moOde sets to "camilladsp")
 ↓
camilladsp (CamillaDSP service)
 ↓ applies bose_wave_filters.yml (room EQ)
HiFiBerry AMP100 (hw:1,0)
 ↓
Speakers (with BOTH base + room filters)
```

### PeppyMeter Active (PeppyMeter ON)
```
MPD (plays music)
 ↓
_audioout (fixed device name)
 ↓
_base_filter (always active)
 ↓ applies eqfa12p base EQ
_routing (moOde sets to "peppy")
 ↓
peppy (PeppyALSA plugin)
 ├─→ /tmp/peppymeter FIFO
 │    ↓
 │   PeppyMeter.py reads FIFO
 │    ↓
 │   Displays VU meters on screen
 │
 └─→ _peppyout (hw:1,0)
      ↓
     HiFiBerry AMP100
      ↓
     Speakers (with BASE filters - consistent sound!)
```

## Base Filter Configuration Options

### Option A: eqfa12p (Parametric EQ)
**Pros:**
- 12 independent bands
- Precise frequency/Q/gain control
- Low CPU usage
- Already in moOde

**Use for:**
- Speaker response compensation
- Specific frequency adjustments
- Tailored corrections

**Example Configuration:**
```
# Bose Wave speaker compensation example:
controls [ 
    1 50 0.7 4      # Boost sub-bass: 50Hz, Q=0.7, +4dB
    1 100 0.7 3     # Boost bass: 100Hz, Q=0.7, +3dB
    1 200 1.0 2     # Warm lower mids: 200Hz, Q=1.0, +2dB
    1 500 1.5 -1    # Cut boxy mids: 500Hz, Q=1.5, -1dB
    0 1000 1 0      # (disabled)
    1 3000 2.0 2    # Boost presence: 3kHz, Q=2.0, +2dB
    1 8000 1.5 3    # Boost air: 8kHz, Q=1.5, +3dB
    0 10000 1 0     # (disabled)
    0 12500 1 0     # (disabled)
    0 14000 1 0     # (disabled)
    0 16000 1 0     # (disabled)
    0 18000 1 0     # (disabled)
    -1              # Master: -1dB (headroom)
]
```

### Option B: alsaequal (Graphic EQ)
**Pros:**
- Simple 10-band graphic EQ
- Visual frequency bands
- Easy to configure
- Persistent settings

**Use for:**
- General tonal shaping
- Quick adjustments
- Standard frequency bands

**Frequencies:** 31Hz, 63Hz, 125Hz, 250Hz, 500Hz, 1kHz, 2kHz, 4kHz, 8kHz, 16kHz

### Option C: Custom LADSPA Plugin
**Pros:**
- Any DSP you want
- Can chain multiple plugins
- Very flexible

**Use for:**
- Complex processing
- Multi-stage filtering
- Specialized corrections

## Filter Design Strategy

### Layer 1: Base/Offset Filters (Always Active)
**Purpose:** Speaker-specific compensation that should NEVER change

**Examples:**
- Speaker frequency response correction
- Cabinet resonance compensation
- Impedance linearization
- Basic loudness compensation

**Characteristics:**
- Static configuration
- Speaker-dependent
- Room-independent
- Same for all listening positions

### Layer 2: Room EQ (CamillaDSP - When Not Using PeppyMeter)
**Purpose:** Acoustic environment compensation

**Examples:**
- Room mode correction
- Reflection cancellation
- Sweet spot optimization
- Measurement-based corrections

**Characteristics:**
- Can be changed per room/position
- Measurement-driven
- Room-dependent
- Can be bypassed for PeppyMeter

## Key Advantages

1. **Consistent Sound**
   - Base filters always applied
   - PeppyMeter doesn't change tonal balance
   - Only room EQ is lost with PeppyMeter (acceptable tradeoff)

2. **Flexible Architecture**
   - Can change base filters independently
   - Can change room EQ independently
   - PeppyMeter works with both or just base

3. **Backward Compatible**
   - moOde's audio.php still works
   - Just modifies different file
   - No MPD config changes needed

4. **Easy to Configure**
   - Base filters: Edit _base_filter.conf
   - Room EQ: Use moOde's CamillaDSP UI
   - Clear separation of concerns

## Implementation Checklist

### Phase 1: Create Files
- [ ] Create `/etc/alsa/conf.d/_base_filter.conf`
- [ ] Configure base EQ settings in _base_filter.conf
- [ ] Backup original `_audioout.conf`

### Phase 2: Modify Configs
- [ ] Update `_audioout.conf` to use _base_filter
- [ ] Test with: `speaker-test -D _audioout -c 2`
- [ ] Verify audio path with: `aplay -L | grep audioout`

### Phase 3: Update moOde
- [ ] Modify `/var/www/inc/audio.php`
- [ ] Change sed target from _audioout to _base_filter
- [ ] Test toggle: Click PeppyMeter button

### Phase 4: Test & Verify
- [ ] Play music in normal mode - verify base + room EQ applied
- [ ] Activate PeppyMeter - verify base filters still active
- [ ] Check sound consistency between modes
- [ ] Verify PeppyMeter visualization works

### Phase 5: Fine-tune
- [ ] Adjust base filter settings for your speakers
- [ ] Adjust room EQ in CamillaDSP
- [ ] Test with different music genres
- [ ] Verify no audio dropouts or latency issues

## Technical Notes

### ALSA Plugin Processing Order
```
MPD outputs PCM samples
  ↓
_audioout (type: copy - just passes through)
  ↓
_base_filter (type: plug - format conversion if needed)
  ↓
_base_eq (type: ladspa - actual DSP processing)
  ↓
_routing (type: copy - routing decision)
  ↓
[camilladsp OR peppy]
```

### CPU Impact
- **eqfa12p**: Very light (~0.5% CPU per instance)
- **Total impact**: <1% CPU for base filters
- **Acceptable**: Pi 5 has plenty of headroom

### Latency Impact
- **eqfa12p**: ~1-2ms additional latency
- **Total chain**: Still well under 50ms
- **Acceptable**: Imperceptible for audio playback

## Current System State

**Already configured:**
- ✅ CamillaDSP with bose_wave_filters.yml
- ✅ PeppyMeter toggle working
- ✅ eqfa12p plugin available
- ✅ alsaequal plugin available

**Ready for:**
- Implementation of base filter layer
- Configuration of offset filters
- Testing with your Bose Wave speakers

## Next Decision Point

**You need to decide:**
1. Which filter plugin to use for base layer? (eqfa12p recommended)
2. What base filter settings for your speakers?
3. Keep current Bose Wave filters in CamillaDSP for room EQ?

**After decisions:**
- I can implement the architecture
- Configure the filters
- Test the complete chain
- Verify consistent sound with PeppyMeter
