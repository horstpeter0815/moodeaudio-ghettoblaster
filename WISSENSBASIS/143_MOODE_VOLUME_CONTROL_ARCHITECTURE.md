# moOde Volume Control Architecture - Complete Analysis

## Current System State (2026-01-20)

**Hardware:** HiFiBerry AMP100 (PCM512x DAC + TAS5756M Amplifier)  
**moOde Version:** 10.0.2  
**CamillaDSP:** OFF (currently disabled due to config errors)

---

## Volume Control Chain - TWO SCENARIOS

### SCENARIO 1: WITHOUT CamillaDSP (Current State)

```
┌─────────────────────────────────────────────────────────────┐
│ USER INPUT (moOde UI Volume Slider 0-100%)                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ MPD (Music Player Daemon)                                   │
│ - mixer_type: "hardware"                                    │
│ - Controls ALSA hardware mixer directly                     │
│ - NO software volume control in MPD                         │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ ALSA Output Device: "_audioout"                             │
│ - Defined in: /etc/alsa/conf.d/_audioout.conf              │
│ - Type: copy PCM                                            │
│ - slave.pcm: "plughw:0,0" (direct to HiFiBerry)            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ ALSA HARDWARE MIXER (on HiFiBerry - PCM512x chip)          │
│                                                             │
│ 1. DIGITAL Volume (Primary Control)                        │
│    - Range: 0-207 (0-100%)                                 │
│    - dB Range: -99999.99dB to 0.00dB                       │
│    - Control: amixer -c 0 sset 'Digital' X%                │
│    - Controlled by MPD via "hardware" mixer_type           │
│                                                             │
│ 2. ANALOGUE Volume (Output Stage)                          │
│    - Range: 0-1 (0-100%)                                   │
│    - dB Range: -6.00dB to 0.00dB                           │
│    - Control: amixer -c 0 sset 'Analogue' X%               │
│    - Should be: 100% (0.00dB) for maximum output           │
│                                                             │
│ 3. AUTO MUTE (Amplifier Protection)                        │
│    - Auto Mute: ON/OFF per channel                         │
│    - Auto Mute Mono: ON/OFF                                │
│    - Should be: OFF (to prevent muting during silence)     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ PHYSICAL OUTPUT (Analog Audio to Amplifier)                │
└─────────────────────────────────────────────────────────────┘
```

**CORRECT SETTINGS (WITHOUT CamillaDSP):**
- **Digital:** Controlled by MPD (user adjusts in UI, 0-100%)
- **Analogue:** 100% (0.00dB) - fixed maximum
- **Auto Mute:** OFF (both channels)
- **MPD Volume:** User controls this (maps to Digital mixer)

---

### SCENARIO 2: WITH CamillaDSP (Target Configuration)

```
┌─────────────────────────────────────────────────────────────┐
│ USER INPUT (moOde UI Volume Slider 0-100%)                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ MPD (Music Player Daemon)                                   │
│ - mixer_type: "null" (no mixer control)                     │
│ - Outputs at 0dB (100% software volume)                     │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ ALSA Output Device: "_audioout"                             │
│ - slave.pcm: "camilladsp" (ALSA CDSP plugin)               │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ ALSA CDSP Plugin                                            │
│ - Launches CamillaDSP as subprocess                         │
│ - Pipes audio through CamillaDSP                            │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ CamillaDSP Process                                          │
│ - Input: STDIN (from ALSA plugin)                          │
│ - Applies: Bose Wave EQ filters (20-band PEQ)              │
│ - Output: ALSA plughw:0,0 (HiFiBerry)                      │
│ - Volume Control: Via CamillaDSP internal volume           │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ mpd2cdspvolume Service (Volume Sync)                        │
│ - Monitors: MPD volume changes                              │
│ - Writes to: /var/lib/cdsp/statefile.yml                   │
│ - CamillaDSP reads this file for volume control             │
│ - dynamic_range: 60dB                                       │
│ - volume_offset: 0                                          │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ ALSA HARDWARE MIXER (on HiFiBerry)                         │
│ - Digital: 100% (0.00dB) - fixed maximum                   │
│ - Analogue: 100% (0.00dB) - fixed maximum                  │
│ - Auto Mute: OFF                                            │
│ - NO volume control here (all done in CamillaDSP)          │
└────────────────────┬────────────────────────────────────────┘
                     │
                     ▼
┌─────────────────────────────────────────────────────────────┐
│ PHYSICAL OUTPUT (Analog Audio to Amplifier)                │
└─────────────────────────────────────────────────────────────┘
```

**CORRECT SETTINGS (WITH CamillaDSP):**
- **MPD mixer_type:** "null" (no control)
- **CamillaDSP volume:** Controlled by mpd2cdspvolume service
- **Digital:** 100% (0.00dB) - fixed maximum
- **Analogue:** 100% (0.00dB) - fixed maximum
- **Auto Mute:** OFF
- **User controls:** MPD volume → synced to CamillaDSP

---

## Database Parameters

### Volume-Related Parameters:
```
alsavolume_max = 100          # Maximum ALSA hardware volume (%)
volume_mpd_max = 100          # Maximum MPD volume (%)
volknob = X                   # Current volume knob setting (0-100)
volknob_mpd = -1              # MPD volume control (-1 = use hardware)
volume_step_limit = 5         # Volume step size
volume_db_display = 1         # Display volume in dB
```

