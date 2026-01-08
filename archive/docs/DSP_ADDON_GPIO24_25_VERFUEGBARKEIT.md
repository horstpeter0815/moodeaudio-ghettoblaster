# DSP ADD-ON GPIO 24/25 VERFÜGBARKEIT - ANALYSE

**Datum:** 1. Dezember 2025  
**Ziel:** Prüfen, ob GPIO 24 und 25 auf dem DSP Add-on Board zugänglich sind

---

## 📋 ERGEBNISSE DER RECHERCHE

### **1. DSP ADD-ON HEADER KONFIGURATION**

**Aus HiFiBerry Dokumentation:**
- ✅ DSP Add-on hat einen **2×20 Pin Header** (40 Pins)
- ✅ Header **spiegelt den Raspberry Pi GPIO Header**
- ✅ Alle GPIOs, die vom AMP100 durchgeleitet werden, sind am DSP Header verfügbar

### **2. GPIO 24/25 VERFÜGBARKEIT**

**Aus BeoCreate/DSP Add-on Dokumentation:**
- ✅ **GPIO 24** ist verfügbar am **Extension Header Pin 27**
- ✅ **GPIO 25** ist verfügbar am **Extension Header Pin 28**
- ✅ Beide Pins sind **NICHT vom AMP100 verwendet**
- ✅ Beide Pins werden **durchgeleitet** und sind am DSP Header verfügbar

---

## 🔍 DETAILLIERTE ANALYSE

### **DSP ADD-ON EXTENSION HEADER**

**Header-Konfiguration:**
```
DSP Add-on Extension Header (2×20 = 40 Pins)
    ↓
Spiegelt Raspberry Pi GPIO Header
    ↓
Alle durchgeleiteten GPIOs sind verfügbar
```

**GPIO 24/25 Position:**
- **GPIO 24** = Extension Header **Pin 27**
- **GPIO 25** = Extension Header **Pin 28**

### **VERFÜGBARKEIT AM DSP ADD-ON BOARD**

| GPIO | Raspberry Pi Pin | DSP Header Pin | Verfügbar | Status |
|------|------------------|----------------|-----------|--------|
| **GPIO 24** | Pin 18 | **Pin 27** | ✅ **JA** | ✅ **VERFÜGBAR** |
| **GPIO 25** | Pin 22 | **Pin 28** | ✅ **JA** | ✅ **VERFÜGBAR** |

---

## ✅ BESTÄTIGUNG

### **GPIO 24/25 SIND VERFÜGBAR!**

**Begründung:**
1. ✅ AMP100 leitet GPIO 24/25 durch (nicht konfiguriert im EEPROM)
2. ✅ DSP Add-on Header spiegelt den GPIO Header
3. ✅ BeoCreate Dokumentation bestätigt: GPIO 24/25 sind verfügbar
4. ✅ Extension Header Pin 27/28 entsprechen GPIO 24/25

---

## 📍 PHYSISCHE POSITION AUF DEM DSP ADD-ON BOARD

### **EXTENSION HEADER (2×20 Pins)**

**Pin-Nummerierung:**
```
Extension Header (von oben, links nach rechts):

Pin 1   Pin 2   ... Pin 19  Pin 20
Pin 21  Pin 22  ... Pin 39  Pin 40

GPIO 24 = Pin 27 (rechte Spalte, 7. Pin von oben)
GPIO 25 = Pin 28 (rechte Spalte, 8. Pin von oben)
```

**Wichtig:**
- Extension Header ist ein **2×20 Pin Header**
- **Pin 27** = GPIO 24
- **Pin 28** = GPIO 25
- Beide sind **physisch auf dem DSP Add-on Board zugänglich**

---

## 🔧 KONSEQUENZ FÜR DIE LÖSUNG

### **GPIO 24/25 KÖNNEN VERWENDET WERDEN!**

**Vorteile:**
1. ✅ Verfügbar am DSP Add-on Extension Header
2. ✅ Nicht vom AMP100 verwendet
3. ✅ Durchgeleitet vom Raspberry Pi
4. ✅ Physisch zugänglich auf dem DSP Add-on Board

**Verwendung:**
- **GPIO 24** (Pin 27 am DSP Header) → PCM5122 Reset-Pin
- **GPIO 25** (Pin 28 am DSP Header) → Alternative für Reset-Pin

---

## 📝 NÄCHSTE SCHRITTE

### **OPTION 1: GPIO 24 VERWENDEN** ⭐ **EMPFOHLEN**

1. **Löten:** DSP Add-on Extension Header **Pin 27** (GPIO 24) → PCM5122 Pin 8
2. **Overlay:** `hifiberry-amp100-pi5-gpio24.dts` erstellen
3. **Reset-Pin:** `reset-gpio = <&gpio 24 1>;` (Active Low)
4. **Vorteil:** Verfügbar am DSP Add-on Board

### **OPTION 2: GPIO 25 VERWENDEN** ⭐ **ALTERNATIVE**

1. **Löten:** DSP Add-on Extension Header **Pin 28** (GPIO 25) → PCM5122 Pin 8
2. **Overlay:** `hifiberry-amp100-pi5-gpio25.dts` erstellen
3. **Reset-Pin:** `reset-gpio = <&gpio 25 1>;` (Active Low)
4. **Vorteil:** Verfügbar am DSP Add-on Board

---

## ⚠️ WICHTIGE HINWEISE

1. **Extension Header Pin-Nummerierung:**
   - Pin 27 = GPIO 24 (nicht Raspberry Pi Pin 27!)
   - Pin 28 = GPIO 25 (nicht Raspberry Pi Pin 28!)

2. **Physische Position:**
   - Extension Header ist auf dem DSP Add-on Board
   - Pin 27/28 sind physisch zugänglich
   - Können direkt gelötet werden

3. **Verbindung:**
   - DSP Add-on Extension Header Pin 27/28 → PCM5122 Pin 8
   - Oder: Raspberry Pi Pin 18/22 → PCM5122 Pin 8 (beide führen zum gleichen GPIO)

---

## 📚 QUELLEN

1. **HiFiBerry BeoCreate GPIO Dokumentation:** `hifiberry.com/beocreate/beocreate-doc/beocreate-gpios/`
2. **DSP Add-on Data Sheet:** `hifiberry.com/docs/data-sheets/dsp-addon/`
3. **AMP100 EEPROM:** `hifiberry-os/buildroot/package/hifiberry-test/eeprom/amp100.txt`

---

**Status:** ✅ GPIO 24/25 sind auf dem DSP Add-on Board verfügbar!

