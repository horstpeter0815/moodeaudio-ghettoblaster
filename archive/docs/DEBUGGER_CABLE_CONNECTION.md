# 🔌 DEBUGGER KABEL-VERBINDUNG - ANLEITUNG

**Datum:** 2025-12-08  
**Debugger:** Heart (2 weiße Stecker)  
**Status:** ✅ KABEL IDENTIFIZIEREN

---

## 📋 DEBUGGER-SETUP

**Debugger:** Heart  
**Stecker:** 2 weiße Stecker am Debugger

**Kabel:**
1. **Kabel 1:** Weißer Stecker → **Pin-Header** (Stiftleiste mit "peaks")
2. **Kabel 2:** Weißer Stecker → **Weißer Stecker** (USB-Seite)

---

## 🔌 KABEL-VERBINDUNG

### **Kabel 1: Debugger → Raspberry Pi (Pin-Header)**

**Dieses Kabel verbindet den Debugger mit dem Raspberry Pi.**

**Pin-Header-Seite (am Raspberry Pi):**
- **GND** (Schwarz) → **GND** (Pin 6 oder 14)
- **TX** (Weiß/Grün) → **RX** (GPIO 15, Pin 10)
- **RX** (Grün/Weiß) → **TX** (GPIO 14, Pin 8)
- **VCC** (Rot) → **NICHT VERBINDEN** (Pi bereits mit Strom versorgt)

**⚠️ WICHTIG:**
- Nur **GND, TX, RX** verbinden!
- **VCC NICHT** verbinden, wenn der Pi bereits läuft!

---

### **Kabel 2: Debugger → Mac (USB-Seite)**

**Dieses Kabel verbindet den Debugger mit dem Mac.**

**USB-Seite:**
- Weißer Stecker → **USB-Port am Mac**

**✅ Bereits erkannt:** `/dev/cu.usbmodem214302`

---

## 🎨 KABEL-FARBEN IDENTIFIZIEREN

### **Standard USB-Serial-Farben:**

**Meistens:**
- **Schwarz** = GND (Ground)
- **Rot** = VCC (Power) - **NICHT VERBINDEN!**
- **Weiß/Grün** = TX (Transmit)
- **Grün/Weiß** = RX (Receive)

**Oder:**
- **Schwarz** = GND
- **Rot** = VCC - **NICHT VERBINDEN!**
- **Gelb** = TX
- **Orange** = RX

**Oder:**
- **Schwarz** = GND
- **Rot** = VCC - **NICHT VERBINDEN!**
- **Blau** = TX
- **Grün** = RX

---

## 🔍 KABEL PRÜFEN

### **Schritt 1: Kabel identifizieren**

**Kabel 1 (Pin-Header-Seite):**
- Hat Stiftleiste/Pin-Header am Ende
- Verbindet Debugger → Raspberry Pi
- **Farben prüfen:** Welche Farben hat dieses Kabel?

**Kabel 2 (USB-Seite):**
- Hat weißen Stecker am Ende
- Verbindet Debugger → Mac
- **Bereits verbunden:** `/dev/cu.usbmodem214302`

---

### **Schritt 2: Pin-Belegung prüfen**

**Am Pin-Header-Kabel (Kabel 1):**
- Zähle die Pins von links nach rechts (oder schaue auf die Beschriftung)
- Normalerweise: **GND, VCC, TX, RX** (in dieser Reihenfolge)

**Am Raspberry Pi:**
- **Pin 6** = GND
- **Pin 8** = TX (GPIO 14)
- **Pin 10** = RX (GPIO 15)
- **Pin 2** = 5V (VCC - NICHT VERBINDEN!)

---

## 📋 VERBINDUNGS-SCHRITTE

### **1. Kabel 2 verbinden (USB → Mac)**
```
Debugger (weißer Stecker) → Kabel 2 → Mac (USB)
```
**✅ Bereits erkannt:** `/dev/cu.usbmodem214302`

### **2. Kabel 1 verbinden (Debugger → Pi)**
```
Debugger (weißer Stecker) → Kabel 1 (Pin-Header) → Raspberry Pi
```

**Verbindungen:**
- **GND** (Schwarz) → **Pin 6** (GND)
- **TX** (Weiß/Grün) → **Pin 10** (RX/GPIO 15)
- **RX** (Grün/Weiß) → **Pin 8** (TX/GPIO 14)

**⚠️ WICHTIG:**
- TX vom Debugger → RX am Pi
- RX vom Debugger → TX am Pi
- **VCC NICHT** verbinden!

---

## 🎯 RASPBERRY PI PINOUT

**GPIO-Pins für Serial:**
```
    3.3V  [1]  [2]  5V
   GPIO2  [3]  [4]  5V
   GPIO3  [5]  [6]  GND  ← GND hier
   GPIO4  [7]  [8]  TX   ← RX vom Debugger hier
      0V  [9] [10]  RX   ← TX vom Debugger hier
  GPIO17 [11] [12] GPIO18
  GPIO27 [13] [14] GND
  GPIO22 [15] [16] GPIO23
      3.3V [17] [18] GPIO24
  GPIO10 [19] [20] GND
   GPIO9 [21] [22] GPIO25
  GPIO11 [23] [24] GPIO8
      0V [25] [26] GPIO7
```

---

## ✅ VERBINDUNG TESTEN

### **Nach der Verbindung:**

1. **Serial-Konsole verbinden:**
```bash
screen /dev/cu.usbmodem214302 115200
```

2. **Pi einschalten** - du solltest Boot-Logs sehen!

3. **Wenn keine Ausgabe:**
   - Prüfe Kabel-Verbindungen
   - Prüfe ob TX/RX vertauscht sind (tausche die Kabel)
   - Prüfe Baudrate (115200)

---

## 📋 NÄCHSTE SCHRITTE

1. ⏳ **Kabel-Farben identifizieren** (welche Farben hat Kabel 1?)
2. ⏳ **Kabel 1 verbinden** (Debugger → Pi)
3. ⏳ **Serial-Konsole testen** (`screen /dev/cu.usbmodem214302 115200`)

---

**Status:** ⏳ WARTE AUF KABEL-FARBEN-INFO