### CamillaDSP Parameters:
```
camilladsp = off/on/<config>  # CamillaDSP config file or off
camilladsp_volume_sync = on   # Enable volume sync via mpd2cdspvolume
```

---

## Current Problems (2026-01-20)

### Problem 1: CamillaDSP Config Incompatibility
- **Issue:** Bose Wave filter configs use `q` parameter
- **Error:** CamillaDSP 3.0.1 expects different parameter name
- **Status:** CamillaDSP disabled (`camilladsp=off`)
- **Fix Needed:** Update all Bose Wave configs for CamillaDSP 3.0.1 syntax

### Problem 2: Worker.php Overwrites _audioout.conf
- **Issue:** Worker.php regenerates `/etc/alsa/conf.d/_audioout.conf`
- **Behavior:** Reverts to `default:vc4hdmi0` (HDMI/SPDIF) instead of `plughw:0,0`
- **Database:** Settings are correct (`adevname=HiFiBerry Amp2/4`, `alsa_output_mode=plughw`)
- **Root Cause:** Worker.php bug or unknown database parameter controlling output device
- **Current Workaround:** Manual file editing (but gets overwritten)

### Problem 3: Volume Set to 0%
- **Issue:** Digital volume currently at 0% (-99999.99dB)
- **Cause:** Emergency stop after accidental loud audio playback
- **Fix Needed:** Restore Digital volume to user-controlled level

---

## CORRECT Volume Configuration

### WITHOUT CamillaDSP (Current Recommended):
```bash
# 1. Disable CamillaDSP
sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='off' WHERE param='camilladsp';"

# 2. Set ALSA output to direct HiFiBerry
# Edit /etc/alsa/conf.d/_audioout.conf:
pcm._audioout {
    type copy
    slave.pcm "plughw:0,0"
}

# 3. Configure MPD mixer type to "hardware"
# In /etc/mpd.conf:
audio_output {
    type "alsa"
    name "ALSA Default"
    device "_audioout"
    mixer_type "hardware"
    mixer_device "hw:0"
    mixer_control "Digital"
}

# 4. Set hardware volumes
sudo amixer -c 0 sset 'Digital' 100%      # User will control via MPD UI
sudo amixer -c 0 sset 'Analogue' 100%     # Fixed maximum
sudo amixer -c 0 sset 'Auto Mute' off     # Disable auto-mute
sudo amixer -c 0 sset 'Auto Mute Mono' off

# 5. Set MPD volume (user starts at safe level)
mpc volume 30  # 30% as safe starting point
```

### WITH CamillaDSP (Future - After Fixing Configs):
```bash
# 1. Fix CamillaDSP configs (update 'q' parameter syntax)
# 2. Enable CamillaDSP with fixed config
sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='bose_wave_filters.yml' WHERE param='camilladsp';"

# 3. Set ALSA output to CamillaDSP
# Edit /etc/alsa/conf.d/_audioout.conf:
pcm._audioout {
    type copy
    slave.pcm "camilladsp"
}

# 4. Configure MPD mixer type to "null"
# In /etc/mpd.conf:
audio_output {
    type "alsa"
    name "ALSA Default"
    device "_audioout"
    mixer_type "null"
}

# 5. Set hardware volumes to maximum (control via CamillaDSP)
sudo amixer -c 0 sset 'Digital' 100%
sudo amixer -c 0 sset 'Analogue' 100%
sudo amixer -c 0 sset 'Auto Mute' off
sudo amixer -c 0 sset 'Auto Mute Mono' off

# 6. Enable mpd2cdspvolume service
sudo systemctl enable mpd2cdspvolume
sudo systemctl start mpd2cdspvolume

# 7. Set MPD volume (synced to CamillaDSP via mpd2cdspvolume)
mpc volume 30
```

---

## Key Learnings

1. **moOde uses "hardware" mixer_type when CamillaDSP is OFF**
   - MPD directly controls the ALSA Digital mixer
   - User volume slider → MPD → ALSA Digital volume

2. **moOde uses "null" mixer_type when CamillaDSP is ON**
   - MPD outputs at fixed 100% (0dB)
   - Volume control happens in CamillaDSP
   - mpd2cdspvolume syncs MPD volume to CamillaDSP

3. **HiFiBerry AMP100 has TWO volume controls:**
   - Digital: Main volume (PCM512x DAC digital volume)
   - Analogue: Output stage analog volume

4. **Analogue volume should always be 100%**
   - Provides maximum signal to the analog output stage
   - Volume control via Digital mixer or CamillaDSP

5. **Auto Mute must be disabled**
   - Otherwise amplifier mutes during silence/pauses
   - Can cause "no audio" issues

---

## Next Steps

1. **Fix _audioout.conf persistence issue**
   - Identify why worker.php generates wrong config
   - Find database parameter or worker.php code that controls ALSA output device

2. **Fix CamillaDSP filter configs for v3.0.1**
   - Update `q` parameter to correct syntax
   - Test with CamillaDSP standalone before enabling in moOde

3. **Restore volume to safe level**
   - Set Digital back to user-controlled level
   - Ensure volume control works via moOde UI

4. **Test complete audio chain**
   - User tests with volume 0 → gradually increase
   - Verify no automatic audio playback
