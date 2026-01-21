# moOde Shairport Sync (AirPlay) Architecture

**Date:** 2026-01-20  
**Purpose:** Complete understanding of moOde's AirPlay integration

## Overview

moOde integrates Shairport Sync as its AirPlay receiver, managing it through PHP functions and systemd services.

## Core Architecture

### 1. **Start Sequence** (`renderer.php::startAirPlay()` lines 55-97)

```php
function startAirPlay() {
    // 1. Start precision time protocol for AirPlay 2
    sysCmd('systemctl start nqptp');
    
    // 2. Determine output device
    $device = $_SESSION['audioout'] == 'Local' ? 
        ($_SESSION['multiroom_tx'] == 'On' ? 'plughw:Loopback,0' : '_audioout') : 
        'btstream';
    
    // 3. Launch shairport-sync
    $cmd = '/usr/bin/shairport-sync ' . $logging .
        ' -a "' . $_SESSION['airplayname'] . '" ' .
        '-- -d ' . $device . ' > ' . $logFile . ' 2>&1 &';
    
    // 4. Wait for metadata pipe
    // (retries up to 3 times, 1 second each)
    
    // 5. Start metadata reader
    $cmd = '/var/www/daemon/aplmeta-reader.sh > /dev/null 2>&1 &';
}
```

### 2. **Output Device Selection Logic**

| Condition | Output Device | Purpose |
|-----------|---------------|---------|
| Local + Multiroom TX Off | `_audioout` | Standard ALSA output (HiFiBerry) |
| Local + Multiroom TX On | `plughw:Loopback,0` | Uses Loopback to reduce glitches |
| Bluetooth streaming | `btstream` | Routes to Bluetooth |

**Key Finding:** `_audioout` is an ALSA device alias defined in `/etc/alsa/conf.d/_audioout.conf`

### 3. **Stop Sequence** (`renderer.php::stopAirPlay()` lines 98-151)

```php
function stopAirPlay() {
    // 1. Kill metadata components (retry up to 3 times)
    //    - aplmeta-reader.sh
    //    - shairport-sync-metadata-reader
    //    - aplmeta.py
    //    - cat process reading metadata pipe
    
    // 2. Kill shairport-sync process
    
    // 3. Stop nqptp
    
    // 4. Restore volume
    sysCmd('/var/www/util/vol.sh -restore');
    
    // 5. Restart CamillaDSP volume sync if enabled
    if (CamillaDSP::isMPD2CamillaDSPVolSyncEnabled()) {
        sysCmd('systemctl restart mpd2cdspvolume');
    }
    
    // 6. Update multiroom receivers
    
    // 7. Update session state
    phpSession('write', 'aplactive', '0');
    sendFECmd('aplactive0');
}
```

### 4. **Configuration Management** (`apl-config.php`)

**Database Table:** `cfg_airplay`  
**Config File:** `/etc/shairport-sync.conf`

**Configuration Flow:**
1. User changes settings in Web UI
2. PHP updates `cfg_airplay` database table
3. PHP uses `sed` to update `/etc/shairport-sync.conf`:
   ```php
   sysCmd("sed -i '/" . $key . ' =' . '/c\\' . 
       $key . ' = ' . $value . ";' /etc/shairport-sync.conf");
   ```
4. Submit `airplaysvc` job to restart service

**Available Settings:**
- **interpolation:** `basic` | `soxr` (SoX resampling)
- **output_format:** `S16` | `S24` | `S24_3LE` | `S24_3BE` | `S32`
- **output_rate:** `44100` | `88200` | `176400` | `352800` Hz
- **allow_session_interruption:** `yes` | `no`
- **disable_synchronization:** `yes` | `no`
- **session_timeout:** seconds
- **audio_backend_latency_offset_in_seconds:** offset
- **audio_backend_buffer_desired_length_in_seconds:** buffer size

### 5. **Network Discovery (Avahi/Bonjour)**

**Service Advertisement:**
- **Service Type:** `_raop._tcp` (AirPlay 1) or `_airplay._tcp` (AirPlay 2)
- **Name:** From `$_SESSION['airplayname']` (default: "Moode")
- **Interfaces:** Advertised on ALL active network interfaces (ethernet + WiFi)

**Verification Command:**
```bash
avahi-browse -a -t | grep -i airplay
```

