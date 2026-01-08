# Troubleshooting Guide

**Häufige Probleme und Lösungen für Ghetto Crew System**

---

## 🔧 Allgemeine Probleme

### **Problem: System bootet nicht**

**Symptome:**
- Kein Display-Output
- Keine LED-Aktivität
- System startet nicht

**Lösungen:**
1. **SD-Karte prüfen:**
   ```bash
   # SD-Karte auf Mac/Linux prüfen
   diskutil list  # Mac
   lsblk           # Linux
   ```

2. **Image erneut brennen:**
   - Image-Datei prüfen (MD5 Hash)
   - SD-Karte formatieren (FAT32)
   - Image erneut brennen

3. **Power Supply prüfen:**
   - Pi 5: 5V, 5A USB-C
   - Pi 4: 5V, 3A USB-C
   - Pi Zero 2W: 5V, 2.5A Micro-USB

4. **Boot-Logs prüfen:**
   - Serial Console anschließen
   - Boot-Messages lesen

---

### **Problem: Web-UI nicht erreichbar**

**Symptome:**
- `http://moode.local` funktioniert nicht
- IP-Adresse nicht bekannt

**Lösungen:**
1. **IP-Adresse finden:**
   ```bash
   # Auf dem Pi
   hostname -I
   ip addr show
   ```

2. **Netzwerk prüfen:**
   ```bash
   # Ping testen
   ping 192.168.178.161
   
   # SSH testen
   ssh pi@192.168.178.161
   ```

3. **Web-Server prüfen:**
   ```bash
   # Service Status
   systemctl status lighttpd
   
   # Service starten
   sudo systemctl start lighttpd
   ```

4. **Firewall prüfen:**
   ```bash
   # Firewall Status
   sudo ufw status
   
   # Firewall deaktivieren (temporär)
   sudo ufw disable
   ```

---

## 🔊 Audio-Probleme

### **Problem: Kein Audio-Output**

**Symptome:**
- Kein Sound
- Audio-Gerät nicht erkannt

**Lösungen:**
1. **HAT prüfen:**
   ```bash
   # HAT erkannt?
   vcgencmd get_config dtoverlay
   
   # Audio-Geräte
   aplay -l
   ```

2. **config.txt prüfen:**
   ```bash
   # config.txt anzeigen
   cat /boot/firmware/config.txt | grep -i audio
   cat /boot/firmware/config.txt | grep -i hifiberry
   ```

3. **MPD Status:**
   ```bash
   # MPD Status
   systemctl status mpd
   mpc status
   
   # MPD neu starten
   sudo systemctl restart mpd
   ```

4. **Volume prüfen:**
   ```bash
   # ALSA Volume
   amixer sget Master
   amixer sset Master 50%
   ```

---

### **Problem: Audio-Verzerrung**

**Symptome:**
- Verzerrter Sound
- Knacken/Poppen

**Lösungen:**
1. **Sample Rate prüfen:**
   ```bash
   # MPD Config
   cat /etc/mpd.conf | grep -i rate
   ```

2. **Buffer Size erhöhen:**
   - Web-UI: Audio Settings → Buffer Size
   - Empfohlen: 4096 oder höher

3. **CPU-Governor:**
   ```bash
   # Performance Mode
   sudo cpufreq-set -g performance
   ```

---

## 🖥️ Display-Probleme

### **Problem: Display zeigt nichts**

**Symptome:**
- Schwarzer Bildschirm
- Kein Signal

**Lösungen:**
1. **HDMI-Kabel prüfen:**
   - Kabel tauschen
   - Anderen HDMI-Port testen

2. **config.txt prüfen:**
   ```bash
   # Display-Config
   cat /boot/firmware/config.txt | grep -i hdmi
   cat /boot/firmware/config.txt | grep -i display
   ```

3. **Display-Info:**
   ```bash
   # Display-Status
   tvservice -s
   vcgencmd get_display_power_state
   ```

4. **Display ein/aus:**
   ```bash
   # Display einschalten
   vcgencmd display_power 1
   ```

---

### **Problem: Falsche Auflösung**

**Symptome:**
- Display zu klein/groß
- Falsche Aspect Ratio

**Lösungen:**
1. **hdmi_cvt prüfen:**
   ```bash
   # config.txt
   hdmi_cvt=1280 400 60 6 0 0 0
   ```

