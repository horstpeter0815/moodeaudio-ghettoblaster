# MOODE OPTIMIERUNG BASIEREND AUF BUILDROOT-ERKENNTNISSEN

**Datum:** 02.12.2025  
**Zweck:** Konkrete Optimierungen für moOde basierend auf HiFiBerryOS Erkenntnissen

---

## SERVICE-OPTIMIERUNGEN

### **1. MPD Service Abhängigkeiten:**
**Problem:** MPD startet möglicherweise bevor Hardware initialisiert ist

**Lösung:**
```ini
[Unit]
After=local-fs.target
Wants=local-fs.target
After=localdisplay.service
Wants=localdisplay.service

[Service]
# Hardware sollte initialisiert sein bevor MPD startet
```

### **2. Touchscreen Service Timing:**
**Problem:** Touchscreen initialisiert zu früh (bekanntes Problem)

**Lösung (bereits implementiert):**
```ini
[Unit]
After=localdisplay.service
Wants=localdisplay.service

[Service]
ExecStart=/bin/bash -c 'sleep 5 && modprobe edt-ft5x06'
```

**Erkenntnis aus Buildroot:** Timing ist kritisch - Display muss zuerst da sein

---

## CONFIG.TXT OPTIMIERUNGEN

### **1. Display Rotation:**
**HiFiBerryOS:** `display_rotate=3` + `video=HDMI-A-1:1280x400@60,rotate=270`

**moOde (Optimal):**
```
display_rotate=3
# ODER in cmdline.txt:
video=HDMI-A-1:1280x400@60,rotate=270
```

**Hinweis:** Nur EINE Methode verwenden, nicht beide gleichzeitig

### **2. Audio Overlay:**
**HiFiBerryOS:** `dtoverlay=hifiberry-dacplus,automute`

**moOde (Optimal):**
```
dtoverlay=hifiberry-dacplus,automute
```

**Hinweis:** Parameter bleiben erhalten (keine Auto-Überschreibung)

---

## I2C TIMING-OPTIMIERUNGEN

### **Problem:**
- I2C Bus 1: AMP100 (0x4d) - funktioniert
- I2C Bus 10: Touchscreen (0x45) - Timing-Probleme

### **Lösung:**
1. **I2C Bus 1 initialisieren** - Standard GPIO 2/3
2. **Display initialisieren** - localdisplay.service
3. **I2C Bus 10 initialisieren** - Nach Display
4. **Touchscreen initialisieren** - Mit Delay nach Display

### **Service-Sequenz:**
```
1. I2C Bus 1 aktiv (dtparam=i2c=on)
2. localdisplay.service (Display initialisiert)
3. I2C Bus 10 aktiv (falls vorhanden)
4. ft6236-delay.service (Touchscreen mit Delay)
```

---

## HARDWARE-INITIALISIERUNG

### **HiFiBerryOS Ansatz:**
- Automatische Hardware-Erkennung
- config.txt wird generiert
- Services starten nach Hardware-Erkennung

### **moOde Ansatz:**
- Manuelle Hardware-Konfiguration
- config.txt wird nicht überschrieben
- Services müssen auf Hardware warten

### **Optimierung:**
```ini
[Unit]
# Warte auf Hardware-Initialisierung
After=local-fs.target
After=sys-devices-platform-soc-*-i2c.device
Wants=sys-devices-platform-soc-*-i2c.device
```

---

## DISPLAY INITIALISIERUNG

### **HiFiBerryOS:**
- Framebuffer (einfach)
- weston.service (Wayland)
- cog.service (Browser)

### **moOde:**
- X Server (komplex)
- LightDM (Display Manager)
- Chromium (Browser)

### **Optimierung:**
- **Timing:** Display VOR Anwendungen
- **Abhängigkeiten:** Klare After=, Wants=
- **Delay:** Touchscreen nach Display

---

## AUDIO INITIALISIERUNG

### **HiFiBerryOS:**
- detect-hifiberry.service
- Automatische Overlay-Generierung
- ALSA direkt

### **moOde:**
- Manuelle config.txt
- MPD Service
- ALSA + MPD

### **Optimierung:**
```ini
[Unit]
# Warte auf Hardware
After=local-fs.target
# Warte auf Display (optional)
After=localdisplay.service

[Service]
# Prüfe Hardware vor Start
ExecStartPre=/bin/bash -c 'until aplay -l | grep -q hifiberry; do sleep 1; done'
```

---

## KONFIGURATIONS-VALIDIERUNG

### **Problem:**
- Config.txt Parameter können falsch sein
- Services starten trotz fehlerhafter Config

### **Lösung:**
```bash
#!/bin/bash
# config-validate.sh
CONFIG=/boot/config.txt

# Prüfe display_rotate
if ! grep -q '^display_rotate=[0-3]' $CONFIG; then
    echo "WARNING: display_rotate nicht gesetzt"
fi

# Prüfe hifiberry Overlay
if ! grep -q 'dtoverlay=hifiberry-' $CONFIG; then
    echo "WARNING: hifiberry Overlay nicht gefunden"
fi
```

---

## MONITORING & LOGGING

### **HiFiBerryOS:**
- /var/log/hifiberry.log
- Journalctl für Services
- Boot-Messages

### **moOde Optimierung:**
```bash
# Service-Logging
journalctl -u localdisplay.service -f
journalctl -u ft6236-delay.service -f
journalctl -u mpd.service -f

# Hardware-Monitoring
dmesg | grep -iE 'i2c|display|audio|hifiberry'
```

---

