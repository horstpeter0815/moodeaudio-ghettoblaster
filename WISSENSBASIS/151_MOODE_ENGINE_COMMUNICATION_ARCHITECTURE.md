# moOde Engine Communication Architecture

**Date:** 2026-01-20  
**Purpose:** Complete understanding of real-time communication between backend (PHP/worker.php) and frontend (JavaScript)

## Overview

moOde uses a sophisticated dual-engine architecture for real-time communication between the PHP backend and JavaScript frontend:

1. **MPD Metadata Engine** (`engine-mpd.php`) - Pushes MPD state changes to UI
2. **Command Engine** (`engine-cmd.php`) - Pushes worker.php commands to UI

Both engines use **long-polling** AJAX for near-real-time updates without WebSockets.

---

## 1. MPD Metadata Engine

### Backend: engine-mpd.php

**Flow:**
```php
// Line 14: Check worker ready
$result = sqlQuery("SELECT value FROM cfg_system WHERE param='wrkready'", sqlConnect());
if ($result[0]['value'] == '0') {
    exit; // Worker still starting
}

// Line 22: Connect to MPD
$sock = openMpdSock('localhost', 6600);

// Line 29: Get current MPD status
$status = getMpdStatus($sock);

// Line 32: Initiate idle if state unchanged
if ($_GET['state'] == $status['state']) {
    sendMpdCmd($sock, 'idle');                 // ← MPD IDLE COMMAND
    stream_set_timeout($sock, 600000);         // 10 minute timeout
    $resp = readMpdResp($sock);                // ← BLOCKS until MPD event!
    
    $event = explode("\n", $resp)[0];
    $status = getMpdStatus($sock);
    $status['idle_timeout_event'] = $event;    // ← Event type
}

// Line 42: Create enhanced metadata
$metadata = enhanceMetadata($status, $sock, 'engine_mpd_php');

// Line 45: Return as JSON
echo json_encode($metadata);
```

**MPD Idle Events:**
- `changed: player` - Track/state changed (play/pause/stop)
- `changed: mixer` - Volume changed
- `changed: playlist` - Queue modified
- `changed: update` - Database update
- `changed: output` - Output enabled/disabled
- `changed: options` - repeat/random/single/consume changed

**Key Feature:** The `idle` command makes MPD **block** until something changes. This provides push-based updates with minimal network traffic!

### Frontend: playerlib.js engineMpd()

**Lines 302-419:**
```javascript
function engineMpd() {
    $.ajax({
        type: 'GET',
        url: 'engine-mpd.php?state=' + MPD.json['state'],  // Pass current state
        async: true,
        cache: false,
        success: function(data) {
            // Parse JSON
            try {
                MPD.json = JSON.parse(data);
            } catch (e) {
                MPD.json['error'] = e;
            }
            
            if (typeof(MPD.json['error']) === 'undefined') {
                // No error - process event
                if (MPD.json['idle_timeout_event'] === '') {
                    // No event (state changed between calls)
                } else {
                    // Hide reconnect overlay if showing
                    if (UI.hideReconnect === true) {
                        hideReconnect();
                    }
                    
                    // Handle specific events
                    if (MPD.json['idle_timeout_event'] == 'changed: update') {
                        // Database update in progress
                        if (typeof(MPD.json['updating_db']) != 'undefined') {
                            $('.busy-spinner').show();
                        } else {
                            $('.busy-spinner').hide();
                        }
                    } else if (MPD.json['idle_timeout_event'] == 'changed: mixer') {
                        // Volume changed - update volume only
                        renderUIVol();
                    } else if (MPD.json['idle_timeout_event'] == 'changed: player' && MPD.json['file'] == null) {
                        // Last track finished - partial update
                        resetPlayCtls();
                    } else {
                        // Everything else - full UI update
                        renderUI();
                    }
                }
                
                // Recursive call
                engineMpd();  // ← IMMEDIATELY starts next poll
            } else {
                // Error occurred
                renderUI();
                setTimeout(function() {
                    engineMpd();  // ← Retry after 3 seconds
                }, ENGINE_TIMEOUT);
            }
        },
        error: function(data) {
            // Network error
            renderReconnect();  // Show "reconnecting" overlay
            MPD.json['state'] = 'reconnect';
            setTimeout(function() {
                engineMpd();  // ← Retry after 3 seconds
            }, ENGINE_TIMEOUT);
        }
    });
}
```

