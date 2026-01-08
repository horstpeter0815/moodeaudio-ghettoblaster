# HIFIBERRYOS PI 4 → PI 5 TRANSFER PLAN

**Datum:** 03.12.2025  
**Quelle:** HiFiBerryOS auf Raspberry Pi 4 (192.168.178.199)  
**Ziel:** moOde Audio auf Raspberry Pi 5 (192.168.178.134)  
**Zweck:** Alle erfolgreichen Erkenntnisse von HiFiBerryOS auf Pi 5 übertragen

---

## NEUESTE ERKENNTNISSE AUS HIFIBERRYOS PI 4

### **1. Display Rotation (✅ GELÖST)**

**Problem:**
- Display blieb in Portrait-Modus trotz `display_rotate=3`
- `video=...rotate=270` in cmdline.txt verursachte Konflikte

**Lösung:**
- `display_rotate=3` in config.txt
- **KEIN** `rotate=270` in cmdline.txt (nur `video=HDMI-A-1:1280x400@60`)
- Weston.ini mit expliziter Rotation: `transform=rotate-270` + `mode=400x1280@60`

**Transfer für Pi 5:**
- moOde verwendet X11, nicht Wayland
- `display_rotate=3` sollte ausreichen
- Falls nicht: X11-Konfiguration prüfen (`/etc/X11/xorg.conf.d/`)

---

### **2. Volume Management (✅ GELÖST)**

**Problem:**
- Volume startete auf 100% (zu laut)
- Wurde nach Reboot zurückgesetzt

**Lösung:**
- `set-volume.service` mit `After=sound.target`, `After=restore-volume.service`
- `ExecStartPre=/bin/sleep 5` für Timing
- `ExecStartPost` mit 10s Delay für Persistenz
- Volume auf 0% gesetzt (Benutzer-Wunsch)

**Transfer für Pi 5:**
- moOde verwendet MPD Volume Control
- Service erstellen: `set-mpd-volume.service`
- MPD Volume auf sinnvollen Wert setzen (z.B. 50%)

---

### **3. Config.txt Auto-Überschreibung (✅ GELÖST)**

**Problem:**
- `detect-hifiberry` überschrieb config.txt Parameter
- `automute` und `display_rotate` gingen verloren

**Lösung:**
- `fix-config.service` läuft NACH `hifiberry-detect.service`
- Korrigiert alle Parameter automatisch

**Transfer für Pi 5:**
- moOde hat KEINE Auto-Überschreibung (Vorteil!)
- Aber: Config-Validierung implementieren
- Service: `config-validate.service` (warnt bei fehlenden Parametern)

---

### **4. Weston.ini Display-Konfiguration (✅ GELÖST)**

**Problem:**
- Weston interpretierte Display-Dimensionen falsch
- Rotation wurde ignoriert

**Lösung:**
- Explizite `[output]` Sektion in `/etc/xdg/weston/weston.ini`:
  ```
  [output]
  name=HDMI-A-1
  mode=400x1280@60
  transform=rotate-270
  ```

**Transfer für Pi 5:**
- moOde verwendet X11, nicht Wayland
- X11-Konfiguration: `/etc/X11/xorg.conf.d/99-display.conf`
- Oder: `xrandr --output HDMI-1 --rotate left` (270°)

---

### **5. Web-basierter Audio-Visualizer (✅ IMPLEMENTIERT)**

**Erkenntnis:**
- PeppyMeter benötigt pygame + X11
- HiFiBerryOS (Buildroot) hat keine pygame
- Alternative: Web-basierter Visualizer

**Lösung:**
- Python-Service: `audio-visualizer-service.py`
  - ALSA Audio-Capture (pyalsaaudio)
  - FFT-Analyse (64 Bands)
  - WebSocket-Server (geventwebsocket)
  - HTTP-Server für HTML-Interface
- Browser-Service: `cog-visualizer.service`
- Umschalt-Skripte: `visualizer-on.sh` / `visualizer-off.sh`

**Transfer für Pi 5:**
- moOde hat bereits PeppyMeter (funktioniert mit X11)
- **ABER:** Web-Visualizer als Alternative implementieren
- Vorteil: Kann im Chromium-Browser laufen
- Umschaltbar zwischen PeppyMeter und Web-Visualizer

---

### **6. Touchscreen (USB-basiert) (⏳ IN ARBEIT)**

**Erkenntnis:**
- WaveShare HDMI Display hat USB-Touchscreen
- **KEIN** I2C-Touchscreen (keine Overlays nötig)
- USB HID wird automatisch erkannt

**Problem:**
- Touchscreen wird erkannt, sendet aber keine Events
- libinput erkennt Calibration (270°)
- Weston erkennt Touchscreen (touch Capability)

**Status:**
- Hardware funktioniert (in moOde getestet)
- Wayland-spezifisches Problem vermutet
- Weitere Analyse nötig

**Transfer für Pi 5:**
- moOde verwendet X11 (nicht Wayland)
- Touchscreen sollte funktionieren
- Falls nicht: X11 Input-Konfiguration prüfen

---

### **7. Service-Abhängigkeiten (✅ OPTIMIERT)**

**HiFiBerryOS Boot-Sequenz:**
```
1. local-fs.target
2. hifiberry-detect.service
3. fix-config.service
4. hifiberry.target
5. sound.target
6. set-volume.service
7. weston.service
8. cog.service
9. mpd.service
```

**Erkenntnisse:**
- Hardware-Erkennung VOR Display
- Display VOR Browser
- Audio VOR MPD
- Volume-Setting NACH Audio-Init

