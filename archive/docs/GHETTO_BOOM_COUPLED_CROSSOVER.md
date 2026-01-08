# GHETTO BOOM COUPLED CROSSOVER SYSTEM

**Datum:** 3. Dezember 2025  
**Status:** FEATURE SPECIFICATION  
**Konzept:** Gekoppelte Crossover-Frequenzen mit Slidern

---

## 🎯 STANDARD-EINSTELLUNGEN

### **Bass:**
- **Cutoff:** 80 Hz (Low-Pass)
- **Bereich:** 20 Hz - 80 Hz

### **Mitten:**
- **Start:** 80 Hz (High-Pass)
- **Trennfrequenz:** 77 Hz (Resonanz der FE108EΣ)
- **Ende:** 2000 Hz (Low-Pass)
- **Bereich:** 80 Hz - 2000 Hz

### **Hochton:**
- **Start:** 2000 Hz (High-Pass)
- **Ende:** 20,000 Hz
- **Bereich:** 2000 Hz - 20,000 Hz

---

## 🎛️ EINSTELLBARE TRENNFREQUENZEN

### **Slider 1: Bass ↔ Mitten Crossover**

**Funktion:**
- **Bass Cutoff:** Einstellbar von 80 Hz bis 120 Hz
- **Mitten Start:** Wird automatisch angepasst (gekoppelt)
- **Trennfrequenz:** Entspricht Bass-Cutoff

**Beispiel:**
- Slider auf 100 Hz → Bass: 20-100 Hz, Mitten: 100-2000 Hz
- Slider auf 80 Hz → Bass: 20-80 Hz, Mitten: 80-2000 Hz (Standard)
- Slider auf 120 Hz → Bass: 20-120 Hz, Mitten: 120-2000 Hz

**Schrittweite:** Zu definieren (z.B. 1 Hz, 5 Hz, 10 Hz)

---

### **Slider 2: Mitten ↔ Hochton Crossover**

**Funktion:**
- **Mitten Ende:** Einstellbar (z.B. 1500 Hz - 5000 Hz)
- **Hochton Start:** Wird automatisch angepasst (gekoppelt)
- **Trennfrequenz:** Entspricht Mitten-Ende

**Beispiel:**
- Slider auf 3000 Hz → Mitten: 80-3000 Hz, Hochton: 3000-20000 Hz
- Slider auf 2000 Hz → Mitten: 80-2000 Hz, Hochton: 2000-20000 Hz (Standard)
- Slider auf 1500 Hz → Mitten: 80-1500 Hz, Hochton: 1500-20000 Hz

**Schrittweite:** Zu definieren (z.B. 100 Hz, 250 Hz, 500 Hz)

---

## 🔗 GEKOPPELTES SYSTEM

### **Prinzip:**
```
Bass Slider (80-120 Hz):
  ↓
Bass Cutoff = Slider-Wert
Mitten Start = Slider-Wert (automatisch)
  ↓
Mitten Slider (1500-5000 Hz):
  ↓
Mitten Ende = Slider-Wert
Hochton Start = Slider-Wert (automatisch)
```

### **Vorteile:**
- ✅ Keine Überlappungen
- ✅ Keine Lücken im Frequenzgang
- ✅ Einfache Bedienung
- ✅ Intuitive Steuerung

---

## 🖥️ UI-KONZEPT

### **Ghetto Blaster Display:**

```
┌─────────────────────────────────┐
│  GHETTO BOOM CROSSOVER           │
├─────────────────────────────────┤
│                                 │
│  Bass ↔ Mitten:                │
│  [━━━━━━━━━━━━━━━━━━━━━━━━]    │ ← Slider
│  80Hz    100Hz    120Hz        │
│  Bass: 20-100Hz                │
│  Mitten: 100-2000Hz            │
│                                 │
│  Mitten ↔ Hochton:              │
│  [━━━━━━━━━━━━━━━━━━━━━━━━]    │ ← Slider
│  1500Hz  2000Hz   5000Hz       │
│  Mitten: 100-2500Hz            │
│  Hochton: 2500-20000Hz         │
│                                 │
└─────────────────────────────────┘
```

