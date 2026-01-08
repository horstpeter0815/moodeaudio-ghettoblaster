# DSP Add-on GPIO 2/3 Analyse

**Datum:** 1. Dezember 2025  
**Frage:** Sind Pin 2 und 3 mit dem DSP Add-on verbunden?

---

## 🔍 ERKENNTNISSE

### BeoCreate/DSP Add-on GPIO-Verwendung

**Aus HiFiBerryOS EEPROM Config (`beocreate2.txt`):**
```
setgpio   2     ALT0      UP    # GPIO 2 = I2C SDA
setgpio   3     ALT0      UP    # GPIO 3 = I2C SCL
```

**Bedeutung:**
- **GPIO 2 (Pin 3) = ALT0 = I2C SDA** - für I2C Data
- **GPIO 3 (Pin 5) = ALT0 = I2C SCL** - für I2C Clock
- **ALT0** = Alternative Funktion 0 = I2C

### BeoCreate Konfiguration

**Aus HiFiBerryOS Test Config:**
```bash
dtoverlay=i2c-gpio
dtparam=i2c_gpio_sda=0    # GPIO 0 für SDA (nicht GPIO 2!)
dtparam=i2c_gpio_scl=1    # GPIO 1 für SCL (nicht GPIO 3!)
dtoverlay=hifiberry-dac
dtparam=spi=on
```

**Widerspruch:**
- EEPROM sagt: GPIO 2/3 für I2C
- Overlay sagt: GPIO 0/1 für i2c-gpio

---

## 📋 AKTUELLER STATUS AUF DEM SYSTEM

### Prüfung:
- ❌ Kein BeoCreate/DSP Add-on aktiv erkannt
- ❌ Keine DSP-Services laufen
- ❌ Keine BeoCreate-Konfiguration gefunden
- ✅ GPIO 2/3 sind **NICHT** vom DSP Add-on belegt

### I2C Bus Status:
- **Bus 1:** Leer (kein PCM5122)
- **Bus 13:** PCM5122 bei 0x4d gefunden
- **Bus 14/15:** Viele Geräte (40-4f) - möglicherweise andere Hardware

---

## ✅ ANTWORT

### **NEIN, Pin 2 und 3 sind NICHT mit dem DSP Add-on verbunden**

**Begründung:**
1. Kein DSP Add-on aktiv auf dem System
2. Keine BeoCreate-Services laufen
3. GPIO 2/3 sind frei für I2C verwendbar
4. PCM5122 ist auf Bus 13, nicht auf Bus 1 (GPIO 2/3)

---

## 🔧 KONSEQUENZEN

### Option 1: Hardware-Kabel (GPIO 2/3)

**Möglich:**
- ✅ GPIO 2/3 sind frei
- ✅ Können für I2C zu AMP100 verwendet werden
- ✅ Sollte PCM5122 auf Bus 1 bringen
- ✅ Standard-Overlay funktioniert dann

**Vorgehen:**
1. GPIO 2 (Pin 3) → SDA auf AMP100
2. GPIO 3 (Pin 5) → SCL auf AMP100
3. Standard-Overlay verwenden: `dtoverlay=hifiberry-amp100`

### Option 2: Software-Overlay (aktuell)

**Status:**
- ✅ Funktioniert mit Bus 13
- ❌ Reset-Fehler (-11) muss noch gelöst werden
- ⚠️ Custom Overlay nötig

---

## ⚠️ WICHTIG: FALLS DSP ADD-ON SPÄTER AKTIVIERT WIRD

**Konflikt:**
- DSP Add-on würde GPIO 2/3 für I2C verwenden
- AMP100 würde dann nicht mehr funktionieren (wenn auf GPIO 2/3)

**Lösung:**
- Entweder: DSP Add-on deaktivieren
- Oder: AMP100 auf anderem I2C Bus (wie aktuell Bus 13)
- Oder: i2c-gpio Overlay für AMP100 verwenden (andere GPIOs)

---

## 📝 EMPFEHLUNG

**Aktuell: GPIO 2/3 sind frei - Hardware-Kabel möglich!**

1. ✅ GPIO 2/3 mit Kabeln verbinden
2. ✅ PCM5122 sollte auf Bus 1 erscheinen
3. ✅ Standard-Overlay verwenden
4. ✅ Bessere Kompatibilität

**Falls später DSP Add-on:**
- Dann Custom Overlay für Bus 13 verwenden (wie aktuell)
- Oder i2c-gpio Overlay mit anderen GPIOs

---

**Status:** ✅ GPIO 2/3 sind frei für Hardware-Kabel-Lösung

