# moOde 10.0.2 Working Configuration
## Date: 2026-01-20
## Source: DOWNLOAD (Official moOde 10.0.2 image, not custom build)

## CRITICAL DISTINCTION
**This is NOT the custom build from hifiberry-os/imgbuild!**
- **Source**: Official moOde Audio 10.0.2 download from https://moodeaudio.org/
- **Downloaded**: 2026-01-19
- **Burned to SD**: Using Balena Etcher

## System Specifications
- **Hardware**: Raspberry Pi 5 (8GB)
- **Audio**: HiFiBerry AMP100
- **Display**: 1280x400 landscape touchscreen (Waveshare)
- **moOde Version**: 10.0.2 (2025-12-28)
- **OS**: Raspberry Pi OS 13.2 Trixie 64-bit
- **Kernel**: Linux 6.12.47 64-bit

## Working Features
✅ HiFiBerry AMP100 audio output (plughw:0,0)
✅ CamillaDSP with Bose Wave filters
✅ Display: 1280x400 landscape orientation
✅ Touch calibration (90° left rotation)
✅ AirPlay (shairport-sync + avahi)
✅ Roon Bridge (enabled, ready for activation)
✅ Safe volume limits (Digital: 50%, Analogue: 100%, MPD: 30%)
✅ Volume sync (mpd2cdspvolume active)

## Critical Configuration Files

### 1. Boot Configuration (`/boot/firmware/config.txt`)
**Purpose**: Hardware initialization, display timing, audio device selection

**Key Settings (NEVER CHANGE THESE)**:
```
arm_boost=1                              # Performance boost (MANDATORY)
dtparam=audio=off                        # Disable onboard audio (MANDATORY)
dtoverlay=vc4-kms-v3d-pi5,noaudio       # KMS with no audio (MANDATORY)
hdmi_force_edid_audio=0                  # No HDMI audio (MANDATORY)
dtoverlay=hifiberry-amp100               # HiFiBerry AMP100 driver
dtoverlay=ft6236                         # Touch driver
hdmi_group=2                             # DMT mode
hdmi_mode=87                             # Custom mode
hdmi_timings=400 0 220 32 110 1280 0 10 10 10 0 0 0 60 0 59510000 0  # 1280x400@60Hz
```

### 2. Kernel Command Line (`/boot/firmware/cmdline.txt`)
**Purpose**: Boot parameters, framebuffer resolution

**Critical Setting**:
```
video=HDMI-A-1:1280x400@60
```
- This sets the FRAMEBUFFER resolution to 1280x400 landscape
- NEVER change this to 400x1280 (breaks boot screen)
- The .xinitrc handles X11 rotation separately

### 3. X11 Initialization (`/home/andre/.xinitrc`)
**Purpose**: Set up X session, apply rotation, launch Chromium

**Key Features**:
- Reads `hdmi_scn_orient` from moOde database
- Applies rotation via `xrandr --output HDMI-2 --rotate left` (for portrait)
- Launches Chromium in kiosk mode with touch-friendly flags
- Sets framebuffer geometry: `fbset -g 1280 400 1280 400 32`

**How cmdline.txt and .xinitrc work together**:
- `cmdline.txt video=`: Sets PHYSICAL framebuffer (always 1280x400)
- `.xinitrc xrandr`: Applies X11 rotation based on database setting
- They work TOGETHER: cmdline sets base, xinitrc rotates it

### 4. Touch Calibration (`/usr/share/X11/xorg.conf.d/40-libinput-touchscreen.conf`)
**Purpose**: Calibrate touchscreen for rotated display

**Matrix for 90° left rotation**:
```
Option "TransformationMatrix" "0 -1 1 1 0 0 0 0 1"
```

### 5. ALSA Audio Output (`/etc/alsa/conf.d/_audioout.conf`)
**Purpose**: Route MPD audio to HiFiBerry or CamillaDSP

**Current Setting (with CamillaDSP)**:
```
pcm._audioout {
  type copy
  slave.pcm "camilladsp"
}
```

**Alternative (direct HiFiBerry, no DSP)**:
```
slave.pcm "plughw:0,0"
```

### 6. Systemd Service (`/etc/systemd/system/fix-audioout-cdsp.service`)
**Purpose**: Workaround for worker.php audio detection bug

**Why This Exists**:
- moOde's `worker.php` has a bug in audio device detection
- Even with HiFiBerry correctly configured, it sometimes detects `ALSA_EMPTY_CARD`
- When this happens, worker.php resets configuration to "Pi HDMI 1" + "iec958"
- This service runs 15 seconds after boot, after worker.php completes
- It reads the database `camilladsp` setting and fixes `_audioout.conf` accordingly
- Then restarts MPD with the correct configuration

**How It Works**:
1. Waits 15 seconds (ExecStartPre=/bin/sleep 15)
2. Checks database: Is CamillaDSP enabled?
3. If enabled: Sets `slave.pcm "camilladsp"`
4. If disabled: Sets `slave.pcm "plughw:0,0"`
5. Restarts MPD (ExecStartPost=/bin/systemctl reload-or-restart mpd)

**This is a WORKAROUND, not a proper fix!**
The proper fix would be to patch worker.php's audio detection logic.

## moOde Database Settings (`/var/local/www/db/moode-sqlite3.db`)

### Audio Configuration (cfg_system table):
```
adevname = 'HiFiBerry Amp2/4'     # Audio device name
cardnum = '0'                      # ALSA card number
alsa_output_mode = 'plughw'        # Output mode (NOT 'iec958'!)
amixname = 'Digital'               # Hardware mixer name (for volume)
```

