# CamillaDSP Activation Research

## Flow Analysis

### 1. Web UI Flow (snd-config.php lines 464-475)
```php
if (isset($_POST['update_cdsp_mode']) && $_POST['cdsp_mode'] != $_SESSION['camilladsp']) {
    $currentMode = $_SESSION['camilladsp'];
    $newMode = $_POST['cdsp_mode'];
    phpSession('write', 'camilladsp', $_POST['cdsp_mode']);
    $cdsp->selectConfig($_POST['cdsp_mode']);
    
    if ($_SESSION['cdsp_fix_playback'] == 'Yes') {
        $cdsp->setPlaybackDevice($_SESSION['cardnum'], $_SESSION['alsa_output_mode']);
    }
    
    $cdsp->updCDSPConfig($newMode, $currentMode, $cdsp);
}
```

### 2. updCDSPConfig Flow (cdsp.php lines 587-613)
- If switching TO/FROM 'off':
  - Sets mixer_type in database: 'null' if turning ON, 'hardware'/'software' if turning OFF
  - Calls submitJob('camilladsp', $newMode . ',change_mixer_to_camilladsp')
- If switching between configs:
  - Calls reloadConfig() only (no mixer switch needed)

### 3. submitJob Function (common.php lines 488-512)
- Sets $_SESSION['w_queue'] = 'camilladsp'
- Sets $_SESSION['w_queueargs'] = $newMode . ',change_mixer_to_camilladsp'
- Worker daemon reads these from session and processes

### 4. Worker Processing (worker.php lines 2950-2982)
- Reads $_SESSION['w_queueargs']
- Splits by comma: queueArgs[0] = config name, queueArgs[1] = mixer command
- If queueArgs[1] == 'change_mixer_to_camilladsp':
  - Calls changeMPDMixer('camilladsp') → sets mixer_type to 'null'
  - Starts mpd2cdspvolume service
  - Restarts MPD
  - Restores volume
- If queueArgs[1] == 'change_mixer_to_default':
  - Sets mixer_type to 'hardware' or 'software'
  - Stops mpd2cdspvolume
  - Restarts MPD
  - Restores volume

## Key Points

1. **Session Sharing**: Worker daemon and Web UI must use the same session file
2. **Session ID**: Stored in cfg_system table as 'sessionid'
3. **Session File**: /var/local/php/sess_<sessionid>
4. **Permissions**: Must be www-data:www-data and 0666

## CLI Activation Requirements

When activating from CLI (not Web UI), we need to:
1. Get the correct session ID from database
2. Use that session ID in our PHP script
3. Load system config into session (phpSession('load_system'))
4. Call the same functions as Web UI
5. Ensure session is written and closed so worker can read it

## Volume Issue When CamillaDSP is OFF

When CamillaDSP is OFF:
- mixer_type should be 'hardware' or 'software' (NOT 'none')
- If mixer_type is 'none', volume won't work
- Need to fix mixer_type based on alsavolume setting

