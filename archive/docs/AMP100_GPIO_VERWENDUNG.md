# AMP100 GPIO-VERWENDUNG - VOLLSTÄNDIGE ANALYSE

**Datum:** 1. Dezember 2025  
**Ziel:** Prüfen, welche GPIO-Pins vom AMP100 Board verwendet werden vs. durchgeleitet werden

---

## 📋 GPIO-VERWENDUNG: AMP100 BOARD

### **VOM AMP100 BOARD VERWENDETE GPIOs:**

| GPIO | Pin | Funktion | EEPROM Config | Verwendung |
|------|-----|----------|---------------|------------|
| **GPIO 2** | Pin 3 | **I2C SDA** | `ALT0 UP` | ✅ **VOM AMP100 VERWENDET** |
| **GPIO 3** | Pin 5 | **I2C SCL** | `ALT0 UP` | ✅ **VOM AMP100 VERWENDET** |
| **GPIO 4** | Pin 7 | **MUTE** | Kommentiert (aber im Overlay) | ✅ **VOM AMP100 VERWENDET** |
| **GPIO 14** | Pin 8 | **UART TXD** | `INPUT DEFAULT` | ⚠️ **VOM AMP100 KONFIGURIERT** |
| **GPIO 17** | Pin 11 | **RESET** | Kommentiert (aber im Overlay) | ✅ **VOM AMP100 VERWENDET** |
| **GPIO 18** | Pin 12 | **I2S BCLK** | `ALT0 DEFAULT` | ✅ **VOM AMP100 VERWENDET (I2S)** |
| **GPIO 19** | Pin 35 | **I2S LRCLK** | `ALT0 DEFAULT` | ✅ **VOM AMP100 VERWENDET (I2S)** |
| **GPIO 20** | Pin 38 | **I2S DIN** | `ALT0 DEFAULT` | ✅ **VOM AMP100 VERWENDET (I2S)** |
| **GPIO 21** | Pin 40 | **I2S MCLK** | `ALT0 DEFAULT` | ✅ **VOM AMP100 VERWENDET (I2S)** |
| **GPIO 23** | Pin 16 | **Unbekannt** | `INPUT DEFAULT` | ⚠️ **VOM AMP100 KONFIGURIERT** |

### **DURCHGELEITETE GPIOs (NICHT VOM AMP100 VERWENDET):**

| GPIO | Pin | EEPROM Config | Status |
|------|-----|---------------|--------|
| **GPIO 24** | Pin 18 | Kommentiert aus | ✅ **WIRD DURCHGELEITET** |
| **GPIO 25** | Pin 22 | Kommentiert aus | ✅ **WIRD DURCHGELEITET** |
| GPIO 5-13 | Verschiedene | Kommentiert aus | ✅ **WERDEN DURCHGELEITET** |
| GPIO 15-16 | Verschiedene | Kommentiert aus | ✅ **WERDEN DURCHGELEITET** |
| GPIO 22 | Pin 15 | Kommentiert aus | ✅ **WIRD DURCHGELEITET** |
| GPIO 26-27 | Verschiedene | Kommentiert aus | ✅ **WERDEN DURCHGELEITET** |

---

## 🔍 ANALYSE DER VORGESCHLAGENEN GPIO-PINS

### **GPIO 18** ❌ **NICHT VERFÜGBAR!**
- **Status:** ✅ **VOM AMP100 VERWENDET (I2S BCLK)**
- **EEPROM:** `setgpio 18 ALT0 DEFAULT`
- **Funktion:** I2S Bit Clock für Audio
- **Konsequenz:** ❌ **KANN NICHT FÜR RESET VERWENDET WERDEN!**

### **GPIO 23** ⚠️ **FRAGLICH!**
- **Status:** ⚠️ **VOM AMP100 KONFIGURIERT (INPUT)**
- **EEPROM:** `setgpio 23 INPUT DEFAULT`
- **Funktion:** Unbekannt (aber als INPUT konfiguriert)
- **Konsequenz:** ⚠️ **MÖGLICHERWEISE VERFÜGBAR, ABER RISKANT**

### **GPIO 24** ✅ **VERFÜGBAR!**
- **Status:** ✅ **WIRD DURCHGELEITET**
- **EEPROM:** Kommentiert aus (nicht konfiguriert)
- **Funktion:** Nicht vom AMP100 verwendet
- **Konsequenz:** ✅ **KANN FÜR RESET VERWENDET WERDEN!**

### **GPIO 25** ✅ **VERFÜGBAR!**
- **Status:** ✅ **WIRD DURCHGELEITET**
- **EEPROM:** Kommentiert aus (nicht konfiguriert)
- **Funktion:** Nicht vom AMP100 verwendet
- **Konsequenz:** ✅ **KANN FÜR RESET VERWENDET WERDEN!**

---

## 📊 ZUSAMMENFASSUNG

### **VERFÜGBARE GPIO-PINS FÜR RESET:**

