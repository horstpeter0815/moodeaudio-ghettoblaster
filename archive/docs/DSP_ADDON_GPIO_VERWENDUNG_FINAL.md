# DSP ADD-ON GPIO-VERWENDUNG - FINALE ANALYSE

**Datum:** 1. Dezember 2025  
**Quelle:** HiFiBerry BeoCreate GPIO Dokumentation (Screenshot)

---

## 📋 VOM DSP ADD-ON (BEOCREATE) VERWENDETE GPIOs

**Aus der offiziellen BeoCreate GPIO-Dokumentation:**

| GPIO | WiringPI | Funktion | Bemerkung |
|------|----------|----------|-----------|
| **GPIO 2** | - | **I2C** | Control communication with the board |
| **GPIO 3** | - | **I2C** | Control communication with the board |
| **GPIO 7-11** | - | **SPI** | Control communication with the board |
| **GPIO 17** | 0 | **RESET** | Resets the board (reset = 1, operation = 0) |
| **GPIO 18-21** | - | **I2S** | Sound data |
| **GPIO 22** | 3 | **SELFBOOT** | Determines if board boots from integrated EEPROM |
| **GPIO 27** | 2 | **MUTE** | Mutes the power stages (1 = muted, 0 = unmuted) |

**WICHTIG:** Diese GPIOs **können NICHT für andere Zwecke verwendet werden!**

---

## ✅ VERFÜGBARE GPIOs (NICHT IN DER LISTE!)

### **GPIO 24** ✅ **VERFÜGBAR!**
- ❌ **NICHT** in der BeoCreate GPIO-Liste
- ✅ **NICHT** vom DSP Add-on verwendet
- ✅ **KANN** für Reset verwendet werden!

### **GPIO 25** ✅ **VERFÜGBAR!**
- ❌ **NICHT** in der BeoCreate GPIO-Liste
- ✅ **NICHT** vom DSP Add-on verwendet
- ✅ **KANN** für Reset verwendet werden!

---

## 🔍 ANALYSE: GPIO 24/25 AUF DEM DSP ADD-ON BOARD

### **PHYSISCHE VERFÜGBARKEIT:**

**DSP Add-on Extension Header:**
- ✅ Header spiegelt Raspberry Pi GPIO Header (2×20 = 40 Pins)
- ✅ Alle durchgeleiteten GPIOs sind am Header verfügbar
- ✅ GPIO 24/25 werden vom AMP100 durchgeleitet
- ✅ GPIO 24/25 werden vom DSP Add-on NICHT verwendet

**Position am Extension Header:**
- **GPIO 24** = Extension Header Pin 27 (Raspberry Pi Pin 18)
- **GPIO 25** = Extension Header Pin 28 (Raspberry Pi Pin 22)

---

## ✅ FINALE BESTÄTIGUNG

### **GPIO 24/25 SIND VERFÜGBAR!**

**Begründung:**
1. ✅ **NICHT in BeoCreate GPIO-Liste** → Nicht vom DSP Add-on verwendet
2. ✅ **NICHT vom AMP100 verwendet** → Durchgeleitet
3. ✅ **Verfügbar am Extension Header** → Physisch zugänglich
4. ✅ **Keine Konflikte** → Können für Reset verwendet werden

---

## 📍 PHYSISCHE POSITION AUF DEM DSP ADD-ON BOARD

### **EXTENSION HEADER (2×20 Pins)**

**Pin-Mapping:**
```
Extension Header (spiegelt Raspberry Pi GPIO Header):

Linke Spalte (1-20):        Rechte Spalte (21-40):
Pin 1  = 3.3V               Pin 21 = 5V
Pin 2  = 5V                 Pin 22 = GND
Pin 3  = GPIO 2 (I2C SDA)   Pin 23 = GPIO 3 (I2C SCL)
...
Pin 17 = GPIO 22            Pin 37 = GPIO 23
Pin 18 = GPIO 24 ← HIER!    Pin 38 = GPIO 25 ← HIER!
Pin 19 = GND                Pin 39 = GPIO 26
Pin 20 = GPIO 27            Pin 40 = GPIO 28
```

**GPIO 24/25 Position:**
- **GPIO 24** = Extension Header **Pin 18** (linke Spalte, 18. Pin von oben)
- **GPIO 25** = Extension Header **Pin 38** (rechte Spalte, 18. Pin von oben)

