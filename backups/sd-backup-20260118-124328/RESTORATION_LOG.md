# SD Card Restoration Log

**Date:** January 18, 2026 12:43  
**Source:** git commit `84aa8c2` (Version 1.0 - Ghettoblaster working configuration)

---

## Files Restored

### cmdline.txt
**Content:**
```
console=tty3 root=PARTUUID=6944cf5f-02 rootfstype=ext4 fsck.repair=yes rootwait quiet loglevel=3 video=HDMI-A-1:400x1280M@60,rotate=90 logo.nologo vt.global_cursor_default=0
```

**Key Parameter:** `video=HDMI-A-1:400x1280M@60,rotate=90`
- This fixes the white screen issue at boot
- Sets framebuffer to 400x1280 rotated 90° = 1280x400 landscape

### config.txt
**Device Tree Overlays:**
- `dtoverlay=vc4-kms-v3d,noaudio` - Display controller, HDMI audio disabled
- `dtoverlay=hifiberry-amp100` - Audio DAC (PCM5122)
- `dtoverlay=ft6236` - Touch controller

**Critical Settings:**
- `arm_boost=0` (from v1.0)
- `dtparam=audio=off` - Onboard audio disabled
- `dtparam=i2c_arm=on` - I2C enabled
- `dtparam=i2s=on` - I2S enabled

---

## Expected Results After Boot

### Display
- ✅ Boot screen: Landscape 1280x400, **no white screen**
- ✅ Console visible during boot
- ✅ moOde UI loads correctly
- ✅ Display orientation: landscape (wide, not tall)

### Touch
- ✅ Touch controller detected (I2C 0x38)
- ✅ Coordinates mapped to 1280x400
- ✅ Touch responds correctly

### Audio
- ⚠️ May need moOde database fixes:
  ```sql
  UPDATE cfg_system SET value='plughw' WHERE param='alsa_output_mode';
  UPDATE cfg_system SET value='hardware' WHERE param='volume_type';
  ```
- ✅ Hardware should be detected (I2C 0x4d)
- ✅ ALSA card: sndrpihifiberry

---

## Backup Location

**Directory:** `/Users/andrevollmer/moodeaudio-cursor/backups/sd-backup-20260118-124328/`

**Files backed up:**
- `cmdline.txt.bak` - Previous cmdline.txt
- `config.txt.bak` - Previous config.txt

---

## Restoration Process

1. ✅ SD card mounted at `/Volumes/bootfs`
2. ✅ Extracted v1.0 files from git commit `84aa8c2`
3. ✅ Backed up current files to timestamped directory
4. ✅ Copied v1.0 cmdline.txt to SD card
5. ✅ Copied v1.0 config.txt to SD card
6. ✅ Verified restoration:
   - cmdline.txt has `video=` parameter
   - config.txt has all 3 overlays
   - arm_boost setting present

---

## Verification Commands (on Pi after boot)

### Display
```bash
# Check framebuffer resolution
cat /sys/class/graphics/fb0/virtual_size
# Should show: 1280,400

# Check X11 display
DISPLAY=:0 xrandr | grep connected
# Should show: 1280x400
```

### Audio
```bash
# Check I2C device
i2cdetect -y 1
# Should show: 0x4d (PCM5122)

# Check ALSA card
cat /proc/asound/cards
# Should show: sndrpihifiberry

# Check moOde database
sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT param, value FROM cfg_system WHERE param IN ('alsa_output_mode', 'volume_type');"
```

### Touch
```bash
# Check I2C device
i2cdetect -y 1
# Should show: 0x38 (FT6236)

# Check input devices
cat /proc/bus/input/devices | grep -A 5 "ft6236"
```

---

## Rollback Instructions

If this configuration doesn't work:

```bash
# Re-insert SD card in Mac
# Restore backup files:
cp /Users/andrevollmer/moodeaudio-cursor/backups/sd-backup-20260118-124328/cmdline.txt.bak /Volumes/bootfs/cmdline.txt
cp /Users/andrevollmer/moodeaudio-cursor/backups/sd-backup-20260118-124328/config.txt.bak /Volumes/bootfs/config.txt
sync
diskutil eject /Volumes/bootfs
```

---

## Post-Boot Fixes (if needed)

### If Audio Doesn't Work

Run on Pi via SSH or WebSSH:
```bash
sudo sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='plughw' WHERE param='alsa_output_mode';"
sudo sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='hardware' WHERE param='volume_type';"
sudo systemctl restart mpd
```

### If Display Rotation Wrong

Check `.xinitrc`:
```bash
cat /home/andre/.xinitrc
# Should use moOde default that reads from database
```

---

## Success Criteria

- [x] cmdline.txt has `video=HDMI-A-1:400x1280M@60,rotate=90`
- [x] config.txt has `vc4-kms-v3d,noaudio`
- [x] config.txt has `hifiberry-amp100`
- [x] config.txt has `ft6236`
- [x] Backup created
- [x] Files verified on SD card
- [ ] Pi boots successfully (to be verified)
- [ ] Display shows correctly (to be verified)
- [ ] Touch works (to be verified)
- [ ] Audio works (may need database fix)

---

## References

- **Git commit:** `84aa8c2` (Version 1.0 - Ghettoblaster working configuration)
- **Date of v1.0:** January 8, 2026
- **Device Tree Study:** [DEVICE_TREE_MASTER_REFERENCE.md](/Users/andrevollmer/moodeaudio-cursor/WISSENSBASIS/DEVICE_TREE_MASTER_REFERENCE.md)
- **Lessons Learned:** [LESSONS_LEARNED.md](/Users/andrevollmer/moodeaudio-cursor/LESSONS_LEARNED.md)

---

**Status:** Restoration complete. SD card ready for Pi boot.  
**Next step:** Eject SD card, insert in Pi, power on, and verify.
