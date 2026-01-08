# BUILDROOT BOOT-SEQUENZ DETAILLIERTE ANALYSE

**Datum:** 02.12.2025  
**System:** HiFiBerryOS (Buildroot)  
**Zweck:** Vollständiges Verständnis der Boot-Sequenz für Transfer auf moOde

---

## VOLLSTÄNDIGE BOOT-SEQUENZ

### **Phase 1: System-Initialisierung**
```
1. Kernel Boot
2. init (systemd)
3. local-fs.target (Dateisystem gemountet)
4. sysinit.target (System initialisiert)
```

### **Phase 2: Hardware-Erkennung**
```
5. hifiberry-detect.service
   - I2C-Scan (Bus 1)
   - Hardware-Erkennung (PCM5122, etc.)
   - config.txt Generierung (überschreibt Parameter!)
   - After: dsptoolkit.service local-fs.target
```

### **Phase 3: Config-Korrektur**
```
6. fix-config.service (wenn implementiert)
   - Korrigiert config.txt Parameter
   - Fügt automute, display_rotate hinzu
   - After: hifiberry-detect.service
```

### **Phase 4: HiFiBerry Target**
```
7. hifiberry.target
   - Sammelt alle HiFiBerry-Services
   - Garantiert Hardware initialisiert
   - After: hifiberry-detect.service
```

### **Phase 5: Display-Initialisierung**
```
8. weston.service
   - Wayland Compositor
   - After: psplash-quit.service hifiberry.target
   - Wants: dbus.socket
   - Environment: XDG_RUNTIME_DIR=/var/run/weston
```

### **Phase 6: Display-Anwendung**
```
9. cog.service
   - Web Browser (WPE WebKit)
   - Requires: weston.service
   - After: weston.service beocreate2.service
   - Environment: COG_PLATFORM_FDO_VIEW_FULLSCREEN=1
   - Environment: WAYLAND_DISPLAY=wayland-1
```

### **Phase 7: Audio-Initialisierung**
```
10. sound.target
    - Audio-System bereit
    - After: hifiberry.target

11. mpd.service
    - Music Player Daemon
    - After: network.target sound.target local-fs.target
    - Wants: network.target local-fs.target
    - Requires: mount-data.service
```

### **Phase 8: Audio-Control**
```
12. audiocontrol2.service
    - Audio Control Service
    - After: hifiberry.target
```

---

## KRITISCHE TIMING-PUNKTE

### **1. Hardware VOR Display:**
- hifiberry-detect.service läuft VOR weston.service
- Hardware ist initialisiert bevor Display startet
- **Transfer:** localdisplay.service sollte NACH Hardware-Initialisierung starten

### **2. Display VOR Anwendungen:**
- weston.service läuft VOR cog.service
- Display ist bereit bevor Browser startet
- **Transfer:** Chromium sollte NACH localdisplay.service starten

### **3. Audio NACH Hardware:**
- sound.target läuft NACH hifiberry.target
- Audio-Hardware ist initialisiert bevor MPD startet
- **Transfer:** MPD sollte NACH Hardware-Prüfung starten

---

## SERVICE-ABHÄNGIGKEITEN (VISUALISIERT)

```
local-fs.target
    └─> hifiberry-detect.service
            └─> hifiberry.target
                    ├─> weston.service
                    │       └─> cog.service
                    └─> sound.target
                            └─> mpd.service
                                    └─> audiocontrol2.service
```

---

## ENVIRONMENT VARIABLES

### **weston.service:**
- `XDG_RUNTIME_DIR=/var/run/weston`
- `XDG_CONFIG_HOME=/etc/xdg/weston`

### **cog.service:**
- `COG_PLATFORM_FDO_VIEW_FULLSCREEN=1`
- `WAYLAND_DISPLAY=wayland-1`
- `XDG_RUNTIME_DIR=/var/run/weston`

### **Transfer für moOde:**
- X Server verwendet `DISPLAY=:0`
- Chromium benötigt `DISPLAY=:0`
- PeppyMeter benötigt `DISPLAY=:0`

---

## I2C INITIALISIERUNG TIMING

### **HiFiBerryOS:**
```
1. Kernel: i2c_bcm2835 geladen
2. Device Tree: I2C Bus 1 aktiv (dtparam=i2c=on)
3. hifiberry-detect: I2C-Scan (Bus 1)
4. Hardware-Erkennung: PCM5122 (0x4d)
5. Overlay-Generierung: dtoverlay=hifiberry-dacplus
```

### **moOde (Optimal):**
```
1. Kernel: i2c_bcm2835 geladen
2. Device Tree: I2C Bus 1 + Bus 10 aktiv
3. Hardware-Initialisierung Service: I2C-Scan
4. Hardware-Erkennung: PCM5122 (0x4d), Touchscreen (0x45)
5. Services starten NACH Hardware-Initialisierung
```

---

## DISPLAY INITIALISIERUNG TIMING

### **HiFiBerryOS:**
```
1. Framebuffer: /dev/fb0 (simplefb)
2. vc4 Driver: fb0 switching to vc4
3. DRM: /dev/dri/card0 (vc4)
4. weston.service: Wayland Compositor
5. cog.service: Web Browser
```

### **moOde (Optimal):**
```
1. Framebuffer: /dev/fb0
2. X Server: DISPLAY=:0
3. LightDM: Display Manager
4. localdisplay.service: Display initialisiert
5. Chromium: Web Browser
```

---

## AUDIO INITIALISIERUNG TIMING

### **HiFiBerryOS:**
```
1. hifiberry-detect: Hardware-Erkennung
2. config.txt: dtoverlay=hifiberry-dacplus
3. Kernel: snd_soc_pcm512x geladen
4. ALSA: Card 0 erstellt
5. sound.target: Audio-System bereit
6. mpd.service: Startet
```

### **moOde (Optimal):**
```
1. config.txt: dtoverlay=hifiberry-dacplus,automute (manuell)
2. Kernel: snd_soc_pcm512x geladen
3. ALSA: Card erstellt
4. MPD Service: Prüft Hardware (ExecStartPre)
5. MPD Service: Startet
```

---

## LESSONS LEARNED

### **1. Timing ist alles:**
- Hardware VOR Display
- Display VOR Anwendungen
- Audio NACH Hardware

### **2. Klare Abhängigkeiten:**
- After=, Wants=, Requires= müssen korrekt sein
- Targets helfen (hifiberry.target, sound.target)

### **3. Automatisierung vs. Kontrolle:**
- Buildroot: Automatisch, aber weniger Kontrolle
- moOde: Manuell, aber volle Kontrolle

### **4. Monitoring ist essentiell:**
- systemd-analyze zeigt Timing
- journalctl zeigt Abhängigkeiten
- dmesg zeigt Hardware-Initialisierung

---

**Boot-Sequenz Analyse wird kontinuierlich erweitert...**

