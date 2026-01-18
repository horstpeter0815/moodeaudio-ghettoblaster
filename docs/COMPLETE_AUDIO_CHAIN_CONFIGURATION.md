# Complete Audio Chain Configuration - Ghetto Blaster
## HiFiBerry AMP100 + PeppyMeter + CamillaDSP

**Date:** 2025-01-09  
**Status:** ✅ Complete Configuration Document

---

## 🎯 Audio Chain Overview

### Complete Flow (PeppyMeter ON + CamillaDSP ON):
```
Music File
  ↓
MPD (Music Player Daemon)
  ↓
device "_audioout" (ALSA PCM)
  ↓
/etc/alsa/conf.d/_audioout.conf
  ↓ (routes to camilladsp when CamillaDSP is ON)
pcm.camilladsp (ALSA device)
  ↓
CamillaDSP Process (applies filters/EQ)
  ↓ (outputs to peppy when PeppyMeter is ON)
pcm.peppy (ALSA device)
  ↓
PeppyMeter Process (reads from /tmp/peppymeter FIFO, displays VU meters)
  ↓
/etc/alsa/conf.d/_peppyout.conf
  ↓
plughw:0,0 (HiFiBerry AMP100 - card 0, device 0)
  ↓
HiFiBerry AMP100 Hardware
  ↓
Speakers
```

### Simplified Flow (PeppyMeter ON, CamillaDSP OFF):
```
MPD → _audioout → peppy → _peppyout → plughw:0,0 → AMP100
```

### Simplified Flow (PeppyMeter OFF, CamillaDSP ON):
```
MPD → _audioout → camilladsp → plughw:0,0 → AMP100
```

### Direct Flow (Both OFF):
```
MPD → _audioout → plughw:0,0 → AMP100
```

---

## 📋 Configuration Files

### 1. Boot Configuration (`/boot/firmware/config.txt`)
```ini
# Pi 5 specific
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0

# Common settings
[all]
max_framebuffers=2
display_auto_detect=1
disable_fw_kms_setup=1
arm_64bit=1
enable_uart=1

# Display settings
disable_overscan=1
hdmi_group=2
hdmi_mode=87
hdmi_cvt=400 1280 60 6 0 0 0
hdmi_force_mode=1

# Audio settings
dtparam=i2s=on
dtparam=audio=off
dtoverlay=hifiberry-amp100,automute
force_eeprom_read=0
```

**Critical Settings:**
- `dtoverlay=hifiberry-amp100,automute` - Enables AMP100 with auto-mute
- `dtparam=audio=off` - Disables onboard audio (prevents conflicts)
- `dtoverlay=vc4-kms-v3d-pi5,noaudio` - Disables HDMI audio

### 2. ALSA Configuration

#### `/etc/alsa/conf.d/_audioout.conf`
**Purpose:** Routes MPD output to correct destination

**Configuration Logic (from `updAudioOutAndBtOutConfs()`):**
```php
Priority order:
1. If alsaequal != 'Off' → slave.pcm "alsaequal"
2. Else if camilladsp != 'off' → slave.pcm "camilladsp"
3. Else if crossfeed != 'Off' → slave.pcm "crossfeed"
4. Else if eqfa12p != 'Off' → slave.pcm "eqfa12p"
5. Else if invert_polarity != '0' → slave.pcm "invpolarity"
6. Else if peppy_display == '1' → slave.pcm "peppy"
7. Else if audioout == 'Bluetooth' → slave.pcm "btstream"
8. Else → slave.pcm "plughw:CARD,0" (direct to hardware)
```

**Default Template:**
```conf
pcm._audioout {
    type copy
    slave.pcm "plughw:0,0"
}
```

#### `/etc/alsa/conf.d/_peppyout.conf`
**Purpose:** Routes PeppyMeter output to hardware

**Configuration Logic (from `updPeppyConfs()`):**
```php
If audioout == 'Bluetooth':
    slave.pcm "btstream"
Else:
    slave.pcm "plughw:CARD,0" (or hw:CARD,0 or iec958 device)
```

**Default Template:**
```conf
pcm._peppyout {
    type copy
    slave.pcm "plughw:0,0"
}
```

#### `/etc/alsa/conf.d/camilladsp.conf`
**Purpose:** ALSA wrapper for CamillaDSP

**Configuration:** Managed by CamillaDSP class
- Capture: stdin (pipe from MPD)
- Playback: Set by `setPlaybackDevice()`
  - If PeppyMeter ON: `device: "peppy"`
  - If Bluetooth: `device: "btstream"`
  - Otherwise: `device: "plughw:CARD,0"`

### 3. MPD Configuration (`/var/lib/mpd/mpd.conf`)

