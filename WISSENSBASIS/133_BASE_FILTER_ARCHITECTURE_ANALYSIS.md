# Base Filter Architecture Analysis - Always-Active Filters

**Date**: 2026-01-19  
**Requirement**: Create base/offset filters that are ALWAYS active, regardless of PeppyMeter state  
**Goal**: Layered filter architecture with PeppyMeter compatibility

## Current Problem

**Current Architecture:**
```
                    ┌─→ camilladsp → Bose Filters → HiFiBerry
MPD → _audioout ────┤
                    └─→ peppy (PeppyALSA) → HiFiBerry
```

**Issue:** When PeppyMeter is active, audio bypasses camilladsp entirely, losing ALL filters.

## Desired Architecture

**Target Architecture:**
```
                          ┌─→ camilladsp → Room EQ → HiFiBerry
MPD → _audioout → BASE ───┤
           FILTERS        └─→ peppy (PeppyALSA) → HiFiBerry
           (ALWAYS)                  ↓
                                FIFO → PeppyMeter Display
```

**Requirements:**
1. **Base Filters** - Always active (speaker compensation, basic EQ)
2. **Room EQ** (CamillaDSP) - Additional processing when not using PeppyMeter
3. **PeppyMeter** - Works with base filters active

## Current Chain Details

### MPD Configuration
```
audio_output {
    type "alsa"
    name "ALSA Default"
    device "_audioout"
    mixer_type "null"
}
```

**MPD always outputs to `_audioout`**

### _audioout Current Configuration
File: `/etc/alsa/conf.d/_audioout.conf`

```
pcm._audioout {
    type copy
    slave.pcm "camilladsp"
}
```

**Dynamically modified by moOde's `audio.php`:**
- Normal: `slave.pcm "camilladsp"`
- Peppy: `slave.pcm "peppy"`

### Available ALSA Plugins

moOde has these filter plugins available:
1. **alsaequal** - 10-band graphic equalizer
2. **eqfa12p** - Parametric EQ (12 bands)
3. **crossfeed** - Headphone crossfeed
4. **invpolarity** - Phase inversion
5. **camilladsp** - Full DSP engine

## Proposed Solution Architecture

### Option 1: Insert Base Layer Before _audioout

**Modify MPD to output to new base filter device:**
```
MPD → base_filter → _audioout → [camilladsp OR peppy] → hardware
```

**Implementation:**
1. Create `/etc/alsa/conf.d/base_filter.conf`:
```
pcm.base_filter {
    type plug
    slave.pcm "base_eq"
}

pcm.base_eq {
    type ladspa
    slave.pcm "_audioout"
    plugins [{
        label "parametricEQ"
        # Base speaker compensation here
    }]
}
```

2. Change MPD output device from `_audioout` to `base_filter`

**Pros:**
- Base filters ALWAYS applied
- Works with both peppy and camilladsp paths

**Cons:**
- Requires MPD config change
- moOde's audio.php doesn't know about base_filter layer

### Option 2: Modify _audioout to Include Base Filters

**Make _audioout a chain:**
```
MPD → _audioout (includes base filters) → [camilladsp OR peppy] → hardware
```

**Implementation:**
1. Modify `/etc/alsa/conf.d/_audioout.conf`:
```
pcm._audioout {
    type plug
    slave.pcm "base_eq"
}

pcm.base_eq {
    type ladspa  # or eqfa12p, or alsaequal
    slave.pcm "routing_decision"  # This gets modified by moOde
    # Base filter config here
}

pcm.routing_decision {
    type copy
    slave.pcm "camilladsp"  # moOde modifies this line
}
```

**Pros:**
- No MPD config change needed
- moOde's audio.php still works (modifies routing_decision)
- Base filters always in chain

**Cons:**
- More complex _audioout.conf structure
- Need to ensure moOde's sed commands target correct line

### Option 3: Use ALSA Loopback (Current Setup Hint)

**Observation:** System has `alsa_loopback=On` in database

Current loopback config exists: `/etc/alsa/conf.d/_sndaloop.conf`

**Could use loopback for base filtering:**
```
MPD → Loopback → Base Filters → _audioout → [camilladsp OR peppy] → hardware
```

**Would need to investigate:** How is loopback currently used?

## Available Filter Options for Base Layer