---

## 🔧 TECHNISCHE UMSETZUNG

### **DSP-Crossover:**

#### **Bass-Kanal:**
- **Low-Pass Filter:** 80-120 Hz (einstellbar)
- **Slope:** Zu definieren (z.B. 12 dB/octave, 24 dB/octave)

#### **Mitten-Kanal:**
- **High-Pass Filter:** 80-120 Hz (gekoppelt mit Bass)
- **Low-Pass Filter:** 1500-5000 Hz (einstellbar)
- **Slope:** Zu definieren

#### **Hochton-Kanal:**
- **High-Pass Filter:** 1500-5000 Hz (gekoppelt mit Mitten)
- **Slope:** Zu definieren

---

## 📊 FREQUENZBEREICHE

### **Bass (Fostex FE108EΣ - 8x in Serie):**
- **Standard:** 20 Hz - 80 Hz
- **Einstellbar:** 20 Hz - 120 Hz (via Slider)
- **Resonanz:** 77 Hz (FE108EΣ)

### **Mitten (Back-loaded Horn):**
- **Standard:** 80 Hz - 2000 Hz
- **Einstellbar Start:** 80-120 Hz (gekoppelt mit Bass)
- **Einstellbar Ende:** 1500-5000 Hz (via Slider)

### **Hochton (Fostex T90A):**
- **Standard:** 2000 Hz - 20,000 Hz
- **Einstellbar Start:** 1500-5000 Hz (gekoppelt mit Mitten)
- **Frequenzbereich:** 5-35 kHz (T90A Spezifikation)

---

## ⚙️ IMPLEMENTATION DETAILS

### **BeoCreate (Ghetto Boom L):**
- **DSP:** Hat DSP-Funktionalität
- **Crossover:** Software-basiert
- **API:** BeoCreate API für Einstellungen

### **Custom Board (Ghetto Boom R):**
- **DSP:** Custom DSP/Crossover
- **API:** Custom API für Einstellungen

### **Ghetto Blaster Interface:**
- **Slider Control:** Touchscreen-Slider
- **API Calls:** Zu BeoCreate/Custom Board
- **Real-time Update:** Sofortige Anpassung

---

## ❓ ZU DEFINIEREN

### **1. Schrittweiten:**
- **Bass ↔ Mitten Slider:** 1 Hz, 5 Hz, oder 10 Hz Schritte?
- **Mitten ↔ Hochton Slider:** 100 Hz, 250 Hz, oder 500 Hz Schritte?

### **2. Filter-Slopes:**
- **Bass Low-Pass:** 12 dB/octave, 24 dB/octave?
- **Mitten High-Pass:** 12 dB/octave, 24 dB/octave?
- **Mitten Low-Pass:** 12 dB/octave, 24 dB/octave?
- **Hochton High-Pass:** 12 dB/octave, 24 dB/octave?

### **3. Mitten ↔ Hochton Bereich:**
- **Minimum:** 1500 Hz? (oder niedriger?)
- **Maximum:** 5000 Hz? (oder höher?)

---

## 🎯 VORTEILE

### **Warum das System cool ist:**
- ✅ **Gekoppelte Frequenzen:** Keine Überlappungen/Lücken
- ✅ **Intuitive Bedienung:** Ein Slider = beide Frequenzen angepasst
- ✅ **Flexibilität:** Anpassung an Raumakustik
- ✅ **Professionell:** Studio-ähnliche Kontrolle

---

**Status:** ✅ SPEZIFIKATION BESTÄTIGT & DOKUMENTIERT  
**Nächster Schritt:** Schrittweiten & Filter-Slopes definieren (später bei Implementation)

