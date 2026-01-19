# IEC958 (S/PDIF) Configuration Summary

**Date:** 2026-01-19  
**Status:** ✅ IEC958 DISABLED (correct for analog output)  
**System:** HiFiBerry AMP100 with analog speakers

---

## What is IEC958?

**IEC958 = S/PDIF (Sony/Philips Digital Interface Format)**

### Purpose
- Digital audio transmission standard
- For optical (TOSLINK) or coaxial (RCA) digital connections
- Transmits PCM audio digitally to external DACs or receivers

### NOT For Your System
- ❌ You have **analog speakers** (not digital receiver)
- ❌ HiFiBerry AMP100 is **DAC + amplifier** (not digital passthrough)
- ❌ IEC958 would bypass the DAC and try to output raw digital signal

---

## Why IEC958 Must Be DISABLED

### Your Audio Chain

```
Audio Source (MPD, AirPlay, etc.)
         ↓
    ALSA (software)
         ↓
  HiFiBerry AMP100 HAT
         ↓
   PCM5122 DAC (converts digital → analog)
         ↓
  60W Class D Amplifier
         ↓
  Analog Speakers 🔊
```

**With IEC958 enabled (WRONG):**
```
Audio Source
    ↓
  IEC958 digital output
    ↓
  ❌ No conversion to analog
    ↓
  ❌ Amplifier gets digital signal (wrong!)
    ↓
  ❌ No sound or garbled output
```

---

## IEC958 is ALSA Software, Not Hardware

### Critical Understanding

**Layer Separation:**

```
┌─────────────────────────────────────┐
│   Hardware Layer (Device Tree)      │
│   - Initializes PCM5122 chip        │
│   - Configures I2C address (0x4d)   │
│   - Enables I2S audio interface      │
│   - Does NOT control IEC958!        │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│   Software Layer (ALSA)             │
│   - Audio routing decisions         │
│   - IEC958 on/off control           │
│   - PCM vs digital output choice    │
│   - Volume control                  │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│   Application Layer (moOde)         │
│   - Database: alsa_output_mode      │
│   - UI: Audio Device selection      │
│   - Configuration management        │
└─────────────────────────────────────┘
```

---

## Common Mistake (From Past Attempts)

### ❌ WRONG Approach

**Tried in past fixes:**
```ini
# /boot/firmware/config.txt
dtoverlay=hifiberry-amp100,disable_iec958
```

**Why it's wrong:**
- Parameter `disable_iec958` **does not exist** in device tree
- IEC958 is configured in ALSA (software), not device tree (hardware)
- Device tree only initializes the PCM5122 chip
- Result: Parameter ignored, IEC958 still enabled

---

## ✅ CORRECT Configuration

### Layer 1: Device Tree (config.txt)

```ini
# /boot/firmware/config.txt
dtoverlay=hifiberry-amp100    # ✅ Initializes PCM5122 hardware
# No IEC958 parameter - doesn't exist!
```

### Layer 2: ALSA (/etc/asound.conf)

**Managed by moOde** - Routes audio to hardware device:
```
pcm.!default {
    type plug
    slave.pcm "hw:1,0"    # Direct hardware access (no IEC958)
}
```

### Layer 3: moOde Database

```sql
-- /var/local/www/db/moode-sqlite3.db
-- cfg_outputdev table
alsa_output_mode = 'plughw'   -- ✅ Direct PCM output
-- NOT 'iec958'
```

### Layer 4: Service Configs

**shairport-sync:**
```ini
# /etc/shairport-sync.conf
output_device = "plughw:1,0";   # ✅ Direct hardware (no IEC958)
```

**MPD:**
```ini
# /etc/mpd.conf
audio_output {
    type "alsa"
    name "HiFiBerry"
    device "hw:1,0"    # ✅ Direct hardware (no IEC958)
}
```

---

## How to Check IEC958 Status

### On Running System

