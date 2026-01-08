# GHETTO BOOM L & R HARDWARE SPECIFICATIONS

**Datum:** 3. Dezember 2025  
**Komponenten:** Ghetto Boom L & R  
**Status:** HARDWARE DOCUMENTATION

---

## 🔊 GHETTO BOOM (Bose 901L, Serie 6)

### **Lautsprecher-Konfiguration:**

#### **Hochton:**
- **Fostex T90A Super Tweeter** (1x)
- Frequenzbereich: 5 kHz - 35 kHz
- Empfindlichkeit: 106 dB/W(1m)

#### **Mitteltön:**
- **1x Mitteltön-Lautsprecher** (Details zu klären)
- Realisiert über Back-loaded Horn System

#### **Bass:**
- **2x Bass-Kanäle** (jeweils 4 Treiber in Serie)
- **Treiber:** 8x Bose 901 Original-Treiber (4,5-Zoll, Helical Voice Coil)
- **Konfiguration:** 4 Treiber pro Kanal in Serie (8x total auf Rückseite)
- **Verstärker:** 2x 60W Kanäle vom BeoCreate
- **System:** Back-loaded Horn (Bose 901 Serie 6 Original)

### **Elektronik:**
- **Board:** HiFiBerry BeoCreate
- **Kanäle:** 4 Kanäle
  - Kanal 1: Hochton (T90A)
  - Kanal 2: Mitteltön
  - Kanal 3: Bass 1 (4x Bose 901 Treiber in Serie) - 60W
  - Kanal 4: Bass 2 (4x Bose 901 Treiber in Serie) - 60W

### **Bose 901 Serie 6:**
- **Prinzip:** Back-loaded Horn System
- **Rückseite:** 2x4 = 8 Lautsprecher (Bose 901 Original-Treiber)
- **Bass & Mitten:** Werden über Horn-System realisiert
- **Messdaten:** Siehe BOSE_901_MEASUREMENTS.md

### **Software:**
- BeoCreate Software
- Web-Interface
- MPD/Streaming-Support

---

## 🔊 GHETTO MOOB (Bose 901R, Serie 6)

### **Lautsprecher-Konfiguration:**

#### **Hochton:**
- **Fostex T90A Super Tweeter** (1x)

#### **Mitteltön:**
- **1x Mitteltön-Lautsprecher** (Details zu klären)
- Realisiert über Back-loaded Horn System

#### **Bass:**
- **2x Bass-Kanäle** (jeweils 4 Treiber in Serie)
- **Treiber:** 8x Bose 901 Original-Treiber (4,5-Zoll, Helical Voice Coil)
- **Konfiguration:** 4 Treiber pro Kanal in Serie (8x total auf Rückseite)
- **Verstärker:** Custom Board (2x 60W Kanäle)
- **System:** Back-loaded Horn (Bose 901 Serie 6 Original)

### **Elektronik:**
- **Board:** Custom Board (selbst-designed)
- **Kanäle:** 4 Kanäle
  - Kanal 1: Hochton (T90A)
  - Kanal 2: Mitteltön
  - Kanal 3: Bass 1 (4x Bose 901 Treiber in Serie) - 60W
  - Kanal 4: Bass 2 (4x Bose 901 Treiber in Serie) - 60W

### **Software:**
- Custom Software
- Web-Interface
- MPD/Streaming-Support

---

## 🎵 FOSTEX KOMPONENTEN

### **Fostex T90A Super Tweeter:**
- **Typ:** Super Tweeter
- **Hersteller:** Fostex
- **Modell:** T90A
- **Frequenzbereich:** 5 kHz bis 35 kHz
- **Empfindlichkeit:** 106 dB/W(1m)
- **Crossover:** 7 kHz (12 dB/octave empfohlen)
- **Verwendung:** Hochton in jedem Ghetto Boom (1x pro Lautsprecher)
- **Referenz:** [Fostex T90A](https://www.fostex.jp/en/products/t90a/)

### **Bose 901 Original-Treiber (Bass - Rückseite):**
- **Typ:** 4,5-Zoll Vollbereichs-Treiber
- **Hersteller:** Bose
- **Modell:** Bose 901 Series 6 Treiber
- **Impedanz:** 8Ω (Nennimpedanz)
- **Typ:** Helical Voice Coil
- **Verwendung:** Bass-Kanäle in Ghetto Boom (8x total auf Rückseite)
  - 4x pro Bass-Kanal in Serie geschaltet
  - 2x Bass-Kanäle pro Lautsprecher
- **System:** Designed für Back-loaded Horn (Bose 901 Original)
- **Referenz:** Siehe BOSE_901_SERIES_6_TECH_DOC.md

---

## 📋 HARDWARE-ÜBERSICHT

### **Ghetto Boom (BeoCreate):**
```
┌─────────────────────────────┐
│  Bose 901L Serie 6          │
│  ┌───────────────────────┐  │
│  │ Fostex T90A           │  │ ← Hochton (Kanal 1)
│  │ Super Tweeter         │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │ Mitteltön             │  │ ← Mitteltön (Kanal 2)
│  │ (Back-loaded Horn)    │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │ Bass 1: 4x Bose 901 Treiber    │  │ ← Bass 1 (Kanal 3, 60W)
│  │ (Serie, Rückseite)    │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │ Bass 2: 4x Bose 901 Treiber    │  │ ← Bass 2 (Kanal 4, 60W)
│  │ (Serie, Rückseite)    │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │ HiFiBerry BeoCreate   │  │
│  │ 4 Kanäle              │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

### **Ghetto Moob (Custom Board):**
```
┌─────────────────────────────┐
│  Bose 901R Serie 6          │
│  ┌───────────────────────┐  │
│  │ Fostex T90A           │  │ ← Hochton (Kanal 1)
│  │ Super Tweeter         │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │ Mitteltön             │  │ ← Mitteltön (Kanal 2)
│  │ (Back-loaded Horn)    │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │ Bass 1: 4x Bose 901 Treiber    │  │ ← Bass 1 (Kanal 3, 60W)
│  │ (Serie, Rückseite)    │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │ Bass 2: 4x Bose 901 Treiber    │  │ ← Bass 2 (Kanal 4, 60W)
│  │ (Serie, Rückseite)    │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │ Custom Board          │  │
│  │ 4 Kanäle              │  │
│  └───────────────────────┘  │
└─────────────────────────────┘
```

---

**Status:** ✅ HARDWARE KOMPLETT DOKUMENTIERT

