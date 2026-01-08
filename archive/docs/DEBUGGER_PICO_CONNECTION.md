# 🔌 RASPBERRY PI PICO DEBUGGER - VERBINDUNG

**Datum:** 2025-12-08  
**Debugger:** Raspberry Pi Pico (in klarem Gehäuse)  
**Status:** ✅ PICO ERKANNT

---

## 📋 ERKANNTES SETUP

**Hauptgerät:**
- **Raspberry Pi Pico** (in klarem Gehäuse mit Raspberry Pi Logo)
- **Rote LED** leuchtet → Gerät ist eingeschaltet
- **USB-Kabel** (weiß) → Verbindung zum Mac

**Kabel:**
1. **Flachbandkabel** (mehrfarbig: rot, braun, gelb, weiß, grau) → Links aus dem Gehäuse
2. **Weißer 4-Pin-Stecker** (female connector) → Oben links
3. **Schwarze Jumper-Verbinder** (2-Pin und 3-Pin) → Für Breadboard-Verbindung

---

## 🔌 RASPBERRY PI PICO PINOUT

**Standard GPIO-Pins für Serial (UART):**
- **GPIO 0 (Pin 1)** = TX (Transmit)
- **GPIO 1 (Pin 2)** = RX (Receive)
- **GND** = Ground
- **VSYS/3V3** = Power (nicht benötigt, wenn USB versorgt)

**Typische Serial-Verbindung:**
- **GND** → GND am Raspberry Pi
- **TX (GPIO 0)** → RX am Raspberry Pi (Pin 10)
- **RX (GPIO 1)** → TX am Raspberry Pi (Pin 8)

---

## 📋 VERBINDUNGS-ANLEITUNG

### **Schritt 1: Kabel identifizieren**

**Flachbandkabel (aus dem Pico):**
- **Rot** = wahrscheinlich VCC/3V3 (nicht verbinden, wenn Pi bereits läuft)
- **Braun** = wahrscheinlich GND
- **Gelb** = wahrscheinlich TX
- **Weiß** = wahrscheinlich RX
- **Grau** = zusätzlicher Pin (möglicherweise GND oder nicht verwendet)

**Weißer 4-Pin-Stecker:**
- Verbindet das Flachbandkabel mit dem Raspberry Pi
- 4 Pins: wahrscheinlich GND, VCC, TX, RX

---

### **Schritt 2: Verbindung zum Raspberry Pi**

**Raspberry Pi GPIO-Pins:**
```
Pin 6  = GND
Pin 8  = TX (GPIO 14) → RX vom Pico
Pin 10 = RX (GPIO 15) → TX vom Pico
```

**Verbindung:**
- **Braun (GND)** → **Pin 6** (GND)
- **Gelb (TX)** → **Pin 10** (RX)
- **Weiß (RX)** → **Pin 8** (TX)
- **Rot (VCC)** → **NICHT VERBINDEN** (Pi bereits mit Strom versorgt)

---

## 🎯 VERBINDUNGS-SCHRITTE

### **1. USB-Kabel verbinden**
```
Pico (USB-Kabel) → Mac
```
**✅ Bereits verbunden:** `/dev/cu.usbmodem214302`

### **2. Serial-Kabel verbinden**
```
Pico (Flachbandkabel) → Weißer 4-Pin-Stecker → Raspberry Pi
```

**Verbindungen:**
- **Braun** → **Pin 6** (GND)
- **Gelb** → **Pin 10** (RX)
- **Weiß** → **Pin 8** (TX)
- **Rot** → **NICHT VERBINDEN**

---

## 🔍 ALTERNATIVE PIN-BELEGUNG

**Wenn die Farben anders sind:**

**Standard Serial-Farben:**
- **Schwarz/Braun** = GND
- **Rot** = VCC (nicht verbinden)
- **Gelb/Weiß** = TX
- **Grün/Weiß** = RX

**Test-Verbindung:**
1. **GND** (Braun/Schwarz) → **Pin 6**
2. **TX** (Gelb) → **Pin 10** (RX)
3. **RX** (Weiß) → **Pin 8** (TX)

**Wenn keine Ausgabe:**
- TX/RX vertauschen (Gelb ↔ Weiß)

---

## ✅ SERIAL-KONSOLE TESTEN

### **Nach der Verbindung:**

1. **Serial-Konsole verbinden:**
```bash
screen /dev/cu.usbmodem214302 115200
```

2. **Raspberry Pi einschalten** - du solltest Boot-Logs sehen!

3. **Wenn keine Ausgabe:**
   - Prüfe Kabel-Verbindungen
   - Prüfe ob TX/RX vertauscht sind (tausche Gelb ↔ Weiß)
   - Prüfe Baudrate (115200)
   - Prüfe GND-Verbindung (Braun → Pin 6)

---

## 📋 RASPBERRY PI KONFIGURATION

### **Serial-Konsole aktivieren (auf dem Pi):**

**Via SSH oder Web-UI:**
```bash
# Boot-Partition beschreibbar machen
sudo mount -o remount,rw /boot

# config.txt bearbeiten
sudo nano /boot/config.txt

# Füge hinzu:
enable_uart=1
dtoverlay=uart0

# Speichere und starte neu
sudo reboot
```

---

## 🎯 NÄCHSTE SCHRITTE

1. ✅ **USB-Kabel verbunden:** `/dev/cu.usbmodem214302`
2. ⏳ **Serial-Kabel verbinden:**
   - Braun → Pin 6 (GND)
   - Gelb → Pin 10 (RX)
   - Weiß → Pin 8 (TX)
3. ⏳ **Serial-Konsole testen:** `screen /dev/cu.usbmodem214302 115200`
4. ⏳ **Pi einschalten** - Boot-Logs sollten erscheinen!

---

**Status:** ✅ PICO ERKANNT - BEREIT FÜR VERBINDUNG