**Key Understanding:**
- Engine polls **continuously** in a recursive loop
- Backend **blocks** on MPD idle until an event occurs
- When event occurs, JSON returned, UI updates, next poll starts immediately
- On error, retry after 3 seconds
- Result: **Near-real-time updates** with minimal CPU/network overhead

---

## 2. Command Engine

### Backend: engine-cmd.php

**Flow:**
```php
// Line 10: Create listening socket on random port
$sock = socket_create_listen(0);

// Line 16: Get assigned port number
socket_getsockname($sock, $addr, $port);

// Line 19: Write port to PORT_FILE
$fp = fopen(PORT_FILE, 'a');  // /tmp/moode_portfile
fwrite($fp, $port . "\n");
fclose($fp);

// Line 29: Wait for connection (BLOCKS HERE!)
$sockres = socket_accept($sock);

// Line 34: Read command (BLOCKS until data received!)
$data = socket_read($sockres, 1024);
$cmd = str_replace(array("\r\n","\r","\n"), '', $data);

// Line 43: Close socket
socket_close($sock);

// Line 46: Remove port from portfile
sysCmd('sed -i /' . $port . '/d ' . PORT_FILE);

// Line 50: Special command handling
if ($cmd == 'inpactive1') {
    $result = sqlQuery("SELECT value FROM cfg_system WHERE param='audioin'", sqlConnect());
    $cmd .= ',' . $result[0]['value'];
}

// Line 56: Return command to JavaScript
echo json_encode($cmd);
```

**Architecture:**
1. Each browser tab gets its own engine-cmd.php instance
2. Each instance creates a random port and registers it in PORT_FILE
3. Instance blocks waiting for commands
4. When worker.php sends command, instance wakes up, returns command, exits
5. JavaScript receives command, processes it, starts new engine-cmd.php instance

### Frontend: playerlib.js engineCmd()

**Lines 515-684:**
```javascript
function engineCmd() {
    var cmd;
    
    $.ajax({
        type: 'GET',
        url: 'engine-cmd.php',
        async: true,
        cache: false,
        success: function(data) {
            cmd = JSON.parse(data).split(',');
            
            switch (cmd[0]) {
                case 'inpactive1':
                case 'inpactive0':
                    var inputSourceName = typeof(cmd[1]) == 'undefined' ? 'Undefined' : cmd[1];
                    inpSrcIndicator(cmd[0], '<span>Input Active: ...');
                    break;
                    
                case 'aplactive1':
                case 'aplactive0':
                    // AirPlay started/stopped
                    break;
                    
                case 'btactive1':
                case 'btactive0':
                    // Bluetooth started/stopped
                    break;
                    
                case 'spotactive1':
                case 'spotactive0':
                    // Spotify started/stopped
                    break;
                    
                case 'refresh_screen':
                    setTimeout(function() {
                        location.reload(true);  // Full page reload
                    }, DEFAULT_TIMEOUT);
                    break;
                    
                case 'cdsp_update_config':
                    notify(NOTIFY_TITLE_INFO, cmd[0], cmd[1], NOTIFY_DURATION_LONG);
                    break;
                    
                // ... 30+ more command types
                
                default:
                    console.log('engineCmd(): ' + cmd[0]);
                    break;
            }
            
            // Recursive call
            engineCmd();  // ← Start next poll immediately
        },
        error: function(data) {
            setTimeout(function() {
                engineCmd();  // ← Retry after 3 seconds
            }, ENGINE_TIMEOUT);
        }
    });
}
```

### Worker → UI Communication: sendFECmd()

**common.php lines 478-508:**
```php
function sendFECmd ($cmd) {
    // Read portfile (contains all active engine-cmd.php ports)
    $ports = file(PORT_FILE, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
    
    if ($ports === false) {
        debugLog('sendFECmd(): File open failed, UI has never been opened in Browser');
        return;
    }
    
    // Retry if no ports registered (UI might be starting)
    $retry_limit = 4;
    while (count($ports) === 0 && $retry_limit > 0) {
        $ports = file(PORT_FILE, FILE_IGNORE_NEW_LINES | FILE_SKIP_EMPTY_LINES);
        sleep(1);
        $retry_limit--;
    }
    
    // Send command to ALL registered ports (all browser tabs)
    foreach ($ports as $port) {
        if (false !== ($sock = socket_create(AF_INET, SOCK_STREAM, SOL_TCP))) {
            if (false !== ($result = socket_connect($sock, '127.0.0.1', $port))) {
                sockWrite($sock, $cmd);  // ← Send command string
                socket_close($sock);
            } else {
                // Port dead, remove from portfile
                sysCmd('sed -i /' . $port . '/d ' . PORT_FILE);
            }
        }
    }
}
```