### CamillaDSP Configuration:
```
camilladsp = 'bose_wave_filters.yml'     # Active filter configuration
camilladsp_volume_sync = 'on'            # Sync MPD volume with CDSP
```

### Display Configuration:
```
local_display = '1'                # Enable local display
hdmi_scn_orient = 'landscape'      # Display orientation (or 'portrait')
```

### Volume Configuration:
```
volknob = '50'                     # Hardware volume (Digital mixer, 50% = -51.5dB)
```
**Important**: Hardware volume should be 50% for Digital mixer, 100% for Analogue mixer

### Network Services:
```
airplaysvc = '1'                   # AirPlay enabled
airplayname = 'Moode AirPlay'      # AirPlay advertised name
roonbridge = 'Roon Bridge'         # Roon Bridge enabled
```

## Volume Control Architecture

### With CamillaDSP (Current Setup):
```
[MPD Volume 30%] → [CamillaDSP Volume via mpd2cdspvolume] → [Digital Mixer 50%] → [HiFiBerry Amp]
```
- MPD: User-controlled (0-100%)
- CamillaDSP: Synced with MPD via mpd2cdspvolume service
- Digital Mixer: FIXED at 50% (-51.5dB)
- Analogue Mixer: FIXED at 100% (0.0dB)
- Auto Mute: OFF

### Without CamillaDSP:
```
[MPD Volume 30%] → [Digital Mixer 50%] → [HiFiBerry Amp]
```
- MPD: User-controlled (0-100%)
- Digital Mixer: FIXED at 50% (-51.5dB)
- Analogue Mixer: FIXED at 100% (0.0dB)

**CRITICAL**: Never use Analogue mixer for volume control with HiFiBerry AMP100! Always use Digital mixer.

## CamillaDSP Bose Wave Filters
- **Location**: `/usr/share/camilladsp/configs/bose_wave_*.yml`
- **Version**: Compatible with CamillaDSP v3.0.1
- **Features**: 20-band parametric EQ, room correction, waveguide compensation
- **Status**: Working and tested

## Known Issues and Workarounds

### Issue 1: Audio Output Resets to HDMI on Boot
**Symptom**: After reboot, audio goes to SPDIF/HDMI instead of HiFiBerry
**Root Cause**: worker.php audio detection bug (returns ALSA_EMPTY_CARD for HiFiBerry)
**Workaround**: `fix-audioout-cdsp.service` (see systemd/ directory)
**Proper Fix**: Patch worker.php audio detection logic (not yet implemented)

### Issue 2: Database Values Revert on Worker Restart
**Symptom**: `adevname` and `alsa_output_mode` revert to HDMI/iec958
**Root Cause**: Same as Issue 1
**Workaround**: Same as Issue 1
**Status**: Workaround is stable and survives reboots

### Issue 3: Display Orientation
**Symptom**: Boot screen and moOde UI have different orientations
**Root Cause**: Framebuffer (cmdline.txt) vs X11 (xinitrc) use different rotation methods
**Solution**: cmdline.txt always 1280x400, .xinitrc applies rotation via xrandr
**Status**: Working correctly

## Setup Procedure (Restore This Configuration)

### Prerequisites:
1. Fresh moOde 10.0.2 SD card (download from moodeaudio.org)
2. Burned with Balena Etcher
3. Pi 5 with HiFiBerry AMP100, 1280x400 display

### Steps:
1. Boot moOde 10.0.2, complete initial setup via web UI
2. SSH into Pi: `ssh andre@<ip>` (password: 0815)
3. Copy configuration files:
   - `/boot/firmware/config.txt` (from this backup)
   - `/boot/firmware/cmdline.txt` (from this backup)
   - `/home/andre/.xinitrc` (from this backup)
   - `/usr/share/X11/xorg.conf.d/40-libinput-touchscreen.conf` (from this backup)
   - `/etc/systemd/system/fix-audioout-cdsp.service` (from this backup)
4. Enable systemd service: `sudo systemctl enable fix-audioout-cdsp`
5. Import database settings: `sqlite3 /var/local/www/db/moode-sqlite3.db < restore-db.sql`
6. Copy CamillaDSP filters to `/usr/share/camilladsp/configs/`
7. Reboot: `sudo reboot`

## Testing Checklist
- [ ] Boot screen displays correctly (1280x400 landscape)
- [ ] moOde UI loads correctly (1280x400 landscape)
- [ ] Touch calibration works correctly
- [ ] Audio plays through HiFiBerry (not HDMI)
- [ ] MPD volume control works (0-100%)
- [ ] CamillaDSP is active (check in moOde UI)
- [ ] AirPlay visible on network (check iPhone)
- [ ] Volume limits are safe (max 30% MPD on first test)

## Important Notes
1. **ALWAYS distinguish between custom build and download image!**
2. **This is a DOWNLOAD image with manual configurations applied**
3. **The custom build (hifiberry-os/imgbuild) is separate and different**
4. **worker.php bug workaround is critical for audio stability**
5. **Volume control must use Digital mixer, not Analogue**
6. **cmdline.txt video parameter must always be 1280x400**

## References
- moOde Audio: https://moodeaudio.org/
- HiFiBerry AMP100: https://www.hifiberry.com/
- CamillaDSP: https://github.com/HEnquist/camilladsp
- Knowledge Base: `/Users/andrevollmer/moodeaudio-cursor/WISSENSBASIS/`