## FEHLERBEHEBUNG

### **Problem: Display nicht im Landscape:**
1. Prüfe config.txt: `display_rotate=3`
2. Prüfe cmdline.txt: `video=...,rotate=270`
3. Nur EINE Methode verwenden
4. Reboot erforderlich

### **Problem: Auto-Mute funktioniert nicht:**
1. Prüfe config.txt: `dtoverlay=hifiberry-dacplus,automute`
2. Prüfe Hardware: `i2cdetect -y 1` (sollte 0x4d zeigen)
3. Prüfe ALSA: `aplay -l` (sollte hifiberry zeigen)
4. Reboot erforderlich

### **Problem: Touchscreen funktioniert nicht:**
1. Prüfe Timing: Service sollte NACH Display starten
2. Prüfe I2C: `i2cdetect -y 10` (sollte 0x45 zeigen)
3. Prüfe Delay: Mindestens 5 Sekunden nach Display
4. Prüfe dmesg: `dmesg | grep -iE 'touch|i2c.*error'`

---

---

## BUILDROOT MECHANISMEN VERSTEHEN

### **1. detect-hifiberry Script:**
- **Läuft:** Beim Boot (hifiberry-detect.service)
- **Macht:** I2C-Scan, Hardware-Erkennung, config.txt Generierung
- **Problem:** Überschreibt Parameter (automute, etc.)
- **Lösung:** fix-config.service korrigiert nachträglich

### **2. hifiberry.target:**
- **Zweck:** Sammelt alle HiFiBerry-Services
- **Timing:** Nach Hardware-Erkennung, vor Anwendungen
- **Transfer:** Ähnliches Target für moOde (moode.target?)

### **3. sound.target:**
- **Zweck:** Garantiert Audio-Hardware initialisiert
- **Timing:** Nach hifiberry.target
- **Transfer:** Prüfung in ExecStartPre statt Target

### **4. weston.service:**
- **Zweck:** Wayland Compositor (Display)
- **Timing:** Nach hifiberry.target, vor cog.service
- **Transfer:** localdisplay.service entspricht weston.service

---

## KONKRETE MOODE SERVICE-OPTIMIERUNGEN

### **1. localdisplay.service (bereits implementiert):**
```ini
[Unit]
After=graphical.target
Wants=graphical.target
# OPTIMIERUNG: Warte auf Hardware
After=sys-devices-platform-soc-*-i2c.device
```

### **2. ft6236-delay.service (bereits implementiert):**
```ini
[Unit]
After=localdisplay.service
Wants=localdisplay.service
# OPTIMIERUNG: Längeres Delay
ExecStart=/bin/bash -c 'sleep 5 && modprobe edt-ft5x06'
```

### **3. mpd.service (zu optimieren):**
```ini
[Unit]
# OPTIMIERUNG: Warte auf Display
After=localdisplay.service
Wants=localdisplay.service
# OPTIMIERUNG: Warte auf Hardware
After=local-fs.target

[Service]
# OPTIMIERUNG: Prüfe Hardware vor Start
ExecStartPre=/bin/bash -c 'until aplay -l | grep -q hifiberry; do sleep 1; done'
```

### **4. peppymeter.service (zu optimieren):**
```ini
[Unit]
# OPTIMIERUNG: Klare Abhängigkeit
After=localdisplay.service
Wants=localdisplay.service
Requires=localdisplay.service
```

---

## CONFIG.TXT TEMPLATES

### **moOde Config.txt Template:**
```
# Display
disable_overscan=1
display_rotate=3  # Landscape (270°)
dtoverlay=vc4-fkms-v3d,audio=off

# I2C
dtparam=i2c=on
dtparam=spi=on

# Audio
dtoverlay=hifiberry-dacplus,automute
# ODER für AMP100:
# dtoverlay=hifiberry-amp100-pi5-dsp-reset

# Kernel
kernel=vmlinuz
```

### **Validierung:**
```bash
#!/bin/bash
# config-validate.sh
CONFIG=/boot/firmware/config.txt

ERRORS=0

# Prüfe display_rotate
if ! grep -q '^display_rotate=[0-3]' $CONFIG; then
    echo "ERROR: display_rotate nicht gesetzt"
    ERRORS=$((ERRORS+1))
fi

# Prüfe hifiberry Overlay
if ! grep -q 'dtoverlay=hifiberry-' $CONFIG; then
    echo "WARNING: hifiberry Overlay nicht gefunden"
fi

# Prüfe automute (falls hifiberry-dacplus)
if grep -q 'dtoverlay=hifiberry-dacplus' $CONFIG && ! grep -q 'dtoverlay=hifiberry-dacplus,automute' $CONFIG; then
    echo "WARNING: automute fehlt bei hifiberry-dacplus"
fi

exit $ERRORS
```

---

## MONITORING & DIAGNOSTIK

### **Boot-Sequenz Logging:**
```bash
# Service-Start-Zeiten
systemd-analyze blame | grep -E 'localdisplay|ft6236|mpd|peppymeter'

# Service-Abhängigkeiten visualisieren
systemd-analyze plot > boot-sequence.svg

# Service-Status
systemctl list-units --type=service --state=failed
```

### **Hardware-Monitoring:**
```bash
# I2C Bus Status
i2cdetect -y 1
i2cdetect -y 10

# Audio Hardware
aplay -l
cat /proc/asound/cards

# Display Hardware
cat /sys/class/graphics/fb0/virtual_size
ls -la /dev/dri/*
```

---

**Optimierungen werden kontinuierlich erweitert...**

