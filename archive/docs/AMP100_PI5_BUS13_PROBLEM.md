# HiFiBerry AMP100 auf Pi 5 - Bus 13 Problem

**Datum:** 1. Dezember 2025  
**Status:** ❌ PCM5122 auf falschem I2C Bus  
**Problem:** PCM5122 wird auf Bus 13 erkannt, Overlay erwartet Bus 1

---

## 🔍 PROBLEM

### Aktueller Status:
- ✅ `i2c1` Alias zeigt jetzt auf `i2c_arm` (`/soc@107c000000/i2c@7d005600`)
- ✅ PCM5122 wird erkannt: `pcm512x 13-004d: Failed to reset device: -11`
- ❌ PCM5122 ist auf **I2C Bus 13** (RP1 Controller: `107d508200.i2c`)
- ❌ Overlay erwartet PCM5122 auf **I2C Bus 1** (`i2c_arm`)
- ❌ Overlay kann nicht geladen werden: `Failed to apply overlay`

### Root Cause:
Das AMP100 HAT ist physisch auf einem anderen I2C Bus angeschlossen als erwartet:
- **Erwartet:** I2C Bus 1 (`i2c_arm`, GPIO Pins 2/3)
- **Tatsächlich:** I2C Bus 13 (RP1 Controller)

---

## 💡 MÖGLICHE URSACHEN

1. **Hardware-Verbindung:**
   - HAT nicht richtig auf GPIO-Header gesteckt
   - Falsche Pins belegt
   - HAT benötigt Pi 5 Adapter

2. **Pi 5 I2C Mapping:**
   - Pi 5 verwendet RP1 Controller
   - I2C Bus Mapping könnte anders sein
   - HAT könnte auf RP1 Bus angeschlossen sein

---

## 🔧 LÖSUNGEN

### Option 1: Hardware prüfen
- HAT richtig auf GPIO-Header stecken
- Sicherstellen, dass SDA/SCL auf GPIO 2/3 sind
- Prüfen ob Pi 5 Adapter benötigt wird

### Option 2: Custom Overlay für Bus 13
Erstelle ein angepasstes Overlay, das Bus 13 verwendet statt Bus 1.

### Option 3: I2C Bus Mapping ändern
Konfiguriere das System so, dass `i2c_arm` auf Bus 13 gemappt wird (falls möglich).

---

## 📋 NÄCHSTE SCHRITTE

1. **Hardware-Verbindung prüfen:**
   - HAT ab- und wieder aufstecken
   - Prüfen ob alle Pins korrekt sind
   - Prüfen ob Pi 5 Adapter benötigt wird

2. **Alternative: Custom Overlay erstellen:**
   - Overlay anpassen für Bus 13
   - Testen ob AMP100 dann funktioniert

---

**Status:** ⚠️ **HARDWARE AUF FALSCHEM I2C BUS**

