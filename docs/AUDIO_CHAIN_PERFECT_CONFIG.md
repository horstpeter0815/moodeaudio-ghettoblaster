# Perfect Audio Chain Configuration - Ghetto Blaster
## Complete, Precise Configuration Reference

**Date:** 2025-01-09  
**System:** Raspberry Pi 5 + HiFiBerry AMP100 + PeppyMeter + CamillaDSP

---

## 🎯 Complete Audio Chain (PeppyMeter ON + CamillaDSP ON)

```
Music File
  ↓
MPD (Music Player Daemon)
  ↓ device "_audioout"
/etc/alsa/conf.d/_audioout.conf
  ↓ slave.pcm "camilladsp"  (when CamillaDSP ON)
pcm.camilladsp (ALSA device)
  ↓
CamillaDSP Process
  ↓ reads from stdin (pipe from MPD)
  ↓ applies filters/EQ (bose_wave_filters.yml)
  ↓ outputs to ALSA device "peppy" (when PeppyMeter ON)
pcm.peppy (ALSA device)
  ↓
PeppyMeter Process
  ↓ reads from /tmp/peppymeter FIFO
  ↓ displays VU meters (blue skin)
  ↓ outputs to _peppyout
/etc/alsa/conf.d/_peppyout.conf
  ↓ slave.pcm "plughw:0,0"
plughw:0,0 (HiFiBerry AMP100 - card 0, device 0)
  ↓
HiFiBerry AMP100 Hardware
  ↓
Speakers
```

---

## ✅ Perfect Configuration Checklist

### 1. Boot Configuration (`/boot/firmware/config.txt`)

**Required Settings:**
```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0

[all]
dtparam=i2s=on
dtparam=audio=off
dtoverlay=hifiberry-amp100,automute
force_eeprom_read=0
```

**Verification:**
```bash
grep "hifiberry-amp100\|audio=off\|i2s=on" /boot/firmware/config.txt
```

### 2. moOde Database (`/var/local/www/db/moode-sqlite3.db`)

**Required Values:**
```sql
-- Audio device
cfg_system.cardnum = 0
cfg_system.i2sdevice = "HiFiBerry AMP100"
cfg_mpd.device = 0

-- PeppyMeter
cfg_system.peppy_display = 1              -- 1 = ON
cfg_system.peppy_display_type = "meter"   -- "meter" or "spectrum"

-- CamillaDSP
cfg_system.camilladsp = "bose_wave_filters.yml"  -- Config name or "off"
cfg_system.cdsp_fix_playback = "Yes"     -- CRITICAL: Enables PeppyMeter integration

-- Display
cfg_system.hdmi_scn_orient = "portrait"
cfg_system.local_display = 1
```

**Verification:**
```bash
sqlite3 /var/local/www/db/moode-sqlite3.db \
  "SELECT param, value FROM cfg_system WHERE param IN ('cardnum', 'i2sdevice', 'peppy_display', 'camilladsp', 'cdsp_fix_playback');"
```

### 3. ALSA Configuration

#### `/etc/alsa/conf.d/_audioout.conf`

**Routing Logic (from `updAudioOutAndBtOutConfs()`):**
```
Priority Order:
1. CamillaDSP ON → slave.pcm "camilladsp"
2. PeppyMeter ON (CamillaDSP OFF) → slave.pcm "peppy"
3. Both OFF → slave.pcm "plughw:0,0"
```

**Perfect Config (PeppyMeter + CamillaDSP):**
```conf
pcm._audioout {
    type copy
    slave.pcm "camilladsp"
}
```

**Perfect Config (PeppyMeter only):**
```conf
pcm._audioout {
    type copy
    slave.pcm "peppy"
}
```

**Perfect Config (Direct):**
```conf
pcm._audioout {
    type copy
    slave.pcm "plughw:0,0"
}
```

**Verification:**
```bash
cat /etc/alsa/conf.d/_audioout.conf
```

#### `/etc/alsa/conf.d/_peppyout.conf`

**Perfect Config:**
```conf
pcm._peppyout {
    type copy
    slave.pcm "plughw:0,0"
}
```

**Verification:**
```bash
cat /etc/alsa/conf.d/_peppyout.conf
```

### 4. MPD Configuration (`/var/lib/mpd/mpd.conf`)

**Perfect Config:**
```conf
audio_output {
    type "alsa"
    name "ALSA Default"
    device "_audioout"
    mixer_type "null"        # When CamillaDSP ON
    # mixer_type "hardware"  # When CamillaDSP OFF
    mixer_control "PCM"
    mixer_device "hw:0"
    mixer_index "0"
}
```

