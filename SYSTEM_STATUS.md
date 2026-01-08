# moOde Audio System - Current Status

## ✅ Working Components

### Audio System
- **MPD**: Active and playing
- **Audio Chain**: MPD → _audioout → peppy → _peppyout → plughw:0,0 (HiFiBerry DAC+)
- **CamillaDSP**: Configured (bose_wave_filters.yml) - currently off
- **Volume Control**: Hardware mixer (Channels) at ~80%

### Display System
- **PeppyMeter**: Active and displaying correctly
- **Resolution**: 1280x400 (landscape)
- **Orientation Setting**: portrait (correct for PeppyMeter framebuffer access)
- **Normalization**: 70.0 (increased sensitivity)
- **Display**: Clean, no green stripes, indicators moving

### Configuration Files
- **Boot Config**: 
  - `config.txt`: framebuffer_width=1280, framebuffer_height=400, framebuffer_depth=32
  - `cmdline.txt`: video=HDMI-A-1:1280x400M@60, quiet loglevel=3
- **ALSA**: 
  - `_audioout.conf`: points to "peppy"
  - `peppy.conf`: configured with meter plugin
  - `_peppyout.conf`: points to plughw:0,0
- **PeppyMeter**: 
  - Config: `/etc/peppymeter/config.txt`
  - Normalization: `volume.max.in.pipe = 70.0`
  - Config folder: `/opt/peppymeter/1280x400`

## 📝 Key Learnings

### Display Rotation Root Cause
- **Web UI (`hdmi_scn_orient`)**: Only affects X11/Xrandr rotation, NOT boot-level
- **Boot-level rotation**: Separate mechanisms (`display_rotate`, `fbcon rotate`)
- **PeppyMeter**: Reads framebuffer directly, needs correct orientation setting
- **Solution**: Set `hdmi_scn_orient=portrait` for PeppyMeter to access framebuffer correctly

### Audio Chain
- **PeppyMeter ALSA Chain**: MPD → _audioout → peppy → _peppyout → hardware
- **Pipe**: `/tmp/peppymeter` (created by ALSA meter plugin)
- **Symlink**: `/tmp/mpd.fifo` → `/tmp/peppymeter` (PeppyMeter reads from mpd.fifo)

## 🔧 Adjustable Settings

### PeppyMeter Sensitivity
- **Location**: `/etc/peppymeter/config.txt` → `volume.max.in.pipe`
- **Current**: 70.0 (more sensitive)
- **Options**: 100.0 (default) down to 10.0 (extremely sensitive)
- **Web UI**: PeppyMeter Config → Normalization

### Display Orientation
- **Location**: Peripherals Config → Screen Orientation
- **Current**: portrait (correct for PeppyMeter)
- **Note**: Portrait setting gives landscape display due to xinitrc swap logic

## 📊 System Health
- All services running correctly
- Audio and display working perfectly
- Configuration documented and understood

