# Ghettoblaster Version 1.0 - Working Configuration

**Date:** 2026-01-08
**Base:** moOde Audio Player Series 10, Release 10.0.3 (2025-12-28)
**OS:** Debian GNU/Linux 13 (trixie) 64-bit
**Kernel:** 6.12.47+rpt-rpi-2712

---

## Hardware

| Component | Model | Notes |
|-----------|-------|-------|
| **SBC** | Raspberry Pi 5B 8GB | |
| **Display** | Waveshare 7.9" HDMI | 400x1280 native (portrait), rotated to 1280x400 landscape |
| **Touch** | WaveShare USB Touch | USB HID multitouch (NOT I2C FT6236) |
| **Audio** | HiFiBerry AMP100 | I2S DAC+Amplifier |
| **Network** | Ethernet / WiFi | GhettoLAN via Mac Internet Sharing |

---

## Critical Configuration Files

### 1. /boot/firmware/config.txt
```ini
# Key settings for Ghettoblaster:
dtoverlay=vc4-kms-v3d,noaudio    # Disable HDMI audio
dtparam=audio=off                 # Disable onboard audio
dtoverlay=hifiberry-amp100        # Enable HiFiBerry AMP100
dtoverlay=ft6236                  # Touch overlay (may not be needed for USB touch)
hdmi_group=0                      # Auto-detect HDMI
hdmi_force_hotplug=1              # Force HDMI detection
```

### 2. /boot/firmware/cmdline.txt
```
console=tty3 root=PARTUUID=XXXXXX-02 rootfstype=ext4 fsck.repair=yes rootwait quiet loglevel=3 video=HDMI-A-1:400x1280M@60,rotate=90
```
**IMPORTANT:** The `video=HDMI-A-1:400x1280M@60,rotate=90` parameter is CRITICAL for display.
- Uses native portrait resolution 400x1280
- rotate=90 rotates at kernel level
- moOde's xinitrc then applies xrandr rotation for X11

### 3. Display Configuration

**Why it works:**
1. Kernel sees 400x1280 with rotate=90 in cmdline.txt
2. moOde reads `hdmi_scn_orient` from database
3. When `hdmi_scn_orient = "portrait"`, moOde's xinitrc runs `xrandr --output HDMI-1 --rotate left`
4. Final result: 1280x400 landscape display

**Database setting:**
```sql
UPDATE cfg_system SET value='portrait' WHERE param='hdmi_scn_orient';
```
Note: "portrait" means the HARDWARE is portrait, so moOde rotates it to landscape!

### 4. Touch Calibration

**File:** `/etc/X11/xorg.conf.d/99-touch-calibration.conf`
```
Section "InputClass"
    Identifier "WaveShare Touchscreen"
    MatchProduct "WaveShare"
    Option "TransformationMatrix" "0 -1 1 1 0 0 0 0 1"
EndSection
```
This matrix rotates touch input to match the rotated display.

### 5. Audio Chain

```
MPD → _audioout → peppy → softvol → peppyalsa → _peppyout → hw:0,0 (HiFiBerry)
                              ↓
                    /tmp/peppymeter (VU data for PeppyMeter)
```

**Files:**

**/etc/alsa/conf.d/_audioout.conf:**
```
pcm._audioout {
    type plug
    slave.pcm "peppy"
}
```

**/etc/alsa/conf.d/_peppyout.conf:**
```
pcm._peppyout {
    type hw
    card 0
    device 0
}
```

**/etc/alsa/conf.d/peppy.conf:** (managed by moOde, may need manual fix)
- Change `card empty` to `card 0`
- Change `name "Digital"` to `name "PCM"` if needed

### 6. Network

**SSH:** User `andre`, Password `0815`
**Ethernet:** DHCP via Mac Internet Sharing (192.168.2.x)
**WiFi:** GhettoLAN (password: 08150815)

---

## Key Services

| Service | Status | Purpose |
|---------|--------|---------|
| localdisplay | enabled | X11 + Chromium kiosk |
| peppymeter | **DISABLED** | VU meter display (enable manually when needed) |
| mpd | enabled | Music Player Daemon |
| nginx | enabled | Web server |

**IMPORTANT:** peppymeter MUST be disabled by default to prevent white screen!

---

## PeppyMeter Notes

**CRITICAL:** PeppyMeter service MUST be disabled by default!
- The peppymeter.service creates a fullscreen overlay window
- Even when `peppy_display=0`, if the SERVICE is running → WHITE SCREEN
- The database setting alone is NOT enough!

**Root cause of white screen:**
- peppymeter.service runs `/opt/peppymeter/peppymeter.py`
- This creates a fullscreen PyGame window (white when no audio data)
- This window overlays Chromium regardless of database settings

