# Convolution Filters - Implementation Plan

**Datum:** 6. Dezember 2025  
**Inspiration:** Roon Convolution Filters  
**Ziel:** FIR Filter Support für erweiterte Room Correction

---

## 🎯 KONZEPT

### **Convolution Filters (FIR):**
- **FIR Filter:** Finite Impulse Response für präzise Korrekturen
- **Impulse Response:** Basierend auf Raum-Messungen
- **Room Correction:** Automatische Kompensation von Raum-Akustik
- **Seamless Integration:** Nahtlose Einbindung in bestehende Device Settings

---

## 🔧 TECHNISCHE IMPLEMENTIERUNG

### **1. CamillaDSP Integration:**
- **FIR Filter Support:** Bereits in CamillaDSP vorhanden
- **Impulse Response Files:** `.wav` oder `.pcm` Format
- **Convolution:** Real-time FIR Filtering

### **2. Filter-Generierung:**
- **Room Measurement:** Handy-Messung am Hörplatz
- **Impulse Response:** Aus Messung generieren
- **Frequency Response:** Analysieren und kompensieren
- **FIR Filter:** Generieren aus Frequency Response

### **3. Storage:**
- **Filter Files:** `/var/lib/camilladsp/convolution/`
- **Presets:** JSON-Konfiguration
- **Database:** Speicherung in moOde Datenbank

---

## 📊 ROOM CORRECTION WIZARD

### **Phase 1: Messung mit Handy**

**Flow:**
1. **Wizard starten** im moOde Web-Interface
2. **Test-Ton abspielen** (Pink Noise, Sweep, etc.)
3. **Handy am Hörplatz** positionieren
4. **Messung aufnehmen** via Handy-App oder Browser
5. **Daten hochladen** zu Ghetto Blaster

### **Phase 2: Filter-Generierung**

**Flow:**
1. **Frequency Response analysieren** (aus Messung)
2. **Target Curve wählen** (Flat, House Curve, Custom)
3. **FIR Filter berechnen** (Inverse Kurve)
4. **Filter testen** (Optional: Vorher/Nachher Vergleich)

### **Phase 3: Anwendung**

**Flow:**
1. **Filter aktivieren** in Device Settings
2. **Nahtlos anwenden** ohne Unterbrechung
3. **A/B Vergleich** (optional: Filter Ein/Aus)

---

## 💻 IMPLEMENTIERUNG

### **1. Wizard Backend:**

**PHP Handler:** `room-correction-wizard.php`

```php
<?php
// Upload measurement file
// Analyze frequency response
// Generate FIR filter
// Save filter preset
?>
```

### **2. Measurement API:**

**Endpoints:**
```
POST /api/room-correction/upload-measurement
POST /api/room-correction/generate-filter
POST /api/room-correction/apply-filter
GET  /api/room-correction/presets
```

### **3. Web-UI Wizard:**

**Step-by-Step Interface:**
1. **Step 1:** Instructions (Position Handy)
2. **Step 2:** Play Test Tone
3. **Step 3:** Record/Upload Measurement
4. **Step 4:** Analyze & Generate Filter
5. **Step 5:** Apply & Test

---

## 🔧 SEAMLESS INTEGRATION

### **Device Settings Integration:**

**Nahtlos einbinden:**
- **Dropdown:** "Room Correction" in Device Settings
- **Presets:** Gespeicherte Filter auswählbar
- **Toggle:** Ein/Aus ohne Unterbrechung
- **Status:** Aktiver Filter wird angezeigt

### **CamillaDSP Konfiguration:**

**Automatische Anwendung:**
- Filter wird in CamillaDSP Pipeline eingebunden
- Keine Unterbrechung beim Aktivieren
- Smooth Transition zwischen Filtern

---

## 📋 FILTER-FORMAT

### **Impulse Response:**
- **Format:** WAV oder PCM
- **Sample Rate:** 44100, 48000, 88200, 96000 Hz
- **Bit Depth:** 16-bit oder 32-bit float
- **Length:** Max 8192 Samples (abhängig von CamillaDSP)

### **Preset JSON:**
```json
{
  "id": "room-correction-living-room",
  "name": "Living Room Correction",
  "description": "Messung vom 2025-12-06",
  "impulse_response": "/var/lib/camilladsp/convolution/living-room.wav",
  "sample_rate": 48000,
  "gain": 0.0,
  "enabled": false,
  "created": "2025-12-06T20:00:00Z"
}
```

---

## 🎯 WIZARD FEATURES

### **1. Measurement Options:**
- **Pink Noise:** Standard Test-Ton
- **Sweep:** Frequency Sweep (20 Hz - 20 kHz)
- **Chirp:** Logarithmic Chirp
- **Custom:** User kann eigenes Signal hochladen

### **2. Target Curves:**
- **Flat:** Gerade Linie (0 dB)
- **House Curve:** Harman Target (leicht ansteigend)
- **Custom:** User-definierte Kurve
- **Auto:** Automatisch optimiert

### **3. Filter Options:**
- **Length:** FIR Filter Länge (Trade-off: Qualität vs CPU)
- **Window:** Windowing Function (Hann, Blackman, etc.)
- **Gain:** Pre-Gain für Headroom

---

## 📱 HANDY-INTEGRATION

### **Option 1: Browser-basiert**
- **Web Audio API:** Direkt im Browser messen
- **No App needed:** Funktioniert auf jedem Smartphone
- **Stream:** Messung direkt an Server senden

### **Option 2: Mobile App**
- **Dedicated App:** iOS/Android App für Messung
- **Better Control:** Mehr Kontrolle über Messung
- **Offline:** Kann auch offline gemessen werden

**Empfehlung:** Option 1 (Browser-basiert) für Seamlessness

---

## 🔧 SEAMLESS USER EXPERIENCE

### **Nahtlose Integration:**
1. **Wizard im moOde Interface:** Integriert in bestehende UI
2. **Device Settings:** Filter auswählbar wie andere Presets
3. **One-Click Apply:** Filter aktivieren ohne Neustart
4. **A/B Vergleich:** Sofort Filter Ein/Aus testen
5. **Visual Feedback:** Frequency Response vorher/nachher anzeigen

### **Auto-Detection:**
- **Device Recognition:** Automatisch richtiges Device erkennen
- **Preset Suggestion:** Passende Presets vorschlagen
- **Auto-Apply:** Optional: Filter automatisch anwenden

---

## 📊 IMPLEMENTIERUNGS-ROADMAP

### **Phase 1: Foundation**
- CamillaDSP Convolution Support aktivieren
- Filter Storage System
- Basic Preset Management

### **Phase 2: Wizard**
- Measurement Upload
- Frequency Response Analysis
- FIR Filter Generation

### **Phase 3: UI Integration**
- Wizard Interface
- Device Settings Integration
- Visual Feedback

### **Phase 4: Advanced**
- Browser-basierte Messung
- Auto-Calibration
- Multiple Measurements

---

**Status:** Konzept erstellt - Ready für Implementation!

