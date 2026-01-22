# moOde Audio Volume Control - Comprehensive Study
**Date:** 2026-01-21  
**Purpose:** High-end audio volume control architecture and best practices

## Executive Summary

moOde Audio uses a **multi-stage volume control architecture** that requires careful configuration for optimal sound quality and proper volume response. The current system has **multiple amplification stages** that can compound, leading to unexpectedly loud volumes even at low settings.

---

## 1. Volume Control Architecture

### 1.1 Three-Stage Volume Chain

**With CamillaDSP:**
```
[MPD Volume 0-100%] 
    ↓
[CamillaDSP Volume (synced with MPD via mpd2cdspvolume)]
    ↓
[Hardware Digital Mixer (FIXED at 50% = -51.5dB)]
    ↓
[Hardware Analogue Mixer (FIXED at 100% = 0.0dB)]
    ↓
[HiFiBerry AMP100 Output]
```

**Without CamillaDSP:**
```
[MPD Volume 0-100%]
    ↓
[Hardware Digital Mixer (FIXED at 50% = -51.5dB)]
    ↓
[Hardware Analogue Mixer (FIXED at 100% = 0.0dB)]
    ↓
[HiFiBerry AMP100 Output]
```

### 1.2 Volume Control Points

| Stage | Control | Range | Purpose | Best Practice |
|-------|---------|-------|---------|---------------|
| **MPD** | User (moOde UI) | 0-100% | Primary volume control | 0-30% for normal listening |
| **CamillaDSP** | Auto-synced with MPD | -60dB to +20dB | Software volume in DSP | Managed by mpd2cdspvolume service |
| **Digital Mixer** | Hardware (ALSA) | 0-207 (0-100%) | HiFiBerry digital attenuation | **FIXED at 50% (-51.5dB)** |
| **Analogue Mixer** | Hardware (ALSA) | 0-1 (0-100%) | HiFiBerry analogue gain | **FIXED at 100% (0.0dB)** |

---

## 2. HiFiBerry AMP100 Volume Architecture

### 2.1 Digital vs Analogue Mixers

**Digital Mixer:**
- **Range:** 0-207 steps (0-100%)
- **Attenuation:** Logarithmic scale
- **50% = -51.5dB** (recommended fixed level)
- **80% = -20.5dB** (too high, causes loudness)
- **Purpose:** Digital volume control before DAC

**Analogue Mixer:**
- **Range:** 0-1 (on/off, 0% or 100%)
- **100% = 0.0dB** (no attenuation)
- **Purpose:** Analogue gain control after DAC
- **CRITICAL:** Never use for volume control! Always keep at 100%

### 2.2 Why 50% Digital Mixer?

**From moOde documentation:**
- 50% provides optimal signal-to-noise ratio
- Prevents digital clipping
- Maintains bit depth integrity
- Standard practice for high-end audio

**Problem:** If Digital mixer is set too high (e.g., 80%), even low MPD volumes become very loud because:
- MPD 10% × Digital 80% = Much louder than intended
- Multiple amplification stages compound

---

## 3. CamillaDSP Volume Control

### 3.1 Volume Sync Service (mpd2cdspvolume)

**Service:** `/usr/lib/systemd/system/mpd2cdspvolume.service`

**Function:**
- Monitors MPD volume changes
- Automatically syncs CamillaDSP volume to match MPD
- Converts MPD percentage to dB scale for CamillaDSP

**Volume Range:**
- Minimum: -60dB (essentially silent)
- Maximum: +20dB (can cause clipping)
- Default: 0dB (unity gain)

### 3.2 Filter Gain Compensation

**Problem:** Room correction filters often have negative gains (attenuation):
- Example: -169.4 dB total attenuation across all bands
- This reduces overall volume significantly
- Solution: Add gain compensation in filter chain

**peqgain Filter:**
- Type: Gain filter
- Purpose: Compensate for filter attenuation
- Current: +12 dB (may be too high)
- **Best Practice:** Start with +6 dB, adjust based on listening

**Warning:** Too much gain compensation (+12 dB or more) combined with:
- High Digital mixer (80%)
- High MPD volume (80%)
= **Excessively loud output even at low settings**

---

## 4. Current Problem Analysis

### 4.1 Issue: Volume Too Loud at Low Settings

**User Report:** "Volume at 12% is already really loud"

**Root Causes Identified:**

1. **Hardware Digital Mixer: 80%** (should be 50%)
   - Current: 80% = -20.5dB
   - Recommended: 50% = -51.5dB
   - **Impact:** +31dB louder than recommended

2. **Filter Gain Compensation: +12 dB**
   - Added to compensate for filter attenuation
   - May be excessive
   - **Impact:** +12dB additional gain

3. **Multiple Amplification Stages:**
   - MPD 12% → CamillaDSP (synced) → Digital 80% → Filters +12dB
   - All stages compound
   - **Result:** Much louder than expected

### 4.2 Volume Calculation Example

**Current Configuration:**
```
MPD: 12%
CamillaDSP: ~-20dB (synced with 12%)
Digital Mixer: 80% = -20.5dB
Filter Gain: +12dB
Total: ~-28.5dB effective
```

