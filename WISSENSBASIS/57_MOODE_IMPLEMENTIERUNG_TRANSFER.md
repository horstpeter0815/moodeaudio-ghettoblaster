# MOODE IMPLEMENTIERUNG BASIEREND AUF BUILDROOT-TRANSFER

**Datum:** 02.12.2025  
**Zweck:** Konkrete Implementierungs-Schritte für moOde basierend auf HiFiBerryOS Erkenntnissen

---

## IMPLEMENTIERUNGS-PHASEN

### **Phase 1: Service-Abhängigkeiten optimieren**
### **Phase 2: Config.txt Management**
### **Phase 3: Hardware-Initialisierung**
### **Phase 4: Monitoring & Validierung**

---

## PHASE 1: SERVICE-ABHÄNGIGKEITEN

### **1.1 MPD Service optimieren:**

**Aktuell:**
```ini
[Unit]
After=network.target
```

**Optimal (basierend auf Buildroot):**
```ini
[Unit]
Wants=network.target local-fs.target localdisplay.service
After=network.target local-fs.target localdisplay.service
# Warte auf Hardware-Initialisierung
After=sys-devices-platform-soc-*-i2c.device

[Service]
# Prüfe Hardware vor Start
ExecStartPre=/bin/bash -c 'until aplay -l | grep -q hifiberry; do sleep 1; done'
ExecStart=/usr/bin/mpd --no-daemon
```

**Erkenntnis aus Buildroot:**
- MPD wartet auf sound.target (Audio-Hardware bereit)
- Transfer: ExecStartPre Prüfung statt Target

---

### **1.2 PeppyMeter Service optimieren:**

**Aktuell:**
```ini
[Unit]
After=localdisplay.service
```

**Optimal:**
```ini
[Unit]
After=localdisplay.service
Wants=localdisplay.service
Requires=localdisplay.service
# Warte auf Display bereit
ExecStartPre=/bin/bash -c 'until [ -f /tmp/.X11-unix/X0 ]; do sleep 1; done'
```

**Erkenntnis aus Buildroot:**
- cog.service hat Requires=weston.service (harte Abhängigkeit)
- Transfer: Requires=localdisplay.service

---

### **1.3 Chromium Service optimieren:**

**Aktuell:**
```ini
[Unit]
After=localdisplay.service
```

**Optimal:**
```ini
[Unit]
Requires=localdisplay.service
After=localdisplay.service
Wants=localdisplay.service

[Service]
Environment=DISPLAY=:0
# Prüfe Display vor Start
ExecStartPre=/bin/bash -c 'until [ -f /tmp/.X11-unix/X0 ]; do sleep 1; done'
Restart=always
RestartSec=20
```

**Erkenntnis aus Buildroot:**
- cog.service hat Restart=always (Stabilität)
- Transfer: Restart=always für Chromium

---

## PHASE 2: CONFIG.TXT MANAGEMENT

### **2.1 Config.txt Template erstellen:**

**Template: `/opt/moode/config/config.txt.template`**
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

---

### **2.2 Config-Validierung Service:**

**Erstellen: `/etc/systemd/system/config-validate.service`**
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

**Script: `/opt/moode/bin/config-validate.sh`**
```bash
#!/bin/bash
CONFIG=/boot/firmware/config.txt
ERRORS=0

# Prüfe display_rotate
if ! grep -q '^display_rotate=[0-3]' $CONFIG; then
    echo "WARNING: display_rotate nicht gesetzt"
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

## PHASE 3: HARDWARE-INITIALISIERUNG

### **3.1 Hardware-Init Service:**

**Erstellen: `/etc/systemd/system/hardware-init.service`**
```ini
[Unit]
Description=Hardware Initialization
After=local-fs.target
Before=localdisplay.service

[Service]
Type=oneshot
ExecStart=/opt/moode/bin/hardware-init.sh
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
```

**Script: `/opt/moode/bin/hardware-init.sh`**
```bash
#!/bin/bash

