# Pi 4 SD-Karte - Konfiguration Abgeschlossen

**Datum:** 30. November 2025  
**Status:** ✅ SD-Karte bereit für Pi 4

---

## ✅ KONFIGURIERT

### config.txt
- ✅ `[pi4]` Sektion mit `dtoverlay=vc4-kms-v3d-pi4,noaudio`
- ✅ HDMI Konfiguration: `hdmi_group=2`, `hdmi_mode=87`, `hdmi_cvt 1280 400 60 6 0 0 0`
- ✅ I2C aktiviert: `dtparam=i2c_arm=on`
- ✅ Waveshare 7.9" Display Support

### cmdline.txt
- ✅ `video=HDMI-A-1:400x1280M@60,rotate=90` (Pi 4 verwendet HDMI-A-1)
- ✅ `consoleblank=0`

---

## 🚀 NÄCHSTE SCHRITTE

### 1. SD-Karte auswerfen
```bash
diskutil eject /Volumes/bootfs
```

### 2. SD-Karte in Pi 4 einstecken und booten

### 3. Nach Boot: .xinitrc anpassen
Siehe: `FORUM_SOLUTION_7.9_DISPLAY.md`

**Wichtig für Pi 4:**
- HDMI Port: `HDMI-1` (nicht HDMI-2)
- xrandr: `DISPLAY=:0 xrandr --output HDMI-1 --rotate left`
- SCREENSIZE Swap: `$3,$2` statt `$2,$3`

---

## 📋 UNTERSCHIEDE ZU PI 5

| Setting | Pi 4 | Pi 5 |
|---------|------|------|
| KMS Overlay | `vc4-kms-v3d-pi4` | `vc4-kms-v3d-pi5` |
| HDMI Port | `HDMI-A-1` | `HDMI-A-2` |
| xrandr Output | `HDMI-1` | `HDMI-2` |
| Device Tree | `/soc/...` | `/axi/...` |

---

## ✅ BACKUP

Backup erstellt in: `/Volumes/bootfs/backup-20251130-125636/`

---

**Status:** ✅ SD-Karte bereit für Pi 4!

