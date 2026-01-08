# HiFiBerry AMP100 auf Pi 5 - Problem-Analyse

**Datum:** 1. Dezember 2025  
**Status:** ❌ AMP100 wird nicht erkannt  
**Hardware:** Raspberry Pi 5 Model B, HiFiBerry AMP100

---

## 🔍 PROBLEM

### Symptome:
- ✅ Overlay-Module werden geladen (`snd_soc_pcm512x`, `snd_soc_hifiberry_dacplus`)
- ❌ Keine ALSA Soundkarte erstellt
- ❌ `deferred probe pending: (reason unknown)`
- ❌ PCM5122 nicht auf I2C Bus 1 gefunden
- ❌ `pcm512x 1-004d: probe with driver pcm512x failed with error -11`

### Konfiguration:
```ini
dtoverlay=hifiberry-amp100
dtoverlay=vc4-kms-v3d-pi5,noaudio
force_eeprom_read=0
dtparam=i2c_arm=on
dtparam=i2s=on
```

---

## 🔬 DIAGNOSE

### I2C Bus Status:
- **Bus 1:** Leer (keine Geräte)
- **Bus 13/14:** Viele Geräte (RP1 Controller, nicht AMP100)

### Problem:
Das Overlay erwartet PCM5122 auf **I2C Bus 1** (`i2c_arm`), aber:
- Bus 1 ist komplett leer
- PCM5122 ist nicht erreichbar
- Hardware-Verbindung möglicherweise defekt oder nicht richtig angeschlossen

---

## 💡 MÖGLICHE URSACHEN

1. **Hardware-Verbindung:**
   - HAT nicht richtig auf GPIO-Header gesteckt
   - I2C Verbindung (SDA/SCL) defekt
   - Falsche GPIO-Pins belegt

2. **I2C Bus Mapping auf Pi 5:**
   - Pi 5 verwendet RP1 Controller
   - I2C Bus Mapping könnte anders sein als auf Pi 4
   - `i2c_arm` könnte auf anderen Bus gemappt sein

3. **Overlay-Kompatibilität:**
   - Overlay ist für Pi 4 optimiert
   - Pi 5 Device Tree Struktur unterschiedlich
   - Sound-Node kann nicht erstellt werden

---

## 🔧 NÄCHSTE SCHRITTE

1. **Hardware prüfen:**
   - HAT richtig aufstecken
   - I2C Verbindung testen
   - Multimeter für Kontinuität

2. **I2C Bus Mapping prüfen:**
   - Welcher Bus ist wirklich `i2c_arm`?
   - Prüfe Device Tree für I2C Mapping

3. **Alternative Overlay-Konfiguration:**
   - Prüfe ob Overlay-Optionen helfen
   - Custom Overlay für Pi 5 erstellen

---

**Status:** ⚠️ **HARDWARE-VERBINDUNG VERMUTET**

