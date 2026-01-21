# Quick Reference - Display & PeppyMeter

**Status:** ✅ **ALL WORKING**  
**Date:** 2026-01-21

---

## ✅ Everything That's Working

### Display
- **Resolution:** 1280x400 landscape ✅
- **moOde UI:** Displaying correctly ✅
- **Boot Screen:** Will be landscape after reboot ✅

### PeppyMeter
- **Display:** 1280x400 landscape ✅
- **Toggle:** Swipe UP or DOWN ✅
- **Button:** Wave icon (🌊) in moOde UI ✅

---

## How To Use

### Toggle TO PeppyMeter:
```
Click wave icon (🌊) → PeppyMeter shows
```

### Toggle FROM PeppyMeter:
```
Swipe UP or DOWN → moOde UI shows
```

---

## Important Files

### Configuration Files:
```
~/.xinitrc                          - Display initialization
/boot/firmware/cmdline.txt          - Boot screen resolution
/boot/firmware/config.txt           - HDMI timings
/usr/local/bin/peppymeter-swipe-wrapper.py - Gesture detection
```

### Backups:
```
~/.xinitrc.backup-20260120-234128
/boot/firmware/cmdline.txt.backup
/boot/firmware/config.txt.backup2
```

---

## If Display Breaks

### Quick Fix:
```bash
ssh andre@192.168.2.3
export DISPLAY=:0
xrandr --newmode "1280x400_60" 59.51 1280 1390 1422 1510 400 410 420 430 -hsync +vsync
xrandr --addmode HDMI-2 1280x400_60
xrandr --output HDMI-2 --mode 1280x400_60 --rotate normal
sudo systemctl restart localdisplay
```

### Restore from Backup:
```bash
ssh andre@192.168.2.3
cp ~/.xinitrc.backup-20260120-234128 ~/.xinitrc
sudo systemctl restart localdisplay
```

---

## Key Settings

### Database:
```sql
hdmi_scn_orient = 'landscape'
disable_gpu_chromium = 'on'
local_display = '1'  (moOde UI)
peppy_display = '0'  (off)
```

### Display Mode:
```
HDMI-2: 1280x400_60 @ 60Hz
Window: 1280,400
Rotation: normal (no rotation)
```

---

## Troubleshooting

### Black Screen
**Cause:** GPU rendering issue  
**Fix:** Already applied (`--disable-gpu` flag)

### Wrong Orientation  
**Cause:** xrandr mode not applied  
**Fix:** Restart localdisplay service

### PeppyMeter Stuck
**Cause:** Swipe not detected  
**Fix:** Swipe more than 100 pixels vertically

### Boot Screen Portrait
**Cause:** Not rebooted yet  
**Fix:** Reboot to apply cmdline.txt changes

---

## Emergency Commands

### Switch to moOde UI:
```bash
ssh andre@192.168.2.3
sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='1' WHERE param='local_display'; UPDATE cfg_system SET value='0' WHERE param='peppy_display';"
sudo systemctl restart localdisplay
```

### Switch to PeppyMeter:
```bash
ssh andre@192.168.2.3
sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='0' WHERE param='local_display'; UPDATE cfg_system SET value='1' WHERE param='peppy_display';"
sudo systemctl restart localdisplay
```

### Check Display Status:
```bash
ssh andre@192.168.2.3
DISPLAY=:0 xrandr | grep HDMI-2
ps aux | grep chromium | head -1
systemctl status localdisplay
```

---

## Credentials

**SSH:**
```
User: andre
Password: 0815
IP: 192.168.2.3
```

---

**For detailed information, see:** `DISPLAY_AND_PEPPYMETER_FINAL_FIX.md`