**Audio Output:**
```conf
audio_output {
    type "alsa"
    name "ALSA Default"
    device "_audioout"
    mixer_type "hardware"  # or "software" or "null" (for CamillaDSP)
    mixer_control "PCM"    # or "Master" depending on device
    mixer_device "hw:0"
    mixer_index "0"
}
```

**Critical Settings:**
- `device "_audioout"` - Always uses ALSA `_audioout` device
- `mixer_type`:
  - `"hardware"` - Uses AMP100 hardware volume control
  - `"software"` - Uses MPD software volume
  - `"null"` - No volume control (used when CamillaDSP is active)

### 4. CamillaDSP Configuration

#### Config File Location
- Active config: `/usr/share/camilladsp/working_config.yml`
- Configs directory: `/usr/share/camilladsp/configs/`
- Coefficients: `/usr/share/camilladsp/coeffs/`

#### Playback Device Logic (`setPlaybackDevice()`)
```php
If peppy_display == '1':
    device: "peppy"  # Output to PeppyMeter
Else if audioout == 'Bluetooth':
    device: "btstream"
Else:
    device: "plughw:CARD,0"  # Direct to hardware
```

#### Capture Device
- Always: `type: "Stdin"` (reads from pipe)
- Format: Auto-detected from hardware capabilities

### 5. PeppyMeter Configuration (`/etc/peppymeter/config.txt`)

**Critical Settings:**
```ini
[current]
meter = blue                    # Always use blue meter skin
random.meter.interval = 0       # Disable random switching
meter.folder = 1280x400         # Display resolution folder
screen.width = 1280
screen.height = 400

[data.source]
type = pipe
pipe.name = /tmp/peppymeter     # FIFO pipe from MPD
```

**Meter Skin:** Always `blue` (set by `set-peppymeter-blue.sh`)

### 6. moOde Database Configuration

**Critical Parameters:**
```sql
-- Audio device
cfg_system.cardnum = 0                    -- AMP100 card number
cfg_system.i2sdevice = "HiFiBerry AMP100"
cfg_mpd.device = 0                        -- MPD device card number

-- PeppyMeter
cfg_system.peppy_display = 1              -- 1 = ON, 0 = OFF
cfg_system.peppy_display_type = "meter"   -- "meter" or "spectrum"

-- CamillaDSP
cfg_system.camilladsp = "bose_wave_filters.yml"  -- Config file name or "off"
cfg_system.cdsp_fix_playback = "Yes"     -- Enable playback device fix

-- Display
cfg_system.hdmi_scn_orient = "portrait"  -- Hardware orientation
cfg_system.local_display = 1              -- 1 = Local display ON
```

---

## 🔧 Configuration Logic (PHP Code)

### Audio Output Routing (`updAudioOutAndBtOutConfs()`)

**Priority Order:**
1. **CamillaDSP** (highest priority if enabled)
2. **PeppyMeter** (if CamillaDSP OFF)
3. **Direct hardware** (if both OFF)

**Code Logic:**
```php
if ($_SESSION['camilladsp'] != 'off') {
    $alsaDevice = 'camilladsp';  // Route to CamillaDSP
} else if ($_SESSION['peppy_display'] == '1') {
    $alsaDevice = 'peppy';       // Route to PeppyMeter
} else {
    $alsaDevice = 'plughw:' . $cardNum . ',0';  // Direct to hardware
}
```

### CamillaDSP Playback Device (`setPlaybackDevice()`)

**Code Logic:**
```php
if ($_SESSION['peppy_display'] == '1') {
    $alsaDevice = 'peppy';  // Output to PeppyMeter for display
} else {
    $alsaDevice = 'plughw:' . $cardNum . ',0';  // Direct to hardware
}
```

**Result:** When PeppyMeter is ON, CamillaDSP outputs to `peppy`, which then routes to `_peppyout` → hardware.

---

## ✅ Perfect Configuration Checklist

### Boot Configuration
- [x] `dtoverlay=hifiberry-amp100,automute` in config.txt
- [x] `dtparam=audio=off` in config.txt
- [x] `dtoverlay=vc4-kms-v3d-pi5,noaudio` in config.txt
- [x] `dtparam=i2s=on` in config.txt

### moOde Database
- [x] `cardnum = 0` (AMP100 card number)
- [x] `i2sdevice = "HiFiBerry AMP100"`
- [x] `mpd.device = 0`
- [x] `peppy_display = 1` (if using PeppyMeter)
- [x] `peppy_display_type = "meter"`
- [x] `camilladsp = "bose_wave_filters.yml"` (or filter config name)
- [x] `cdsp_fix_playback = "Yes"`