**Correct configuration:**
- `peppy_display=0` in database
- `peppymeter.service` DISABLED (not just stopped)
- Result: moOde UI displays correctly

**To enable PeppyMeter (when you want VU meters):**
```bash
# 1. Set database
sudo sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='1' WHERE param='peppy_display';"
# 2. Start service
sudo systemctl start peppymeter
# 3. Restart display
sudo systemctl restart localdisplay
# 4. PLAY AUDIO (otherwise still white!)
```

**To disable PeppyMeter (show moOde UI):**
```bash
# Set database
sudo sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='0' WHERE param='peppy_display';"
sudo sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='1' WHERE param='local_display';"
# Restart display
sudo systemctl restart localdisplay
```

---

## PeppyMeter Configuration (Working)

**Config file:** `/etc/peppymeter/config.txt`

**Key settings:**
```ini
[current]
meter = blue
meter.folder = 1280x400
screen.width = 1280
screen.height = 400
exit.on.touch = True
mouse.enabled = True
```

**Database settings:**
```sql
peppy_display = 1    -- Enable PeppyMeter
local_display = 0    -- Disable web UI (PeppyMeter takes over)
peppy_meter = blue   -- Blue VU meter theme
```

**Touch to switch flow:**
1. PeppyMeter shows blue VU meters fullscreen
2. User touches screen → PeppyMeter exits
3. xinitrc continues to launch Chromium (moOde UI)
4. moOde web UI appears

**Modified xinitrc:** Added Chromium launch after PeppyMeter exits in `/home/andre/.xinitrc`

---

## Recovery Procedure

### If display doesn't work:
1. Check cmdline.txt has `video=HDMI-A-1:400x1280M@60,rotate=90`
2. Check moOde DB: `hdmi_scn_orient` must be `portrait`
3. Restart: `sudo systemctl restart localdisplay`

### If audio doesn't work:
1. Check `aplay -l` shows only HiFiBerry (card 0)
2. Check config.txt has `dtparam=audio=off` and `vc4-kms-v3d,noaudio`
3. Fix ALSA configs if needed (_audioout.conf, _peppyout.conf)

### If touch doesn't work:
1. Check `/etc/X11/xorg.conf.d/99-touch-calibration.conf` exists
2. Apply runtime: `DISPLAY=:0 xinput set-prop "WaveShare WaveShare" "Coordinate Transformation Matrix" 0 -1 1 1 0 0 0 0 1`

### If white screen:
1. **STOP PeppyMeter service:** `sudo systemctl stop peppymeter`
2. **Disable it:** `sudo systemctl disable peppymeter`
3. Set database: `sudo sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='0' WHERE param='peppy_display';"`
4. Restart display: `sudo systemctl restart localdisplay`

**Root cause:** PeppyMeter service creates fullscreen overlay even when database says disabled!

---

## Files to Backup for Full Restore

**All backed up to:** `backups/v1.0-2026-01-08/`

1. `/boot/firmware/config.txt` → `config.txt`
2. `/boot/firmware/cmdline.txt` → `cmdline.txt`
3. `/etc/alsa/conf.d/_audioout.conf` → `_audioout.conf`
4. `/etc/alsa/conf.d/_peppyout.conf` → `_peppyout.conf`
5. `/etc/alsa/conf.d/peppy.conf` → `peppy.conf`
6. `/etc/X11/xorg.conf.d/99-touch-calibration.conf` → `99-touch-calibration.conf`
7. `/etc/peppymeter/config.txt` → `peppymeter-config.txt`
8. `/home/andre/.xinitrc` → `xinitrc`

**Database settings to restore:**
```sql
UPDATE cfg_system SET value='portrait' WHERE param='hdmi_scn_orient';
UPDATE cfg_system SET value='0' WHERE param='peppy_display';  -- moOde UI default (stable)
UPDATE cfg_system SET value='1' WHERE param='local_display';  -- Enable web UI
UPDATE cfg_system SET value='blue' WHERE param='peppy_meter';
UPDATE cfg_system SET value='meter' WHERE param='peppy_display_type';
```

**Boot config (cmdline.txt):**
```
console=tty3 root=PARTUUID=XXXXXX-02 rootfstype=ext4 fsck.repair=yes rootwait quiet loglevel=3 video=HDMI-A-1:400x1280M@60,rotate=90 logo.nologo vt.global_cursor_default=0
```
- `logo.nologo` - No Raspberry Pi logo
- `vt.global_cursor_default=0` - No cursor

---

## Version History

- **1.0** (2026-01-08): First stable working version
  - Display: 1280x400 landscape ✅
  - Audio: HiFiBerry AMP100 only ✅
  - Touch: Calibrated for rotation ✅
  - PeppyMeter: Configured (disabled by default) ✅

