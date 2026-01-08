# Status Zusammenfassung - HiFiBerry AMP100 auf Pi 5

**Datum:** 1. Dezember 2025  
**Zeitaufwand:** ~10 Stunden

---

## ✅ ERREICHT

### 1. Custom Overlay erstellt
- **Datei:** `/boot/firmware/overlays/hifiberry-amp100-pi5.dtbo`
- **Source:** `/boot/firmware/overlays/hifiberry-amp100-pi5.dts`
- **Kompatibilität:** Raspberry Pi 5 (`brcm,bcm2712`)
- **I2C Bus:** Bus 13 (RP1 Controller) statt Bus 1

### 2. Hardware-Verbindungen dokumentiert
- **DSP Add-on → AMP100:**
  - GPIO 2 (Pin 3) = SDA
  - GPIO 3 (Pin 5) = SCL
  - GPIO 4 (Pin 7) = MUTE
  - GPIO 17 (Pin 11) = RESET

### 3. Reset-Service erstellt
- **Script:** `/usr/local/bin/reset-amp100.sh`
- **Service:** `/etc/systemd/system/reset-amp100.service`
- **Timing:** Wird vor Treiber-Laden ausgeführt

### 4. Konfiguration
- **config.txt:** `dtoverlay=hifiberry-amp100-pi5`
- **Moode DB:** Bereit für `i2sdevice = 'HiFiBerry AMP100'`

---

## ❌ VERBLEIBENDES PROBLEM

### Reset-Fehler (-11) verhindert Treiber-Bindung

**Symptom:**
```
pcm512x 1-004d: Failed to reset device: -11
pcm512x 1-004d: probe with driver pcm512x failed with error -11
```

**Auswirkung:**
- ❌ Treiber wird nicht gebunden
- ❌ Soundcard wird nicht registriert
- ❌ Keine Audio-Ausgabe

**Mögliche Ursachen:**
1. I2C Arbitration Problem ("lost arbitration")
2. GPIO-Konflikt (DSP Add-on vs. Treiber)
3. Reset-Timing Problem

---

## 📁 ERSTELLTE DATEIEN

### Overlay-Dateien
- `/boot/firmware/overlays/hifiberry-amp100-pi5.dtbo` - Kompiliertes Overlay
- `/boot/firmware/overlays/hifiberry-amp100-pi5.dts` - Source Code

### Scripts
- `/usr/local/bin/reset-amp100.sh` - Reset-Script
- `/etc/systemd/system/reset-amp100.service` - Systemd Service

### Dokumentation
- `CUSTOM_OVERLAY_FINAL_DOKUMENTATION.md` - Vollständige Dokumentation
- `DSP_ADDON_AMP100_VERBINDUNGEN.md` - GPIO-Verbindungen
- `GPIO_RESET_PIN_DOKUMENTATION.md` - Reset-Pin Details
- `HARDWARE_VS_SOFTWARE_ANALYSE.md` - Vergleich Hardware vs. Software
- `VERGLEICH_CUSTOM_OVERLAY_VS_CUSTOM_BUILD.md` - Vergleich Custom Overlay vs. Custom Build

---

## 🔄 NÄCHSTE SCHRITTE

### Option 1: Kernel-Patch (komplex)
- PCM5122 Treiber modifizieren
- Reset-Code optional machen
- Nicht wartbar bei Kernel-Updates

### Option 2: Alternative Treiber-Konfiguration
- Anderen Treiber verwenden
- Oder Treiber-Parameter anpassen

### Option 3: Hardware-Verbindung prüfen
- GPIO 2/3 (SDA/SCL) Verbindung prüfen
- Möglicherweise Hardware-Problem

---

**Status:** ⚠️ **TEILWEISE FUNKTIONIERT** - Reset-Problem muss noch gelöst werden
