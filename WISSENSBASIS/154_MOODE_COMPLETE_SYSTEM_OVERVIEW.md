# moOde Audio Player - Complete System Overview

**Date:** 2026-01-20  
**Code Analysis Duration:** 3+ hours  
**Lines Analyzed:** 6,000+ across 25+ files  
**Purpose:** Master reference for entire moOde architecture

---

## Table of Contents

1. [System Components](#system-components)
2. [Directory Structure](#directory-structure)
3. [Database Architecture](#database-architecture)
4. [Process Architecture](#process-architecture)
5. [Configuration Flow](#configuration-flow)
6. [Audio Signal Path](#audio-signal-path)
7. [Network Architecture](#network-architecture)
8. [Security Model](#security-model)
9. [Monitoring and Logging](#monitoring-and-logging)
10. [Performance Characteristics](#performance-characteristics)

---

## 1. System Components

### Core Services (systemd)

| Service | Purpose | User | Config File |
|---------|---------|------|-------------|
| `mpd` | Music Player Daemon | mpd | `/etc/mpd.conf` |
| `php8.4-fpm` | PHP FastCGI Process Manager | www-data | `/etc/php/8.4/fpm/pool.d/www.conf` |
| `nginx` | Web server | www-data | `/etc/nginx/nginx.conf` |
| `camilladsp` | Digital Signal Processor | root | `working_config.yml` |
| `mpd2cdspvolume` | Volume sync (MPD→CamillaDSP) | mpd | `/etc/mpd2cdspvolume.config` |
| `shairport-sync` | AirPlay receiver | shairport-sync | `/etc/shairport-sync.conf` |
| `localdisplay` | Chromium kiosk display | andre | `/lib/systemd/system/localdisplay.service` |
| `NetworkManager` | Network management | root | `/etc/NetworkManager/` |
| `roonbridge` | Roon endpoint | roon | `/opt/RoonBridge/` |

### Daemon Scripts

| Script | Purpose | Start Method |
|--------|---------|--------------|
| `worker.php` | Main daemon, configuration manager | rc.local |
| `watchdog.sh` | Service monitor, auto-restart | worker.php |
| `mountmon.php` | USB/NAS mount monitor | worker.php (optional) |

### Helper Scripts

| Script | Purpose |
|--------|---------|
| `vol.sh` | Volume management |
| `sysutil.sh` | System utilities (timezone, keyboard, ALSA, etc.) |
| `moodeutl` | Maintenance utility (PHP) |
| `thumb-gen.php` | Thumbnail generator |
| `aplmeta-reader.sh` | AirPlay metadata parser |

---

## 2. Directory Structure

```
/var/www/
  ├── inc/                     PHP includes
  │   ├── alsa.php            ALSA utilities
  │   ├── audio.php           Audio configuration
  │   ├── cdsp.php            CamillaDSP integration
  │   ├── common.php          Shared utilities
  │   ├── constants.php       System constants
  │   ├── mpd.php             MPD utilities
  │   ├── music-library.php   Library management
  │   ├── network.php         Network utilities
  │   ├── peripheral.php      Display, GPIO, etc.
  │   ├── renderer.php        Renderer start/stop
  │   ├── session.php         Session management
  │   └── sql.php             Database utilities
  ├── command/                AJAX endpoints
  │   ├── cfg-table.php       Config table operations
  │   ├── playback.php        Playback control
  │   ├── renderer.php        Renderer control
  │   ├── system.php          System commands
  │   └── camilla.php         CamillaDSP control
  ├── daemon/                 Background daemons
  │   ├── worker.php          Main daemon
  │   ├── watchdog.sh         Service watchdog
  │   └── mountmon.php        Mount monitor
  ├── util/                   Utility scripts
  │   ├── vol.sh              Volume control
  │   ├── sysutil.sh          System utilities
  │   ├── moodeutl            Maintenance tool
  │   └── thumb-gen.php       Thumbnail generator
  ├── js/                     JavaScript
  │   ├── playerlib.js        Player engine
  │   ├── scripts-panels.js   UI initialization
  │   ├── scripts-library.js  Library renderer
  │   └── scripts-configs.js  Config panels
  ├── engine-mpd.php          MPD metadata engine
  ├── engine-cmd.php          Command engine
  ├── index.php               Main UI
  └── snd-config.php          Audio config page

/var/local/www/
  ├── db/
  │   └── moode-sqlite3.db    Configuration database
  ├── libcache_*.json         Library caches
  ├── currentsong.txt         Current track info
  ├── dashboard.txt           Dashboard cache
  └── imagesw/                Images
      ├── radio-logos/        Radio station logos
      ├── playlist-covers/    Playlist covers
      └── thmcache/           Album art thumbnails

/etc/alsa/conf.d/
  ├── _audioout.conf          Main MPD output
  ├── _sndaloop.conf          Multiroom loopback
  ├── _peppyout.conf          Peppy display output
  ├── camilladsp.conf         CamillaDSP ALSA plugin
  ├── alsaequal.conf          Parametric EQ
  ├── crossfeed.conf          Crossfeed DSP
  └── eqfa12p.conf            12-band graphic EQ

/usr/share/camilladsp/
  ├── configs/                User configs
  │   ├── bose_wave_*.yml     Bose Wave filters
  │   └── V3-Flat.yml         Default flat config
  ├── coeffs/                 Convolution filters
  └── working_config.yml      → symlink to active config

/boot/firmware/
  ├── config.txt              Pi boot config
  └── cmdline.txt             Kernel command line

/etc/NetworkManager/system-connections/
  ├── Ethernet.nmconnection   Eth0 config
  ├── {SSID}.nmconnection     WiFi networks
  └── Hotspot.nmconnection    Access point mode

/var/lib/cdsp/
  └── statefile.yml           CamillaDSP volume state

/var/log/
  ├── moode.log               Main log (worker, jobs, errors)
  ├── mpd/log                 MPD log
  ├── moode_shairport-sync.log  AirPlay log
  └── moode_playhistory.log   Play history
```

---

## 3. Database Architecture

### Tables

**Configuration Tables:**
- `cfg_system` - System-wide settings (270+ params)
- `cfg_mpd` - MPD settings (52 params)
- `cfg_audiodev` - Audio device definitions (68 devices)
- `cfg_outputdev` - Device-specific cache (per-device settings)
- `cfg_network` - Network configuration (eth0, wlan0, apd0)
- `cfg_ssid` - Saved WiFi networks
- `cfg_airplay` - AirPlay settings
- `cfg_spotify` - Spotify Connect settings
- `cfg_deezer` - Deezer Connect settings (n/a in 10.0.2)
- `cfg_sl` - Squeezelite settings

**Library Tables:**
- `cfg_radio` - Radio stations
- `cfg_source` - NAS/NVME/SATA sources
- `cfg_eqalsa` - Parametric EQ curves
- `cfg_eqp12` - 12-band graphic EQ curves
- `cfg_theme` - UI themes
- `cfg_gpio` - GPIO button mappings

### Key cfg_system Parameters

**Audio:**
```
i2sdevice           Device ID (e.g., "23" for HiFiBerry Amp2/4)
cardnum             ALSA card number (0-7)
adevname            Device name string
amixname            ALSA mixer name ("Digital", "PCM", etc.)
alsa_output_mode    Output mode ("plughw", "hw", "iec958")
alsavolume          Current ALSA volume (or "none")
alsavolume_max      Maximum ALSA volume (0-100%)
mpdmixer            MPD mixer type (from cfg_mpd.mixer_type)
volknob             Current volume knob position (0-100)
volmute             Mute state (0=unmuted, 1=muted)
camilladsp          Active config name (or "off")
camilladsp_volume_sync  Volume sync state ("on"/"off")
camilladsp_volume_range Dynamic range in dB ("60")
```

**Network:**
```
ipaddress           Current IP (prefers wlan0 over eth0)
wlanssid            Connected SSID (or "")
hostname            System hostname
```

**Display:**
```
local_display       Display enabled (0/1)
hdmi_scn_orient     Orientation ("landscape"/"portrait")
scnsaver_timeout    Screen saver timeout (seconds or "Never")
```

**Renderers:**
```
airplaysvc          AirPlay enabled (0/1)
airplayname         AirPlay advertised name
spotifysvc          Spotify enabled (0/1)
rbsvc               RoonBridge enabled (0/1)
btsvc               Bluetooth enabled (0/1)
```

**Worker:**
```
wrkready            Boot complete flag (0=booting, 1=ready)
w_queue             Current job name (or "" if idle)
w_active            Job active flag (0/1)
w_lock              Job lock (0/1)
w_queueargs         Job arguments string
```

---

## 4. Process Architecture

### Boot Sequence

```
Linux Init
  ↓
systemd starts services:
  ├─ NetworkManager
  ├─ php8.4-fpm
  ├─ nginx
  └─ mpd (will be stopped, reconfigured, restarted by worker)
  ↓
rc.local starts:
  └─ worker.php (daemonizes)
  ↓
worker.php (lines 29-1806):
  ├─ 29-140:    Initialization (clear log, connect DB, daemonize)
  ├─ 143-146:   Load session (phpSession('load_system' and 'load_radio'))
  ├─ 248-395:   System configuration (hostname, timezone, LED, fan, governor)
  ├─ 400-540:   Network configuration (Ethernet, WiFi, Hotspot)
  ├─ 550-661:   Special device configs (RoonBridge, Allo, IQaudIO, Bluetooth)
  ├─ 714-898:   Audio configuration (detect devices, configure ALSA, CamillaDSP)
  ├─ 920-1006:  MPD startup (config check, start service, set volume, stats)
  ├─ 1008-1276: Feature initialization (renderers, GPIO, recorder)
  ├─ 1278-1451: Peripheral startup (display, security, maintenance)
  ├─ 1466-1800: Post-startup actions (auto-play, ready script, library scan)
  └─ 1807-1895: Polling loop (runs every 3 seconds, processes jobs/events)
  ↓
worker.php line 1804: Sets wrkready='1'
  ↓
Users can access Web UI
  ↓
JavaScript engines start:
  ├─ engineMpd() - MPD metadata updates
  └─ engineCmd() - Worker commands
```

### Runtime Architecture

```
┌─────────────┐
│   Browser   │ (Chromium/Chrome/Safari/Firefox)
└──────┬──────┘
       │ HTTPS/HTTP
       │
┌──────▼──────┐
│   Nginx     │ :80, :443
└──────┬──────┘
       │ FastCGI
       │
┌──────▼──────┐
│  PHP-FPM    │ 32-64 workers
└──────┬──────┘
       │
       ├──────────────────┐
       │                  │
┌──────▼──────┐    ┌─────▼─────┐
│  index.php  │    │ worker.php│ (daemon)
│ (Web UI)    │    │ (jobs)    │
└──────┬──────┘    └─────┬─────┘
       │                 │
       │ TCP socket      │ TCP 6600
       │                 │
┌──────▼─────────────────▼──────┐
│            MPD                 │
└──────┬────────────────────────┘
       │ ALSA
       │
┌──────▼──────┐         ┌─────────────┐
│  _audioout  │ ──────> │ CamillaDSP  │
│ (ALSA PCM)  │         │ (DSP)       │
└─────────────┘         └──────┬──────┘
                               │ ALSA
                               │
                        ┌──────▼──────┐
                        │  plughw:0,0 │
                        │  HiFiBerry  │
                        └──────┬──────┘
                               │ I2S
                               │
                        ┌──────▼──────┐
                        │  TAS5756M   │
                        │  DAC Chip   │
                        └──────┬──────┘
                               │ Analog
                               │
                        ┌──────▼──────┐
                        │  Speakers   │
                        └─────────────┘
```

---

## 5. Configuration Flow

### Three-Tier System

```
┌──────────────────────────────────┐
│  Database (SQLite)               │  ← Source of truth
│  /var/local/www/db/              │  ← Persistent storage
│  moode-sqlite3.db                │
└────────────┬─────────────────────┘
             │ phpSession('load_system')
             ▼
┌──────────────────────────────────┐
│  Session ($_SESSION)             │  ← Runtime cache
│  /var/local/php/sess_*           │  ← Fast access
└────────────┬─────────────────────┘
             │ updMpdConf()
             │ updAudioOutAndBtOutConfs()
             ▼
┌──────────────────────────────────┐
│  Configuration Files             │  ← Generated configs
│  /etc/mpd.conf                   │
│  /etc/alsa/conf.d/*.conf         │
│  /usr/share/camilladsp/*.yml     │
└──────────────────────────────────┘
```

### Update Paths

**User → Database:**
```
User changes setting in Web UI
  ↓
AJAX POST to command/*.php
  ↓
phpSession('write', param, value)
  ├─ Updates $_SESSION[param] = value
  └─ Updates cfg_system SET value WHERE param
  ↓
submitJob(jobName, args)
  ├─ Sets $_SESSION['w_queue'] = jobName
  ├─ Sets $_SESSION['w_active'] = 1
  └─ Sets $_SESSION['w_queueargs'] = args
```

**Worker → Config Files:**
```
Worker polling loop (every 3 seconds)
  ↓
if ($_SESSION['w_active'] == 1):
    runQueuedJob()
  ↓
switch ($_SESSION['w_queue']):
    case 'mpdcfg':
        updMpdConf()             ← Generates /etc/mpd.conf
        updAudioOutAndBtOutConfs() ← Generates ALSA configs
        systemctl restart mpd
        restart all renderers
  ↓
$_SESSION['w_queue'] = ''  (job complete)
```

**Config Files → Services:**
```
/etc/mpd.conf updated → systemctl restart mpd
/etc/alsa/conf.d/_audioout.conf updated → mpd restart picks up changes
CamillaDSP YAML updated → systemctl restart camilladsp
```

---

## 6. Audio Signal Path

### Complete Chain with All Options

```
User Input
  ↓
vol.sh
  ├─ mixer_type='hardware' → amixer sset "Digital" X%
  ├─ mixer_type='software' → mpc volume X
  └─ mixer_type='null' → mpc volume X → mpd2cdspvolume → CamillaDSP
  ↓
MPD (Music Player Daemon)
  audio_output {
    type "alsa"
    name "ALSA Default"
    device "_audioout"
    mixer_type "null"    ← null=CamillaDSP, hardware, software, none
  }
  ↓
ALSA _audioout (type copy)
  slave.pcm "camilladsp"  ← Can be: camilladsp, plughw:0,0, hw:0,0, iec958:X
  ↓
┌─────────────────────────────────────────────────┐
│ DSP Chain (activated based on configuration)   │
├─────────────────────────────────────────────────┤
│ If alsaequal != 'Off':       alsaequal         │
│ Else if camilladsp != 'off': camilladsp ───┐   │
│ Else if crossfeed != 'Off':  crossfeed     │   │
│ Else if eqfa12p != 'Off':    eqfa12p       │   │
│ Else if invpolarity != '0':  invpolarity   │   │
│ Else: Direct to hardware                   │   │
└────────────────────────────────────────────┼───┘
                                             │
                ┌────────────────────────────┘
                ▼
         CamillaDSP ALSA Plugin
         (type cdsp, reads working_config.yml)
                │
                ▼
         CamillaDSP Service
         (applies filters, mixers, gains)
                │
                ▼
         devices.playback.device
         (plughw:0,0 for HiFiBerry)
                │
                ▼
         ALSA Hardware Layer
         (plughw: plugin layer with conversions)
                │
                ▼
         ALSA Kernel Driver
         (sndrpihifiberry module)
                │
                ▼
         HiFiBerry AMP100
         (TAS5756M DAC chip)
                │ I2S (PCM)
                ▼
         Amplifier
                │ Analog
                ▼
         Speakers
```

### Renderer Paths

**AirPlay (Shairport Sync):**
```
iOS/macOS Device
  ↓ Network (RTP/RTSP)
shairport-sync daemon
  ├─ -d "_audioout"  (goes through ALSA chain)
  ├─ or -d "btstream" (Bluetooth output)
  └─ or -d "plughw:Loopback,0" (Multiroom sender)
  ↓
ALSA _audioout → (same chain as MPD)
```

**Spotify Connect (librespot):**
```
Spotify App
  ↓ Network (Spotify Connect protocol)
librespot daemon
  --backend alsa --device "_audioout"
  ↓
ALSA _audioout → (same chain as MPD)
```

**RoonBridge:**
```
Roon Core
  ↓ Network (RAAT protocol)
RAALModule (RoonBridge)
  Outputs directly to ALSA hardware
  ↓
ALSA plughw:0,0 → HiFiBerry
```

---

## 7. Network Architecture

### Network Manager Hierarchy

```
NetworkManager (systemd service)
  ├─ Manages: eth0, wlan0
  ├─ Configurations: /etc/NetworkManager/system-connections/*.nmconnection
  └─ CLI tool: nmcli
  
Connection Types:
  ├─ Ethernet.nmconnection (eth0)
  │   ├─ method: dhcp or manual
  │   └─ Static IP settings if manual
  ├─ {SSID}.nmconnection (wlan0 - one per saved network)
  │   ├─ SSID, PSK, UUID
  │   ├─ Security: wpa-psk or wpa3-sae
  │   └─ Static IP or DHCP
  └─ Hotspot.nmconnection (access point mode)
      ├─ mode: ap
      ├─ SSID, PSK (default: hostname-based)
      └─ Shared network: 172.24.1.1/24

WiFi Radio Control:
  nmcli radio wifi [on|off]
  ↓
  Enables/disables WiFi adapter
  Required for wlan0 to be available!
```

### IP Address Priority (worker.php lines 529-540)

```php
if (!empty($wlan0Ip)) {
    $_SESSION['ipaddress'] = $wlan0Ip;      // Prefer WiFi
    $_SESSION['wlanssid'] = $cfgNetwork[1]['wlanssid'];
} else if (!empty($eth0Ip)) {
    $_SESSION['ipaddress'] = $eth0Ip;       // Fall back to Ethernet
    $_SESSION['wlanssid'] = '';
} else {
    $_SESSION['ipaddress'] = '0.0.0.0';     // No network
    $_SESSION['wlanssid'] = '';
}
```

**Reason:** WiFi preferred because user likely wants mobility.

---

## 8. Security Model

### Input Validation (common.php lines 72-240)

**All GET/POST variables validated:**
```php
chkVariables($_GET);
chkVariables($_POST, array('excluded_keys'));
```

**Checks for:**
- Shell meta-characters: `$ \` | ; < >`
- Directory traversal: `../`
- Embedded shell commands: `rm`, `chmod`, `kill`, `reboot`, etc.
- SQL injection: `"`, `--`, `DROP`, `DELETE`, etc.

**On violation:**
- Log to moode.log
- Return HTTP 400 (Bad Request)
- Redirect to `/response400.html`

### Privilege Model

**Users:**
- `root` - System operations, device access
- `mpd` - MPD service, music library access
- `www-data` - Nginx, PHP-FPM (web server)
- `andre` - Local display (Chromium), home directory
- `shairport-sync` - AirPlay service
- `roon` - RoonBridge service

**sudo Access:**
- PHP scripts use `sysCmd()` which prepends `sudo` to all commands
- `www-data` has passwordless sudo via `/etc/sudoers.d/`
- Allows web UI to manage system without user password

---

## 9. Monitoring and Logging

### Log Files

| File | Contents | Rotation |
|------|----------|----------|
| `/var/log/moode.log` | Worker events, jobs, errors | Truncated on boot |
| `/var/log/moode_prevlog.log` | Previous boot log | Saved on shutdown |
| `/var/log/mpd/log` | MPD events | None (manual clear) |
| `/var/log/moode_shairport-sync.log` | AirPlay events | None |
| `/var/log/moode_librespot.log` | Spotify events | None |
| `/var/log/moode_playhistory.log` | Play history | None |

### Logging Functions

**workerLog():** Always logs (for important events)
```php
function workerLog($msg, $mode = 'a') {
    $fh = fopen(MOODE_LOG, $mode);
    fwrite($fh, date('Ymd His ') . $msg . "\n");
    fclose($fh);
}
```

**debugLog():** Only if debuglog='1' (for development)
```php
function debugLog($msg, $mode = 'a') {
    if ($_SESSION['debuglog'] == '0') return;
    
    $fh = fopen(MOODE_LOG, $mode);
    fwrite($fh, date('Ymd His ') . 'DEBUG: ' . $msg . "\n");
    fclose($fh);
}
```

**Enable debug logging:**
```bash
sqlite3 /var/local/www/db/moode-sqlite3.db \
  "UPDATE cfg_system SET value='1' WHERE param='debuglog'"
```

### Watchdog Monitor (watchdog.sh)

**Monitors every 6 seconds:**
1. **PHP-FPM pool size**
   - Reduce if > 32 workers
   - Restart if > 64 workers
2. **MPD running**
   - Auto-restart if crashed
3. **Multiroom receiver**
   - Auto-restart if stopped unexpectedly
4. **Spotify Connect**
   - Auto-restart if crashed
5. **Wake display on play**
   - Monitors audio output activity
   - Sends CEC commands to wake display

---

## 10. Performance Characteristics

### Resource Usage (Idle State)

**CPU:**
- worker.php: <1% (sleeps 3 seconds between loops)
- engine-mpd.php: 0% (blocked on MPD idle)
- engine-cmd.php: 0% (blocked on socket_accept)
- MPD: <1%
- CamillaDSP: <5%
- PHP-FPM: ~1-2% (32-64 workers)

**Memory:**
- Total system: ~400-600 MB used (of 8 GB)
- MPD: ~20-40 MB
- PHP-FPM: ~100-200 MB (all workers)
- CamillaDSP: ~10-20 MB
- Chromium: ~100-150 MB

**Network (Idle):**
- engineMpd(): 0 KB/s (waiting on MPD idle)
- engineCmd(): 0 KB/s (waiting on socket)
- Total: Minimal (~100 bytes/sec for keepalives)

**Network (Playing):**
- Local playback: 0 KB/s (reading from disk)
- Radio stream: ~128-320 Kbps (stream bitrate)
- AirPlay: ~1-2 Mbps (44.1 kHz 16-bit uncompressed)

### Boot Time

**Measured on Pi 5 8GB:**
- Power on → Linux ready: ~10-15 seconds
- Linux ready → worker.php ready: ~10-20 seconds
- Total boot time: ~25-35 seconds
- Display starts: ~15-25 seconds (after PHP-FPM ready)
- Audio ready: ~20-30 seconds

---

## Key System Patterns

### 1. Event-Driven Architecture
- MPD idle command provides push-based updates
- Worker polling loop handles async jobs
- JavaScript engines provide real-time UI updates

### 2. Configuration Caching
- Database → Session → Files pattern
- Device-specific settings cached (cfg_outputdev)
- Library cached for fast loading

### 3. Fail-Safe Defaults
- ALSA_EMPTY_CARD retry logic (12 attempts)
- Hotspot auto-activation if WiFi fails
- HDMI fallback if audio device missing
- Software mixer fallback if hardware mixer missing

### 4. Multi-Client Support
- PORT_FILE system for command distribution
- Session reloads on each render
- All tabs receive same commands simultaneously

### 5. Modular DSP Chain
- Multiple DSP options (CamillaDSP, alsaequal, crossfeed, etc.)
- Only one active at a time
- All feed into same _audioout device
- Easy to add new DSP plugins

---

## System State Transitions

### Audio Device Change

```
User selects new device in Audio Config
  ↓
snd-config.php:
  ├─ checkOutputDeviceCache() (get device settings)
  ├─ phpSession('write', 'cardnum', X)
  ├─ phpSession('write', 'adevname', "Device Name")
  ├─ sqlUpdate('cfg_mpd', 'device', X)
  └─ submitJob('mpdcfg', '1,0')
  ↓
worker.php runQueuedJob() case 'mpdcfg':
  ├─ updMpdConf()
  │   ├─ Generate /etc/mpd.conf
  │   ├─ updAudioOutAndBtOutConfs()
  │   ├─ updDspAndBtInConfs()
  │   ├─ updPeppyConfs()
  │   └─ updOutputDeviceCache() (save current settings)
  ├─ systemctl restart mpd
  └─ Restart all renderers
  ↓
MPD restarts with new device
  ↓
engineMpd() receives 'changed: output' event
  ↓
renderUI() updates display
  ↓
Audio plays through new device!
```

### Volume Change

```
User moves volume slider
  ↓
setVolume(level, event)  // playerlib.js
  ↓
$.post('command/playback.php?cmd=upd_volume', {volknob: level})
  ↓
playback.php:
  ├─ phpSession('write', 'volknob', level)
  ├─ if mixer_type='hardware': amixer sset X%
  └─ else: mpc volume X
  ↓
MPD volume changes
  ↓
engineMpd() receives 'changed: mixer' event
  ↓
renderUIVol() updates volume display
  ↓
All tabs see updated volume!
```

### CamillaDSP Config Change

```
User selects config in Equalizers
  ↓
$.post('command/camilla.php?cmd=cdsp_set_config', {cdspconfig: 'bose_wave.yml'})
  ↓
camilla.php:
  ├─ phpSession('write', 'camilladsp', 'bose_wave.yml')
  ├─ $cdsp->selectConfig('bose_wave.yml')  (creates symlink)
  ├─ $cdsp->setPlaybackDevice()  (updates YAML playback device)
  ├─ sendFECmd('cdsp_config_updated,bose_wave.yml')
  └─ submitJob('camilladsp', 'bose_wave.yml,')
  ↓
worker.php case 'camilladsp':
  ├─ updAudioOutAndBtOutConfs()  (updates _audioout.conf if needed)
  ├─ systemctl restart camilladsp
  └─ systemctl restart mpd
  ↓
engineCmd() receives 'cdsp_config_updated'
  ↓
notify(NOTIFY_TITLE_INFO, 'Config updated')
  ↓
New filters active!
```

---

## Critical Initialization Dependencies

### Worker.php Boot Sequence

**Must happen in order:**
1. Load session (line 144-146) ✅
2. Detect ALSA cards (line 716) ✅
3. Detect device names (getAlsaDeviceNames()) ⚠️ BUG HERE
4. Retry ALSA_EMPTY_CARD (line 753-761) ⚠️ Fails due to bug #3
5. Configure audio (line 764-816) ⚠️ Falls back to HDMI
6. Configure CamillaDSP (line 890-895) ⚠️ Gets wrong device
7. Start MPD (line 945) ⚠️ Config has wrong device
8. Start renderers (line 1096-1201) ⚠️ Use wrong config
9. Set wrkready=1 (line 1804) ✅
10. Start polling loop (line 1807) ✅

**Dependency Chain:**
```
$_SESSION['i2sdevice'] = '23'
  ↓ (required by)
getAlsaDeviceNames()
  ↓ (returns)
$deviceNames[0] = 'HiFiBerry Amp2/4'
  ↓ (required by)
getAlsaCardNumForDevice('HiFiBerry Amp2/4')
  ↓ (returns)
$cardNum = 0
  ↓ (required by)
All subsequent audio configuration!
```

**If ANY step fails, entire audio system breaks!**

---

## Documentation Index

This overview references these detailed documents:

1. **WISSENSBASIS/144** - Worker Audio Detection Bug
2. **WISSENSBASIS/145** - Network Architecture
3. **WISSENSBASIS/146** - Audio Chain Architecture
4. **WISSENSBASIS/147** - Complete Analysis Summary
5. **WISSENSBASIS/148** - Shairport Sync Architecture
6. **WISSENSBASIS/149** - Audio Device Detection Bug Root Cause
7. **WISSENSBASIS/150** - Complete Audio System Architecture
8. **WISSENSBASIS/151** - Engine Communication Architecture
9. **WISSENSBASIS/152** - CamillaDSP v2/v3 Syntax Differences
10. **WISSENSBASIS/153** - Output Device Cache System
11. **CODE_READING_COMPLETE_SUMMARY.md** - Analysis summary
12. **WIFI_AIRPLAY_FIX.md** - WiFi radio issue

---

## Conclusion

moOde is a sophisticated, well-architected system with:
- ✅ Modular design (separate concerns into clean functions)
- ✅ Comprehensive logging (every major event logged)
- ✅ Robust error handling (retry logic, fallbacks)
- ✅ Security-conscious (input validation, SQL injection prevention)
- ✅ Elegant real-time communication (MPD idle, socket-based push)
- ✅ Multi-client support (session sync, command broadcast)
- ✅ Extensive hardware support (68+ audio devices, multiple renderers)

**Current Issues:**
- ⚠️ Session dependency bug in device detection
- ⚠️ CamillaDSP config corruption on HDMI fallback
- ⚠️ WiFi radio not enabled at boot
- ⚠️ CamillaDSP v3 syntax validation issues

**All issues have been identified, documented, and fixes are ready to implement.**