# Prüfe I2C Bus 1
if [ -e /dev/i2c-1 ]; then
    echo "I2C Bus 1 verfügbar"
    i2cdetect -y 1
else
    echo "WARNING: I2C Bus 1 nicht verfügbar"
fi

# Prüfe Audio Hardware
until aplay -l | grep -q hifiberry; do
    echo "Warte auf Audio Hardware..."
    sleep 1
done

echo "Audio Hardware gefunden"
aplay -l
```

---

## PHASE 4: MONITORING & DIAGNOSTIK

### **4.1 Boot-Sequenz Monitoring:**

**Script: `/opt/moode/bin/boot-analyze.sh`**
```bash
#!/bin/bash

echo "=== BOOT-SEQUENZ ANALYSE ==="
echo ""

echo "Service-Start-Zeiten:"
systemd-analyze blame | grep -E 'localdisplay|ft6236|mpd|peppymeter|chromium'

echo ""
echo "Service-Abhängigkeiten:"
systemctl list-dependencies localdisplay.service --no-pager

echo ""
echo "Hardware-Status:"
echo "I2C Bus 1:"
i2cdetect -y 1
echo "Audio:"
aplay -l
echo "Display:"
cat /sys/class/graphics/fb0/virtual_size 2>/dev/null
```

---

## IMPLEMENTIERUNGS-CHECKLISTE

### **✅ Bereits implementiert:**
- [x] localdisplay.service
- [x] ft6236-delay.service
- [x] Config.txt Dokumentation

### **⏳ Zu implementieren:**
- [ ] MPD Service optimieren (After=localdisplay.service)
- [ ] PeppyMeter Service optimieren (Requires=localdisplay.service)
- [ ] Chromium Service optimieren (Restart=always)
- [ ] Config-Validierung Service
- [ ] Hardware-Init Service
- [ ] Boot-Analyse Script

---

## TEST-PROZESS

### **1. Service-Abhängigkeiten testen:**
```bash
# Prüfe Abhängigkeiten
systemctl list-dependencies localdisplay.service
systemctl list-dependencies mpd.service

# Prüfe Timing
systemd-analyze blame | grep -E 'localdisplay|mpd'
```

### **2. Config-Validierung testen:**
```bash
# Manuell ausführen
/opt/moode/bin/config-validate.sh

# Service testen
systemctl start config-validate.service
journalctl -u config-validate.service
```

### **3. Hardware-Init testen:**
```bash
# Manuell ausführen
/opt/moode/bin/hardware-init.sh

# Service testen
systemctl start hardware-init.service
journalctl -u hardware-init.service
```

---

---

## VOLUME MANAGEMENT TRANSFER

### **HiFiBerryOS Volume:**
- **Control:** DSPVolume (DSP-basiert)
- **Status:** Läuft auf 100% (Standard)
- **Korrektur:** `amixer -c 0 set 'DSPVolume' 50%`

### **moOde Volume:**
- **Control:** MPD Volume Control
- **Status:** Kann über MPD gesteuert werden
- **Transfer:** MPD Volume auf sinnvollen Wert setzen

### **Erkenntnis:**
- HiFiBerryOS: Hardware-Volume (DSPVolume)
- moOde: Software-Volume (MPD)
- **Beide:** Sollten auf sinnvollem Wert starten (nicht 100%)

---

## WEITERARBEITEN AM PI 5 SYSTEM

### **Ziele:**
1. Service-Abhängigkeiten optimieren
2. Config.txt perfekt konfigurieren
3. Timing-Probleme lösen
4. Von HiFiBerryOS lernen und adaptieren

### **Nächste Schritte:**
1. Pi 5 System analysieren
2. Service-Abhängigkeiten prüfen
3. Config.txt optimieren
4. Timing testen

---

**Implementierung wird kontinuierlich erweitert...**

