# moOde Complete Audio System Architecture - Deep Code Analysis

**Date:** 2026-01-20  
**Duration:** 2+ hours of systematic code reading  
**Purpose:** Complete understanding of moOde's audio stack from boot to playback

## Table of Contents
1. [Boot Sequence](#boot-sequence)
2. [Session Management](#session-management)
3. [Audio Device Detection](#audio-device-detection)
4. [ALSA Configuration Layer](#alsa-configuration-layer)
5. [MPD Configuration](#mpd-configuration)
6. [CamillaDSP Integration](#camilladsp-integration)
7. [Renderer System](#renderer-system)
8. [Job Queue System](#job-queue-system)
9. [Volume Management](#volume-management)
10. [Critical Bugs Identified](#critical-bugs-identified)

---

## 1. Boot Sequence

### worker.php Startup (lines 29-146)

```php
// Line 29: Clear moode.log
sysCmd('truncate ' . MOODE_LOG . ' --size 0');

// Line 30: Connect to database
$dbh = sqlConnect();

// Line 31: Set wrkready = 0 (boot in progress)
sqlQuery("UPDATE cfg_system SET value='0' WHERE param='wrkready'", $dbh);

// Lines 39-75: Daemonize worker.php process

// Lines 83-104: Wait for Linux startup (systemctl is-system-running)

// Lines 105-122: Check boot config.txt (disabled in our system)

// Lines 124-140: Cleanup boot folder, session files

// Lines 143-146: LOAD SESSION
phpSession('load_system');  // ← Loads ALL cfg_system into $_SESSION
phpSession('load_radio');   // ← Loads cfg_radio into $_SESSION
workerLog('worker: PHP session:   loaded');
```

**Critical Point:** Session is loaded at line 144, BEFORE any audio configuration code runs.

### Audio Configuration Section (lines 714-895)

```php
// Line 714-721: Get ALSA card IDs
$cards = getAlsaCardIDs();  // Reads /proc/asound/card*/id

// Line 745: Log currently configured device
workerLog('worker: Audio device:  ' . $_SESSION['cardnum'] . ':' . $_SESSION['adevname']);

// Lines 753-761: ALSA_EMPTY_CARD retry loop
for ($i = 0; $i < 12; $i++) {
    $actualCardNum = getAlsaCardNumForDevice($_SESSION['adevname']);
    if ($actualCardNum == ALSA_EMPTY_CARD) {
        workerLog('worker: ALSA card:     is empty, retry ' . ($i + 1));
        sleep(5);  // Wait 5 seconds
    } else {
        break;
    }
}

// Lines 764-784: Configure audio device
if ($actualCardNum == ALSA_EMPTY_CARD) {
    // Reconfigure to HDMI 1
    phpSession('write', 'adevname', PI_HDMI1);
    phpSession('write', 'cardnum', $hdmi1CardNum);
    phpSession('write', 'alsa_output_mode', 'iec958');
    updMpdConf();
    sysCmd('systemctl restart mpd');
}

// Lines 890-894: Configure CamillaDSP
$cdsp = new CamillaDsp($_SESSION['camilladsp'], $_SESSION['cardnum'], $_SESSION['camilladsp_quickconv']);
$cdsp->selectConfig($_SESSION['camilladsp']);
if ($_SESSION['cdsp_fix_playback'] == 'Yes') {
    $cdsp->setPlaybackDevice($_SESSION['cardnum'], $_SESSION['alsa_output_mode']);
}
```

---

## 2. Session Management

### phpSession() Function (session.php lines 45-132)

```php
function phpSession($cmd, $param = '', $value = '', $caller = '') {
    switch ($cmd) {
        case 'load_system':
            // Open session
            session_id($id);
            session_start();
            
            // Load cfg_system into session
            $rows = sqlRead('cfg_system', sqlConnect());
            foreach ($rows as $row) {
                if (!str_contains($row['param'], 'RESERVED_')) {
                    $_SESSION[$row['param']] = $row['value'];
                }
            }
            // Remove SQL-only vars
            unset($_SESSION['wrkready']);
            break;
            
        case 'load_radio':
            // Load cfg_radio into session
            $rows = sqlRead('cfg_radio', sqlConnect(), 'all');
            foreach ($rows as $row) {
                $_SESSION[$row['station']] = array(...);
            }
            break;
            
        case 'open':
            return session_start();
            break;
            
        case 'close':
            return session_write_close();
            break;
            
        case 'write':
            $_SESSION[$param] = $value;
            sqlUpdate('cfg_system', sqlConnect(), $param, $value);
            break;
    }
}
```

**Key Understanding:**
- `load_system` loads **ALL** `cfg_system` rows into `$_SESSION`
- This includes `i2sdevice`, `adevname`, `cardnum`, `alsa_output_mode`, etc.
- Session is the **runtime cache** of database values
- `phpSession('write')` updates **BOTH** session AND database

---

## 3. Audio Device Detection

### getAlsaDeviceNames() (alsa.php lines 121-177)

**Flow Chart:**
```
For each card 0-7:
  ├─ Get card ID from /proc/asound/card{i}/id
  ├─ Get aplay name from `aplay -l`
  ├─ If card ID is empty → deviceNames[i] = 'empty'
  ├─ If card ID is 'Loopback' → deviceNames[i] = 'Loopback'
  ├─ If card ID is 'Dummy' → deviceNames[i] = 'Dummy'
  └─ Otherwise:
      ├─ Format vc4hdmi0 if singleton
      ├─ Look up card ID in cfg_audiodev table
      ├─ If FOUND in table:
      │   └─ Use alt_name (e.g., "Pi HDMI 1")
      └─ If NOT FOUND in table:
          ├─ Check if USB device
          │   └─ Use aplay name
          └─ Otherwise (I2S device):
              ├─ Look up $_SESSION['i2sdevice'] in cfg_audiodev  ← BUG HERE!
              ├─ If FOUND: Use name from table
              └─ If NOT FOUND: Use aplay name
```

**BUG:** Line 159 depends on `$_SESSION['i2sdevice']` being set!

**When Session Not Initialized:**
```php
// Session has no 'i2sdevice' key
$result = sqlRead('cfg_audiodev', $dbh, $_SESSION['i2sdevice']);
// This queries with NULL or empty value
// Returns first matching row or wrong device!
```

**Evidence:**
```
# Test without session:
Session i2sdevice: NOT SET
Device names array:
    [0] => Allo Boss 2 DAC   ← WRONG! Should be "HiFiBerry Amp2/4"

# With session properly set:
Session i2sdevice: 23
Device names array:
    [0] => HiFiBerry Amp2/4  ← CORRECT!
```

### getAlsaCardNumForDevice() (alsa.php lines 180-196)

```php
function getAlsaCardNumForDevice($deviceName) {
    $deviceNames = getAlsaDeviceNames();  // ← Gets array
    
    if ($deviceName == TRX_SENDER_NAME) {
        $cardNum = getArrayIndex(ALSA_DUMMY_DEVICE, $deviceNames);
    } else {
        $cardNum = getArrayIndex($deviceName, $deviceNames);  // ← Search for match
    }
    
    return $cardNum;  // Returns 'empty' if not found
}
```

**The Bug Chain:**
1. `getAlsaDeviceNames()` returns wrong name ("Allo Boss 2 DAC")
2. Worker looks for "HiFiBerry Amp2/4" in array
3. Not found → returns `ALSA_EMPTY_CARD` (string "empty")
4. Worker retries 12 times (60 seconds total)
5. Still fails → switches to HDMI

---

## 4. ALSA Configuration Layer

### Configuration Files in `/etc/alsa/conf.d/`

| File | Purpose | Master Device |
|------|---------|---------------|
| `_audioout.conf` | Main MPD output | `camilladsp` or `plughw:0,0` |
| `_sndaloop.conf` | Loopback for Multiroom | Mirrors _audioout |
| `_peppyout.conf` | Peppy display output | plughw:X,0 or btstream |
| `camilladsp.conf` | CamillaDSP ALSA plugin | Points to working_config.yml |
| `alsaequal.conf` | Parametric EQ | plughw:X,0 |
| `crossfeed.conf` | Crossfeed DSP | plughw:X,0 |
| `eqfa12p.conf` | 12-band graphic EQ | plughw:X,0 |
| `invpolarity.conf` | Polarity inversion | plughw:X,0 or hw:X,0 |
| `btstream.conf` | Bluetooth output | Bluetooth device |

### _audioout.conf Structure

```
pcm._audioout {
    type copy
    slave.pcm "camilladsp"    ← Can be: camilladsp, plughw:0,0, hw:0,0, iec958:X, peppy, btstream
}
```

### updAudioOutAndBtOutConfs() (audio.php lines 208-288)

**Decision Logic:**
```php
if ($_SESSION['alsaequal'] != 'Off') {
    $alsaDevice = 'alsaequal';
} else if ($_SESSION['camilladsp'] != 'off') {
    $alsaDevice = 'camilladsp';          // ← Most common for our system
} else if ($_SESSION['crossfeed'] != 'Off') {
    $alsaDevice = 'crossfeed';
} else if ($_SESSION['eqfa12p'] != 'Off') {
    $alsaDevice = 'eqfa12p';
} else if ($_SESSION['invert_polarity'] != '0') {
    $alsaDevice = 'invpolarity';
} else {
    // No DSP active
    if ($_SESSION['peppy_display'] == '1') {
        $alsaDevice = 'peppy';
    } else if ($_SESSION['audioout'] == 'Bluetooth') {
        $alsaDevice = 'btstream';
    } else {
        // Direct to hardware
        $alsaDevice = $outputMode == 'iec958' ? getAlsaIEC958Device() : $outputMode . ':' . $cardNum . ',0';
    }
}

// Update _audioout.conf
sysCmd("sed -i 's/^slave.pcm.*/slave.pcm \"" . $alsaDevice .  "\"/' /etc/alsa/conf.d/_audioout.conf");
```

**Output Modes:**
- `plughw` (Default): ALSA plugin layer with conversions
- `hw` (Direct): Direct hardware access, no conversions
- `iec958` (IEC958): HDMI/SPDIF digital output

---

## 5. MPD Configuration

### updMpdConf() (mpd.php lines 17-244)

**Structure of generated `/etc/mpd.conf`:**

```
#########################################
# This file is managed by moOde
#########################################

# Basic settings from cfg_mpd table
music_directory "/var/lib/mpd/music"
playlist_directory "/var/lib/mpd/playlists"
...

# Decoder
decoder {
    plugin "ffmpeg"
    enabled "yes"
}

# Input cache (optional)
input_cache {
    size "128 MB"
}

# Resampler (SoX)
resampler {
    plugin "soxr"
    quality "very high"
    threads "0"
}

# =====================
# ALSA Default output
# =====================
audio_output {
    type "alsa"
    name "ALSA Default"
    device "_audioout"              ← Points to ALSA plugin
    mixer_type "null"               ← null=CamillaDSP, hardware, software, none
    mixer_control "Digital"         ← Only for mixer_type="hardware"
    mixer_device "hw:0"
    mixer_index "0"
    dop "no"
    stop_dsd_silence "no"
    thesycon_dsd_workaround "no"
    close_on_pause "yes"
}

# ALSA Bluetooth output
audio_output {
    type "alsa"
    name "ALSA Bluetooth"
    device "_audioout"
    mixer_type "software"
}

# HTTP Server output
audio_output {
    type "httpd"
    name "HTTP Server"
    port "8000"
    encoder "lame"
    bitrate "320"
    tags "yes"
    always_on "yes"
    format "44100:16:2"
}
```

**Audio Chain Comment (line 181):**
```
MPD → {_audioout || DSP(MPD) → _audioout} → {{plughw || hw} || DSP(ALSA/Camilla) → {plughw || hw}} → audio device
```

**Translation:**
1. **MPD** outputs to `_audioout` ALSA device
2. **_audioout** can point to:
   - `camilladsp` → CamillaDSP ALSA plugin → `plughw:0,0` → HiFiBerry
   - `plughw:0,0` → directly to HiFiBerry
   - `iec958:X` → HDMI digital output
3. **CamillaDSP** (if active) processes audio and outputs to hardware device

### Lines 237-243: Configuration Update Cascade

```php
// Update ALSA and Bluetooth confs
updAudioOutAndBtOutConfs($cardNum, $_SESSION['alsa_output_mode']);
updDspAndBtInConfs($cardNum, $_SESSION['alsa_output_mode']);
updPeppyConfs($cardNum, $_SESSION['alsa_output_mode']);

// Update output device cache
updOutputDeviceCache($_SESSION['adevname']);
```

**Every MPD config update triggers:**
1. `_audioout.conf` update (slave.pcm)
2. `_sndaloop.conf` update (for Multiroom)
3. All DSP configs updated (alsaequal, crossfeed, eqfa12p, invpolarity)
4. CamillaDSP YAML updated (playback device)
5. Peppy config updated
6. Bluetooth config updated
7. Output device cache updated

---

## 6. CamillaDSP Integration

### CamillaDsp Class (cdsp.php)

**Key Properties:**
```php
private $ALSA_CDSP_CONFIG = '/etc/alsa/conf.d/camilladsp.conf';
private $CAMILLA_CONFIG_DIR = '/usr/share/camilladsp';
private $CAMILLA_EXE = '/usr/local/bin/camilladsp';
private $CAMILLAGUI_WORKING_CONGIG = '/usr/share/camilladsp/working_config.yml';
```

### setPlaybackDevice() (lines 55-110)

**Called from:**
- worker.php line 893 (during boot)
- audio.php line 319 (when DSP configs updated)

**What it does:**
```php
function setPlaybackDevice($cardNum, $outputMode = 'plughw') {
    if ($this->configFile != 'off' && $this->configFile != 'custom') {
        // Determine ALSA device
        if ($_SESSION['peppy_display'] == '1') {
            $alsaDevice = 'peppy';
        } else if ($_SESSION['audioout'] == 'Bluetooth') {
            $alsaDevice = 'btstream';
        } else {
            // Line 63: THE BUG - when outputMode='iec958' returns HDMI!
            $alsaDevice = $outputMode == 'iec958' ? getAlsaIEC958Device() : $outputMode . ':' . $cardNum . ',0';
        }
        
        // Detect supported formats
        $supportedFormats = $this->detectSupportedSoundFormats();
        $useFormat = count($supportedFormats) >= 1 ? $supportedFormats[0] : 'S32LE';
        
        // Read YAML
        $ymlCfg = yaml_parse_file($this->getCurrentConfigFileName());
        
        // Update devices section
        $ymlCfg['devices']['capture'] = [
            'type' => 'Stdin',
            'channels' => 2,
            'format' => $useFormat
        ];
        $ymlCfg['devices']['playback'] = [
            'type' => 'Alsa',
            'channels' => 2,
            'device' => $alsaDevice,  // ← Written here!
            'format' => $useFormat
        ];
        
        // Write YAML
        yaml_emit_file($this->getCurrentConfigFileName(), $ymlCfg);
    }
}
```

### CamillaDSP ALSA Plugin (camilladsp.conf)

```
pcm.camilladsp {
    type cdsp
    cpath "/usr/local/bin/camilladsp"
    config_out "/usr/share/camilladsp/working_config.yml"
    config_cdsp 1
    
    rates = [44100, 48000, 88200, 96000, 176400, 192000, 352800, 384000]
    
    cargs [
        -p "1234"           ← WebSocket port for GUI
        -a "0.0.0.0"        ← Listen on all interfaces
        -s "/var/lib/cdsp/statefile.yml"  ← Volume state
    ]
}
```

### working_config.yml Symlink

```bash
/usr/share/camilladsp/working_config.yml → configs/bose_wave_physics_optimized.yml
```

**Flow:**
1. User selects config in WebUI: "bose_wave_physics_optimized.yml"
2. `selectConfig()` creates symlink: `working_config.yml` → `configs/bose_wave_physics_optimized.yml`
3. ALSA plugin reads `working_config.yml`
4. CamillaDSP service started with `working_config.yml`

---

## 7. Renderer System

### Architecture (renderer.php)

**Supported Renderers:**
- **Bluetooth** (BlueALSA): `startBluetooth()`, `stopBluetooth()`
- **AirPlay** (Shairport Sync): `startAirPlay()`, `stopAirPlay()`
- **Spotify Connect** (librespot): `startSpotify()`, `stopSpotify()`
- **Deezer Connect** (pleezer): `startDeezer()`, `stopDeezer()`
- **UPnP** (upmpdcli): `startUPnP()`, `stopUPnP()`
- **Squeezelite** (LMS): `startSqueezeLite()`, `stopSqueezeLite()`
- **Plexamp**: `startPlexamp()`, `stopPlexamp()`
- **RoonBridge**: `startRoonBridge()`, `stopRoonBridge()`

### startAirPlay() (lines 55-97)

```php
function startAirPlay() {
    // Start precision time protocol
    sysCmd('systemctl start nqptp');
    
    // Determine output device
    $device = $_SESSION['audioout'] == 'Local' ? 
        ($_SESSION['multiroom_tx'] == 'On' ? 'plughw:Loopback,0' : '_audioout') : 
        'btstream';
    
    // Launch shairport-sync
    $cmd = '/usr/bin/shairport-sync ' . $logging .
        ' -a "' . $_SESSION['airplayname'] . '" ' .
        '-- -d ' . $device . ' > ' . $logFile . ' 2>&1 &';
    sysCmd($cmd);
    
    // Wait for metadata pipe
    for ($i = 0; $i < 3; $i++) {
        if (file_exists('/tmp/shairport-sync-metadata')) {
            break;
        }
        sleep(1);
    }
    
    // Start metadata reader
    sysCmd('/var/www/daemon/aplmeta-reader.sh > /dev/null 2>&1 &');
}
```

**Key Understanding:** 
- Multiroom TX uses `plughw:Loopback,0` to reduce glitches
- Standard mode uses `_audioout` (goes through our ALSA chain)
- Bluetooth output uses `btstream`

### stopAirPlay() (lines 98-151)

```php
function stopAirPlay() {
    // Kill metadata components (retry up to 3 times)
    // Kill shairport-sync process
    // Stop nqptp
    
    // Restore volume
    sysCmd('/var/www/util/vol.sh -restore');
    
    // Restart CamillaDSP volume sync if enabled
    if (CamillaDSP::isMPD2CamillaDSPVolSyncEnabled()) {
        sysCmd('systemctl restart mpd2cdspvolume');
    }
    
    // Update multiroom receivers
    if ($_SESSION['multiroom_tx'] == "On") {
        updReceiverVol('-restore');
    }
    
    // Update session state
    phpSession('write', 'aplactive', '0');
    sendFECmd('aplactive0');
}
```

---

## 8. Job Queue System

### submitJob() (common.php lines 536-560)

```php
function submitJob($jobName, $jobArgs = '', $title = '', $msg = '', $duration = NOTIFY_DURATION_DEFAULT) {
    if ($_SESSION['w_lock'] != 1 && $_SESSION['w_queue'] == '') {
        // For worker.php
        $_SESSION['w_queue'] = $jobName;
        $_SESSION['w_active'] = 1;
        $_SESSION['w_queueargs'] = $jobArgs;
        
        // For UI notification
        $_SESSION['notify']['title'] = $title;
        $_SESSION['notify']['msg'] = $msg;
        $_SESSION['notify']['duration'] = $duration;
        
        return true;
    } else {
        // Worker busy
        $_SESSION['notify']['msg'] = 'System is busy, try again';
        return false;
    }
}
```

### Worker Loop (worker.php lines 1807-1895)

```php
while (true) {
    usleep(WORKER_SLEEP);  // 3 seconds default
    
    phpSession('open');
    
    // Check various conditions (screen saver, renderer active, etc.)
    
    // Process queued job
    if ($_SESSION['w_active'] == 1 && $_SESSION['w_lock'] == 0) {
        runQueuedJob();
    }
    
    phpSession('close');
}
```

### runQueuedJob() (lines 2672-3844)

**Structure:**
```php
function runQueuedJob() {
    $_SESSION['w_lock'] = 1;  // Lock
    
    if ($_SESSION['w_queue'] != 'reset_screen_saver') {
        workerLog('worker: Job ' . $_SESSION['w_queue']);
    }
    
    switch ($_SESSION['w_queue']) {
        case 'mpdcfg':
            // Update MPD configuration
            updMpdConf();
            sysCmd('systemctl restart mpd');
            // Restart all renderers
            break;
            
        case 'camilladsp':
            $queueArgs = explode(',', $_SESSION['w_queueargs']);
            updAudioOutAndBtOutConfs($_SESSION['cardnum'], $_SESSION['alsa_output_mode']);
            if (!empty($queueArgs[1])) {
                // Change mixer type
                changeMPDMixer($mixerType);
                sysCmd('systemctl restart mpd2cdspvolume');
                sysCmd('systemctl restart mpd');
            }
            break;
            
        case 'i2sdevice':
            cfgI2SDevice();
            updMpdConf();
            break;
            
        case 'airplaysvc':
            stopAirPlay();
            if ($_SESSION['airplaysvc'] == 1) {
                startAirPlay();
            }
            break;
        
        // ... 60+ other job types
    }
    
    // Reset job queue (lines 3839-3843)
    $_SESSION['w_queue'] = '';
    $_SESSION['w_queueargs'] = '';
    $_SESSION['w_lock'] = 0;
    $_SESSION['w_active'] = 0;
}
```

---

## 9. Volume Management

### Three Volume Systems

#### 1. **ALSA Hardware Volume** (for I2S/USB devices)
```php
// Get volume
$result = sysCmd('amixer -c ' . $cardNum . ' sget "' . $mixerName . '"');

// Set volume
sysCmd('amixer -c ' . $cardNum . ' sset "' . $mixerName . '" ' . $level . '%');

// Set to 0dB (100%)
function setALSAVolTo0dB($alsaVolMax = '100') {
    sysCmd('/var/www/util/sysutil.sh set-alsavol "' . $_SESSION['amixname'] . '" ' . $alsaVolMax);
}
```

**Mixer Names:**
- HiFiBerry, most I2S: `Digital`
- HiFiBerry Amp+: `Channels`
- HiFiBerry DAC+ DSP: `DSPVolume`
- HiFiBerry DAC2 HD: `DAC`
- Allo Katana/Boss/Piano: `Master`
- Pi HDMI: `PCM`

#### 2. **MPD Software Volume**
```php
// MPD mixer_type options:
// - "software": MPD controls volume in software
// - "hardware": MPD controls ALSA mixer
// - "null": No volume control (used with CamillaDSP)
// - "none": Fixed 0dB output

// Set via mpc
sysCmd('mpc volume ' . $level);
```

#### 3. **CamillaDSP Volume** (when mixer_type="null")
```php
// Volume stored in statefile
static function getCDSPVol() {
    $result = sysCmd("cat /var/lib/cdsp/statefile.yml | grep 'volume' -A1 | grep -e '- ' | awk '/- /{print $2}'")[0];
    return (intval($result * 100) / 100);
}

// Calculate dB from 0-100%
static function calcMappedDbVol($volume, $dynamic_range) {
    $x = $volume / 100.0;
    $y = pow(10, $dynamic_range / 20);
    $a = 1/$y;
    $b = log($y);
    $y= $a * exp($b * ($x));
    if ($x < .1) {
        $y = $x * 10 * $a * exp(0.1 * $b);
    }
    if ($y == 0) {
        $y = 0.000001;
    }
    return 20 * log10($y);
}
```

**Volume Sync Service:** `mpd2cdspvolume`
- Monitors MPD volume changes
- Sends volume to CamillaDSP via WebSocket
- Configuration: `/etc/mpd2cdspvolume.config`
- Dynamic range setting: 60dB default

### Volume Restoration

**After renderer stops:**
```php
sysCmd('/var/www/util/vol.sh -restore');
```

**This script:**
1. Reads `volknob` from cfg_system
2. Sets MPD volume: `mpc volume $level`
3. If CamillaDSP active: sends volume to CamillaDSP

---

## 10. Critical Bugs Identified

### Bug #1: Session Initialization Order

**File:** `alsa.php::getAlsaDeviceNames()` line 159  
**Severity:** CRITICAL - causes ALSA_EMPTY_CARD detection failures

**Root Cause:**
```php
// Line 159: Depends on $_SESSION['i2sdevice'] being set
$result = sqlRead('cfg_audiodev', $dbh, $_SESSION['i2sdevice']);
```

**Problem:**
- Function can be called before session is fully initialized
- If `$_SESSION['i2sdevice']` is NULL/empty, sqlRead returns wrong device
- Results in incorrect device name mapping
- Leads to ALSA_EMPTY_CARD false positives

**Fix:**
```php
// Query database directly if session not initialized
if (!isset($_SESSION['i2sdevice']) || empty($_SESSION['i2sdevice'])) {
    $i2sDeviceId = sqlQuery("SELECT value FROM cfg_system WHERE param='i2sdevice'", $dbh);
    $i2sDevice = !empty($i2sDeviceId) ? $i2sDeviceId[0]['value'] : null;
    $result = $i2sDevice ? sqlRead('cfg_audiodev', $dbh, $i2sDevice) : true;
} else {
    $result = sqlRead('cfg_audiodev', $dbh, $_SESSION['i2sdevice']);
}
```

### Bug #2: CamillaDSP Config Corruption

**File:** `cdsp.php::setPlaybackDevice()` line 63  
**Severity:** HIGH - causes CamillaDSP to fail at boot

**Root Cause:**
- When `outputMode == 'iec958'` (HDMI mode), function returns HDMI device
- But this gets called AFTER worker.php switches to HDMI due to Bug #1
- CamillaDSP YAML gets HDMI device written to it
- CamillaDSP tries to open HDMI, fails
- Service stays inactive/dead
- `_audioout` → `camilladsp` device doesn't exist
- MPD can't open audio output

**Fix:**
- Prevent Bug #1 (so outputMode never becomes 'iec958' for HiFiBerry)
- OR: Add check to never use iec958 for I2S devices

### Bug #3: Worker.php HDMI Fallback Logic

**File:** `worker.php` lines 764-779  
**Severity:** HIGH - overwrites correct configuration

**Issue:**
- When ALSA_EMPTY_CARD detected, switches to HDMI
- But doesn't validate if HDMI exists
- Can result in `cardnum='empty'` even after switching
- Database gets corrupted with HDMI values

**Current Workaround:**
- `fix-audioout-cdsp.service` runs after boot
- Updates database back to HiFiBerry values
- But doesn't fix CamillaDSP YAML (requires our v2 fix)

---

## Summary

### Complete Failure Chain (Current System)

```
Boot starts
  ↓
worker.php line 144: phpSession('load_system')  ← Session SHOULD be initialized
  ↓
worker.php line 754: getAlsaCardNumForDevice($_SESSION['adevname'])
  ↓
alsa.php line 159: sqlRead('cfg_audiodev', $dbh, $_SESSION['i2sdevice'])
  ↓  ← BUG: If session variable not set, wrong device returned
getAlsaDeviceNames() returns "Allo Boss 2 DAC" instead of "HiFiBerry Amp2/4"
  ↓
getAlsaCardNumForDevice('HiFiBerry Amp2/4') → 'empty'
  ↓
worker.php retries 12 times (60 seconds)
  ↓
worker.php line 765: Switches to HDMI
  ↓
Database updated: adevname='Pi HDMI 1', alsa_output_mode='iec958'
  ↓
worker.php line 893: cdsp->setPlaybackDevice('empty', 'iec958')
  ↓
cdsp.php line 63: outputMode=='iec958' → returns HDMI device
  ↓
CamillaDSP YAML written with: device: default:vc4hdmi0
  ↓
CamillaDSP service tries to start → "Invalid config file"
  ↓
fix-audioout-cdsp.service (after 15 seconds):
  - Updates database back to HiFiBerry
  - Updates _audioout.conf to "camilladsp"
  - YAML still has HDMI device!
  ↓
MPD tries: _audioout → camilladsp → device doesn't exist
  ↓
ERROR: "Failed to open audio output: No such device"
```

### Root Cause

**THE SESSION IS ACTUALLY LOADED!** (worker.php line 144)

**BUT:** There's a timing/context issue where `getAlsaDeviceNames()` is called in a context where `$_SESSION['i2sdevice']` is not accessible, OR the `sqlRead()` with an empty/NULL parameter returns the wrong row from `cfg_audiodev`.

**The Real Fix:** Make `getAlsaDeviceNames()` session-independent by querying the database directly instead of relying on the session variable.

---

## Related Documentation

- `WISSENSBASIS/144_MOODE_WORKER_AUDIO_DETECTION_BUG.md` - Original ALSA_EMPTY_CARD bug analysis
- `WISSENSBASIS/146_MOODE_AUDIO_CHAIN_ARCHITECTURE.md` - Audio signal path
- `WISSENSBASIS/148_MOODE_SHAIRPORT_SYNC_ARCHITECTURE.md` - AirPlay integration
- `WISSENSBASIS/149_MOODE_AUDIO_DEVICE_DETECTION_BUG_ROOT_CAUSE.md` - Detailed bug analysis
