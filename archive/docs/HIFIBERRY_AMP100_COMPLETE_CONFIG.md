# HiFiBerry AMP100 - Vollständige Konfiguration

**Datum:** 30. November 2025  
**Hardware:** Raspberry Pi 5, HiFiBerry AMP100 (DAC+ mit Amp)  
**Status:** Dokumentation basierend auf Recherche

---

## 🎯 WICHTIGE ERKENNTNISSE

### HiFiBerry AMP100
- **AMP100 = DAC+ mit integriertem Verstärker**
- **Overlay:** `hifiberry-amp100` (NICHT `hifiberry-dacplus-pro`)
- **Hardware:** PCM5122 DAC + TAS5756M Amp

---

## 📋 VOLLSTÄNDIGE KONFIGURATION

### `/boot/firmware/config.txt`

```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0

[all]
dtoverlay=vc4-kms-v3d
dtoverlay=hifiberry-amp100
dtparam=audio=off
dtparam=i2s=on
force_eeprom_read=0
```

**KRITISCHE PUNKTE:**

1. **Overlay:** `dtoverlay=hifiberry-amp100` (NICHT `hifiberry-dacplus-pro`)
2. **HDMI Audio deaktiviert:** `dtoverlay=vc4-kms-v3d-pi5,noaudio`
3. **Pi Audio deaktiviert:** `dtparam=audio=off`
4. **force_eeprom_read=0:** ERFORDERLICH für HiFiBerry (bereits persistent gesichert)
5. **I2S aktiviert:** `dtparam=i2s=on` (wird auch durch Overlay aktiviert)

---

## 🔑 I2S Device vs DT Overlay

### DT Overlay (Richtiger Weg)
- **DT Overlay aktiviert Hardware:** `dtoverlay=hifiberry-amp100` in config.txt
- **DT Overlay File System:** `/sys/firmware/devicetree/base/` (aktiv)
- **Overlay lädt Treiber automatisch**

### I2S Device in Moode
- **Nur Auswahl:** Welches Overlay verwendet wird
- **NICHT** separate Konfiguration
- **Muss zu Overlay passen:** `i2sdevice = 'HiFiBerry AMP100'` in Moode

**WICHTIG:** DT Overlay in config.txt ist die Hauptkonfiguration. Moode i2sdevice ist nur die Auswahl.

---

## ✅ force_eeprom_read=0

**Laut HiFiBerry Dokumentation: ERFORDERLICH**

**Warum:**
- Neuere Linux-Kernel lesen automatisch HAT-EEPROMs
- HiFiBerry hat EEPROM, das Konflikte verursachen kann
- `force_eeprom_read=0` deaktiviert automatisches Lesen
- **MUSS gesetzt sein**

**Status:**
- ✅ `force_eeprom_read=0` in config.txt
- ✅ Persistent durch systemd Service gesichert
- ✅ Wird bei jedem Boot korrigiert falls nötig

---

## 🔧 HDMI Audio deaktivieren

**ERFORDERLICH - HDMI und HiFiBerry können nicht gleichzeitig aktiv sein**

**Konfiguration:**
```ini
dtoverlay=vc4-kms-v3d-pi5,noaudio  # HDMI Audio deaktiviert
dtparam=audio=off                   # Pi Analog Audio deaktiviert
```

---

## 📝 Moode Audio Konfiguration

```sql
i2sdevice = 'HiFiBerry AMP100'
i2soverlay = 'None'  -- Wird durch config.txt Overlay gesetzt
audioout = 'Local'
```

**WICHTIG:** 
- Moode i2sdevice muss zu Overlay passen
- `hifiberry-amp100` Overlay → `i2sdevice = 'HiFiBerry AMP100'`

---

## 🛠️ INSTALLATION

### Schritt 1: config.txt anpassen

```bash
sudo nano /boot/firmware/config.txt
```

**Ändere:**
```ini
# ALT (FALSCH):
dtoverlay=hifiberry-dacplus-pro

# NEU (RICHTIG):
dtoverlay=hifiberry-amp100
```

### Schritt 2: Moode i2sdevice setzen

