# DSP Add-on → AMP100 Verbindungen

**Datum:** 1. Dezember 2025  
**Hardware-Setup:** DSP Add-on auf Pi → einzelne Kabel → AMP100

---

## 📋 GPIO VERBINDUNGEN: DSP ADD-ON → AMP100

### **JA, es gibt SDA/SCL Verbindungen!**

Basierend auf HiFiBerry Dokumentation:

| GPIO | Pin | Funktion | Verbindung |
|------|-----|----------|------------|
| **GPIO 2** | Pin 3 | **SDA (I2C Data)** | ✅ **DSP Add-on → AMP100** |
| **GPIO 3** | Pin 5 | **SCL (I2C Clock)** | ✅ **DSP Add-on → AMP100** |
| GPIO 4 | Pin 7 | MUTE | ✅ DSP Add-on → AMP100 |
| GPIO 17 | Pin 11 | RESET | ✅ DSP Add-on → AMP100 |
| GPIO 18-21 | Pins 12,35,38,40 | I2S Sound | ✅ DSP Add-on → AMP100 |

---

## 🔍 WICHTIGE ERKENNTNISSE

### 1. **I2C-Verbindung läuft über DSP Add-on**

**Setup:**
```
Raspberry Pi
    ↓ (GPIO Header)
DSP Add-on (sitzt auf Pi)
    ↓ (einzelne Kabel)
AMP100 (separates Board)
```

**I2C-Pfad:**
- Pi → DSP Add-on (über GPIO Header)
- DSP Add-on → AMP100 (über einzelne Kabel: GPIO 2/3 = SDA/SCL)

### 2. **Warum PCM5122 auf Bus 13 ist**

**Problem:**
- I2C läuft NICHT direkt über GPIO 2/3 vom Pi
- Sondern über DSP Add-on → AMP100
- DSP Add-on verwendet möglicherweise RP1 I2C Controller (Bus 13)

**Das erklärt:**
- ✅ Warum PCM5122 auf Bus 13 ist (nicht Bus 1)
- ✅ Warum Bus 1 leer ist
- ✅ Warum Custom Overlay für Bus 13 nötig ist

---

## 🔧 KONSEQUENZEN FÜR DIE LÖSUNG

### Option 1: Custom Overlay für Bus 13 (aktuell)

**Status:**
- ✅ Overlay erstellt für Bus 13
- ✅ PCM5122 wird erkannt
- ❌ Reset-Fehler (-11) muss noch gelöst werden

**Warum das richtig ist:**
- I2C läuft über DSP Add-on → Bus 13
- Overlay muss Bus 13 verwenden, nicht Bus 1

### Option 2: Hardware-Kabel direkt (nicht möglich)

**Warum nicht:**
- ❌ GPIO 2/3 sind bereits vom DSP Add-on verwendet
- ❌ Können nicht direkt vom Pi zu AMP100 verbunden werden
- ❌ Würde Konflikt mit DSP Add-on verursachen

---

## 📝 LÖSUNG: RESET-PINS VOM DSP ADD-ON

### Problem: Reset-Fehler (-11)

**Ursache:**
- Overlay versucht GPIO 17/4 zu steuern
- Aber DSP Add-on steuert diese Pins bereits
- Konflikt → Reset schlägt fehl

### Lösung: Reset-Pins optional machen

**Im Overlay:**
- Reset-Pins NICHT vom Overlay steuern lassen
- DSP Add-on steuert Reset/Mute
- Overlay nur für I2C + Sound Node

---

## ✅ EMPFEHLUNG

### Custom Overlay für Bus 13 (ohne Reset-Pins)

1. **Overlay behält:**
   - ✅ I2C Bus 13 für PCM5122
   - ✅ Sound Node
   - ✅ Clock (dacpro_osc)

2. **Overlay entfernt:**
   - ❌ Reset-Pin Steuerung (GPIO 17)
   - ❌ Mute-Pin Steuerung (GPIO 4)
   - ✅ Diese werden vom DSP Add-on gesteuert

3. **Vorteil:**
   - Kein Konflikt mit DSP Add-on
   - Reset-Fehler sollte verschwinden
   - DSP Add-on steuert Reset/Mute wie vorgesehen

---

## 🔄 NÄCHSTER SCHRITT

**Overlay ohne Reset/Mute-Pins erstellen:**
- Nur I2C + Sound Node
- Reset/Mute vom DSP Add-on
- Sollte Reset-Fehler beheben

---

**Status:** ✅ SDA/SCL Verbindungen identifiziert - Custom Overlay für Bus 13 ist richtig!

