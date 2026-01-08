# GHETTO BOOM ADVANCED CONTROLS - FEATURE PLAN

**Datum:** 3. Dezember 2025  
**Status:** FEATURE PLANNING  
**Feature:** Einstellbare Crossover-Frequenzen & Cutoff

---

## 🎯 FEATURE-IDEE

### **Später auf Ghetto Boom implementieren:**

**Einstellbare Crossover-Frequenzen:**
- **Bass ↔ Mitten:** Trennfrequenz einstellbar (Slider)
- **Mitten ↔ Hochton:** Trennfrequenz einstellbar (Slider)

**Cutoff-Filter:**
- **Cutoff-Frequenz:** Einstellbar (Slider)
- **Typ:** High-Pass oder Low-Pass (zu klären)

**Steuerung:**
- Über **Ghetto Blaster** Display/Interface
- Slider/Schieberegler für jede Einstellung
- Schrittweise Anpassung möglich

---

## 🎛️ KONZEPT

### **Steuerung über Ghetto Blaster:**

```
┌─────────────────────────────────┐
│  GHETTO BOOM CONTROLS            │
├─────────────────────────────────┤
│                                 │
│  Bass ↔ Mitten Crossover:      │
│  [━━━━━━━━━━━━━━━━━━━━━━━━]    │ ← Slider
│  50Hz    200Hz    500Hz        │
│                                 │
│  Mitten ↔ Hochton Crossover:   │
│  [━━━━━━━━━━━━━━━━━━━━━━━━]    │ ← Slider
│  2kHz    5kHz    10kHz         │
│                                 │
│  Cutoff Frequency:              │
│  [━━━━━━━━━━━━━━━━━━━━━━━━]    │ ← Slider
│  20Hz    100Hz    500Hz        │
│                                 │
└─────────────────────────────────┘
```

---

## 🔧 TECHNISCHE UMSETZUNG

### **Option 1: DSP-basiert (BeoCreate)**
- **BeoCreate:** Hat DSP-Funktionalität
- **Crossover:** Software-basiert im DSP
- **Steuerung:** Über BeoCreate API
- **Interface:** Ghetto Blaster → BeoCreate API

### **Option 2: Custom Board**
- **Custom Board:** Eigener DSP/Crossover
- **Steuerung:** Über Custom API
- **Interface:** Ghetto Blaster → Custom API

### **Option 3: Hybrid**
- **BeoCreate (Ghetto Boom):** DSP-basiert
- **Custom Board (Ghetto Mob):** Custom Implementation
- **Unified Interface:** Ghetto Blaster steuert beide

---

## 📊 CROSSOVER-FREQUENZEN

### **Typische Bereiche:**

#### **Bass ↔ Mitten:**
- **Bereich:** 50 Hz - 500 Hz
- **Standard:** ~200-300 Hz
- **Schritte:** 10-25 Hz Schritte

#### **Mitten ↔ Hochton:**
- **Bereich:** 2 kHz - 10 kHz
- **Standard:** ~5-7 kHz
- **Schritte:** 100-500 Hz Schritte

#### **Cutoff:**
- **Bereich:** 20 Hz - 500 Hz (Low-Pass) oder 5 kHz - 20 kHz (High-Pass)
- **Typ:** Zu klären (High-Pass oder Low-Pass?)
- **Schritte:** Abhängig von Typ

---

## 🖥️ INTERFACE-INTEGRATION

### **Ghetto Blaster Display:**

#### **Option A: Display-Umschaltung**
- Umschalten zwischen moOde UI und Ghetto Boom Controls
- Vollständige Kontrolle über Crossover & Cutoff

#### **Option B: Oversized Control (Ideale Lösung)**
- Split-Screen: moOde UI + Ghetto Boom Controls
- Oder Tab-System: moOde / Ghetto Boom L / Ghetto Boom R

#### **Option C: Web-UI Integration**
- Crossover-Controls in moOde Web-UI integrieren
- Zusätzliche Seite für Ghetto Boom Settings

---

## ✅ SPEZIFIKATION (Aktualisiert)

### **Standard-Einstellungen:**
- **Bass:** 80 Hz Cutoff (Low-Pass)
- **Mitten:** 80 Hz - 2000 Hz
- **Hochton:** 2000 Hz - 20,000 Hz

### **Einstellbare Trennfrequenzen:**
- **Bass ↔ Mitten:** Slider 80-120 Hz (gekoppelt)
- **Mitten ↔ Hochton:** Slider 1500-5000 Hz (gekoppelt)

### **Details:** Siehe GHETTO_BOOM_COUPLED_CROSSOVER.md

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

### **3. Speicherung:**
- **Presets:** Sollen Presets gespeichert werden können?
- **Profil:** Pro Lautsprecher oder global?

### **4. Real-time:**
- **Live-Anpassung:** Soll während Wiedergabe anpassbar sein?
- **Feedback:** Soll man den Effekt sofort hören?

---

## 🎯 IMPLEMENTATION PLAN

### **Phase 1: Research**
- [ ] BeoCreate DSP-Funktionalität analysieren
- [ ] Custom Board DSP-Möglichkeiten prüfen
- [ ] Crossover-Algorithmen recherchieren

### **Phase 2: API-Design**
- [ ] BeoCreate API für Crossover
- [ ] Custom Board API für Crossover
- [ ] Unified Control Interface

### **Phase 3: UI-Design**
- [ ] Slider-Design für Ghetto Blaster Display
- [ ] Touchscreen-Steuerung
- [ ] Web-UI Integration

### **Phase 4: Implementation**
- [ ] DSP-Crossover implementieren
- [ ] API-Endpoints erstellen
- [ ] UI-Integration

---

## 💡 VORTEILE

### **Warum das cool ist:**
- ✅ **Flexibilität:** Anpassung an Raumakustik
- ✅ **Optimierung:** Beste Crossover-Frequenzen finden
- ✅ **Experimentieren:** Verschiedene Einstellungen testen
- ✅ **Professionell:** Studio-ähnliche Kontrolle

---

**Status:** ✅ FEATURE SPEZIFIZIERT & DOKUMENTIERT  
**Nächster Schritt:** Implementation später (nach Ghetto Blaster Build)

