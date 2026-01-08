# HIFIBERRYOS PI 4 - LETZTE VERSUCHE ZUSAMMENFASSUNG

**Datum:** 02.12.2025  
**System:** HiFiBerryOS auf Raspberry Pi 4 (192.168.178.199)  
**Status:** Dokumentation der letzten Versuche

---

## ✅ IMPLEMENTIERTE LÖSUNGEN

### **1. fix-config.service**
**Zweck:** Korrigiert config.txt nach detect-hifiberry Script

**Script:** `/opt/hifiberry/bin/fix-config.sh`
```bash
#!/bin/bash
# Fix config.txt after detect-hifiberry runs
CONFIG=/boot/config.txt

mount -o remount,rw /boot

# Füge automute zu allen hifiberry-Overlays hinzu
sed -i -E 's|dtoverlay=(hifiberry-[^,[:space:]]+)$|dtoverlay=\1,automute|' $CONFIG

# Stelle sicher dass display_rotate=3 gesetzt ist (Landscape 270°)
if ! grep -q '^display_rotate=3' $CONFIG; then
    sed -i '/^display_rotate=/d' $CONFIG
    echo 'display_rotate=3' >> $CONFIG
fi

# Stelle sicher dass video Parameter KORREKT ist (1280x400 OHNE Rotation)
# Entferne alle video Parameter mit rotate
sed -i 's/ video=[^ ]*rotate[^ ]*//' /boot/cmdline.txt
# Setze korrekten video Parameter falls nicht vorhanden
if ! grep -q 'video=HDMI-A-1:1280x400@60' /boot/cmdline.txt; then
    sed -i 's/\(rootwait\)/\1 video=HDMI-A-1:1280x400@60/' /boot/cmdline.txt
fi

sync
mount -o ro,remount /boot
```

**Service:** `/etc/systemd/system/fix-config.service`
```ini
[Unit]
Description=Fix config.txt after detect-hifiberry
After=hifiberry-detect.service
Before=hifiberry-finish.service

[Service]
Type=oneshot
ExecStart=/opt/hifiberry/bin/fix-config.sh
StandardOutput=journal

[Install]
WantedBy=multi-user.target
```

**Status:** ✅ Aktiv und läuft beim Boot

---

### **2. set-volume.service**
**Zweck:** Setzt Audio-Volume auf 50% (statt 100%)

**Service:** `/etc/systemd/system/set-volume.service`
```ini
[Unit]
Description=Set Audio Volume to 50%
After=sound.target

[Service]
Type=oneshot
ExecStart=/bin/bash -c 'amixer -c 0 set DSPVolume 50% && alsactl store'
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Status:** ✅ Aktiv - Volume ist auf 50% (128/255)

---

## 📊 AKTUELLE KONFIGURATION

### **config.txt:**
```
dtoverlay=vc4-fkms-v3d,audio=off
display_rotate=3
dtoverlay=hifiberry-blocked,automute
```

**Hinweis:** `hifiberry-blocked` statt `hifiberry-dacplus` - möglicherweise durch detect-hifiberry erkannt

### **cmdline.txt:**
```
root=/dev/mmcblk0p2 rootwait video=HDMI-A-1:1280x400@60 console=tty5 systemd.show_status=0 quiet splash
```

**✅ Korrekt:** Kein `rotate=270` im video Parameter!

### **Volume:**
```
Front Left: 128 [50%]
Front Right: 128 [50%]
```

**✅ Korrekt:** Volume auf 50% gesetzt

### **Display:**
```
Framebuffer: 1280,400 (Landscape)
```

**✅ Korrekt:** Display im Landscape-Modus

---

## 🔍 PROBLEME & LÖSUNGEN

### **Problem 1: Config.txt wird überschrieben**
- **Ursache:** `detect-hifiberry` Script entfernt Parameter wie `automute`
- **Lösung:** `fix-config.service` korrigiert nachträglich
- **Status:** ✅ Funktioniert

### **Problem 2: Display im Portrait-Modus**
- **Ursache:** `video=...rotate=270` zusätzlich zu `display_rotate=3`
- **Lösung:** `fix-config.sh` entfernt `rotate` aus cmdline.txt
- **Status:** ✅ Funktioniert - Display ist Landscape

### **Problem 3: Volume auf 100%**
- **Ursache:** Standard-Volume ist 100% (255)
- **Lösung:** `set-volume.service` setzt auf 50% (128)
- **Status:** ✅ Funktioniert

---

## 📝 JOURNAL LOGS

**fix-config.service:**
```
Dec 02 20:26:59 ghettoblasterp4 systemd[1]: Starting Fix config.txt after detect-hifiberry...
Dec 02 20:26:59 ghettoblasterp4 systemd[1]: fix-config.service: Deactivated successfully.
Dec 02 20:26:59 ghettoblasterp4 systemd[1]: Finished Fix config.txt after detect-hifiberry.
```

**Status:** ✅ Service läuft erfolgreich beim Boot

---

## 🎯 ERKENNTNISSE

### **1. Buildroot-Mechanismen:**
- `detect-hifiberry` überschreibt config.txt automatisch
- Services müssen nach Hardware-Erkennung laufen
- `fix-config.service` korrigiert Parameter nachträglich

### **2. Display Rotation:**
- `display_rotate=3` in config.txt (270° = Landscape)
- `video=HDMI-A-1:1280x400@60` in cmdline.txt (OHNE rotate!)
- **Wichtig:** `rotate=270` im video Parameter würde Portrait erzeugen!

### **3. Volume Management:**
- Standard: 100% (255)
- Gewünscht: 50% (128)
- `set-volume.service` setzt nach Boot

### **4. Auto-Mute:**
- `automute` Parameter wird von `fix-config.sh` hinzugefügt
- Funktioniert mit `hifiberry-dacplus` Overlay

---

## ⚠️ OFFENE FRAGEN

### **1. hifiberry-blocked:**
- **Frage:** Warum zeigt config.txt `hifiberry-blocked` statt `hifiberry-dacplus`?
- **Möglichkeit:** detect-hifiberry erkennt Hardware als "blocked"
- **Prüfung:** `aplay -l` zeigt `sndrpihifiberry` - Hardware funktioniert

### **2. Auto-Mute:**
- **Frage:** Funktioniert `automute` mit `hifiberry-blocked`?
- **Status:** Unbekannt - muss getestet werden

---

## 📚 VERWANDTE DOKUMENTATION

- [52_HIFIBERRYOS_SYSTEM_ANALYSE.md](52_HIFIBERRYOS_SYSTEM_ANALYSE.md) - System-Analyse
- [53_BUILDROOT_CONFIG_ÜBERSCHREIBUNG.md](53_BUILDROOT_CONFIG_ÜBERSCHREIBUNG.md) - Config-Überschreibung Problem
- [59_HIFIBERRYOS_PI4_DOKUMENTATION.md](59_HIFIBERRYOS_PI4_DOKUMENTATION.md) - Vollständige Dokumentation

---

**Letzte Aktualisierung:** 02.12.2025