**Commands Sent:**
- `aplactive1` / `aplactive0` - AirPlay started/stopped
- `btactive1` / `btactive0` - Bluetooth started/stopped
- `spotactive1` / `spotactive0` - Spotify started/stopped
- `inpactive1` / `inpactive0` - Input source changed
- `rxactive1` / `rxactive0` - Multiroom receiver started/stopped
- `scnactive1` / `scnactive0` - Screen saver activated/deactivated
- `refresh_screen` - Reload browser
- `cdsp_update_config,{msg}` - CamillaDSP config changed
- `libupd_done` - Library update complete
- And 20+ more...

---

## 3. Complete Communication Flow

### Example: User Changes CamillaDSP Config

**Step 1: User clicks "Apply" in Equalizers UI**

```javascript
// Frontend (scripts-panels.js or similar)
$.post('command/camilla.php', {
    'save': '1',
    'camilladsp': 'bose_wave_physics_optimized.yml'
}, function(result) {
    // Wait for completion
});
```

**Step 2: PHP processes request**

```php
// command/camilla.php
phpSession('open');
$_SESSION['camilladsp'] = $_POST['camilladsp'];

$cdsp = new CamillaDsp($_SESSION['camilladsp'], $_SESSION['cardnum'], $_SESSION['camilladsp_quickconv']);
$cdsp->updCDSPConfig($_POST['camilladsp'], $old, $cdsp);

// updCDSPConfig() does:
sendFECmd('cdsp_update_config,CamillaDSP volume.');
submitJob('camilladsp', 'bose_wave_physics_optimized.yml,change_mixer_to_camilladsp');

phpSession('close');
```

**Step 3: Worker.php processes job**

```php
// Worker loop (runs every 3 seconds)
if ($_SESSION['w_active'] == 1 && $_SESSION['w_lock'] == 0) {
    runQueuedJob();
}

// runQueuedJob() case 'camilladsp':
$queueArgs = explode(',', $_SESSION['w_queueargs']);
updAudioOutAndBtOutConfs($_SESSION['cardnum'], $_SESSION['alsa_output_mode']);

if ($queueArgs[1] == 'change_mixer_to_camilladsp') {
    changeMPDMixer('camilladsp');  // Sets mixer_type = 'null'
    sysCmd('systemctl start mpd2cdspvolume');
    sysCmd('systemctl restart mpd');
}

// Reset job queue
$_SESSION['w_queue'] = '';
$_SESSION['w_active'] = 0;
$_SESSION['w_lock'] = 0;
```

**Step 4: MPD restarts, UI updates**

```javascript
// engineMpd() receives 'changed: mixer' event
if (MPD.json['idle_timeout_event'] == 'changed: mixer') {
    renderUIVol();  // Update volume controls
}

// engineCmd() receives 'cdsp_update_config' command
case 'cdsp_update_config':
    notify(NOTIFY_TITLE_INFO, cmd[0], cmd[1], NOTIFY_DURATION_LONG);
    break;
```

---

## 4. UI Rendering System

### renderUI() (playerlib.js lines 1088-1400+)

**Called when:** Any MPD event except mixer or playlist end

**What it does:**
```javascript
function renderUI() {
    // 1. Reload session vars
    $.getJSON('command/cfg-table.php?cmd=get_cfg_system', function(data) {
        SESSION.json = data;
        
        // 2. Update volume controls
        if (SESSION.json['mpdmixer'] == 'none') {
            disableVolKnob();
        } else {
            $('#volume').val(SESSION.json['volknob']);
            $('.volume-display div').text(SESSION.json['volknob']);
            // ... update mute state, etc.
        }
        
        // 3. Update playback controls
        // ... (play/pause button, progress bar, etc.)
        
        // 4. Update track info
        // ... (artist, title, album, cover art)
        
        // 5. Render Queue
        if (MPD.json['idle_timeout_event'] == 'changed: playlist' || GLOBAL.playQueueChanged) {
            renderPlayqueue(MPD.json['state']);
        }
        
        // 6. Update search controls, extra metadata, etc.
    });
}
```

### renderUIVol() (playerlib.js lines 1032-1086)

**Called when:** `changed: mixer` event only

