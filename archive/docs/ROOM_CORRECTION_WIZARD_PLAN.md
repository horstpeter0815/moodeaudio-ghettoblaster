# Room Correction Wizard - Seamless Integration

**Datum:** 6. Dezember 2025  
**Ziel:** Room Correction Wizard mit Handy-Messung, nahtlos integriert

---

## 🎯 KONZEPT

### **User Flow:**
1. **Wizard öffnen** im moOde Web-Interface
2. **Handy am Hörplatz** positionieren
3. **Test-Ton abspielen** (automatisch)
4. **Messung aufnehmen** mit Handy (Browser oder App)
5. **Filter generieren** (automatisch)
6. **Anwenden** (nahtlos, keine Unterbrechung)

---

## 📱 HANDY-MESSUNG

### **Option 1: Browser-basiert (EMPFEHLUNG!)**

**Vorteile:**
- ✅ **No App needed:** Funktioniert auf jedem Smartphone
- ✅ **Seamless:** Direkt im moOde Web-Interface
- ✅ **Cross-Platform:** iOS, Android, Desktop
- ✅ **Real-time:** Sofortige Messung

**Implementation:**
- **Web Audio API:** Mikrofon-Zugriff im Browser
- **Stream:** Messung direkt an Server senden
- **Visual Feedback:** Frequency Response in Echtzeit

### **Option 2: Mobile App**

**Vorteile:**
- ✅ **Better Control:** Mehr Kontrolle über Messung
- ✅ **Offline:** Kann auch offline gemessen werden
- ✅ **Advanced:** Erweiterte Mess-Optionen

**Nachteile:**
- ❌ App muss installiert werden
- ❌ Weniger seamless

**Empfehlung:** Option 1 für maximale Seamlessness!

---

## 🔧 WIZARD IMPLEMENTIERUNG

### **Step 1: Wizard Start**

**UI:**
```
┌─────────────────────────────────────┐
│  Room Correction Wizard             │
├─────────────────────────────────────┤
│                                      │
│  1. Positioniere dein Handy am      │
│     Hörplatz                        │
│                                      │
│  2. Stelle sicher, dass Mikrofon    │
│     Zugriff erlaubt ist             │
│                                      │
│  3. Klicke "Start Measurement"      │
│                                      │
│  [Start Measurement]                 │
└─────────────────────────────────────┘
```

### **Step 2: Test-Ton Abspielen**

**Automatisch:**
- Pink Noise, Sweep, oder Chirp
- Länge: 10-30 Sekunden
- Volume: Automatisch kalibriert

**UI:**
```
┌─────────────────────────────────────┐
│  Playing Test Tone...               │
├─────────────────────────────────────┤
│                                      │
│  🔊 Test-Ton läuft...               │
│                                      │
│  ⏱️ 5 / 30 Sekunden                 │
│                                      │
│  📱 Messung läuft auf Handy         │
│                                      │
│  [Cancel]                            │
└─────────────────────────────────────┘
```

### **Step 3: Messung aufnehmen**

**Browser-basiert:**
```javascript
// Web Audio API
navigator.mediaDevices.getUserMedia({ audio: true })
  .then(stream => {
    // Record measurement
    // Stream to server
  });
```

**Real-time:**
- Frequency Response in Echtzeit anzeigen
- Visual Feedback während Messung
- Qualitäts-Indikator

### **Step 4: Analyse & Filter-Generierung**

**Automatisch:**
1. Frequency Response analysieren
2. Target Curve wählen (Flat, House Curve, Custom)
3. FIR Filter berechnen
4. Filter validieren

**UI:**
```
┌─────────────────────────────────────┐
│  Analyzing Measurement...           │
├─────────────────────────────────────┤
│                                      │
│  📊 Frequency Response:             │
│  [Graph anzeigen]                   │
│                                      │
│  🎯 Target Curve:                   │
│  ○ Flat                             │
│  ○ House Curve                      │
│  ○ Custom                           │
│                                      │
│  [Generate Filter]                   │
└─────────────────────────────────────┘
```

### **Step 5: Anwenden & Testen**

**Seamless Application:**
- Filter wird nahtlos aktiviert
- Keine Unterbrechung
- A/B Vergleich möglich

**UI:**
```
┌─────────────────────────────────────┐
│  Filter Generated!                  │
├─────────────────────────────────────┤
│                                      │
│  ✅ Room Correction Filter          │
│     "Living Room 2025-12-06"        │
│                                      │
│  📊 Before / After:                 │
│  [Frequency Response Comparison]     │
│                                      │
│  [Apply Filter]  [Save as Preset]   │
│                                      │
│  [Test A/B]                          │
└─────────────────────────────────────┘
```

---

## 🔧 SEAMLESS INTEGRATION

### **Device Settings:**

**Integration in bestehende UI:**
```html
<!-- Room Correction -->
<div class="control-group">
    <label>Room Correction</label>
    <select id="room-correction-preset">
        <option value="none">None</option>
        <option value="living-room-2025-12-06">Living Room (2025-12-06)</option>
        <option value="custom-1">Custom Filter 1</option>
    </select>
    <button onclick="startRoomCorrectionWizard()">Run Wizard</button>
</div>
```

### **One-Click Apply:**
- Filter aktivieren ohne Neustart
- Smooth Transition
- Visual Feedback

### **A/B Vergleich:**
- Toggle zwischen Filter Ein/Aus
- Sofortiger Vergleich
- Keine Verzögerung

---

## 📊 TECHNISCHE DETAILS

### **Measurement Format:**
- **Sample Rate:** 44100 oder 48000 Hz
- **Duration:** 10-30 Sekunden
- **Format:** WAV oder PCM
- **Channels:** Mono oder Stereo

### **Filter Generation:**
- **Algorithm:** FFT-basierte FIR Filter Generierung
- **Length:** 4096-8192 Samples (je nach CPU)
- **Window:** Hann oder Blackman Window
- **Target:** Flat, House Curve, oder Custom

### **CamillaDSP Integration:**
```yaml
filters:
  room_correction:
    type: convolution
    parameters:
      ir_file: /var/lib/camilladsp/convolution/filter.wav
      gain: 0.0
      normalize: true
```

---

## 🎯 USER EXPERIENCE

### **Seamless Flow:**
1. ✅ **Wizard öffnen:** Ein Klick
2. ✅ **Messung:** Automatisch, keine Konfiguration
3. ✅ **Filter generieren:** Automatisch
4. ✅ **Anwenden:** Nahtlos, keine Unterbrechung
5. ✅ **Testen:** Sofort A/B Vergleich möglich

### **Visual Feedback:**
- Frequency Response Graph
- Before/After Vergleich
- Real-time Messung
- Quality Indikator

---

## 📋 IMPLEMENTIERUNGS-PRIORITÄTEN

### **Phase 1: Basic Wizard**
- Browser-basierte Messung
- Basic Filter Generation
- Device Settings Integration

### **Phase 2: Advanced**
- Multiple Measurements
- Auto-Calibration
- Advanced Target Curves

### **Phase 3: Optimization**
- Performance Optimization
- Better Algorithms
- Enhanced UI

---

**Status:** ✅ Konzept erstellt - Seamless Integration geplant!