**Mixer Type Logic:**
- CamillaDSP ON → `mixer_type "null"` (CamillaDSP handles volume)
- CamillaDSP OFF → `mixer_type "hardware"` or `"software"`

**Verification:**
```bash
grep -A 10 "audio_output" /var/lib/mpd/mpd.conf | head -10
```

### 5. CamillaDSP Configuration

#### Config File Location
- Active: `/usr/share/camilladsp/working_config.yml`
- Configs: `/usr/share/camilladsp/configs/`

#### Perfect Config (PeppyMeter ON)
```yaml
devices:
  capture:
    type: Stdin
    channels: 2
    format: S32LE
  playback:
    type: Alsa
    channels: 2
    device: "peppy"          # CRITICAL: Outputs to PeppyMeter
    format: S32LE
```

#### Perfect Config (PeppyMeter OFF)
```yaml
devices:
  capture:
    type: Stdin
    channels: 2
    format: S32LE
  playback:
    type: Alsa
    channels: 2
    device: "plughw:0,0"    # Direct to hardware
    format: S32LE
```

**Verification:**
```bash
cat /usr/share/camilladsp/working_config.yml | grep -A 5 "playback"
```

### 6. PeppyMeter Configuration (`/etc/peppymeter/config.txt`)

**Perfect Config:**
```ini
[current]
meter = blue                    # Always blue skin
random.meter.interval = 0       # No random switching
meter.folder = 1280x400         # Display resolution
screen.width = 1280
screen.height = 400

[data.source]
type = pipe
pipe.name = /tmp/peppymeter     # FIFO from MPD
```

**Verification:**
```bash
grep "meter\|random\|pipe.name" /etc/peppymeter/config.txt
```

---

## 🔄 Configuration Update Flow

### When Settings Change in moOde:

1. **User changes setting** (e.g., enables CamillaDSP)
2. **moOde calls `updMpdConf()`**
3. **`updMpdConf()` calls:**
   - `updAudioOutAndBtOutConfs()` → Updates `_audioout.conf`
   - `updPeppyConfs()` → Updates `_peppyout.conf`
   - `updDspAndBtInConfs()` → Updates CamillaDSP playback device
4. **MPD restarts** → Picks up new `_audioout` routing
5. **CamillaDSP reloads** → Picks up new playback device

### Critical Functions:

**`updAudioOutAndBtOutConfs($cardNum, $outputMode)`**
- Updates `_audioout.conf` routing
- Priority: CamillaDSP > PeppyMeter > Direct

**`updPeppyConfs($cardNum, $outputMode)`**
- Updates `_peppyout.conf` routing
- Always routes to `plughw:CARD,0`

**`setPlaybackDevice($cardNum, $outputMode)`**
- Updates CamillaDSP YAML config
- Sets playback device based on PeppyMeter state

---

## 🛡️ Safety Mechanisms

### 1. Audio Chain Fix Script
**Location:** `/usr/local/bin/fix-audio-chain.sh`

**What it does:**
- Detects AMP100 card number
- Updates database (cardnum, i2sdevice, cdsp_fix_playback)
- Fixes `_audioout.conf` with correct routing logic
- Fixes `_peppyout.conf` to AMP100
- Verifies CamillaDSP config
- Verifies PeppyMeter config
- Unmutes and sets safe volume
- Restarts MPD

**Runs:** On boot (via systemd service)

### 2. PeppyMeter Blue Skin Script
**Location:** `/usr/local/bin/set-peppymeter-blue.sh`

**What it does:**
- Sets `meter = blue` in PeppyMeter config
- Disables random meter switching
- Restarts PeppyMeter if running

**Runs:** On boot (via systemd service)

### 3. Validation Script
**Location:** `/usr/local/bin/validate-audio-chain.sh`

**What it does:**
- Checks all components
- Verifies configurations
- Reports issues

**Runs:** Manually or scheduled

---

## 📊 Configuration Matrix

| PeppyMeter | CamillaDSP | _audioout.conf | CamillaDSP Playback | _peppyout.conf | MPD Mixer |
|------------|------------|----------------|---------------------|----------------|-----------|
| ON         | ON         | `camilladsp`   | `peppy`             | `plughw:0,0`   | `null`    |
| ON         | OFF        | `peppy`        | N/A                 | `plughw:0,0`   | `hardware`|
| OFF        | ON         | `camilladsp`   | `plughw:0,0`        | N/A            | `null`    |
| OFF        | OFF        | `plughw:0,0`   | N/A                 | N/A            | `hardware`|

