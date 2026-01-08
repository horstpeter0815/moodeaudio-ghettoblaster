# INSTALLATION: DSP ADD-ON RESET FÜR AMP100

**Datum:** 1. Dezember 2025  
**Ziel:** Reset vom DSP Add-on aus, OHNE am PCM5122 Chip zu löten

---

## 📋 ÜBERSICHT

### **Lösung:**
- Overlay OHNE `reset-gpio` definieren
- DSP Add-on steuert GPIO 17 komplett
- Systemd Service führt Reset durch (vor Treiber-Laden)
- **KEIN LÖTEN AM CHIP NÖTIG!**

### **Verbindungspfad:**
```
DSP Add-on → GPIO 17 → AMP100 Board → PCM5122 Reset-Pin
(Bereits vorhanden! Standard-Verbindung!)
```

---

## 🔧 INSTALLATION

### **SCHRITT 1: OVERLAY KOMPILIEREN UND INSTALLIEREN**

```bash
# Auf dem Raspberry Pi (oder mit Cross-Compiler):

# 1. DTS nach /boot/firmware/overlays/ kopieren
sudo cp hifiberry-amp100-pi5-dsp-reset.dts /boot/firmware/overlays/

# 2. Kompilieren
cd /boot/firmware/overlays/
sudo dtc -@ -I dts -O dtb -o hifiberry-amp100-pi5-dsp-reset.dtbo hifiberry-amp100-pi5-dsp-reset.dts

# 3. Berechtigungen setzen
sudo chmod 644 hifiberry-amp100-pi5-dsp-reset.dtbo
```

### **SCHRITT 2: CONFIG.TXT AKTUALISIEREN**

```bash
# /boot/firmware/config.txt bearbeiten
sudo nano /boot/firmware/config.txt
```

**Hinzufügen/Ändern:**
```ini
# Altes Overlay entfernen (falls vorhanden):
# dtoverlay=hifiberry-amp100-pi5-gpio14
# dtoverlay=hifiberry-amp100-pi5-no-reset

# Neues Overlay aktivieren:
dtoverlay=hifiberry-amp100-pi5-dsp-reset

# Weitere Einstellungen (falls noch nicht vorhanden):
dtoverlay=vc4-kms-v3d-pi5,noaudio
dtparam=i2c_arm=on
dtparam=i2s=on
force_eeprom_read=0
```

### **SCHRITT 3: RESET-SCRIPT INSTALLIEREN**

```bash
# Script nach /usr/local/bin/ kopieren
sudo cp dsp-reset-amp100.sh /usr/local/bin/
sudo chmod +x /usr/local/bin/dsp-reset-amp100.sh
```

### **SCHRITT 4: SYSTEMD SERVICE INSTALLIEREN**

```bash
# Service nach /etc/systemd/system/ kopieren
sudo cp dsp-reset-amp100.service /etc/systemd/system/

# Service aktivieren
sudo systemctl daemon-reload
sudo systemctl enable dsp-reset-amp100.service

# Service testen (ohne Reboot)
sudo systemctl start dsp-reset-amp100.service
sudo systemctl status dsp-reset-amp100.service
```

### **SCHRITT 5: MOODE DATENBANK AKTUALISIEREN**

```bash
# i2sdevice auf AMP100 setzen
moodeutl -w i2sdevice "HiFiBerry AMP100"
```

---

## ✅ VERIFICATION

### **1. OVERLAY PRÜFEN:**

```bash
# Overlay sollte geladen sein
vcgencmd get_config dtoverlay | grep hifiberry-amp100-pi5-dsp-reset
```

### **2. GPIO 17 PRÜFEN:**

```bash
# GPIO 17 sollte exportiert sein
ls -la /sys/class/gpio/gpio17

# GPIO 17 Wert prüfen (sollte 1 = HIGH sein)
cat /sys/class/gpio/gpio17/value
```

### **3. PCM5122 PRÜFEN:**

```bash
# I2C Bus 13 prüfen
i2cdetect -y 13

# Sollte 0x4d zeigen (PCM5122)
```

### **4. SOUNDCARD PRÜFEN:**

```bash
# Soundcard sollte erkannt sein
aplay -l

# Sollte "snd_rpi_hifiberry_dacplus" zeigen
```

### **5. SERVICE LOGS PRÜFEN:**

```bash
# Service-Logs anzeigen
sudo journalctl -u dsp-reset-amp100.service -n 50

# Sollte erfolgreich sein (keine Fehler)
```

---

## 🔍 TROUBLESHOOTING

### **Problem: "Failed to reset device: -11"**

**Ursache:** Treiber versucht immer noch, GPIO 17 zu steuern

**Lösung:**
1. Prüfen, ob Overlay korrekt geladen ist
2. Prüfen, ob `reset-gpio` wirklich nicht im Overlay ist
3. Dmesg prüfen: `dmesg | grep pcm5122`

### **Problem: GPIO 17 kann nicht exportiert werden**

**Ursache:** GPIO 17 ist bereits exportiert (vom DSP Add-on)

**Lösung:**
- Das ist OK! Script prüft, ob GPIO bereits exportiert ist
- Script verwendet bereits exportiertes GPIO

### **Problem: Soundcard wird nicht erkannt**

**Ursache:** Reset funktioniert nicht oder I2C-Verbindung fehlt

**Lösung:**
1. Reset-Script manuell ausführen: `sudo /usr/local/bin/dsp-reset-amp100.sh`
2. I2C Bus 13 prüfen: `i2cdetect -y 13`
3. Dmesg prüfen: `dmesg | grep -i pcm5122`

---

## 📝 WICHTIGE HINWEISE

1. **GPIO 17 Verbindung:**
   - DSP Add-on → GPIO 17 → AMP100 Board → PCM5122 Reset-Pin
   - **Bereits vorhanden!** Kein Löten nötig!

2. **Reset-Timing:**
   - Reset muss VOR Treiber-Laden erfolgen
   - Systemd Service mit `Before=sound.target`

3. **Overlay ohne reset-gpio:**
   - Overlay definiert KEINEN `reset-gpio`
   - DSP Add-on steuert GPIO 17 komplett
   - Kein Konflikt!

---

## 🔄 NÄCHSTE SCHRITTE

1. ✅ Overlay installieren
2. ✅ Reset-Script installieren
3. ✅ Systemd Service aktivieren
4. ✅ Rebooten
5. ✅ Prüfen, ob Soundcard erkannt wird

---

**Status:** ✅ Installation vorbereitet - Bereit zum Testen!