2. **Display-Mode ändern:**
   - Web-UI: System Settings → Display
   - Oder config.txt bearbeiten

---

### **Problem: Touchscreen funktioniert nicht**

**Symptome:**
- Keine Touch-Reaktion
- Touchscreen nicht erkannt

**Lösungen:**
1. **I2C prüfen:**
   ```bash
   # I2C Devices
   i2cdetect -y 1
   ```

2. **Service prüfen:**
   ```bash
   # FT6236 Service
   systemctl status ft6236-delay
   
   # Service starten
   sudo systemctl start ft6236-delay
   ```

3. **Touchscreen-Test:**
   ```bash
   # Event-Test
   evtest /dev/input/event0
   ```

4. **Kabel prüfen:**
   - I2C-Verbindung (SDA/SCL)
   - Power-Verbindung

---

## 🎛️ Feature-Probleme

### **Problem: Flat EQ funktioniert nicht**

**Symptome:**
- Checkbox hat keine Wirkung
- EQ wird nicht angewendet

**Lösungen:**
1. **Preset-Datei prüfen:**
   ```bash
   # Preset existiert?
   ls -l /var/www/html/command/ghettoblaster-flat-eq.json
   cat /var/www/html/command/ghettoblaster-flat-eq.json
   ```

2. **PHP Handler prüfen:**
   ```bash
   # Handler existiert?
   ls -l /var/www/html/command/ghettoblaster-flat-eq.php
   ```

3. **Logs prüfen:**
   ```bash
   # moOde Logs
   tail -f /var/log/moode.log | grep -i flat
   ```

4. **EQ Service prüfen:**
   ```bash
   # EQ Status
   moodeutl -A
   ```

---

### **Problem: Room Correction Wizard funktioniert nicht**

**Symptome:**
- Wizard öffnet nicht
- Measurement fehlgeschlagen
- Filter wird nicht angewendet

**Lösungen:**
1. **Browser-Kompatibilität:**
   - Chrome/Edge empfohlen
   - Mikrofon-Berechtigung prüfen

2. **File Upload prüfen:**
   ```bash
   # Upload-Verzeichnis
   ls -l /var/lib/camilladsp/measurements/
   
   # Permissions
   sudo chown -R www-data:www-data /var/lib/camilladsp/
   ```

3. **CamillaDSP prüfen:**
   ```bash
   # Service Status
   systemctl status camilladsp
   
   # Config prüfen
   camilladsp --check /etc/camilladsp/config.yml
   ```

4. **Logs prüfen:**
   ```bash
   # CamillaDSP Logs
   journalctl -u camilladsp -f
   ```

---

## 🔌 Hardware-Probleme

### **Problem: HAT wird nicht erkannt**

**Symptome:**
- HAT funktioniert nicht
- Keine Kommunikation

**Lösungen:**
1. **GPIO-Verbindung prüfen:**
   - HAT korrekt auf GPIO gesteckt?
   - Standoffs montiert?

2. **dtoverlay prüfen:**
   ```bash
   # Overlay geladen?
   vcgencmd get_config dtoverlay
   ```

3. **I2C/I2S prüfen:**
   ```bash
   # I2C Devices
   i2cdetect -y 1
   
   # I2S Status
   cat /boot/firmware/config.txt | grep -i i2s
   ```

4. **Neustart:**
   ```bash
   sudo reboot
   ```

---

## 📊 Performance-Probleme

### **Problem: System langsam**

**Symptome:**
- Hohe CPU-Auslastung
- Audio-Dropouts

**Lösungen:**
1. **CPU-Status:**
   ```bash
   # CPU-Auslastung
   top
   htop
   
   # Temperatur
   vcgencmd measure_temp
   ```

2. **Services prüfen:**
   ```bash
   # Laufende Services
   systemctl list-units --type=service --state=running
   ```

3. **RAM-Status:**
   ```bash
   # RAM-Auslastung
   free -h
   ```

---

## 🔗 Weitere Ressourcen

- **Hardware-Setup:** [hardware-setup.md](hardware-setup.md)
- **Commands:** [../quick-reference/commands.md](../quick-reference/commands.md)
- **Config:** [../config-parameters/](../config-parameters/)

---

**Letzte Aktualisierung:** 2025-12-07

