# CamillaDSP v2 vs v3 Syntax Differences

**Date:** 2026-01-20  
**Issue:** Bose Wave filters using v2 syntax, but system has CamillaDSP v3.0.1

## Current Error

```
ERROR [src/bin.rs:939] Invalid config file!
filters: unknown field `q`, expected `freq` at line 23 column 11
```

## Problem Config (bose_wave_physics_optimized.yml)

```yaml
filters:
  bass_lp1:
    type: Biquad
    parameters:
      type: LowpassFO      ← First-Order Lowpass
      freq: 300
      q: 0.707             ← ERROR: q not valid for LowpassFO in v3!
```

## CamillaDSP v3 Syntax (from V3-Flat.yml)

```yaml
filters:
  Master gain:
    description: null
    parameters:
      gain: 0
      inverted: false
      mute: false
      scale: dB
    type: Gain
```

**Key Differences:**
1. v3 uses `description: null` (can be omitted)
2. v3 requires specific parameters for each filter type
3. First-order filters (`LowpassFO`, `HighpassFO`) only accept `freq`, no `q`
4. Second-order filters (`Lowpass`, `Highpass`) accept both `freq` and `q`

## Filter Type Parameter Requirements

### v2 (Permissive)
- Most filter types accepted `q` even if not used
- Extra parameters often ignored

### v3 (Strict)
- **LowpassFO / HighpassFO:** Only `freq` (no `q`)
- **Lowpass / Highpass:** `freq` + `q`
- **Peaking:** `freq` + `gain` + `q`
- **Highshelf / Lowshelf:** `freq` + `gain` + `q` (or slope)
- **Gain:** `gain` + `inverted` + `mute` + `scale`

## Fix for Bose Wave Configs

**Option 1:** Change filter type from `LowpassFO` → `Lowpass`
```yaml
bass_lp1:
  type: Biquad
  parameters:
    type: Lowpass         ← Second-order (allows q)
    freq: 300
    q: 0.707
```

**Option 2:** Remove `q` parameter (changes filter response!)
```yaml
bass_lp1:
  type: Biquad
  parameters:
    type: LowpassFO       ← First-order (no q)
    freq: 300
```

**Note:** Changing `LowpassFO` to `Lowpass` preserves the intended frequency response since Q=0.707 is Butterworth (standard second-order response).

## Version Detection

**CamillaDSP installed version:**
```bash
$ camilladsp --version
CamillaDSP 3.0.1
```

**moOde compatibility code** (cdsp.php lines 90-108):
```php
// Patches required for migrating config to camilladsp 2.0
$majorVer = substr($this->version(), 11, 1); // Ex: version() -> CamillaDSP 2.0
if ($majorVer >= 2) {
    if (key_exists('volume_ramp_time', $ymlCfg['devices']) && $ymlCfg['devices']['volume_ramp_time'] != 150) {
        $ymlCfg['devices']['volume_ramp_time'] = 150;
    }
    // ... remove deprecated parameters
}
```

**Issue:** Code checks for v2+, but v3 has breaking syntax changes not handled!

## Bose Wave Filter Analysis

All filters that need fixing:

```yaml
# WRONG (v2 syntax):
bass_lp1:
  type: Biquad
  parameters:
    type: LowpassFO
    q: 0.707          ← Remove or change to Lowpass

bass_lp2:
  type: Biquad
  parameters:
    type: LowpassFO
    q: 0.707          ← Remove or change to Lowpass

mid_hp1:
  type: Biquad
  parameters:
    type: HighpassFO
    q: 0.707          ← Remove or change to Highpass

mid_hp2:
  type: Biquad
  parameters:
    type: HighpassFO
    q: 0.707          ← Remove or change to Highpass
```

All other filters use `Peaking`, `Highshelf`, `Lowshelf`, or `Highpass` which DO accept `q` in v3.

## Testing

```bash
# Validate config
/usr/local/bin/camilladsp --check /path/to/config.yml

# Exit codes:
# 0 = valid
# 101 = invalid
```

## Related Files

- `/usr/share/camilladsp/configs/bose_wave_physics_optimized.yml` - Needs v3 syntax fix
- `/usr/share/camilladsp/configs/bose_wave_*.yml` - All 5 Bose configs need checking
- `/usr/share/camilladsp/working_config.yml` - Symlink to active config
- `/var/lib/cdsp/statefile.yml` - Volume state