**Example Output:**
```
+  wlan0 IPv4 88A29E2C8E55@Moode    AirTunes Remote Audio local
+   end0 IPv4 88A29E2C8E55@Moode    AirTunes Remote Audio local
+  wlan0 IPv4 Moode                 AirPlay Remote Video local
+   end0 IPv4 Moode                 AirPlay Remote Video local
```

### 6. **Metadata Handling**

**Metadata Pipe:** `/tmp/shairport-sync-metadata`

**Components:**
1. **Shairport Sync:** Writes metadata to pipe
2. **aplmeta-reader.sh:** Shell script that launches metadata reader
3. **aplmeta.py:** Python script that parses metadata
4. **moOde UI:** Displays metadata (artist, album, title, cover art)

**Cover Art:**
- **Cache Directory:** `/var/local/www/imagesw/airplay-covers`
- **Configured in:** `/etc/shairport-sync.conf` (`metadata.cover_art_cache_directory`)

### 7. **Worker Integration** (`daemon/worker.php`)

**Job: `airplaysvc`**
```php
case 'airplaysvc':
    if ($_SESSION['airplaysvc'] == '1') {
        startAirPlay();
        $aplactive = checkForAplActive();
        $_SESSION['aplactive'] = $aplactive;
        sendFECmd('aplactive' . $aplactive);
        workerLog('worker: AirPlay ' . ($aplactive == '1' ? 'started' : 'available'));
    } else {
        stopAirPlay();
        workerLog('worker: AirPlay stopped');
    }
    break;
```

### 8. **Key Learnings**

**WiFi Radio State:**
- NetworkManager WiFi radio must be **enabled** for AirPlay to work over WiFi
- Command: `nmcli radio wifi on`
- Without this, wlan0 shows "unavailable" and AirPlay only works on Ethernet

**Network Discovery:**
- AirPlay is advertised on **ALL active interfaces** (Ethernet + WiFi)
- Devices must be on the **SAME network** to discover the service
- If Pi has multiple IPs (e.g., 192.168.1.x on WiFi, 192.168.2.x on Ethernet):
  - iPhone on 192.168.1.x → sees WiFi AirPlay
  - Device on 192.168.2.x → sees Ethernet AirPlay

**Device Selection:**
- `_audioout` points to the configured audio device
- When using CamillaDSP, `_audioout` → `camilladsp` ALSA plugin
- When Multiroom TX is active, uses `Loopback` device to reduce audio glitches

**Volume Management:**
- AirPlay changes volume during playback
- When AirPlay stops, moOde restores previous volume with `vol.sh -restore`
- If CamillaDSP volume sync is enabled, `mpd2cdspvolume` service is restarted

## Troubleshooting

### Issue: AirPlay not discoverable

**Check:**
1. Service running: `systemctl status shairport-sync`
2. Network interfaces: `ip addr show`
3. WiFi radio: `nmcli radio wifi` (should show "enabled")
4. Avahi advertising: `avahi-browse -a -t | grep -i airplay`
5. Firewall: Ports 5000 (AirPlay 1) or 7000 (AirPlay 2) open

### Issue: AirPlay only works on Ethernet, not WiFi

**Root Cause:** WiFi radio disabled in NetworkManager

**Fix:**
```bash
sudo nmcli radio wifi on
sudo nmcli connection up 'SSID_NAME'
```

### Issue: Audio glitches during AirPlay playback

**Solution:** Enable Multiroom TX mode (uses Loopback device)

**Alternative:** Adjust `audio_backend_buffer_desired_length_in_seconds` in config

## Related Files

- `/var/www/inc/renderer.php` - Start/stop functions
- `/var/www/apl-config.php` - Configuration UI
- `/etc/shairport-sync.conf` - Main configuration
- `/var/www/daemon/aplmeta-reader.sh` - Metadata reader launcher
- `/etc/alsa/conf.d/_audioout.conf` - ALSA output device alias
- `/var/local/www/db/moode-sqlite3.db` - Database (`cfg_airplay` table)

## Summary

moOde's AirPlay integration is well-architected with:
- **Automatic service management** via systemd
- **Flexible output routing** (standard, Loopback, Bluetooth)
- **Complete metadata support** with cover art caching
- **Network-aware discovery** on all active interfaces
- **Volume restoration** after playback
- **CamillaDSP integration** for DSP processing

The key to successful WiFi AirPlay is ensuring **NetworkManager WiFi radio is enabled** - without this, the interface remains "unavailable" and AirPlay only works on Ethernet.
