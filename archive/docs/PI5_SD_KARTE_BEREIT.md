# ✅ PI5 SD-KARTE KONFIGURIERT

**Datum:** 2025-11-30  
**Status:** ✅ **BEREIT FÜR PI5!**  
**Hardware:** Raspberry Pi 5  
**Display:** Waveshare 7.9" HDMI LCD (1280x400 Landscape)  
**OS:** Moode Audio

---

## 🎯 KONFIGURIERTE EINSTELLUNGEN

### `/boot/firmware/config.txt`

```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
disable_fw_kms_setup=0
hdmi_enable_4kp60=0

[all]
dtoverlay=vc4-kms-v3d
hdmi_group=2
hdmi_mode=87
hdmi_cvt 1280 400 60 6 0 0 0
hdmi_drive=2
hdmi_force_hotplug=1
dtparam=i2c_arm=on
dtparam=i2s=on
force_eeprom_read=0
```

### `/boot/firmware/cmdline.txt`

```
console=serial0,115200 console=tty1 root=PARTUUID=e77cf027-02 rootfstype=ext4 fsck.repair=yes rootwait video=HDMI-A-2:400x1280M@60,rotate=90 consoleblank=0 cfg80211.ieee80211_regdom=DE
```

---

## 🔄 NACH DEM BOOTEN AUF PI5

### 1. Moode-DB Einstellungen

```bash
sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='portrait' WHERE param='hdmi_scn_orient';"
sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='1' WHERE param='local_display';"
sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='0' WHERE param='peppy_display';"
```

### 2. `.xinitrc` (Standard Moode)

Die Standard `.xinitrc` führt automatisch die Rotation durch, wenn `hdmi_scn_orient=portrait` gesetzt ist.

**Wichtig für Pi5:**
- HDMI-Output ist `HDMI-2` (statt `HDMI-1` auf Pi4)
- `.xinitrc` verwendet automatisch `HDMI-1` oder `HDMI-2` basierend auf dem System

### 3. Touchscreen (falls USB-Touchscreen erkannt wird)

```bash
export DISPLAY=:0
xinput map-to-output <touch-ID> HDMI-2
xinput set-prop <touch-ID> "Coordinate Transformation Matrix" -1 0 1 0 -1 1 0 0 1
```

---

## ✅ ERWARTETES ERGEBNIS

- **Display:** 1280x400 Landscape (rotated left)
- **Chromium:** `--window-size=1280,400` (korrekt!)
- **Service:** `localdisplay.service` aktiv
- **Web UI:** Funktioniert!

---

## 📝 UNTERSCHIEDE ZU PI4

| Einstellung | Pi4 | Pi5 |
|------------|-----|-----|
| HDMI Port | `HDMI-A-1` | `HDMI-A-2` |
| xrandr Output | `HDMI-1` | `HDMI-2` |
| KMS Overlay | `vc4-kms-v3d-pi4,noaudio` | `vc4-kms-v3d-pi5,noaudio` |

---

**Status:** ✅ **SD-KARTE BEREIT FÜR PI5!**

