# 🔌 DEBUGGER 3-DRAHT-VERBINDUNG - ANLEITUNG

**Datum:** 2025-12-08  
**Debugger:** Heart (2 weiße Stecker, je 3 Drähte)  
**Status:** ✅ KABEL IDENTIFIZIERT

---

## 📋 KABEL-BESCHREIBUNG

**Kabel 1 (Pin-Header-Seite → Raspberry Pi):**
- **Grau** (2x)
- **Rot**

**Kabel 2 (USB-Seite → Mac):**
- **Orange**
- **Gelb**
- **Lila**

**✅ Kabel 2 bereits verbunden:** `/dev/cu.usbmodem214302`

---

## 🔌 STANDARD 3-DRAHT-VERBINDUNG

**Typische Belegung für 3-Draht Serial-Kabel:**

### **Kabel 1 (Pin-Header → Raspberry Pi):**

**Standard-Zuordnung:**
- **Rot** = VCC (Power) - **NICHT VERBINDEN!** (Pi bereits mit Strom versorgt)
- **Grau 1** = TX (Transmit) → **Pin 10** (RX/GPIO 15)
- **Grau 2** = RX (Receive) → **Pin 8** (TX/GPIO 14)

**Oder:**
- **Rot** = VCC - **NICHT VERBINDEN!**
- **Grau 1** = GND → **Pin 6** (GND)
- **Grau 2** = TX → **Pin 10** (RX)

**⚠️ WICHTIG:** Da beide Grau gleich aussehen, müssen wir testen!

---

## 🎯 VERBINDUNGS-ANLEITUNG

### **Schritt 1: Kabel 1 identifizieren**

**Am Pin-Header-Kabel (Kabel 1):**
- Zähle die Pins von links nach rechts
- Normalerweise: **GND, TX, RX** oder **VCC, TX, RX**

**Typische Reihenfolge (von links nach rechts):**
1. **GND** (meist schwarz/grau)
2. **TX** (Transmit)
3. **RX** (Receive)

**Oder:**
1. **VCC** (meist rot)
2. **TX** (Transmit)
3. **RX** (Receive)

---

### **Schritt 2: Verbindung zum Raspberry Pi**

**Raspberry Pi GPIO-Pins:**
```
Pin 6  = GND
Pin 8  = TX (GPIO 14) → RX vom Debugger
Pin 10 = RX (GPIO 15) → TX vom Debugger
```

**Verbindung (wenn Rot = VCC):**
- **Rot** → **NICHT VERBINDEN** (VCC)
- **Grau 1** → **Pin 10** (RX) - TX vom Debugger
- **Grau 2** → **Pin 8** (TX) - RX vom Debugger
- **GND** → **Pin 6** (GND) - **FEHLT? Prüfe ob einer der Grauen GND ist!**

**⚠️ PROBLEM:** Wir haben nur 3 Drähte, aber brauchen GND, TX, RX!

**Lösung:** Einer der Grauen ist wahrscheinlich GND!

---

## 🔍 KORREKTE ZUORDNUNG (WAHRSCHEINLICH)

**Kabel 1 (Pin-Header):**
- **Rot** = VCC - **NICHT VERBINDEN!**
- **Grau 1** = GND → **Pin 6** (GND)
- **Grau 2** = TX → **Pin 10** (RX)

**ABER:** Wir brauchen auch RX! 

**Möglichkeit:** Das Kabel hat nur GND, TX, VCC - RX fehlt?

**Oder:** Die beiden Grauen sind TX und RX, Rot ist VCC?

---

## ✅ EMPFOHLENE VERBINDUNG

### **Option 1: Rot = VCC (nicht verbinden)**
```
Rot    → NICHT VERBINDEN (VCC)
Grau 1 → Pin 10 (RX) - TX vom Debugger
Grau 2 → Pin 8 (TX) - RX vom Debugger
GND    → Pin 6 (GND) - FEHLT! Prüfe ob einer der Grauen GND ist
```

### **Option 2: Rot = VCC, Grau = GND/TX/RX**
```
Rot    → NICHT VERBINDEN (VCC)
Grau 1 → Pin 6 (GND)
Grau 2 → Pin 10 (RX) - TX vom Debugger
```

**Aber:** RX fehlt dann!

---

## 🎯 TEST-VERBINDUNG

**Da wir unsicher sind, teste beide Möglichkeiten:**

### **Test 1:**
```
Rot    → NICHT VERBINDEN
Grau 1 → Pin 10 (RX)
Grau 2 → Pin 8 (TX)
```

**Dann testen:**
```bash
screen /dev/cu.usbmodem214302 115200
```

**Wenn keine Ausgabe:**
- TX/RX vertauschen (Grau 1 ↔ Grau 2)
- Prüfe ob GND fehlt (verbinde einen Grauen mit Pin 6)

---

## 📋 RASPBERRY PI PINOUT

**Wichtige Pins:**
```
Pin 6  = GND (Ground)
Pin 8  = TX (GPIO 14) - RX vom Debugger hier
Pin 10 = RX (GPIO 15) - TX vom Debugger hier
Pin 2  = 5V (VCC) - NICHT VERBINDEN!
```

---

## 🔧 NÄCHSTE SCHRITTE

1. ⏳ **Kabel 1 verbinden:**
   - Rot → NICHT VERBINDEN
   - Grau 1 → Pin 10 (RX)
   - Grau 2 → Pin 8 (TX)

2. ⏳ **GND prüfen:**
   - Wenn kein GND-Kabel: Einer der Grauen könnte GND sein
   - Teste: Verbinde einen Grauen mit Pin 6 (GND)

3. ⏳ **Serial-Konsole testen:**
```bash
screen /dev/cu.usbmodem214302 115200
```

4. ⏳ **Wenn keine Ausgabe:**
   - TX/RX vertauschen (Grau 1 ↔ Grau 2)
   - GND verbinden (einer der Grauen mit Pin 6)

---

**Status:** ⏳ BEREIT FÜR TEST-VERBINDUNG


