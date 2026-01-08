# GHETTO BOOM L & R - KORREKTE SPEZIFIKATIONEN

**Datum:** 3. Dezember 2025  
**Status:** ✅ KORRIGIERT

---

## 🔊 GHETTO BOOM (Bose 901L, Serie 6)

### **Lautsprecher-Konfiguration:**

#### **Hochton:**
- **Fostex T90A Super Tweeter** (1x)
- Frequenzbereich: 5 kHz - 35 kHz
- Empfindlichkeit: 106 dB/W(1m)

#### **Mitteltön:**
- **1x Mitteltön-Lautsprecher** (Details zu klären)
- Wird über Back-loaded Horn System realisiert

#### **Bass:**
- **2x Bass-Kanäle** (jeweils 4 Treiber in Serie)
- **Treiber:** Fostex FE108EΣ Full Range (8x total auf Rückseite)
  - Impedanz: 8Ω pro Treiber
  - Resonanz: 77 Hz
  - Frequenzgang: bis 23 kHz
  - Empfindlichkeit: 90 dB/W(1m)
- **Konfiguration:** 4 Treiber pro Kanal in Serie geschaltet
- **Verstärker:** 2x 60W Kanäle vom BeoCreate
- **System:** Back-loaded Horn (Bose 901 Serie 6)
- **Referenz:** [Fostex FE108EΣ](https://www.fostex.jp/en/products/fe108e%CF%83/)

### **Elektronik:**
- **Board:** HiFiBerry BeoCreate
- **Kanäle:** 4 Kanäle total
  - Linker Kanal (für Ghetto Boom L):
    - 1x Hochton (T90A)
    - 1x Mitteltön
    - 2x Bass (je 4 Treiber in Serie)
  - Rechter Kanal (für Ghetto Boom R - Custom Board)

### **Bose 901 Serie 6:**
- **Prinzip:** Back-loaded Horn System
- **Rückseite:** 2x4 = 8 Lautsprecher (Fostex FE108EΣ)
- **Bass & Mitten:** Werden über Horn-System realisiert

---

## 🔊 GHETTO MOB (Bose 901R, Serie 6)

### **Lautsprecher-Konfiguration:**

#### **Hochton:**
- **Fostex T90A Super Tweeter** (1x)

#### **Mitteltön:**
- **1x Mitteltön-Lautsprecher** (Details zu klären)
- Wird über Back-loaded Horn System realisiert

#### **Bass:**
- **2x Bass-Kanäle** (jeweils 4 Treiber in Serie)
- **Treiber:** Fostex FE108EΣ Full Range (8x total auf Rückseite)
- **Konfiguration:** 4 Treiber pro Kanal in Serie geschaltet
- **Verstärker:** Custom Board (2x 60W Kanäle)
- **System:** Back-loaded Horn (Bose 901 Serie 6)

### **Elektronik:**
- **Board:** Custom Board (selbst-designed)
- **Kanäle:** 4 Kanäle total
  - Rechter Kanal (für Ghetto Boom R):
    - 1x Hochton (T90A)
    - 1x Mitteltön
    - 2x Bass (je 4 Treiber in Serie)

---

## 🎵 BACK-LOADED HORN SYSTEM

### **Bose 901 Serie 6 Prinzip:**
- **Bass & Mitten:** Werden über Back-loaded Horn realisiert
- **Rückseite:** 8x Fostex FE108EΣ Treiber
- **Konfiguration:** 2x4 Treiber (2 Gruppen à 4 Treiber)
- **Serienschaltung:** 4 Treiber pro Kanal in Serie

### **Vorteile:**
- Effiziente Bass-Wiedergabe
- Natürliche Klangcharakteristik
- Gute Impedanz-Anpassung

---

## 📊 KANAL-AUFTEILUNG

### **Ghetto Boom (BeoCreate):**

```
BeoCreate (4 Kanäle):
├── Kanal 1: Hochton (Fostex T90A)
├── Kanal 2: Mitteltön
├── Kanal 3: Bass 1 (4x FE108EΣ in Serie) - 60W
└── Kanal 4: Bass 2 (4x FE108EΣ in Serie) - 60W
```

### **Ghetto Mob (Custom Board):**

```
Custom Board (4 Kanäle):
├── Kanal 1: Hochton (Fostex T90A)
├── Kanal 2: Mitteltön
├── Kanal 3: Bass 1 (4x FE108EΣ in Serie) - 60W
└── Kanal 4: Bass 2 (4x FE108EΣ in Serie) - 60W
```

---

## 🔧 TECHNISCHE DETAILS

### **Bass-Konfiguration:**
- **Treiber pro Kanal:** 4x Fostex FE108EΣ
- **Schaltung:** Serie
- **Verstärker:** 2x 60W Kanäle
- **Total Treiber:** 8x FE108EΣ (4 pro Bass-Kanal)

### **Impedanz (Bass):**
- 4 Treiber in Serie → Impedanz addiert sich
- Muss mit Verstärker-Ausgangsimpedanz abgestimmt werden

---

## ❓ ZU KLÄREN

### **Mitteltön:**
- Welcher Lautsprecher wird für Mitteltön verwendet?
- Details zur Mitteltön-Konfiguration?

---

**Status:** ✅ KORRIGIERT - Back-loaded Horn System dokumentiert

