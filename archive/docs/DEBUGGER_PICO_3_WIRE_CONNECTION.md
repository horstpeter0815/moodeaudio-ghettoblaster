# 🔌 RASPBERRY PI PICO DEBUGGER - 3-DRAHT-VERBINDUNG

**Datum:** 2025-12-08  
**Debugger:** Raspberry Pi Pico (in klarem Gehäuse)  
**Stecker:** Weißer 3-Pin-Stecker  
**Status:** ✅ 3-DRAHT-SETUP

---

## 📋 ERKANNTES SETUP

**Hauptgerät:**
- **Raspberry Pi Pico** (in klarem Gehäuse mit Raspberry Pi Logo)
- **Rote LED** leuchtet → Gerät ist eingeschaltet
- **USB-Kabel** (weiß) → Verbindung zum Mac

**Kabel:**
- **Flachbandkabel** (mehrfarbig: rot, braun, gelb, weiß, grau) → Links aus dem Gehäuse
- **Weißer 3-Pin-Stecker** → Nur 3 Drähte!

---

## 🔌 3-DRAHT-VERBINDUNG

**Typische 3-Draht Serial-Verbindung:**
- **GND** (Ground)
- **TX** (Transmit)
- **RX** (Receive)

**Kein VCC** → Pi bereits mit Strom versorgt!

---

## 📋 VERBINDUNGS-ANLEITUNG

### **Schritt 1: Kabel identifizieren**

**Flachbandkabel (aus dem Pico):**
- **Rot** = wahrscheinlich nicht verwendet (oder VCC, nicht verbinden)
- **Braun** = wahrscheinlich GND
- **Gelb** = wahrscheinlich TX
- **Weiß** = wahrscheinlich RX
- **Grau** = wahrscheinlich nicht verwendet

**Weißer 3-Pin-Stecker:**
- Nur 3 Drähte verbunden
- Wahrscheinlich: **GND, TX, RX**

---

### **Schritt 2: Verbindung zum Raspberry Pi**

**Raspberry Pi GPIO-Pins:**
```
Pin 6  = GND
Pin 8  = TX (GPIO 14) → RX vom Pico
Pin 10 = RX (GPIO 15) → TX vom Pico
```

**Verbindung (3 Drähte):**
- **Braun (GND)** → **Pin 6** (GND)
- **Gelb (TX)** → **Pin 10** (RX)
- **Weiß (RX)** → **Pin 8** (TX)

**Rot und Grau:** Nicht verwenden (nicht am 3-Pin-Stecker)

---

## 🎯 VERBINDUNGS-SCHRITTE

### **1. USB-Kabel verbinden**
```
Pico (USB-Kabel) → Mac
```
**✅ Bereits verbunden:** `/dev/cu.usbmodem214302`

### **2. Serial-Kabel verbinden (3 Drähte)**
```
Pico (Flachbandkabel) → Weißer 3-Pin-Stecker → Raspberry Pi
```

**Verbindungen:**
- **Braun** → **Pin 6** (GND)
- **Gelb** → **Pin 10** (RX)
- **Weiß** → **Pin 8** (TX)

---

## 🔍 PIN-REIHENFOLGE AM 3-PIN-STECKER

**Typische Reihenfolge (von links nach rechts):**
1. **GND** (meist braun/schwarz)
2. **TX** (meist gelb/weiß)
3. **RX** (meist weiß/grün)

**Oder:**
1. **GND**
2. **RX**
3. **TX**

**⚠️ WICHTIG:** Die Reihenfolge kann variieren!

---

## ✅ SERIAL-KONSOLE TESTEN

### **Nach der Verbindung:**

1. **Serial-Konsole verbinden:**
```bash
screen /dev/cu.usbmodem214302 115200
```

2. **Raspberry Pi einschalten** - du solltest Boot-Logs sehen!

3. **Wenn keine Ausgabe:**
   - **TX/RX vertauschen** (Gelb ↔ Weiß)
   - Prüfe GND-Verbindung (Braun → Pin 6)
   - Prüfe Baudrate (115200)

---

## 🧪 TEST-VERBINDUNG

### **Option 1 (empfohlen):**
```
Braun → Pin 6 (GND)
Gelb  → Pin 10 (RX)
Weiß  → Pin 8 (TX)
```

**Test:**
```bash
screen /dev/cu.usbmodem214302 115200
```

**Wenn keine Ausgabe:**

### **Option 2 (TX/RX vertauscht):**
```
Braun → Pin 6 (GND)
Gelb  → Pin 8 (TX)   ← Vertauscht!
Weiß  → Pin 10 (RX)  ← Vertauscht!
```

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
2. ⏳ **3 Drähte verbinden:**
   - Braun → Pin 6 (GND)
   - Gelb → Pin 10 (RX)
   - Weiß → Pin 8 (TX)
3. ⏳ **Serial-Konsole testen:** `screen /dev/cu.usbmodem214302 115200`
4. ⏳ **Pi einschalten** - Boot-Logs sollten erscheinen!

---

**Status:** ✅ 3-DRAHT-SETUP - BEREIT FÜR VERBINDUNG


