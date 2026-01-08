# HIFIBERRYOS PI 4 VOLLSTÄNDIGE DOKUMENTATION

**Datum:** 02.12.2025  
**System:** HiFiBerryOS auf Raspberry Pi 4  
**IP:** 192.168.178.199  
**Zweck:** Vollständige Dokumentation des laufenden Systems

---

## SYSTEM INFORMATIONEN

### **Hardware:**
- **Raspberry Pi 4 Model B**
- **Audio:** HiFiBerry DAC+ Pro
- **Display:** HDMI Display (1280x400)

### **Software:**
- **OS:** HiFiBerryOS (Buildroot-basiert)
- **Init:** systemd
- **Display:** Weston (Wayland Compositor)
- **Browser:** cog (WPE WebKit)

---

## KONFIGURATIONSDATEIEN

### **1. /boot/config.txt:**
```
display_rotate=3
dtoverlay=hifiberry-dacplus,automute
dtoverlay=vc4-fkms-v3d,audio=off
dtparam=i2c=on
```

### **2. /boot/cmdline.txt:**
```
root=/dev/mmcblk0p2 rootwait console=tty5 systemd.show_status=0 quiet splash video=HDMI-A-1:1280x400@60
```

**Wichtig:** Kein `rotate=270` im video Parameter! (1280x400 ist bereits Landscape)

---

## HIFIBERRY SERVICES

### **1. hifiberry-detect.service:**
- **Zweck:** Automatische Hardware-Erkennung
- **Script:** `/opt/hifiberry/bin/detect-hifiberry`
- **Problem:** Überschreibt config.txt Parameter

### **2. fix-config.service:**
- **Zweck:** Korrigiert config.txt nach detect-hifiberry
- **Script:** `/opt/hifiberry/bin/fix-config.sh`
- **Funktion:**
  - Fügt `automute` zu hifiberry-Overlay hinzu
  - Setzt `display_rotate=3`
  - Entfernt `rotate` aus cmdline.txt

### **3. set-volume.service:**
- **Zweck:** Setzt Audio-Volume auf 50%
- **Funktion:** `amixer -c 0 set DSPVolume 50% && alsactl store`
- **Timing:** After=sound.target

---

## DISPLAY SYSTEM

### **Weston Service:**
- **After:** psplash-quit.service hifiberry.target
- **Wants:** dbus.socket
- **Environment:** XDG_RUNTIME_DIR=/var/run/weston

### **Cog Service:**
- **Requires:** weston.service
- **After:** weston.service beocreate2.service
- **Environment:** WAYLAND_DISPLAY=wayland-1

### **Display Status:**
- **Framebuffer:** 1280,400 (Landscape)
- **Resolution:** 1280x400@60Hz
- **Rotation:** display_rotate=3 (270°)

---

## AUDIO SYSTEM

### **Hardware:**
- **Card:** sndrpihifiberry (HiFiBerry DAC+ Pro)
- **Device:** HiFiBerry DAC+ Pro HiFi pcm512x-hifi-0

### **Volume Control:**
- **Control:** DSPVolume
- **Range:** 0-255
- **Standard:** 255 (100%) - wird auf 50% (128) gesetzt

### **MPD Service:**
- **After:** network.target sound.target local-fs.target
- **Wants:** network.target local-fs.target
- **Requires:** mount-data.service

---

## BOOT SEQUENZ

### **Chronologische Reihenfolge:**
```
1. local-fs.target
2. hifiberry-detect.service (Hardware-Erkennung)
3. fix-config.service (Parameter korrigieren)
4. hifiberry.target (HiFiBerry-Services bereit)
5. sound.target (Audio-System bereit)
6. set-volume.service (Volume auf 50%)
7. weston.service (Wayland Compositor)
8. cog.service (Web Browser)
9. mpd.service (Music Player Daemon)
```

---

## WICHTIGE ERKENNTNISSE

### **1. Config.txt Überschreibung:**
- `detect-hifiberry` überschreibt config.txt
- `fix-config.service` korrigiert nachträglich
- **Lösung:** fix-config.service läuft nach hifiberry-detect.service

### **2. Display Rotation:**
- `display_rotate=3` in config.txt (270° = Landscape)
- `video=HDMI-A-1:1280x400@60` in cmdline.txt (OHNE rotate!)
- **Fehler:** `video=...rotate=270` würde Portrait erzeugen!

### **3. Volume Management:**
- Standard: 100% (255)
- Gewünscht: 50% (128)
- **Lösung:** set-volume.service setzt nach Boot

### **4. Buildroot-Mechanismen:**
- Automatische Hardware-Erkennung
- Config.txt wird generiert
- Services müssen nach Hardware-Initialisierung starten

---

## SERVICE ABHÄNGIGKEITEN

```
local-fs.target
    └─> hifiberry-detect.service
            └─> hifiberry.target
                    ├─> fix-config.service
                    ├─> sound.target
                    │       └─> set-volume.service
                    │       └─> mpd.service
                    └─> weston.service
                            └─> cog.service
```

---

## KONFIGURATIONSPARAMETER

### **config.txt:**
- `display_rotate=3` - Landscape (270°)
- `dtoverlay=hifiberry-dacplus,automute` - Audio mit Auto-Mute
- `dtoverlay=vc4-fkms-v3d,audio=off` - Display ohne Audio

### **cmdline.txt:**
- `video=HDMI-A-1:1280x400@60` - Display Resolution (OHNE rotate!)

### **fix-config.sh:**
- Entfernt `rotate` aus cmdline.txt
- Setzt `display_rotate=3` in config.txt
- Fügt `automute` zu hifiberry-Overlay hinzu

---

## PROBLEME & LÖSUNGEN

### **Problem 1: Config.txt wird überschrieben**
- **Ursache:** detect-hifiberry Script
- **Lösung:** fix-config.service

### **Problem 2: Display im Portrait-Modus**
- **Ursache:** `video=...rotate=270` zusätzlich zu `display_rotate=3`
- **Lösung:** Entferne `rotate` aus cmdline.txt

### **Problem 3: Volume auf 100%**
- **Ursache:** Standard-Volume
- **Lösung:** set-volume.service

---

**Dokumentation wird kontinuierlich erweitert...**