### ALSA Configuration
- [x] `_audioout.conf` routes to correct device:
  - CamillaDSP ON → `camilladsp`
  - PeppyMeter ON (CamillaDSP OFF) → `peppy`
  - Both OFF → `plughw:0,0`
- [x] `_peppyout.conf` routes to `plughw:0,0`
- [x] `camilladsp.conf` configured correctly

### PeppyMeter Configuration
- [x] `meter = blue` (always blue skin)
- [x] `random.meter.interval = 0` (no random switching)
- [x] `meter.folder = 1280x400` (correct resolution)
- [x] `pipe.name = /tmp/peppymeter` (FIFO pipe)

### CamillaDSP Configuration
- [x] Config file exists in `/usr/share/camilladsp/configs/`
- [x] Playback device set correctly:
  - PeppyMeter ON → `device: "peppy"`
  - PeppyMeter OFF → `device: "plughw:0,0"`
- [x] Capture device: `type: "Stdin"`

### MPD Configuration
- [x] `device "_audioout"` (always uses ALSA _audioout)
- [x] `mixer_type`:
  - CamillaDSP ON → `"null"` (no volume control)
  - CamillaDSP OFF → `"hardware"` or `"software"`

---

## 🛡️ Safety Checks & Validation

### Audio Chain Validation Script

**Location:** `scripts/audio/validate-audio-chain.sh`

**Checks:**
1. AMP100 detection (`/proc/asound/cards`)
2. moOde database configuration
3. ALSA config files (`_audioout.conf`, `_peppyout.conf`)
4. MPD status and configuration
5. PeppyMeter status
6. CamillaDSP status
7. Volume/mute state

### Audio Chain Fix Script

**Location:** `scripts/audio/fix-audio-chain.sh`

**Fixes:**
1. Detects AMP100 card number
2. Updates moOde database (`cardnum`, `i2sdevice`, `mpd.device`)
3. Fixes `_audioout.conf` to point to correct device
4. Fixes `_peppyout.conf` to point to AMP100
5. Unmutes and sets safe volume
6. Restarts MPD

### PeppyMeter Blue Skin Script

**Location:** `scripts/wizard/set-peppymeter-blue.sh`

**Fixes:**
1. Sets `meter = blue` in `/etc/peppymeter/config.txt`
2. Disables random meter switching
3. Restarts PeppyMeter if running

---

## 🔄 Audio Chain Scenarios

### Scenario 1: PeppyMeter ON + CamillaDSP ON
```
MPD → _audioout → camilladsp → peppy → _peppyout → plughw:0,0 → AMP100
```
**Configuration:**
- `_audioout.conf`: `slave.pcm "camilladsp"`
- CamillaDSP playback: `device: "peppy"`
- `_peppyout.conf`: `slave.pcm "plughw:0,0"`
- MPD mixer_type: `"null"` (CamillaDSP handles volume)

### Scenario 2: PeppyMeter ON + CamillaDSP OFF
```
MPD → _audioout → peppy → _peppyout → plughw:0,0 → AMP100
```
**Configuration:**
- `_audioout.conf`: `slave.pcm "peppy"`
- `_peppyout.conf`: `slave.pcm "plughw:0,0"`
- MPD mixer_type: `"hardware"` or `"software"`

### Scenario 3: PeppyMeter OFF + CamillaDSP ON
```
MPD → _audioout → camilladsp → plughw:0,0 → AMP100
```
**Configuration:**
- `_audioout.conf`: `slave.pcm "camilladsp"`
- CamillaDSP playback: `device: "plughw:0,0"`
- MPD mixer_type: `"null"`

### Scenario 4: Both OFF (Direct)
```
MPD → _audioout → plughw:0,0 → AMP100
```
**Configuration:**
- `_audioout.conf`: `slave.pcm "plughw:0,0"`
- MPD mixer_type: `"hardware"` or `"software"`

---

## 📝 Configuration Update Functions

### `updAudioOutAndBtOutConfs($cardNum, $outputMode)`
**Purpose:** Updates `_audioout.conf` routing

**Called from:**
- `updMpdConf()` - When MPD config is updated
- `setAudioOut()` - When audio output changes
- `changeMPDMixer()` - When mixer type changes

### `updPeppyConfs($cardNum, $outputMode)`
**Purpose:** Updates `_peppyout.conf` routing

**Called from:**
- `updMpdConf()` - When MPD config is updated
- `setAudioOut()` - When audio output changes

### `setPlaybackDevice($cardNum, $outputMode)`
**Purpose:** Sets CamillaDSP playback device in YAML config

**Called from:**
- `updDspAndBtInConfs()` - When DSP configs are updated

---

## 🚨 Common Issues & Fixes

### Issue: No Audio Output
**Causes:**
1. AMP100 not detected (check `/proc/asound/cards`)
2. Wrong card number in database
3. `_audioout.conf` points to wrong device
4. MPD not running
5. Volume muted or too low