**Recommended Configuration:**
```
MPD: 12%
CamillaDSP: ~-20dB (synced with 12%)
Digital Mixer: 50% = -51.5dB
Filter Gain: +6dB
Total: ~-65.5dB effective
```

**Difference:** ~37dB louder in current config!

---

## 5. Best Practices for High-End Audio

### 5.1 Recommended Volume Settings

**For HiFiBerry AMP100 with CamillaDSP:**

| Setting | Value | Reason |
|---------|-------|--------|
| **Digital Mixer** | **50%** (FIXED) | Optimal SNR, prevents clipping |
| **Analogue Mixer** | **100%** (FIXED) | Unity gain, no attenuation |
| **MPD Volume** | 0-30% (normal) | User control range |
| **Filter Gain** | +6 to +9 dB | Compensate for filter attenuation |
| **Auto Mute** | OFF | Prevents unwanted muting |

### 5.2 Volume Control Strategy

**Option 1: Software Volume Only (Recommended)**
- Digital Mixer: FIXED at 50%
- Analogue Mixer: FIXED at 100%
- MPD Volume: 0-100% (user control)
- CamillaDSP: Synced with MPD
- **Advantage:** Full bit depth, no digital attenuation

**Option 2: Hybrid (Not Recommended)**
- Digital Mixer: Variable (user control)
- MPD Volume: Variable
- **Disadvantage:** Multiple stages, harder to control, potential clipping

### 5.3 Filter Gain Compensation Guidelines

**Rule of Thumb:**
1. Measure total filter attenuation
2. Add 50-75% of attenuation as gain compensation
3. Example: -169dB attenuation → +8 to +12dB compensation
4. **Start conservative:** Begin with +6dB, increase if needed

**Testing Protocol:**
1. Set MPD volume to 1%
2. Set Digital mixer to 50%
3. Set filter gain to +6dB
4. Play audio
5. Gradually increase MPD volume
6. Adjust filter gain if needed (max +12dB)

---

## 6. moOde Volume Control Implementation

### 6.1 Volume Control Script (vol.sh)

**Location:** `/var/www/util/vol.sh`

**Function:**
- Handles all volume changes from moOde UI
- Updates database: `cfg_system.volknob`, `cfg_system.volmute`
- Calls `amixer` or `mpc volume` based on mixer type

**Mixer Types:**
- `hardware`: Uses ALSA hardware mixer (Digital/Analogue)
- `software`: Uses MPD software volume
- `null`: CamillaDSP handles volume (current setup)

### 6.2 Database Settings

**Key Parameters:**
```sql
cfg_system.volknob = '50'        -- Hardware volume (0-100)
cfg_system.amixname = 'Digital' -- Mixer name
cfg_system.mpdmixer = 'null'    -- MPD mixer type (null = CamillaDSP)
cfg_mpd.mixer_type = 'null'     -- MPD mixer type
```

**Current Issue:**
- `volknob = 8` (should reflect Digital mixer %)
- `amixname = Analogue` (should be 'Digital')
- `mpdmixer = null` (correct for CamillaDSP)

### 6.3 Volume Sync Service

**Service:** `mpd2cdspvolume.service`

**How It Works:**
1. Monitors MPD volume via MPD protocol
2. Converts percentage to dB scale
3. Sends volume command to CamillaDSP via HTTP API
4. CamillaDSP applies volume in software

**Volume Mapping:**
- MPD 0% → CamillaDSP -60dB
- MPD 50% → CamillaDSP 0dB
- MPD 100% → CamillaDSP +20dB

---

## 7. Recommended Configuration Fix

### 7.1 Immediate Actions

**Step 1: Reset Hardware Mixers**
```bash
amixer sset Digital 50%    # Reset to recommended level
amixer sset Analogue 100%  # Ensure unity gain
```

**Step 2: Reduce Filter Gain**
```bash
# Edit /usr/share/camilladsp/working_config.yml
# Change peqgain from +12dB to +6dB
gain: 6  # Instead of gain: 12
```

**Step 3: Update Database**
```sql
UPDATE cfg_system SET value='50' WHERE param='volknob';
UPDATE cfg_system SET value='Digital' WHERE param='amixname';
```

**Step 4: Restart Services**
```bash
systemctl restart mpd
systemctl restart camilladsp  # If using systemd service
```

### 7.2 Target Configuration

**Hardware:**
- Digital Mixer: **50%** (-51.5dB) - FIXED
- Analogue Mixer: **100%** (0.0dB) - FIXED

**Software:**
- MPD Volume: **0-30%** for normal listening
- Filter Gain: **+6 to +9 dB** (adjust based on listening)
- Volume Sync: **ON** (mpd2cdspvolume active)

**Expected Behavior:**
- MPD 1%: Very quiet, safe for testing
- MPD 10%: Quiet background listening
- MPD 20%: Normal listening
- MPD 30%: Moderate volume
- MPD 50%: Loud (maximum recommended)

---

## 8. High-End Audio Best Practices

