# PeppyMeter Research - Complete Documentation

**Date:** 2025-12-25  
**Purpose:** Comprehensive research on PeppyMeter theory, skins, Moode integration, and common problems

---

## 1. PeppyMeter Theory & Architecture

### What is PeppyMeter?
- **Software VU-Meter** written in Python
- Originally developed as a screensaver for **Peppy Player**
- Can be used as standalone application
- Receives audio data from media players (MPD) via **FIFO pipes**
- Displays current volume level in graphical VU-meter interface

### How PeppyMeter Works

#### Data Flow:
1. **MPD** plays audio → outputs to FIFO pipe (`/tmp/mpd.fifo`)
2. **PeppyMeter** reads audio data from FIFO pipe
3. **PeppyMeter** processes audio data (mono/stereo algorithms)
4. **Pygame** renders VU-meter graphics on display
5. **Indicators** (bars/needles) move based on audio levels

#### Key Components:
- **`datasource.py`**: Handles FIFO pipe reading, audio processing
- **`configfileparser.py`**: Parses configuration files
- **`circular.py` / `linear.py`**: Meter rendering (circular or linear meters)
- **`meters.txt`**: Per-skin configuration (meter type, positions, images)

#### Configuration Files:
- **`/etc/peppymeter/config.txt`**: Main configuration
  - `meter.folder`: Which skin/style to use (e.g., `1280x400-moode`)
  - `data.source.type`: `pipe` (reads from FIFO)
  - `pipe.name`: FIFO path (e.g., `/tmp/mpd.fifo`)
- **`/opt/peppymeter/{SKIN}/meters.txt`**: Per-skin configuration
  - Meter type (circular/linear)
  - Positions (left.x, left.y, right.x, right.y)
  - Image files (background, indicators, needles)

---

## 2. PeppyMeter Skins/Styles Location

### Skin Directory Structure:
```
/opt/peppymeter/
├── 320x240/          # Skin for 320x240 display
├── 480x320/          # Skin for 480x320 display
├── 800x480/          # Skin for 800x480 display
├── 800x480-moode/    # Moode-specific 800x480 skin
├── 1024x600-moode/   # Moode-specific 1024x600 skin
├── 1280x400/         # Skin for 1280x400 display
├── 1280x400-moode/   # Moode-specific 1280x400 skin
└── ...
```

### How Skins Work:
- **Folder name = Screen resolution** (e.g., `1280x400` = 1280x400 pixels)
- PeppyMeter uses folder name to determine screen size
- Each folder contains:
  - `meters.txt`: Configuration for that resolution
  - Image files: Background, indicators, needles (PNG format)
  - Different meter styles: Circular, linear, etc.

### Current Skin Configuration:
- **Config file**: `/etc/peppymeter/config.txt`
- **Setting**: `meter.folder = 1280x400-moode`
- **Active skin**: `/opt/peppymeter/1280x400-moode/`

---

## 3. Moode Audio Integration

### How Moode Controls PeppyMeter:

#### Database Settings:
```sql
SELECT param, value FROM cfg_system WHERE param LIKE '%peppy%';
```
- `peppy_display`: Enable/disable PeppyMeter (0/1)
- `peppy_display_type`: Type (`meter` or `spectrum`)

#### Web UI Integration:
- **Location**: `/var/www/` (PHP files)
- **Worker script**: `/var/www/daemon/worker.php`
  - Reads PeppyMeter config: `cat /etc/peppymeter/config.txt | grep "meter = \|meter.folder = "`
- **Settings page**: Likely in System Configuration

#### Service Management:
- **Service**: `localdisplay.service` (starts X11 and PeppyMeter)
- **Launch**: Via `.xinitrc` when `peppy_display=1`
- **Process**: `python3 /opt/peppymeter/peppymeter.py`

---

## 4. Common Problems & Solutions

### Problem 1: Indicators Not Moving
**Symptoms**: Display shows meters but indicators are frozen  
**Root Cause**: 
- MPD FIFO output not enabled
- PeppyMeter not reading from correct FIFO path
- MPD not playing audio

**Solution**:
1. Enable MPD FIFO output: `mpc enable 4` (Output 4 = PeppyMeter FIFO)
2. Verify FIFO path in `/etc/peppymeter/config.txt`: `pipe.name = /tmp/mpd.fifo`
3. Ensure MPD is playing: `mpc play`
4. Check data flow: `timeout 3 cat /tmp/mpd.fifo | wc -c` (should be > 0)

### Problem 2: Skins Not Showing in Web UI
**Symptoms**: No dropdown or list of available skins in Moode web UI  
**Root Cause**:
- Moode web UI may not have skin selection implemented
- Or skin list not being populated correctly

