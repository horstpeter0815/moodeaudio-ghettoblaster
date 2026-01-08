# TOUCHSCREEN & VOLUME FIX - HIFIBERRYOS PI 4

**Datum:** 03.12.2025  
**System:** HiFiBerryOS auf Raspberry Pi 4 (192.168.178.199)  
**Status:** ⏳ In Arbeit

---

## 🔧 DURCHGEFÜHRTE FIXES

### **1. TOUCHSCREEN KONFIGURATION:**

**Problem:**
- ❌ Touchscreen nicht konfiguriert
- ❌ Kein Touchscreen-Overlay in config.txt

**Lösung:**
- ✅ WaveShare 7.9" Panel Overlay hinzugefügt
- ✅ `dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,rotation=90`
- ✅ `fix-config.sh` erweitert für automatische Touchscreen-Konfiguration

**Änderungen:**
```bash
# config.txt:
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,rotation=90

# fix-config.sh erweitert:
# Touchscreen-Overlay hinzufügen (WaveShare 7.9")
if ! grep -q 'vc4-kms-dsi-waveshare-panel' $CONFIG; then
    sed -i '/^dtoverlay=vc4-fkms-v3d/a dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,rotation=90' $CONFIG
fi
```

---

### **2. VOLUME-PROBLEM BEHEBEN:**

**Problem:**
- ❌ Volume geht auf 100% zurück
- ❌ `restore-volume.service` überschreibt Volume
- ❌ Andere Services (mpd, squeezelite, etc.) setzen Volume zurück

**Lösung:**
- ✅ `set-volume.service` erweitert
- ✅ Läuft NACH allen Audio-Services
- ✅ Setzt Volume mehrfach (sofort + nach 10 Sekunden)
- ✅ Speichert Volume in `/etc/alsactl.store`

**Neue set-volume.service:**
```ini
[Unit]
Description=Set Audio Volume to 0%
After=sound.target
After=restore-volume.service
After=mpd.service
After=squeezelite.service
After=spotifyd.service
After=roon.service
Wants=sound.target

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 5
ExecStart=/bin/bash -c 'amixer -c 0 set DSPVolume 0% && alsactl store && sync'
ExecStartPost=/bin/bash -c 'sleep 10 && amixer -c 0 set DSPVolume 0% && alsactl store'
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Service-Abhängigkeiten:**
1. `restore-volume.service` - Stellt gespeichertes Volume wieder her
2. `mpd.service` - Music Player Daemon
3. `squeezelite.service` - Squeezebox Client
4. `spotifyd.service` - Spotify Daemon
5. `roon.service` - Roon Bridge
6. **→ `set-volume.service`** - Setzt Volume auf 0% NACH allen Services

---

## 📋 KONFIGURATIONSDATEIEN

### **config.txt (nach Fix):**
```
dtoverlay=i2c-gpio,i2c_gpio_sda=0,i2c_gpio_scl=1
dtoverlay=vc4-fkms-v3d,audio=off
dtoverlay=vc4-kms-dsi-waveshare-panel,7_9_inch,rotation=90
dtoverlay=hifiberry-dacplus,automute
display_rotate=3
```

### **fix-config.sh (erweitert):**
- Fügt automatisch Touchscreen-Overlay hinzu
- Wird nach `hifiberry-detect.service` ausgeführt
- Verhindert, dass Touchscreen-Overlay überschrieben wird

---

## 🎯 ERWARTETE ERGEBNISSE

### **Nach Reboot:**

**Touchscreen:**
- ✅ Touchscreen-Device erkannt (`/dev/input/eventX`)
- ✅ Goodix Driver geladen
- ✅ Input Device in `/proc/bus/input/devices`
- ✅ Weston/Wayland erkennt Touchscreen

**Volume:**
- ✅ Volume auf 0% (0/255)
- ✅ Bleibt auf 0% nach Reboot
- ✅ Wird nicht von anderen Services überschrieben

---

## 🔍 PRÜFUNG NACH REBOOT

### **Touchscreen prüfen:**
```bash
# Input Devices
cat /proc/bus/input/devices | grep -i touch

# I2C Bus
i2cdetect -y 1

# Kernel Modules
lsmod | grep -i touch
```

### **Volume prüfen:**
```bash
# Volume Status
amixer -c 0 get DSPVolume

# Service Status
systemctl status set-volume.service
```

---

## 📝 NÄCHSTE SCHRITTE

1. ⏳ System nach Reboot prüfen
2. ⏳ Touchscreen testen
3. ⏳ Volume prüfen (sollte 0% bleiben)
4. ⏳ Falls Probleme: Anpassungen vornehmen

---

**Status:** ⏳ System neu gestartet, Prüfung läuft...