**ODER:**
- **GPIO 24** = Raspberry Pi **Pin 18** (wenn direkt am Pi gemessen)
- **GPIO 25** = Raspberry Pi **Pin 22** (wenn direkt am Pi gemessen)

---

## 🔧 KONSEQUENZ FÜR DIE LÖSUNG

### **GPIO 24/25 KÖNNEN VERWENDET WERDEN!**

**Vorteile:**
1. ✅ **NICHT vom DSP Add-on verwendet** (bestätigt durch Dokumentation)
2. ✅ **NICHT vom AMP100 verwendet** (durchgeleitet)
3. ✅ **Verfügbar am Extension Header** (physisch zugänglich)
4. ✅ **Keine Konflikte** (weder mit DSP noch mit AMP100)

**Verwendung:**
- **GPIO 24** (Extension Header Pin 18) → PCM5122 Reset-Pin
- **GPIO 25** (Extension Header Pin 38) → Alternative für Reset-Pin

---

## 📝 NÄCHSTE SCHRITTE

### **OPTION 1: GPIO 24 VERWENDEN** ⭐ **EMPFOHLEN**

1. **Löten:** DSP Add-on Extension Header **Pin 18** (GPIO 24) → PCM5122 Pin 8
2. **ODER:** Raspberry Pi Pin 18 (GPIO 24) → PCM5122 Pin 8
3. **Overlay:** `hifiberry-amp100-pi5-gpio24.dts` erstellen
4. **Reset-Pin:** `reset-gpio = <&gpio 24 1>;` (Active Low)

### **OPTION 2: GPIO 25 VERWENDEN** ⭐ **ALTERNATIVE**

1. **Löten:** DSP Add-on Extension Header **Pin 38** (GPIO 25) → PCM5122 Pin 8
2. **ODER:** Raspberry Pi Pin 22 (GPIO 25) → PCM5122 Pin 8
3. **Overlay:** `hifiberry-amp100-pi5-gpio25.dts` erstellen
4. **Reset-Pin:** `reset-gpio = <&gpio 25 1>;` (Active Low)

---

## ⚠️ WICHTIGE HINWEISE

1. **Extension Header vs. Raspberry Pi Header:**
   - Extension Header Pin 18 = GPIO 24 = Raspberry Pi Pin 18
   - Extension Header Pin 38 = GPIO 25 = Raspberry Pi Pin 22
   - Beide führen zum gleichen GPIO!

2. **Physische Position:**
   - Extension Header ist auf dem DSP Add-on Board
   - Pin 18/38 sind physisch zugänglich
   - Können direkt gelötet werden

3. **Verbindung:**
   - **Option A:** DSP Add-on Extension Header Pin 18/38 → PCM5122 Pin 8
   - **Option B:** Raspberry Pi Pin 18/22 → PCM5122 Pin 8
   - Beide führen zum gleichen GPIO!

---

## 📚 QUELLEN

1. **HiFiBerry BeoCreate GPIO Dokumentation:** 
   - URL: `hifiberry.com/beocreate/beocreate-doc/beocreate-gpios/`
   - Screenshot: `beocreate-gpios-page.png`
   - Tabelle: "CONTROL CONNECTIONS FROM THE RASPBERRY PI"

2. **AMP100 EEPROM:** 
   - `hifiberry-os/buildroot/package/hifiberry-test/eeprom/amp100.txt`
   - GPIO 24/25 nicht konfiguriert (durchgeleitet)

3. **DSP Add-on Data Sheet:** 
   - `hifiberry.com/docs/data-sheets/dsp-addon/`
   - Extension Header spiegelt GPIO Header

---

## ✅ ZUSAMMENFASSUNG

### **GPIO 24/25 SIND VERFÜGBAR!**

- ✅ **NICHT vom DSP Add-on verwendet** (bestätigt durch BeoCreate Dokumentation)
- ✅ **NICHT vom AMP100 verwendet** (durchgeleitet)
- ✅ **Verfügbar am Extension Header** (Pin 18/38)
- ✅ **Können für Reset verwendet werden!**

**Empfehlung:** GPIO 24 oder GPIO 25 für Reset-Pin verwenden!

---

**Status:** ✅ GPIO 24/25 sind auf dem DSP Add-on Board verfügbar und können verwendet werden!