### 8.1 Bit Depth Preservation

**Principle:** Minimize digital attenuation to preserve bit depth

**Why 50% Digital Mixer?**
- Provides headroom for dynamic range
- Prevents digital clipping
- Maintains 24-bit resolution
- Standard practice in professional audio

**Avoid:**
- High Digital mixer settings (>60%)
- Multiple digital attenuation stages
- Excessive filter gain (>+15dB)

### 8.2 Signal Chain Optimization

**Optimal Chain:**
```
Source (24-bit) 
  → MPD (software volume, bit-perfect)
  → CamillaDSP (DSP processing, volume control)
  → HiFiBerry (hardware, minimal attenuation)
  → Amplifier
```

**Key Points:**
- Keep digital attenuation minimal
- Use software volume for control
- Hardware mixers for fine-tuning only
- Preserve bit depth throughout chain

### 8.3 Volume Calibration

**Professional Method:**
1. Set Digital mixer to 50%
2. Set Analogue mixer to 100%
3. Play reference tone at 0dBFS
4. Measure output level
5. Adjust filter gain to achieve target SPL
6. Document settings

**Home Method:**
1. Set Digital mixer to 50%
2. Set filter gain to +6dB
3. Play music at MPD 20%
4. Adjust filter gain until comfortable
5. Use MPD 0-30% for normal listening

---

## 9. Troubleshooting Volume Issues

### 9.1 Too Loud at Low Settings

**Symptoms:**
- Volume at 10-15% is already loud
- Can't find comfortable listening level

**Causes:**
1. Digital mixer too high (>60%)
2. Filter gain too high (>+12dB)
3. Multiple amplification stages

**Fix:**
1. Reduce Digital mixer to 50%
2. Reduce filter gain to +6dB
3. Restart MPD

### 9.2 Too Quiet Even at High Settings

**Symptoms:**
- Volume at 80-100% is still quiet
- Need maximum volume for normal listening

**Causes:**
1. Digital mixer too low (<40%)
2. Filter gain too low or negative
3. Filter attenuation not compensated

**Fix:**
1. Increase Digital mixer to 50% (max recommended)
2. Increase filter gain to +9dB
3. Check filter attenuation

### 9.3 Volume Not Responding

**Symptoms:**
- Volume slider doesn't change output
- Volume stuck at one level

**Causes:**
1. mpd2cdspvolume service not running
2. CamillaDSP not receiving volume commands
3. Hardware mixer locked

**Fix:**
1. Check `systemctl status mpd2cdspvolume`
2. Check CamillaDSP HTTP API (port 1234)
3. Verify mixer is not locked: `amixer sget Digital`

---

## 10. Configuration Files Reference

### 10.1 Volume Control Script

**File:** `/var/www/util/vol.sh`

**Key Functions:**
- `set-volume`: Updates volume via amixer or mpc
- `get-volume`: Reads current volume level
- `get-mixername`: Detects mixer name

### 10.2 CamillaDSP Configuration

**File:** `/usr/share/camilladsp/working_config.yml`

**Volume Settings:**
```yaml
filters:
  peqgain:
    type: Gain
    parameters:
      gain: 6  # Adjust this for compensation
```

### 10.3 ALSA Configuration

**File:** `/etc/alsa/conf.d/_audioout.conf`

**Routing:**
```conf
pcm._audioout {
  type copy
  slave.pcm "camilladsp"  # Routes to CamillaDSP
}
```

### 10.4 Database Settings

**File:** `/var/local/www/db/moode-sqlite3.db`

**Key Tables:**
- `cfg_system`: volknob, amixname, mpdmixer
- `cfg_mpd`: mixer_type

---

## 11. Recommendations Summary

### 11.1 Immediate Fix

1. **Set Digital mixer to 50%** (from 80%)
2. **Reduce filter gain to +6dB** (from +12dB)
3. **Keep Analogue mixer at 100%**
4. **Test with MPD volume 1-30%**

### 11.2 Long-Term Configuration

1. **Digital Mixer: FIXED at 50%** (never change)
2. **Analogue Mixer: FIXED at 100%** (never change)
3. **MPD Volume: Primary control** (0-100%)
4. **Filter Gain: +6 to +9dB** (adjust based on listening)
5. **Volume Sync: ON** (mpd2cdspvolume active)

### 11.3 Testing Protocol

1. Set MPD volume to 1%
2. Set Digital mixer to 50%
3. Set filter gain to +6dB
4. Play audio
5. Gradually increase MPD volume
6. Adjust filter gain if needed (max +9dB)
7. Document final settings

---

## 12. References

- moOde Audio Documentation: https://moodeaudio.org/
- HiFiBerry AMP100 Manual: https://www.hifiberry.com/
- CamillaDSP Documentation: https://github.com/HEnquist/camilladsp
- ALSA Mixer Guide: https://www.alsa-project.org/
- High-End Audio Best Practices: Professional audio engineering standards

---

**Document Version:** 1.0  
**Last Updated:** 2026-01-21  
**Author:** System Analysis  
**Status:** Complete Study