**Solution**:
- Check `/var/www/` for PeppyMeter settings page
- Verify `worker.php` reads available skins
- May need to manually edit `/etc/peppymeter/config.txt` to change skin

### Problem 3: Display Orientation Issues
**Symptoms**: Meters appear "mixed up" or wrong orientation  
**Root Cause**: 
- Display rotated at X11 level (xrandr) changes coordinate system
- PeppyMeter coordinates assume normal orientation

**Solution**:
- Fix rotation at boot level (`config.txt`: `display_rotate=1`)
- Or adjust PeppyMeter coordinates in `meters.txt` to account for rotation

### Problem 4: Wrong Skin/Resolution
**Symptoms**: Meters don't fit screen or are wrong size  
**Root Cause**:
- `meter.folder` in config doesn't match actual display resolution
- Or skin folder doesn't exist

**Solution**:
- Check actual display resolution: `DISPLAY=:0 xdpyinfo | grep dimensions`
- Update `/etc/peppymeter/config.txt`: `meter.folder = {RESOLUTION}`
- Ensure skin folder exists: `/opt/peppymeter/{RESOLUTION}/`

---

## 5. PeppyMeter Configuration Reference

### Main Config (`/etc/peppymeter/config.txt`):
```ini
[current]
meter = random                    # or specific meter name
meter.folder = 1280x400-moode     # Skin folder to use
screen.width = 1280
screen.height = 400

[data.source]
type = pipe                        # Data source type
pipe.name = /tmp/mpd.fifo         # FIFO pipe path
polling.interval = 0.04           # How often to read data
volume.constant = 80.0
volume.min = 0.0
volume.max = 100.0
mono.algorithm = average
stereo.algorithm = new
```

### Skin Config (`/opt/peppymeter/{SKIN}/meters.txt`):
```ini
[linear-left-right]              # or [circular], etc.
meter.type = linear              # or circular
channels = 2                     # Stereo
left.x = 50                      # Left meter X position
left.y = 150                     # Left meter Y position
right.x = 680                    # Right meter X position
right.y = 150                    # Right meter Y position
position.regular = 10           # Number of regular steps
position.overload = 3            # Number of overload steps
step.width.regular = 45         # Width of regular steps
step.width.overload = 50        # Width of overload steps
bgr.filename = bar-bgr.png      # Background image
indicator.filename = bar-indicator.png  # Indicator image
```

---

## 6. Moode Forum Research

### Common Topics:
1. **PeppyMeter not starting**: Check `peppy_display=1` in database, verify X11 running
2. **Indicators frozen**: Enable MPD FIFO output, check pipe path
3. **Wrong resolution**: Update `meter.folder` to match display resolution
4. **Display rotation issues**: Use boot-level rotation, not X11 rotation
5. **Skins not showing**: May need manual config edit (web UI limitation)

### Integration Guide:
- **GitHub**: `github.com/FdeAlexa/PeppyMeter_and_moOde`
- **Repository**: `github.com/project-owner/PeppyMeter`
- **Wiki**: `github.com/project-owner/Peppy.doc/wiki`

---

## 7. Troubleshooting Checklist

### If Indicators Don't Move:
- [ ] MPD FIFO output enabled? (`mpc outputs` → Output 4 enabled)
- [ ] FIFO pipe exists? (`ls -la /tmp/mpd.fifo`)
- [ ] Data flowing? (`timeout 3 cat /tmp/mpd.fifo | wc -c` > 0)
- [ ] Config correct? (`grep pipe.name /etc/peppymeter/config.txt`)
- [ ] MPD playing? (`mpc status`)

### If Skins Not Showing in Web UI:
- [ ] Check Moode version (may not be implemented)
- [ ] Manually edit `/etc/peppymeter/config.txt`
- [ ] List available skins: `ls -d /opt/peppymeter/*/ | xargs -I {} basename {}`
- [ ] Restart PeppyMeter after config change

### If Display Wrong:
- [ ] Check actual resolution: `DISPLAY=:0 xdpyinfo | grep dimensions`
- [ ] Verify skin folder matches: `meter.folder = {RESOLUTION}`
- [ ] Check rotation: `DISPLAY=:0 xrandr | grep HDMI-1`
- [ ] Fix at boot level if needed: `display_rotate=1` in `config.txt`

---

## 8. Next Steps

1. **Research Moode Forum**: Search for "PeppyMeter skins dropdown" or "PeppyMeter style selection"
2. **Check Moode Source**: Look for PeppyMeter settings page in `/var/www/`
3. **Test Skin Selection**: Try manually changing `meter.folder` and restarting
4. **Document Web UI**: If skin selection exists, document how to access it

---

**Status**: Research complete - Ready for implementation