### 1. LADSPA Plugins
ALSA supports LADSPA (Linux Audio Developer's Simple Plugin API):
- Can load DSP plugins
- Parametric EQ, compressors, etc.
- Config in ALSA asoundrc

### 2. eqfa12p (Parametric EQ)
Already configured in moOde:
```
pcm.eqfa12p {
    type plug
    slave.pcm "plug_eqfa12p";
}

pcm.plug_eqfa12p {
    type ladspa
    slave.pcm "default:vc4hdmi0" #device
    plugins [ ... ]
}
```

**Could be adapted** for base filter layer

### 3. alsaequal (Graphic EQ)
10-band graphic equalizer:
```
pcm.alsaequal {
    type plug
    slave.pcm "plug_alsaequal";
}

pcm.plug_alsaequal {
    type equal
    slave.pcm "device"
    controls "/opt/alsaequal/alsaequal.bin"
}
```

**Persistent settings** stored in binary file

### 4. CamillaDSP Base Config
Could use CamillaDSP itself for base layer:
- Create `base_filters.yml` with speaker compensation
- Keep `bose_wave_filters.yml` for room EQ
- Stack them: base → room EQ

**But:** CamillaDSP gets bypassed with PeppyMeter, so won't work

## Key Architectural Decision

**Critical Question:** Where does moOde's `audio.php` modify the chain?

Looking at audio.php code:
```php
sysCmd("sed -i 's/^slave.pcm.*/slave.pcm \"" . $alsaDevice .  "\"/' " . 
    ALSA_PLUGIN_PATH . '/_audioout.conf');
```

**It modifies `_audioout.conf`** - specifically the `slave.pcm` line.

**This means:**
- We CAN'T use _audioout itself for base filters (gets overwritten)
- We MUST insert base filters BEFORE _audioout
- OR create a NEW intermediate device that _audioout points to

## Recommended Approach

### Implementation Strategy

**Step 1: Create base filter device**
File: `/etc/alsa/conf.d/_base_filter.conf`
```
pcm._base_filter {
    type plug
    slave.pcm "_routing"
}

# Use eqfa12p or alsaequal for base speaker compensation
pcm._routing {
    type copy
    slave.pcm "camilladsp"  # moOde will modify this
}
```

**Step 2: Modify _audioout to point to base filter**
File: `/etc/alsa/conf.d/_audioout.conf`
```
pcm._audioout {
    type copy
    slave.pcm "_base_filter"  # FIXED - never changes
}
```

**Step 3: Update moOde's audio.php to modify _routing instead**
Change sed target from `_audioout.conf` to `_routing.conf` (or _base_filter.conf)

**Result:**
```
MPD → _audioout → _base_filter (ALWAYS) → _routing → [camilladsp OR peppy]
         ↑            ↑                        ↑
       Fixed      Base Filters          moOde modifies this
```

## Filter Configuration for Base Layer

### Example: Speaker Compensation EQ

For Bose Wave speakers, you might want:
- **Bass roll-off compensation** - Boost low frequencies
- **Treble adjustment** - Compensate for speaker response
- **Loudness curve** - Maintain tonal balance at all volumes

**This is SEPARATE from:**
- Room EQ (CamillaDSP) - Acoustic environment compensation
- Dynamic processing - Compression, limiting

### Configuration Options

**Option A: Use eqfa12p for Base**
- 12-band parametric EQ
- Set specific frequencies for speaker compensation
- Persistent settings

**Option B: Use alsaequal for Base**
- 10-band graphic EQ
- Simple to configure
- Visual interface available

**Option C: Simple ALSA plug with coefficients**
- Lightweight
- Static configuration
- No runtime adjustment

## Integration with moOde

### Changes Needed

1. **ALSA Configuration:**
   - Create `_base_filter.conf`
   - Modify `_audioout.conf`
   - Create `_routing.conf` for dynamic switching

2. **moOde PHP Code:**
   - Update `audio.php` to modify `_routing` instead of `_audioout`
   - Add UI for base filter configuration
   - Ensure base filters persist across reboots

3. **Testing:**
   - Verify base filters active in normal playback
   - Verify base filters active with PeppyMeter
   - Verify CamillaDSP still works on top
   - Check latency impact

## Audio Chain Flow (Final)

### Normal Playback
```
MPD
 ↓
_audioout (fixed)
 ↓
_base_filter (speaker compensation - ALWAYS ACTIVE)
 ↓
_routing (dynamic - moOde modifies)
 ↓
camilladsp (room EQ)
 ↓
HiFiBerry AMP100
```

### PeppyMeter Active
```
MPD
 ↓
_audioout (fixed)
 ↓
_base_filter (speaker compensation - ALWAYS ACTIVE)
 ↓
_routing (dynamic - moOde modifies)
 ↓
peppy (PeppyALSA)
 ├─→ /tmp/peppymeter FIFO → PeppyMeter Display
 └─→ HiFiBerry AMP100
```

**Result:** Base filters applied in BOTH modes!

## Next Steps (Analysis Only - No Implementation)

1. **Confirm current loopback usage** - Check _sndaloop.conf purpose
2. **Select base filter type** - eqfa12p vs alsaequal vs custom
3. **Design base filter settings** - Specific speaker compensation values
4. **Map moOde's audio.php logic** - Understand all sed modification points
5. **Plan backward compatibility** - Ensure existing configs don't break

## Current Status

**Understanding Phase Complete:**
- ✅ Identified insertion point for base filters
- ✅ Analyzed available ALSA filter plugins
- ✅ Designed architecture for always-active filters
- ✅ Mapped moOde's dynamic configuration mechanism

**Ready for:** Implementation planning when user approves approach
