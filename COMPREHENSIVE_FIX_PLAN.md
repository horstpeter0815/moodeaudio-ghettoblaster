# Comprehensive CamillaDSP Activation Fix Plan

## Problem Analysis

**Current State:**
- Config file exists: `bose_wave_filters.yml` ✓
- Database updated: `camilladsp = bose_wave_filters.yml` ✓
- `_audioout.conf` points to `camilladsp` ✓
- Mixer type: `null` (CamillaDSP volume) ✓
- `mpd2cdspvolume` service: running ✓
- **CamillaDSP fails to start**: tries to use non-existent `peppy` device ✗

**Root Cause:**
`setPlaybackDevice()` function checks `$_SESSION['peppy_display'] == '1'` and incorrectly sets device to `peppy` even when peppy device doesn't exist.

## moOde Web UI Flow (What Actually Works)

From `snd-config.php`:
1. User selects CamillaDSP config from dropdown
2. POST `update_cdsp_mode` with `cdsp_mode` value
3. Code path:
   ```php
   if (isset($_POST['update_cdsp_mode']) && $_POST['cdsp_mode'] != $_SESSION['camilladsp']) {
       $currentMode = $_SESSION['camilladsp'];
       $newMode = $_POST['cdsp_mode'];
       phpSession('write', 'camilladsp', $_POST['cdsp_mode']);
       $cdsp->selectConfig($_POST['cdsp_mode']);
       
       if ($_SESSION['cdsp_fix_playback'] == 'Yes' ) {
           $cdsp->setPlaybackDevice($_SESSION['cardnum'], $_SESSION['alsa_output_mode']);
       }
       
       $cdsp->updCDSPConfig($newMode, $currentMode, $cdsp);
   }
   ```
4. `updCDSPConfig()` submits job: `submitJob('camilladsp', $newMode . $queueArg1)`
5. Worker processes job:
   - Calls `updAudioOutAndBtOutConfs()` → updates `_audioout.conf`
   - Calls `updDspAndBtInConfs()` → calls `setPlaybackDevice()` if needed
   - Changes mixer type
   - Restarts MPD

## The Real Issue

`setPlaybackDevice()` has a bug: it sets device to `peppy` when `peppy_display == '1'`, but doesn't verify the device exists.

**Solution:** 
1. Fix the config file directly to use correct device (don't rely on `setPlaybackDevice()` bug)
2. OR: Don't call `setPlaybackDevice()` if `peppy_display == '1'` but peppy device doesn't exist

## Proper Fix Strategy

**Option 1: Fix Config File Directly (Simplest)**
- Manually set device in config file to `plughw:0,0` or `hw:0,0` based on `alsa_output_mode`
- Don't call `setPlaybackDevice()` at all for this config
- This is what we attempted, but need to verify it worked

**Option 2: Fix Activation Script Logic**
- Check if `peppy_display == '1'` but peppy device doesn't exist
- If so, override the device to use hardware device instead
- This requires modifying the activation flow

**Option 3: Verify Current Config File State**
- Check what device is actually in the config file on the system
- If it's wrong, fix it
- Ensure working_config.yml symlink points to correct file

## Recommended Action Plan

1. **Verify current config file state on moOde system**
   ```bash
   grep -A 3 "playback:" /usr/share/camilladsp/configs/bose_wave_filters.yml
   ```

2. **If device is wrong, fix it directly:**
   ```bash
   # Get correct device
   ALSA_MODE=$(sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='alsa_output_mode';")
   CARDNUM=$(sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param='cardnum';")
   DEVICE="${ALSA_MODE}:${CARDNUM},0"
   
   # Fix config
   sudo sed -i "s|device:.*|device: \"$DEVICE\"|" /usr/share/camilladsp/configs/bose_wave_filters.yml
   ```

3. **Recreate working_config.yml symlink:**
   ```bash
   sudo rm -f /usr/share/camilladsp/working_config.yml
   sudo ln -s /usr/share/camilladsp/configs/bose_wave_filters.yml /usr/share/camilladsp/working_config.yml
   ```

4. **Restart MPD and test:**
   ```bash
   sudo systemctl restart mpd
   mpc play
   pgrep camilladsp
   ```

## Key Insight

The config file itself needs to have the correct device string. Once that's correct, CamillaDSP should start when MPD plays audio through the `camilladsp` ALSA device.

