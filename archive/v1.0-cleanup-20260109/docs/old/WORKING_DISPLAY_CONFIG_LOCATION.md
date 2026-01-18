# 🎯 WORKING DISPLAY CONFIG - EXACT LOCATION

## ✅ CONFIRMED WORKING CONFIGURATION

**File:** `DISPLAY_CONFIG_WORKING.md`  
**Status:** ✅ CONFIRMED WORKING - Landscape mode (1280x400)  
**Date:** 2025-01-27

---

## 📁 Files That Need This Configuration

### 1. `/boot/firmware/config.txt`
```
hdmi_group=0
```

**Location in backup:** `moode-working-backup/bootfs-backup/bootfs/config.txt`  
**Current backup has:** `hdmi_group=0` ✅

### 2. `/boot/firmware/cmdline.txt`
```
video=HDMI-A-1:400x1280M@60,rotate=90
```

**Location in backup:** `moode-working-backup/bootfs-backup/bootfs/cmdline.txt`  
**Status:** Need to check if this is in backup

### 3. `/home/andre/.xinitrc`
**Critical settings:**
- `SCREEN_RES="1280,400"`
- Xrandr rotation sequence (see DISPLAY_CONFIG_WORKING.md lines 48-56)
- Chromium launch flags (see DISPLAY_CONFIG_WORKING.md lines 65-77)

**Location:** Not in backup (user home directory)

### 4. moOde Database
```sql
UPDATE cfg_system SET value='portrait' WHERE param='hdmi_scn_orient';
```

**Location in backup:** `moode-working-backup/var/local/www/db/moode-sqlite3.db`  
**Status:** Database file should be in backup

---

## 📋 Complete Configuration Reference

**See:** `DISPLAY_CONFIG_WORKING.md` (lines 1-143)

**Key points:**
- Hardware: 400x1280 portrait (Waveshare 7.9" HDMI)
- Target: 1280x400 landscape
- Kernel rotation: `rotate=90` in cmdline.txt
- X11 rotation: `xrandr --rotate left` after setting mode to 400x1280
- Chromium: `--window-size="1280,400"`

---

## 🔍 Where to Find Each File

1. **config.txt:** ✅ In backup at `moode-working-backup/bootfs-backup/bootfs/config.txt`
2. **cmdline.txt:** Need to check backup
3. **.xinitrc:** Not in backup (user home directory, created at runtime)
4. **Database:** ✅ In backup at `moode-working-backup/var/local/www/db/`

---

**This is the ONLY confirmed working configuration!**