**What it does:**
```javascript
function renderUIVol() {
    // Reload session (for multi-client sync)
    $.getJSON('command/cfg-table.php?cmd=get_cfg_system', function(data) {
        SESSION.json = data;
        
        if (SESSION.json['mpdmixer'] == 'none') {
            disableVolKnob();
        } else {
            // Update volume knobs
            $('#volume').val(SESSION.json['volknob']).trigger('change');
            $('.volume-display div').text(SESSION.json['volknob']);
            $('#volume-2').val(SESSION.json['volknob']).trigger('change');
            
            // Update dB display
            $('.volume-display-db').text(SESSION.json['volume_db_display'] == '1' ? MPD.json['mapped_db_vol'] : '');
            
            // Update mute state
            if (SESSION.json['volmute'] == '1') {
                $('.volume-display div').html('<i class="fa fa-volume-xmark"></i>');
            } else {
                $('.volume-display div').text(SESSION.json['volknob']);
            }
        }
    });
}
```

**Optimization:** Only updates volume-related elements, not the entire UI.

---

## 5. Multi-Client Support

### The PORT_FILE System

**File:** `/tmp/moode_portfile`

**Contents (example):**
```
45123
45124
45125
```

Each line is a port number for an active `engine-cmd.php` instance.

**How it works:**
1. Browser Tab 1 opens → `engine-cmd.php` starts → port 45123 written to PORT_FILE
2. Browser Tab 2 opens → another `engine-cmd.php` → port 45124 written
3. Browser Tab 3 opens → another `engine-cmd.php` → port 45125 written
4. Worker sends command → `sendFECmd()` reads PORT_FILE → sends to ALL ports
5. All tabs receive command simultaneously

**Lifecycle:**
```
Browser loads → engine-cmd.php starts → port added to PORT_FILE
  ↓
engine-cmd.php blocks on socket_accept()
  ↓
Worker sends command → sendFECmd() → socket_connect(port)
  ↓
engine-cmd.php wakes up → reads command → returns to JavaScript → exits
  ↓
JavaScript receives command → processes it → starts NEW engine-cmd.php
  ↓
New port added to PORT_FILE → cycle repeats
```

**Cleanup:** If port connection fails (browser closed), `sendFECmd()` removes stale port from PORT_FILE.

---

## 6. Session Synchronization

### cfg-table.php get_cfg_system

**Used by:** `renderUI()` and `renderUIVol()` to reload session

**Why needed:**
- Multiple browser tabs can modify session
- Worker.php modifies session
- Each render needs fresh data

**Command:**
```javascript
$.getJSON('command/cfg-table.php?cmd=get_cfg_system', function(data) {
    SESSION.json = data;  // ← Overwrite local session cache
    // ... use fresh data
});
```

**Backend (cfg-table.php lines 83-98):**
```php
case 'get_cfg_system':
    phpSession('open_ro');
    $result = sqlRead('cfg_system', $dbh);
    $cfgSystem = array();
    
    foreach ($result as $row) {
        $cfgSystem[$row['param']] = $row['value'];
    }
    
    // Add session vars
    addExtraSessionVars($cfgSystem);  // Adds runtime info (IP, hostname, etc.)
    
    // Add MPD settings
    $cfgSystem['mpd_log_level'] = sqlQuery("SELECT value FROM cfg_mpd WHERE param='log_level'", $dbh)[0]['value'];
    
    echo json_encode($cfgSystem);
    break;
```

---

## 7. Performance Characteristics

### Backend (PHP)

**engine-mpd.php:**
- **CPU:** Very low when idle (blocked on MPD idle)
- **Wake time:** Immediate when MPD event occurs
- **Response time:** ~10-50ms after MPD event

**engine-cmd.php:**
- **CPU:** Zero when idle (blocked on socket_accept)
- **Wake time:** Immediate when worker sends command
- **Response time:** ~1-5ms

**worker.php:**
- **CPU:** Low (sleeps 3 seconds between loops)
- **Job processing:** Immediate (within 3 seconds of job submission)

### Frontend (JavaScript)

**engineMpd():**
- **Polling interval:** Continuous (starts next poll immediately after response)
- **Timeout on error:** 3 seconds
- **Network traffic:** Minimal (only when MPD events occur)

**engineCmd():**
- **Polling interval:** Continuous
- **Timeout on error:** 3 seconds
- **Network traffic:** Minimal (only when worker sends commands)

### Comparison to WebSockets

**Advantages of this approach:**
- No WebSocket server required
- Works with standard PHP-FPM
- Compatible with all browsers
- Handles multiple tabs elegantly
- Automatic reconnection on network issues

**Disadvantages:**
- Slightly higher latency than WebSockets (~100-200ms vs ~10-50ms)
- More complex to debug

---

## 8. Error Handling and Reconnection

