# Configuration Changes Summary
**Date:** 2026-01-18  
**System:** moode audio on Raspberry Pi 5 (192.168.2.3)  
**Status:** ✅ Working Configuration

## Changes Applied

### 1. Boot Configuration

#### `/boot/firmware/config.txt`

**Added:**
- `dtoverlay=hifiberry-amp100` - Enables HiFiBerry AMP100 audio card
- `dtoverlay=vc4-kms-v3d-pi5,noaudio` - Disables HDMI audio on Pi 5
- `dtparam=audio=off` - Disables onboard audio

**Saved as:** `config.txt.working`

#### `/boot/firmware/cmdline.txt`

**Added:**
- `video=HDMI-A-1:1280x400@60` - Sets display resolution to 1280x400 at 60Hz at boot level

**Saved as:** `cmdline.txt.working`

**Key Settings:**
- HDMI audio disabled (noaudio parameter)
- I2S enabled for HiFiBerry
- Display auto-detect enabled
- Overscan disabled
- Video resolution set in cmdline.txt (not config.txt)

### 2. ALSA Audio Configuration

#### `_audioout.conf` (`/etc/alsa/conf.d/_audioout.conf`)
- Routes audio to HiFiBerry AMP100 (card 0, device 0)
- Uses `plug` type for format conversion
- **Saved as:** `_audioout.conf.working`

#### `_peppyout.conf` (`/etc/alsa/conf.d/_peppyout.conf`)
- Direct hardware output to HiFiBerry AMP100
- Used by PeppyMeter for audio visualization
- **Saved as:** `_peppyout.conf.working`

### 3. Display Configuration

#### `.xinitrc` (`/home/andre/.xinitrc`)
- Configures display to 1280x400 landscape mode
- Sets HDMI-1 output with normal rotation
- **Saved as:** `.xinitrc.working`

#### Touch Calibration (`/etc/X11/xorg.conf.d/99-calibration.conf`)
- Calibrates touchscreen for 1280x400 display
- Matches FT6236 touch controller
- **Saved as:** `99-calibration.conf.working`

### 4. PeppyMeter Configuration (`/etc/peppymeter/config.txt`)
- Screen dimensions: 1280x400
- Meter folder: 1280x400
- **Saved as:** `peppymeter-config.txt.working`

## Audio Chain

**Configuration:**
```
MPD → _audioout → HiFiBerry AMP100 (card 0)
```

**Hardware:**
- HiFiBerry AMP100 detected as card 0
- HDMI audio disabled
- Volume set to 30% (safe level)

## moOde Database Settings

**Updated:**
- `cardnum`: 0 (HiFiBerry AMP100)
- `i2sdevice`: HiFiBerry AMP100
- `adevname`: HiFiBerry AMP100

## Services Status

✅ **Running:**
- MPD (Music Player Daemon)
- nginx (Web server)
- php8.4-fpm (PHP processor)
- localdisplay (Display service)

## Verification

**Audio:**
- HiFiBerry AMP100 detected: ✅
- ALSA chain configured: ✅
- moOde database updated: ✅

**Display:**
- X server running: ✅
- 1280x400 configured: ✅
- Touch calibration: ✅

**Web Interface:**
- Accessible at: http://192.168.2.3
- All services running: ✅

## Notes

- All configuration files backed up before changes
- Volume set to safe level (30%)
- System rebooted after config.txt changes
- All fixes verified and working

## Restore Instructions

To restore this working configuration:

1. Copy `config.txt.working` to `/boot/firmware/config.txt`
2. Copy `cmdline.txt.working` to `/boot/firmware/cmdline.txt`
3. Copy ALSA configs to `/etc/alsa/conf.d/`
4. Copy `.xinitrc.working` to `/home/andre/.xinitrc`
5. Copy touch calibration to `/etc/X11/xorg.conf.d/`
6. Reboot system

**Note:** The video parameter is set in `cmdline.txt` (boot command line), NOT in `config.txt`. This ensures the display resolution is set at the earliest boot stage.