```bash
sqlite3 /var/local/www/db/moode-sqlite3.db "UPDATE cfg_system SET value='HiFiBerry AMP100' WHERE param='i2sdevice';"
```

### Schritt 3: MPD Konfiguration aktualisieren

```bash
sudo /var/www/command/worker.php --cmd="upd_mpd_config"
sudo systemctl restart mpd
```

### Schritt 4: Reboot

```bash
sudo reboot
```

---

## 🔍 DIAGNOSE

### Nach Reboot prüfen:

```bash
# 1. ALSA Soundkarten
aplay -l
# Erwartet: card 0: sndrpihifiberry [snd_rpi_hifiberry_amp100]

# 2. Hardware-Erkennung
dmesg | grep -i "hifiberry\|amp100\|pcm5122\|tas5756"

# 3. I2C Geräte
i2cdetect -y 1
# Erwartet: 0x4c (PCM5122 DAC), 0x2b (TAS5756M Amp)

# 4. DT Overlay Status
ls -la /sys/firmware/devicetree/base/sound/
```

---

## ✅ ERWARTETES ERGEBNIS

**Nach korrekter Konfiguration:**
- ✅ ALSA zeigt: `card 0: sndrpihifiberry [snd_rpi_hifiberry_amp100]`
- ✅ I2C zeigt: `0x4c` (DAC) und `0x2b` (Amp)
- ✅ dmesg zeigt: HiFiBerry AMP100 erkannt
- ✅ MPD kann Audio abspielen

---

## 📋 ZUSAMMENFASSUNG

**Korrekte Konfiguration:**
1. ✅ `dtoverlay=hifiberry-amp100` (NICHT dacplus-pro)
2. ✅ `dtoverlay=vc4-kms-v3d-pi5,noaudio` (HDMI Audio deaktiviert)
3. ✅ `dtparam=audio=off` (Pi Audio deaktiviert)
4. ✅ `force_eeprom_read=0` (ERFORDERLICH, persistent)
5. ✅ Moode: `i2sdevice = 'HiFiBerry AMP100'`

**WICHTIG:**
- DT Overlay ist die Hauptkonfiguration
- I2S Device in Moode ist nur die Auswahl
- force_eeprom_read=0 MUSS gesetzt sein
- HDMI Audio MUSS deaktiviert sein

---

---

## 🔍 DIAGNOSE-ERGEBNISSE

### Aktueller Status (30. November 2025)

**Konfiguration:**
- ✅ `dtoverlay=hifiberry-amp100` gesetzt
- ✅ `dtoverlay=vc4-kms-v3d-pi5,noaudio` (HDMI Audio deaktiviert)
- ✅ `dtparam=audio=off` (Pi Audio deaktiviert)
- ✅ `force_eeprom_read=0` (persistent gesichert)
- ✅ Moode: `i2sdevice = 'HiFiBerry AMP100'`

**Problem:**
- ❌ ALSA zeigt: `--- no soundcards ---`
- ❌ I2C Bus 1 zeigt keine Geräte (0x4c, 0x2b fehlen)
- ⚠️  dmesg zeigt: `deferred probe pending`
- ⚠️  Viele "lost arbitration" Fehler auf i2c1

**Erkenntnisse:**
- ✅ ALSA Module geladen: `snd_soc_hifiberry_dacplus`, `snd_soc_pcm512x`
- ✅ Overlay-Datei existiert und ist korrekt
- ✅ DT Overlay versucht zu laden, findet Hardware nicht
- ❌ I2C Bus 1 ist leer (keine Geräte auf 0x4c, 0x2b)

**Mögliche Ursachen:**
1. **Hardware nicht angeschlossen** - HiFiBerry AMP100 HAT nicht auf Pi gesteckt
2. **I2C Bus Problem** - "lost arbitration" Fehler deuten auf Bus-Konflikt hin
3. **Hardware-Defekt** - HAT antwortet nicht auf I2C

**Nächste Schritte:**
1. Hardware-Verbindung prüfen (HAT richtig aufgesteckt?)
2. I2C Bus Konflikt beheben
3. Hardware auf anderen Pi testen

---

**Letzte Aktualisierung:** 30. November 2025  
**Status:** Konfiguration korrekt, Hardware wird nicht erkannt