**Transfer für Pi 5:**
- Ähnliche Sequenz für moOde:
```
1. local-fs.target
2. Hardware-Init (I2C, Audio)
3. localdisplay.service
4. ft6236-delay.service (Touchscreen)
5. set-mpd-volume.service
6. mpd.service
7. peppymeter.service
8. chromium.service
```

---

## KONKRETE TRANSFER-SCHRITTE FÜR PI 5

### **Schritt 1: Display Rotation prüfen**

**Prüfen:**
```bash
# Auf Pi 5
grep display_rotate /boot/firmware/config.txt
# Sollte sein: display_rotate=3

# X11 Rotation prüfen
xrandr --query
```

**Falls nicht korrekt:**
```bash
# config.txt setzen
echo "display_rotate=3" >> /boot/firmware/config.txt

# Oder X11-Konfiguration
sudo nano /etc/X11/xorg.conf.d/99-display.conf
```

---

### **Schritt 2: Volume Management implementieren**

**Service erstellen: `/etc/systemd/system/set-mpd-volume.service`**
```ini
[Unit]
Description=Set MPD Volume to 50%
After=mpd.service
Wants=mpd.service

[Service]
Type=oneshot
ExecStartPre=/bin/sleep 5
ExecStart=/usr/bin/mpc volume 50
ExecStartPost=/bin/bash -c 'sleep 10 && /usr/bin/mpc volume 50'
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Aktivieren:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable set-mpd-volume.service
```

---

### **Schritt 3: Config-Validierung implementieren**

**Service erstellen: `/etc/systemd/system/config-validate.service`**
```ini
[Unit]
Description=Validate config.txt
Before=localdisplay.service

[Service]
Type=oneshot
ExecStart=/opt/moode/bin/config-validate.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Script erstellen: `/opt/moode/bin/config-validate.sh`**
```bash
#!/bin/bash
CONFIG=/boot/firmware/config.txt
ERRORS=0

# Prüfe display_rotate
if ! grep -q '^display_rotate=3' $CONFIG; then
    echo "WARNING: display_rotate=3 nicht gesetzt"
    ERRORS=$((ERRORS+1))
fi

# Prüfe hifiberry Overlay
if ! grep -q 'dtoverlay=hifiberry-' $CONFIG; then
    echo "WARNING: hifiberry Overlay nicht gefunden"
fi

# Prüfe automute (falls hifiberry-dacplus)
if grep -q 'dtoverlay=hifiberry-dacplus' $CONFIG && ! grep -q 'automute' $CONFIG; then
    echo "WARNING: automute fehlt bei hifiberry-dacplus"
fi

exit $ERRORS
```

---

### **Schritt 4: Web-Visualizer als Alternative**

**Option A: PeppyMeter behalten (empfohlen)**
- PeppyMeter funktioniert bereits auf moOde
- Keine Änderung nötig

**Option B: Web-Visualizer zusätzlich**
- Als Alternative zu PeppyMeter
- Kann im Chromium laufen
- Umschaltbar per Script

**Implementierung (falls gewünscht):**
- Dateien von HiFiBerryOS kopieren
- Anpassen für moOde (X11 statt Wayland)
- Service erstellen

---

### **Schritt 5: Service-Abhängigkeiten optimieren**

**MPD Service optimieren:**
```ini
[Unit]
After=localdisplay.service
Wants=localdisplay.service
After=local-fs.target

[Service]
ExecStartPre=/bin/bash -c 'until aplay -l | grep -q hifiberry; do sleep 1; done'
```

**PeppyMeter Service optimieren:**
```ini
[Unit]
Requires=localdisplay.service
After=localdisplay.service
Wants=localdisplay.service

[Service]
ExecStartPre=/bin/bash -c 'until [ -f /tmp/.X11-unix/X0 ]; do sleep 1; done'
```

---

## CHECKLISTE FÜR PI 5

### **✅ Zu prüfen:**
- [ ] Display Rotation (`display_rotate=3`)
- [ ] Volume Management (MPD Volume auf 50%)
- [ ] Config-Validierung (Service + Script)
- [ ] Service-Abhängigkeiten (MPD, PeppyMeter)
- [ ] Touchscreen (USB-basiert, sollte funktionieren)
- [ ] Boot-Sequenz (Timing optimiert)

### **⏳ Optional:**
- [ ] Web-Visualizer als Alternative
- [ ] X11 Display-Konfiguration (falls Rotation nicht funktioniert)
- [ ] Hardware-Init Service (wie HiFiBerryOS)

---

## ERWARTETE ERGEBNISSE

### **Nach Transfer:**
1. ✅ Display in Landscape (270°)
2. ✅ Volume startet auf 50% (nicht 100%)
3. ✅ Config.txt wird validiert beim Boot
4. ✅ Services starten in korrekter Reihenfolge
5. ✅ Touchscreen funktioniert (X11)
6. ✅ Boot-Sequenz ist optimiert

---

## NÄCHSTE SCHRITTE

1. **Pi 5 System analysieren:**
   - SSH-Zugriff prüfen
   - Aktuelle Config prüfen
   - Services analysieren

2. **Transfer durchführen:**
   - Display Rotation prüfen/korrigieren
   - Volume Management implementieren
   - Config-Validierung implementieren
   - Service-Abhängigkeiten optimieren

3. **Testen:**
   - Reboot testen
   - Boot-Sequenz prüfen
   - Alle Funktionen testen

---

**Status:** 📋 Plan erstellt, ⏳ Bereit für Implementierung

