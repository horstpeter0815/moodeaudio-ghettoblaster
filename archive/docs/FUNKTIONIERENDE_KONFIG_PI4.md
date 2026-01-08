# ✅ FUNKTIONIERENDE KONFIGURATION - Pi 4

**Datum:** 2025-11-30  
**Status:** ✅ **FUNKTIONIERT!**  
**Hardware:** Raspberry Pi 4 Model B  
**Display:** Waveshare 7.9" HDMI LCD (1280x400 Landscape)  
**OS:** Moode Audio 10.0.0

---

## 🎯 ZUSAMMENFASSUNG

Die Lösung verwendet **Moode's native Rotation-Logik** durch Setzen von `hdmi_scn_orient=portrait` in der Moode-Datenbank. Die Standard `.xinitrc` führt dann automatisch die Rotation durch.

---

## ✅ FUNKTIONIERENDE EINSTELLUNGEN

### 1. Moode Datenbank-Einstellungen

```sql
hdmi_scn_orient = 'portrait'
local_display = '1'
peppy_display = '0'
```

**Befehl zum Setzen:**
```bash
sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='portrait' WHERE param='hdmi_scn_orient';"
sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='1' WHERE param='local_display';"
sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='0' WHERE param='peppy_display';"
```

### 2. `/home/andre/.xinitrc`

**Status:** ✅ **Standard Moode .xinitrc + Touchscreen-Konfiguration**

Die Standard `.xinitrc` enthält bereits die Rotation-Logik:
```bash
if [ $DSI_SCN_TYPE = 'none' ]; then
    if [ $HDMI_SCN_ORIENT = "portrait" ]; then
        SCREEN_RES=$(echo $SCREEN_RES | awk -F"," '{print $2","$1}')
        DISPLAY=:0 xrandr --output HDMI-1 --rotate left
    fi
fi
```

**Touchscreen-Konfiguration (hinzugefügt):**
```bash
# Touchscreen: 180° Inversion (beide Achsen)
export DISPLAY=:0
sleep 2
xinput set-prop 7 "Coordinate Transformation Matrix" -1 0 1 0 -1 1 0 0 1 2>/dev/null || true
xinput set-prop 8 "Coordinate Transformation Matrix" -1 0 1 0 -1 1 0 0 1 2>/dev/null || true
```

**Touchscreen-Geräte:**
- `vc4-hdmi-0` (ID 7) - USB-Touchscreen wird als HDMI-CEC erkannt
- `vc4-hdmi-1` (ID 8) - USB-Touchscreen wird als HDMI-CEC erkannt
- **Matrix:** `-1 0 1 0 -1 1 0 0 1` (180° Inversion, beide Achsen)
- **Hinweis:** Der USB-Touchscreen wird nicht als separates Gerät erkannt, sondern als `vc4-hdmi-0/1`. Die Matrix muss für beide Geräte gesetzt werden.

### 3. `/boot/firmware/config.txt`

```ini
[pi4]
dtoverlay=vc4-kms-v3d-pi4,noaudio
hdmi_group=2
hdmi_mode=87
hdmi_cvt 1280 400 60 6 0 0 0
dtparam=i2c_arm=on
dtparam=i2s=on
dtparam=audio=on
force_eeprom_read=0
```

### 4. `/boot/firmware/cmdline.txt`

```
console=serial0,115200 console=tty1 root=PARTUUID=... video=HDMI-A-1:400x1280M@60,rotate=90 consoleblank=0 ...
```

---

## 🔄 WIE ES FUNKTIONIERT

1. **Kernel-Level:** `cmdline.txt` startet Display im Portrait-Modus (400x1280)
2. **X11-Level:** `.xinitrc` liest `hdmi_scn_orient=portrait` aus Moode-DB
3. **Rotation:** `xrandr --output HDMI-1 --rotate left` rotiert zu 1280x400 Landscape
4. **SCREEN_RES Swap:** `SCREEN_RES` wird von `400,1280` zu `1280,400` getauscht
5. **Chromium:** Startet mit `--window-size=1280,400` (korrekt!)

---

## ✅ ERGEBNIS

- **Display:** `1280x400+0+0 left` (Landscape, rotiert)
- **Chromium:** `--window-size=1280,400` (korrekt!)
- **Touchscreen:** 180° Inversion (beide Achsen) - vc4-hdmi-0/1
- **Service:** `localdisplay.service` aktiv
- **Web UI:** Funktioniert!

---

## 🔧 WIEDERHERSTELLUNG

Falls die Konfiguration verloren geht:

```bash
# 1. Standard .xinitrc wiederherstellen (falls nötig)
# Siehe RESTORE_STANDARD_CONFIG.sh

# 2. Moode Einstellungen setzen
sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='portrait' WHERE param='hdmi_scn_orient';"
sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='1' WHERE param='local_display';"
sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='0' WHERE param='peppy_display';"

# 3. Service neu starten
sudo systemctl restart localdisplay.service
```

---

## 📝 WICHTIGE PUNKTE

1. ✅ **Keine manuellen .xinitrc Änderungen nötig** - Moode's Standard-Logik reicht!
2. ✅ **`hdmi_scn_orient=portrait`** aktiviert die Rotation in `.xinitrc`
3. ✅ **Touchscreen-Konfiguration** in `.xinitrc` für Persistenz nach Reboot
4. ✅ **Persistent** - Moode-DB-Einstellungen bleiben nach Reboot erhalten
5. ✅ **Touchscreen-Matrix** wird automatisch nach X-Server-Start angewendet

---

**Status:** ✅ **FUNKTIONIERT PERFEKT!**