### Scenarios

#### MPD Connection Lost

**Detected by:** engine-mpd.php line 22-27

**Response:**
```javascript
// error branch in engineMpd()
error: function(data) {
    renderReconnect();  // Show overlay: "moOde: Reconnecting..."
    MPD.json['state'] = 'reconnect';
    setTimeout(function() {
        engineMpd();  // Keep retrying every 3 seconds
    }, ENGINE_TIMEOUT);
}
```

#### PHP-FPM Not Ready

**Detected by:** AJAX failure (connection refused)

**Response:**
- JavaScript keeps retrying
- Eventually PHP-FPM starts
- Next poll succeeds
- UI loads (this was the display loading issue!)

#### Network Interrupted

**Detected by:** AJAX error

**Response:**
- Show reconnect overlay
- Keep retrying both engines
- When network returns, resume normal operation

---

## 9. Command Types

### Backend → Frontend Commands (via engineCmd)

**Player State:**
- `aplactive1` / `aplactive0` - AirPlay
- `btactive1` / `btactive0` - Bluetooth
- `spotactive1` / `spotactive0` - Spotify
- `deezactive1` / `deezactive0` - Deezer
- `slactive1` / `slactive0` - Squeezelite
- `paactive1` / `paactive0` - Plexamp
- `rbactive1` / `rbactive0` - RoonBridge
- `rxactive1` / `rxactive0` - Multiroom receiver
- `inpactive1` / `inpactive0` - Input source

**UI Updates:**
- `refresh_screen` - Full page reload
- `reset_view` - Reset to Playback view
- `scnactive1` / `scnactive0` - Screen saver
- `close_notification` - Close notification popup

**Configuration:**
- `cdsp_update_config,{msg}` - CamillaDSP changed
- `cdsp_config_updated,{config}` - CamillaDSP switched
- `libregen_done` - Library regeneration complete
- `libupd_done` - Library update complete
- `nvme_formatting_drive` - NVMe format in progress

**Maintenance:**
- `reduce_fpm_pool` - Reduce PHP-FPM idle connections

### Frontend → Backend Commands (via AJAX)

**Playback Control:**
- `command/playback.php?cmd=upd_volume` - Volume change
- `command/playback.php?cmd=get_mpd_status` - Get current status
- `command/playback.php?cmd=reset_screen_saver` - Reset timeout
- `command/playback.php?cmd=upd_clock_radio` - Update clock radio

**Configuration:**
- `command/cfg-table.php?cmd=get_cfg_system` - Reload session
- `command/cfg-table.php?cmd=upd_cfg_system` - Update single param
- `command/cfg-table.php?cmd=get_cfg_tables` - Load all tables

**System:**
- `command/system.php?cmd=reboot` - Reboot system
- `command/system.php?cmd=poweroff` - Shutdown
- `command/system.php?cmd=update_library` - Update library

---

## 10. Key Learnings

### 1. **No Polling Overhead**
- Both engines use **blocking** operations (MPD idle, socket_accept)
- No busy-waiting or timer-based polling
- CPU usage near zero when idle

### 2. **Push-Based Updates**
- MPD pushes events → engine-mpd.php → JavaScript
- Worker pushes commands → engine-cmd.php → JavaScript
- Result: **Real-time UI** with minimal overhead

### 3. **Multi-Tab Support**
- Each tab gets own engine-cmd.php instance
- Worker sends to ALL tabs simultaneously
- Session kept in sync via get_cfg_system reloads

### 4. **Resilient to Failures**
- Engines auto-reconnect on errors
- Stale ports cleaned up automatically
- UI shows reconnect overlay when backend unavailable

### 5. **Why Display Loading Issue Occurred**
- `engineMpd()` and `engineCmd()` started from scripts-panels.js line 186-187
- BUT only started in the callback of the initial `$.getJSON()` config load (line 67)
- If that AJAX call fails (PHP-FPM not ready), callback NEVER runs
- Engines NEVER start
- UI shows incomplete/stale content
- Eventually user refreshes or PHP-FPM becomes ready
- Next load succeeds → engines start → UI loads completely

---

## Related Documentation

- `WISSENSBASIS/150_MOODE_COMPLETE_AUDIO_SYSTEM_ARCHITECTURE.md` - Audio stack
- `WISSENSBASIS/148_MOODE_SHAIRPORT_SYNC_ARCHITECTURE.md` - AirPlay integration
- `WISSENSBASIS/147_MOODE_COMPLETE_ANALYSIS_SUMMARY.md` - Overall system analysis