**Fix:** Run `fix-audio-chain.sh`

### Issue: PeppyMeter Shows No Activity
**Causes:**
1. PeppyMeter not running (`systemctl status peppymeter`)
2. FIFO pipe not created (`/tmp/peppymeter`)
3. MPD not outputting to `_audioout`
4. `_audioout.conf` not routing to `peppy`

**Fix:** Check PeppyMeter service and ALSA routing

### Issue: CamillaDSP Filters Not Applied
**Causes:**
1. CamillaDSP not running (`systemctl status camilladsp`)
2. Config file not selected in moOde
3. Config file missing from `/usr/share/camilladsp/configs/`
4. Playback device misconfigured

**Fix:** Check CamillaDSP service and config file

### Issue: Wrong Meter Skin
**Causes:**
1. `meter = blue` not set in `/etc/peppymeter/config.txt`
2. Random meter switching enabled

**Fix:** Run `set-peppymeter-blue.sh`

---

## 🔍 Verification Commands

### Check Audio Chain
```bash
# 1. Check AMP100 detection
cat /proc/asound/cards

# 2. Check ALSA routing
cat /etc/alsa/conf.d/_audioout.conf
cat /etc/alsa/conf.d/_peppyout.conf

# 3. Check MPD config
grep "device\|mixer_type" /var/lib/mpd/mpd.conf

# 4. Check moOde database
sqlite3 /var/local/www/db/moode-sqlite3.db \
  "SELECT param, value FROM cfg_system WHERE param IN ('cardnum', 'i2sdevice', 'peppy_display', 'camilladsp');"

# 5. Check PeppyMeter config
grep "meter\|random" /etc/peppymeter/config.txt

# 6. Check CamillaDSP config
cat /usr/share/camilladsp/working_config.yml | grep -A 5 "playback"

# 7. Check services
systemctl status mpd
systemctl status peppymeter
systemctl status camilladsp
```

### Test Audio Output
```bash
# Direct hardware test
speaker-test -c 2 -t sine -f 1000 -D plughw:0,0

# Test via _audioout
speaker-test -c 2 -t sine -f 1000 -D _audioout
```

---

## 📦 Deployment

### Files to Deploy

**Scripts:**
- `scripts/audio/fix-audio-chain.sh` → `/usr/local/bin/`
- `scripts/audio/validate-audio-chain.sh` → `/usr/local/bin/`
- `scripts/wizard/set-peppymeter-blue.sh` → `/usr/local/bin/`

**Services:**
- `moode-source/lib/systemd/system/fix-audio-chain.service` → `/lib/systemd/system/`
- `moode-source/lib/systemd/system/set-peppymeter-blue.service` → `/lib/systemd/system/`

**ALSA Configs:**
- `moode-source/etc/alsa/conf.d/_audioout.conf` → `/etc/alsa/conf.d/`
- `moode-source/etc/alsa/conf.d/_peppyout.conf` → `/etc/alsa/conf.d/`

### Deployment Method

**Via INSTALL_FIXES_AFTER_FLASH.sh:**
- All scripts and services automatically installed
- Configurations applied on boot

**Manual Deployment:**
- Copy scripts to `/usr/local/bin/`
- Copy services to `/lib/systemd/system/`
- Enable services: `systemctl enable fix-audio-chain.service`
- Run scripts manually or let services run on boot

---

## ✅ Summary

**Complete Audio Chain:**
1. **MPD** outputs to `_audioout` ALSA device
2. **`_audioout.conf`** routes based on enabled features:
   - CamillaDSP ON → `camilladsp`
   - PeppyMeter ON → `peppy`
   - Both OFF → `plughw:0,0`
3. **CamillaDSP** (if ON) processes audio, outputs to:
   - PeppyMeter ON → `peppy`
   - PeppyMeter OFF → `plughw:0,0`
4. **PeppyMeter** (if ON) displays VU meters, outputs to `_peppyout`
5. **`_peppyout.conf`** routes to `plughw:0,0`
6. **Hardware** `plughw:0,0` = HiFiBerry AMP100

**Perfect Configuration:**
- Boot: AMP100 overlay enabled, onboard audio disabled
- Database: Correct card number, device settings
- ALSA: Correct routing based on enabled features
- PeppyMeter: Blue skin, no random switching
- CamillaDSP: Correct playback device, filters configured
- MPD: Correct mixer type, device routing

**Safety:**
- Validation scripts check all components
- Fix scripts ensure correct configuration
- Services run on boot to maintain configuration
- Volume safety (unmute, set safe level)

---

**This document contains the complete, precise audio chain configuration for Ghetto Blaster system.**