---

## ✅ Verification Commands

### Complete Check
```bash
# Run validation script
sudo /usr/local/bin/validate-audio-chain.sh
```

### Manual Checks
```bash
# 1. AMP100 detected?
cat /proc/asound/cards | grep -i hifiberry

# 2. Database correct?
sqlite3 /var/local/www/db/moode-sqlite3.db \
  "SELECT param, value FROM cfg_system WHERE param IN ('cardnum', 'i2sdevice', 'peppy_display', 'camilladsp', 'cdsp_fix_playback');"

# 3. ALSA routing correct?
echo "_audioout.conf:"
cat /etc/alsa/conf.d/_audioout.conf | grep slave.pcm
echo "_peppyout.conf:"
cat /etc/alsa/conf.d/_peppyout.conf | grep slave.pcm

# 4. CamillaDSP playback device?
cat /usr/share/camilladsp/working_config.yml | grep -A 3 "playback:" | grep device

# 5. PeppyMeter config?
grep "meter\|random" /etc/peppymeter/config.txt

# 6. Services running?
systemctl status mpd peppymeter camilladsp --no-pager | grep Active
```

---

## 🚨 Common Issues & Solutions

### Issue: No Audio
**Check:**
1. AMP100 detected? → `cat /proc/asound/cards`
2. Database cardnum correct? → Check database
3. `_audioout.conf` routing correct? → Check ALSA config
4. MPD running? → `systemctl status mpd`
5. Volume muted? → `amixer -c 0 sget Master`

**Fix:** Run `sudo /usr/local/bin/fix-audio-chain.sh`

### Issue: PeppyMeter Shows No Activity
**Check:**
1. PeppyMeter running? → `systemctl status peppymeter`
2. FIFO exists? → `ls -la /tmp/peppymeter`
3. `_audioout.conf` routes to `peppy`? → Check ALSA config
4. MPD outputs to `_audioout`? → Check MPD config

**Fix:** Ensure PeppyMeter is enabled in moOde, restart services

### Issue: CamillaDSP Filters Not Applied
**Check:**
1. CamillaDSP running? → `systemctl status camilladsp`
2. Config selected? → Check database `camilladsp` value
3. Config file exists? → `ls /usr/share/camilladsp/configs/`
4. Playback device correct? → Check YAML config

**Fix:** Select config in moOde Audio Config, apply, restart

### Issue: Wrong Meter Skin
**Check:**
1. `meter = blue` in config? → `grep "meter = " /etc/peppymeter/config.txt`
2. Random switching disabled? → `grep "random.meter.interval" /etc/peppymeter/config.txt`

**Fix:** Run `sudo /usr/local/bin/set-peppymeter-blue.sh`

---

## 📦 Files & Scripts

### Scripts
- `scripts/audio/fix-audio-chain.sh` - Main audio chain fix
- `scripts/audio/validate-audio-chain.sh` - Validation
- `scripts/wizard/set-peppymeter-blue.sh` - PeppyMeter blue skin

### Services
- `moode-source/lib/systemd/system/fix-audio-chain.service` - Auto-fix on boot
- `moode-source/lib/systemd/system/set-peppymeter-blue.service` - Auto-set blue skin

### Documentation
- `docs/COMPLETE_AUDIO_CHAIN_CONFIGURATION.md` - Full documentation
- `docs/AUDIO_CHAIN_QUICK_REFERENCE.md` - Quick reference
- `docs/AUDIO_CHAIN_PERFECT_CONFIG.md` - This file

---

## 🎯 Summary

**Complete Audio Chain:**
```
MPD → _audioout → camilladsp → peppy → _peppyout → plughw:0,0 → AMP100
```

**Perfect Configuration:**
- ✅ Boot: AMP100 overlay, audio disabled
- ✅ Database: Correct cardnum, i2sdevice, peppy_display, camilladsp, cdsp_fix_playback
- ✅ ALSA: Correct routing based on enabled features
- ✅ PeppyMeter: Blue skin, no random switching
- ✅ CamillaDSP: Correct playback device, filters configured
- ✅ MPD: Correct mixer type, device routing

**Safety:**
- ✅ Fix scripts ensure correct configuration
- ✅ Services run on boot
- ✅ Validation scripts check all components
- ✅ Volume safety (unmute, safe level)

**This is the complete, precise configuration for Ghetto Blaster audio chain.**
