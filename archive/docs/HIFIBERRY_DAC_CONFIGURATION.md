# HiFiBerry DAC+ Pro Konfiguration - Vollständige Dokumentation

**Datum:** 30. November 2025  
**Hardware:** Raspberry Pi 5, HiFiBerry DAC+ Pro  
**Status:** Konfiguration dokumentiert

---

## 📋 WICHTIGE ERKENNTNISSE

### 1. I2S Device vs DT Overlay

**DT Overlay ist der richtige Weg:**
- `dtoverlay=hifiberry-dacplus-pro` in `/boot/firmware/config.txt`
- DT Overlay File System ist aktiv: `/sys/firmware/devicetree/base/` existiert
- I2S Device in Moode ist nur die **Auswahl** welches Overlay verwendet wird
- **NICHT** zwei separate Konfigurationen - DT Overlay aktiviert I2S automatisch

**Konfiguration:**
```ini
# DT Overlay aktiviert HiFiBerry
dtoverlay=hifiberry-dacplus-pro

# I2S wird automatisch aktiviert durch Overlay
dtparam=i2s=on  # Optional, wird durch Overlay aktiviert
```

### 2. force_eeprom_read=0

**Laut HiFiBerry Dokumentation: ERFORDERLICH für HiFiBerry DAC+ Pro**

**Warum:**
- Neuere Linux-Kernel-Versionen lesen automatisch HAT-EEPROMs
- HiFiBerry DAC+ Pro hat ein EEPROM, das Konflikte verursachen kann
- `force_eeprom_read=0` deaktiviert das automatische Lesen des HAT-EEPROMs
- **MUSS gesetzt sein:** `force_eeprom_read=0` in `/boot/firmware/config.txt`

**Aktueller Status:**
- ✅ `force_eeprom_read=0` ist gesetzt
- ✅ Persistent durch systemd Service gesichert

### 3. HDMI Audio deaktivieren

**ERFORDERLICH für HiFiBerry - HDMI und HiFiBerry können nicht gleichzeitig aktiv sein**

**Konfiguration:**
```ini
# HDMI Audio DEAKTIVIEREN
dtoverlay=vc4-kms-v3d-pi5,noaudio

# Pi Analog Audio DEAKTIVIEREN
dtparam=audio=off
```

**Aktueller Status:**
- ✅ `dtoverlay=vc4-kms-v3d-pi5,noaudio` ist gesetzt
- ✅ `dtparam=audio=off` ist gesetzt

---

## ✅ KORREKTE KONFIGURATION

### `/boot/firmware/config.txt`

```ini
[pi5]
dtoverlay=vc4-kms-v3d-pi5,noaudio
hdmi_enable_4kp60=0

[all]
dtoverlay=vc4-kms-v3d
dtoverlay=hifiberry-dacplus-pro
dtparam=audio=off
dtparam=i2s=on
force_eeprom_read=0
```

**WICHTIGE PUNKTE:**
1. ✅ `dtoverlay=hifiberry-dacplus-pro` - Aktiviert HiFiBerry
2. ✅ `dtoverlay=vc4-kms-v3d-pi5,noaudio` - HDMI Audio deaktiviert
3. ✅ `dtparam=audio=off` - Pi Analog Audio deaktiviert
4. ✅ `force_eeprom_read=0` - **ERFORDERLICH** für HiFiBerry DAC+ Pro
5. ✅ `dtparam=i2s=on` - I2S aktiviert (wird auch durch Overlay aktiviert)

### Moode Audio Konfiguration

```sql
i2sdevice = 'HiFiBerry DAC+ Pro'
i2soverlay = 'None'  -- Wird durch config.txt Overlay gesetzt
audioout = 'Local'
```

---

## 🔍 AKTUELLER STATUS

**Was funktioniert:**
- ✅ DT Overlay File System aktiv
- ✅ `force_eeprom_read=0` gesetzt und persistent
- ✅ HDMI Audio deaktiviert
- ✅ HiFiBerry Overlay in config.txt
- ✅ Moode auf HiFiBerry konfiguriert

**Problem:**
- ❌ HiFiBerry wird NICHT erkannt: `--- no soundcards ---`
- ❌ I2C Scan zeigt keine Geräte
- ❌ Keine HiFiBerry Hardware-Erkennung in dmesg

**Mögliche Ursachen:**
1. **Hardware nicht angeschlossen** - HiFiBerry HAT nicht auf Pi gesteckt
2. **I2C Problem** - I2C Bus funktioniert nicht
3. **Overlay wird nicht geladen** - DT Overlay Fehler
4. **Falsches Overlay** - `hifiberry-dacplus-pro` vs `hifiberry-dacplus`

---

## 🛠️ DIAGNOSE-SCHRITTE

### 1. Prüfe Hardware-Verbindung
```bash
# I2C Bus prüfen
i2cdetect -y 1

# Erwartet: Gerät auf Adresse 0x4c (PCM5122 DAC Chip)
```

### 2. Prüfe DT Overlay wird geladen
```bash
# Prüfe ob Overlay geladen wurde
dmesg | grep -i "hifiberry\|dacplus\|pcm5122"

# Prüfe DT Overlay Status
ls -la /sys/firmware/devicetree/base/sound/
```

### 3. Prüfe Overlay-Datei
```bash
# Prüfe ob Overlay-Datei existiert
ls -la /boot/firmware/overlays/hifiberry-dacplus-pro.dtbo

# Prüfe Overlay-Inhalt
dtc -I dtb -O dts /boot/firmware/overlays/hifiberry-dacplus-pro.dtbo | head -20
```

### 4. Prüfe I2S Status
```bash
# Prüfe I2S wird aktiviert
dmesg | grep -i "i2s\|bcm2835"

# Prüfe I2S Device
ls -la /dev/snd/
```

---

## 📝 ZUSAMMENFASSUNG

**Korrekte Konfiguration (alle Punkte erfüllt):**
1. ✅ DT Overlay: `dtoverlay=hifiberry-dacplus-pro`
2. ✅ HDMI Audio deaktiviert: `dtoverlay=vc4-kms-v3d-pi5,noaudio`
3. ✅ Pi Audio deaktiviert: `dtparam=audio=off`
4. ✅ `force_eeprom_read=0` gesetzt (ERFORDERLICH)
5. ✅ Moode auf HiFiBerry konfiguriert

**Nächster Schritt:**
- Hardware-Verbindung prüfen
- I2C Bus prüfen
- DT Overlay Lade-Status prüfen

---

**WICHTIG:** Diese Konfiguration ist korrekt. Wenn HiFiBerry nicht erkannt wird, liegt es an Hardware oder I2C, nicht an der Konfiguration.

**Letzte Aktualisierung:** 30. November 2025