```bash
# 1. Check ALSA controls
amixer -c 1 scontrols
# Should NOT see 'IEC958' control

# 2. Check moOde database
moodeutl -q "SELECT alsa_output_mode FROM cfg_outputdev WHERE device_name='HiFiBerry AMP100'"
# Expected: plughw (NOT iec958)

# 3. Check ALSA config
cat /etc/asound.conf
# Should route to hw:1,0 (not iec958 device)

# 4. Check PCM devices
aplay -L | grep -A 2 iec958
# Should be empty or minimal (iec958 not primary device)
```

---

## IEC958 Use Cases (When It's Needed)

### When IEC958 IS Correct

```
Scenarios where IEC958 is appropriate:
1. Output to external DAC via optical (TOSLINK)
2. Output to AV receiver via coaxial S/PDIF
3. Output to soundbar via digital connection
4. Pass-through to external digital equipment
```

### Your System: IEC958 NOT Needed

```
Your setup:
- Internal DAC (PCM5122 on HiFiBerry)
- Internal amplifier (60W Class D)
- Analog speakers (passive, no DAC)
- Result: Use direct PCM output (plughw)
```

---

## moOde Configuration

### Audio Output Mode Options

| Mode | Device String | Use Case |
|------|---------------|----------|
| `plughw` | `plughw:1,0` | ✅ Your setup (analog speakers) |
| `iec958` | `iec958:1,0` | ❌ Wrong (digital S/PDIF output) |
| `hw` | `hw:1,0` | ✅ Also OK (direct hardware) |

**Your build uses:** `plughw:1,0` ✅

---

## Build Configuration Status

### ✅ Correctly Configured

**Device Tree (config.txt):**
```ini
dtoverlay=hifiberry-amp100    # ✅ No fake parameters
```

**AirPlay (shairport-sync.conf):**
```ini
output_device = "plughw:1,0";  # ✅ Direct PCM output
```

**No IEC958 references** - System will use direct PCM output to DAC

---

## Verification Commands

### After Build/Flash

```bash
# 1. Check moOde audio config
moodeutl -q "SELECT * FROM cfg_outputdev"
# Verify alsa_output_mode is NOT 'iec958'

# 2. Check ALSA routing
cat /etc/asound.conf
# Should route to hw:1,0 or plughw:1,0

# 3. Test audio output
speaker-test -D plughw:1,0 -c 2
# Should hear test tone through speakers

# 4. Check for IEC958 device
aplay -L | grep iec958
# Should be minimal/absent

# 5. Verify PCM routing
cat /proc/asound/card1/pcm0p/sub0/hw_params
# Should show PCM format (when playing audio)
```

---

## Documentation References

From device tree study (extensive research):

### COMMON_MISTAKES.md
```markdown
## Mistake 1: Trying to Configure IEC958 in Device Tree

❌ Wrong: dtoverlay=hifiberry-amp100,disable_iec958
✅ Correct: Configure in ALSA layer (amixer or asound.conf)
```

### PARAMETERS_REFERENCE.md
```markdown
| Parameter | Exists? | Layer |
|-----------|---------|-------|
| disable_iec958 | ❌ NO | Doesn't exist |
| IEC958 control | ✅ YES | ALSA software |
```

---

## Summary

### What IEC958 Is
- Digital audio format (S/PDIF)
- For optical/coaxial digital connections
- Configured in ALSA software layer

### Your System
- ✅ IEC958 **not used** (correct)
- ✅ Direct PCM output to PCM5122 DAC
- ✅ Analog output to speakers
- ✅ No device tree parameters needed

### Configuration Status
- ✅ Device tree: Only initializes hardware
- ✅ ALSA: Routes to `plughw:1,0` (direct PCM)
- ✅ shairport-sync: Uses `plughw:1,0`
- ✅ MPD: Uses `hw:1,0`
- ✅ No IEC958 references

**Result:** Proper analog audio output through DAC and amplifier to speakers! 🔊

---

## Key Takeaway

**IEC958 is for digital passthrough, NOT for systems with internal DAC + amplifier like yours.**

Your HiFiBerry AMP100 is a complete audio solution:
- DAC (converts digital to analog)
- Amplifier (drives speakers)
- No need for external digital connection
- **Therefore: No IEC958 needed!** ✅