| GPIO | Pin | Verfügbar | Empfehlung |
|------|-----|-----------|------------|
| GPIO 14 | Pin 8 | ⚠️ Konfiguriert als INPUT | ⚠️ Möglich, aber UART |
| GPIO 18 | Pin 12 | ❌ **VERWENDET (I2S)** | ❌ **NICHT VERFÜGBAR!** |
| GPIO 23 | Pin 16 | ⚠️ Konfiguriert als INPUT | ⚠️ Möglich, aber riskant |
| **GPIO 24** | Pin 18 | ✅ **DURCHGELEITET** | ✅ **EMPFOHLEN!** |
| **GPIO 25** | Pin 22 | ✅ **DURCHGELEITET** | ✅ **EMPFOHLEN!** |

---

## ✅ EMPFEHLUNG

### **BESTE OPTIONEN:**

1. **GPIO 24 (Pin 18)** ⭐ **BESTE WAHL**
   - ✅ Wird vom AMP100 durchgeleitet
   - ✅ Nicht konfiguriert im EEPROM
   - ✅ Verfügbar für DSP Add-on
   - ✅ Keine Konflikte

2. **GPIO 25 (Pin 22)** ⭐ **ZWEITBESTE WAHL**
   - ✅ Wird vom AMP100 durchgeleitet
   - ✅ Nicht konfiguriert im EEPROM
   - ✅ Verfügbar für DSP Add-on
   - ✅ Keine Konflikte

3. **GPIO 14 (Pin 8)** ⚠️ **MÖGLICH, ABER PROBLEMATISCH**
   - ⚠️ Wird vom AMP100 als INPUT konfiguriert
   - ⚠️ Normalerweise UART TXD
   - ⚠️ UART muss deaktiviert werden
   - ✅ Aber bereits getestet

4. **GPIO 23 (Pin 16)** ⚠️ **RISKANT**
   - ⚠️ Wird vom AMP100 als INPUT konfiguriert
   - ⚠️ Funktion unbekannt
   - ⚠️ Möglicherweise für etwas verwendet

---

## 🔧 KONSEQUENZ FÜR DSP ADD-ON

### **DSP ADD-ON KANN VERWENDEN:**

✅ **GPIO 24** (Pin 18) - **EMPFOHLEN!**
- Wird vom AMP100 durchgeleitet
- Verfügbar am DSP Header
- Keine Konflikte

✅ **GPIO 25** (Pin 22) - **EMPFOHLEN!**
- Wird vom AMP100 durchgeleitet
- Verfügbar am DSP Header
- Keine Konflikte

❌ **GPIO 18** (Pin 12) - **NICHT VERFÜGBAR!**
- Wird vom AMP100 für I2S verwendet
- **KANN NICHT VERWENDET WERDEN!**

---

## 📝 NÄCHSTE SCHRITTE

### **OPTION 1: GPIO 24 VERWENDEN** ⭐ **EMPFOHLEN**

1. **Overlay erstellen:** `hifiberry-amp100-pi5-gpio24.dts`
2. **Reset-Pin:** `reset-gpio = <&gpio 24 1>;` (Active Low)
3. **Löten:** Raspberry Pi Pin 18 (GPIO 24) → PCM5122 Pin 8
4. **Vorteil:** Keine Konflikte, durchgeleitet

### **OPTION 2: GPIO 25 VERWENDEN** ⭐ **ALTERNATIVE**

1. **Overlay erstellen:** `hifiberry-amp100-pi5-gpio25.dts`
2. **Reset-Pin:** `reset-gpio = <&gpio 25 1>;` (Active Low)
3. **Löten:** Raspberry Pi Pin 22 (GPIO 25) → PCM5122 Pin 8
4. **Vorteil:** Keine Konflikte, durchgeleitet

---

## ⚠️ WICHTIGE HINWEISE

1. **GPIO 18 ist NICHT verfügbar!**
   - Wird für I2S verwendet
   - **NICHT für Reset verwenden!**

2. **GPIO 24/25 sind verfügbar!**
   - Werden durchgeleitet
   - **KÖNNEN für Reset verwendet werden!**

3. **DSP Add-on Header:**
   - Spiegelt den GPIO Header
   - Durchgeleitete GPIOs sind verfügbar
   - GPIO 24/25 sind am DSP Header verfügbar

---

## 📚 QUELLEN

1. **AMP100 EEPROM-Konfiguration:** `hifiberry-os/buildroot/package/hifiberry-test/eeprom/amp100.txt`
2. **AMP100 Overlay:** `kernel-build/linux/arch/arm/boot/dts/overlays/hifiberry-amp100-overlay.dts`
3. **HiFiBerry Dokumentation:** GPIO Usage of HiFiBerry Boards
4. **DSP Add-on Dokumentation:** DSP Add-on Data Sheet

---

**Status:** ✅ GPIO-Verwendung analysiert - GPIO 24/25 sind verfügbar!

