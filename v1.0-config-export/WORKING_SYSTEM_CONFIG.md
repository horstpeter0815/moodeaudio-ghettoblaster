# Working System Configuration
**Date:** 2026-01-18  
**Status:** ✅ **ALL WORKING**

## Complete Working Configuration

### 1. Touch Calibration
**File:** `/etc/X11/xorg.conf.d/99-calibration.conf`
```ini
Section "InputClass"
    Identifier "calibration"
    MatchProduct "FT6236|ft6236|WaveShare|touchscreen"
    Driver "libinput"
    Option "Calibration" "0 1280 0 400"
    Option "TransformationMatrix" "0 -1 1 1 0 0 0 0 1"
EndSection
```
**Key:** TransformationMatrix for 90° left rotation

### 2. Boot Configuration
**File:** `/boot/firmware/config.txt`
- `dtoverlay=hifiberry-amp100`
- `dtoverlay=vc4-kms-v3d-pi5,noaudio`
- `dtparam=audio=off`

**File:** `/boot/firmware/cmdline.txt`
- `video=HDMI-A-1:1280x400@60`

### 3. Audio Configuration
**ALSA:** `/etc/alsa/conf.d/_audioout.conf`, `_peppyout.conf`
- Routes to HiFiBerry AMP100 (card 0)

**moOde Database:**
- cardnum: 0
- i2sdevice: HiFiBerry AMP100
- volume_control: software

### 4. Display Configuration
**File:** `/home/andre/.xinitrc`
- Rotates display to 1280x400 landscape
- Starts Chromium in kiosk mode

### 5. PeppyMeter
**File:** `/etc/peppymeter/config.txt`
- screen.width = 1280
- screen.height = 400

## System Status
✅ Audio: HiFiBerry AMP100 (card 0)  
✅ Display: 1280x400 landscape  
✅ Touch: Working with TransformationMatrix  
✅ Web UI: http://192.168.2.3  
✅ Chromium: Kiosk mode, no popups

**Everything is working and saved in v1.0-config-export/**
