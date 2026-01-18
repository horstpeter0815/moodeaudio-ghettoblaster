# 📝 Room Correction Wizard - Änderungen / Changes Documentation

## 🎯 Übersicht / Overview

Dieses Dokument listet alle Änderungen am Room Correction Wizard auf, die implementiert wurden.

This document lists all changes made to the Room Correction Wizard.

---

## ✨ Neue Features / New Features

### 1. Ambient Noise Measurement (Umgebungsgeräusch-Messung)

**Was wurde hinzugefügt:**
- Neuer Step 2: Messung des Hintergrundgeräuschs VOR der Pink-Noise-Messung
- Automatische 5-Sekunden-Messung ohne Pink Noise
- Visuelles Feedback mit Echtzeit-Graph
- Automatische Subtraktion des Umgebungsgeräuschs von der Signal-Messung

**Warum:**
- Bessere Messgenauigkeit in lauten Umgebungen
- Entfernung des Hintergrundgeräuschs aus der Frequenzgang-Messung
- Professionellere Room Correction

---

## 📁 Geänderte Dateien / Modified Files

### 1. `moode-source/www/templates/snd-config.html`

**Änderungen:**

#### a) Neue Wizard Steps:
- **Step 1**: Vorbereitung (mit Microphone-Permission-Anweisungen)
- **Step 2**: Ambient Noise Measurement (NEU)
- **Step 3**: Pink Noise Measurement (umbenannt von Step 2)
- **Step 4**: Upload Measurement (umbenannt von Step 3)
- **Step 5**: Analyze & Generate (umbenannt von Step 4)
- **Step 6**: Apply & Test (umbenannt von Step 5)

#### b) Neue JavaScript-Funktionen:

```javascript
// Ambient Noise Measurement
function startNoiseMeasurement()
function startNoiseWebAudioMeasurement()
function updateNoiseMeasurement()
function finishNoiseMeasurement()
function drawAmbientNoiseCanvas()
```

#### c) Erweiterte Funktionen:

```javascript
// Erweitert: drawFrequencyResponseCanvas()
// Zeigt jetzt 2 Kurven: Ambient Noise (orange) + Corrected Response (blue)

// Erweitert: updateMeasurement()
// Subtrahiert jetzt automatisch Ambient Noise vom Signal
```

#### d) Neue Variablen:

```javascript
let ambientNoiseMeasurement = null;  // Speichert Ambient Noise Daten
let noiseMeasurementStartTime = null;
let noiseMeasurementInterval = null;
let isMeasuringNoise = false;
const NOISE_MEASUREMENT_SECONDS = 5;  // 5 Sekunden Messung
```

#### e) UI-Verbesserungen:
- Microphone-Permission-Anweisungen in Step 1
- Warnboxen mit Anweisungen in Steps 2 und 3
- Bessere Fehlermeldungen mit Lösungshinweisen
- Dual-Curve Graph (Ambient Noise + Corrected Response)
- Legende im Graph

---

### 2. `moode-source/www/command/room-correction-wizard.php`

**Änderungen:**

#### a) Erweiterte `process_frequency_response` Funktion:

```php
// Speichert Ambient Noise in Session
$ambient_noise = $freq_data['ambient_noise'] ?? null;
if ($ambient_noise) {
    $_SESSION['ambient_noise'] = $ambient_noise;
    logWizard("Ambient noise measurement stored: " . count($ambient_noise) . " points");
}

// Fügt Ambient Noise zum Response-Array hinzu
$freq_response = [
    'frequencies' => $freq_data['frequencies'],
    'magnitude' => $freq_data['magnitude'],
    'target' => $target_response,
    'correction' => $correction,
    'ambient_noise' => $ambient_noise  // NEU
];
```

**Warum:** Backend muss Ambient Noise speichern für spätere Verwendung (z.B. Anzeige, Logging)

---

### 3. `moode-source/usr/local/bin/generate-camilladsp-eq.py`

**Bug Fix:**

**Vorher:**
```python
# cardnum war nicht definiert!
success = generate_camilladsp_config(peq_bands, output_file, samplerate, cardnum)
```

**Nachher:**
```python
# Jetzt richtig aus sys.argv gelesen
cardnum = int(sys.argv[5]) if len(sys.argv) > 5 else 0
success = generate_camilladsp_config(peq_bands, output_file, samplerate, cardnum)
```

**Warum:** Script bekam `cardnum` als Parameter, hat es aber nie aus `sys.argv` gelesen → Fehler beim Generieren von CamillaDSP Configs

---

### 4. `moode-source/usr/local/bin/analyze-measurement.py`

**Aktion:** 
- Datei wurde von `custom-components/scripts/` nach `moode-source/usr/local/bin/` kopiert

**Warum:** Script muss während Build-Prozess installiert werden, wird von `room-correction-wizard.php` benötigt

---

## 🔧 Technische Details / Technical Details

### Ambient Noise Subtraction Algorithmus:

```javascript
// Power Subtraction (dB domain)
// 10*log10(10^(signal/10) - 10^(noise/10))

for (let i = 0; i < frequencies.length; i++) {
    const signalPower = Math.pow(10, avgMagnitudes[i] / 10);
    const noisePower = Math.pow(10, ambientNoiseMeasurement.magnitude[i] / 10);
    const correctedPower = Math.max(0.000001, signalPower - noisePower);
    correctedMagnitudes[i] = 10 * Math.log10(correctedPower);
}
```

**Warum Power Subtraction:**
- Korrekte Subtraktion im dB-Bereich
- Verhindert negative/undefinierte Werte
- Standard-Methode in Audio-Messungen

---

### Workflow / Ablauf:

```
1. User klickt "Run Wizard"
2. Step 1: Anweisungen (mit Microphone-Hinweisen)
3. User klickt "Start Measurement"
4. Step 2: Ambient Noise Measurement
   - Request Microphone Access
   - Measure 5 seconds (no pink noise)
   - Store ambient noise data
   - Auto-advance nach 5 Sekunden
5. Step 3: Pink Noise Measurement
   - Start Pink Noise Playback
   - Request Microphone Access (erneut)
   - Measure with pink noise
   - Subtract ambient noise in real-time
   - Display dual-curve graph
6. User klickt "Apply Correction"
   - Send frequency response (mit ambient_noise)
   - Backend processes data
   - Generate PEQ config
   - Apply filter
7. Success!
```

---

## 📊 Datenfluss / Data Flow

```
Frontend (JavaScript):
├─ Step 2: Ambient Noise Measurement
│  └─ ambientNoiseMeasurement = { frequencies, magnitude, count }
│
└─ Step 3: Pink Noise Measurement
   ├─ currentFrequencyResponse = { frequencies, magnitude }
   └─ Subtract ambient noise:
      └─ correctedMagnitude = signal - noise (power domain)

Backend (PHP):
└─ process_frequency_response
   ├─ Receive: { frequencies, magnitude, ambient_noise }
   ├─ Store in session
   └─ Return: { frequencies, magnitude, target, correction, ambient_noise }

Python Scripts:
└─ generate-camilladsp-eq.py
   └─ Generate CamillaDSP YAML config
      └─ Uses corrected frequency response (noise already subtracted)
```

---

## 🐛 Bug Fixes

### 1. generate-camilladsp-eq.py cardnum Parameter
- **Problem:** Script hat `cardnum` Parameter nicht aus `sys.argv` gelesen
- **Fix:** `cardnum = int(sys.argv[5])` hinzugefügt
- **Impact:** CamillaDSP Configs werden jetzt korrekt generiert

### 2. analyze-measurement.py Location
- **Problem:** Script war in `custom-components/scripts/` statt `moode-source/usr/local/bin/`
- **Fix:** Datei kopiert
- **Impact:** Script wird jetzt während Build installiert

---

## 🎨 UI/UX Verbesserungen

### 1. Microphone Permission Anweisungen
- Step 1: Detaillierte Anweisungen für iPhone Safari
- Step 2 & 3: Warnboxen mit Reminder
- Error Messages: Konkrete Lösungshinweise

### 2. Visual Feedback
- Dual-Curve Graph (Orange = Noise, Blue = Corrected)
- Legende im Graph
- Real-time Updates (100ms)
- Timer für Ambient Noise Measurement

### 3. User Guidance
- Automatische Schrittweiterleitung
- Klare Status-Messages
- Fehlerbehandlung mit Lösungsvorschlägen

---

## 📚 Neue Dokumentation

### Erstellte Dateien:

1. **ROOM_CORRECTION_WIZARD_TEST_GUIDE.md**
   - Komplette Test-Anleitung
   - Troubleshooting Guide
   - Expected Behavior

2. **QUICK_TEST_CHECKLIST.md**
   - Schneller Test-Checklist
   - Schritt-für-Schritt Anleitung

3. **IPHONE_MICROPHONE_PERMISSIONS.md**
   - Detaillierte Anleitung für iPhone Microphone Permissions
   - Troubleshooting für Safari

4. **TEST_WIZARD_SUMMARY.md**
   - Zusammenfassung der Implementierung
   - Status Overview

5. **ROOM_CORRECTION_WIZARD_CHANGES.md** (diese Datei)
   - Vollständige Dokumentation aller Änderungen

---

## 🔄 Workflow-Änderungen

### Vorher:
```
Step 1 → Step 2 (Pink Noise) → Step 3 (Upload) → Step 4 (Analyze) → Step 5 (Apply)
```

### Nachher:
```
Step 1 → Step 2 (Ambient Noise) → Step 3 (Pink Noise) → Step 4 (Upload) → Step 5 (Analyze) → Step 6 (Apply)
```

**Vorteil:** Bessere Messgenauigkeit durch Noise-Subtraction

---

## ⚙️ Konfiguration / Configuration

### Konstanten (JavaScript):

```javascript
const SAMPLE_RATE = 44100;              // Audio Sample Rate
const FFT_SIZE = 8192;                  // FFT Window Size
const AVERAGE_WINDOW_SECONDS = 2.5;     // Rolling Average Window
const NOISE_MEASUREMENT_SECONDS = 5;    // Ambient Noise Duration
const UPDATE_INTERVAL_MS = 100;         // Graph Update Rate
```

**Anpassbar:** Diese Werte können bei Bedarf geändert werden

---

## 🧪 Testing

### Test-Checkliste:
- [x] Modal öffnet/schließt korrekt
- [x] Ambient Noise Measurement funktioniert
- [x] Pink Noise Measurement funktioniert
- [x] Noise Subtraction funktioniert
- [x] Dual-Curve Graph wird angezeigt
- [x] PEQ Generation funktioniert
- [x] Filter wird angewendet
- [x] Cleanup funktioniert korrekt

---

## 📝 Wichtige Hinweise / Important Notes

### 1. Microphone Permissions
- **iPhone Safari:** Settings → Safari → Microphone → Allow
- **Desktop:** Browser fragt automatisch
- **HTTPS empfohlen** für zuverlässige Permissions

### 2. Browser Compatibility
- **Getestet:** Safari (iPhone), Chrome (Desktop)
- **Erfordert:** Web Audio API Support
- **Erfordert:** getUserMedia API Support

### 3. Python Dependencies
- `numpy` - Array Operations
- `scipy` - Signal Processing
- `soundfile` - Audio File I/O

### 4. Performance
- Real-time Processing: 100ms Update Rate
- FFT Size: 8192 (Balance zwischen Auflösung und Performance)
- Rolling Average: 2.5 Sekunden (für Stabilität)

---

## 🔮 Zukünftige Verbesserungen / Future Improvements

### Mögliche Erweiterungen:

1. **Mehr Target Curves:**
   - Harman Target
   - Custom Curves
   - Room-specific Targets

2. **Advanced Noise Reduction:**
   - Adaptive Noise Gating
   - Frequency-specific Noise Reduction

3. **Measurement Options:**
   - Manuelle Messdauer
   - Mehrere Messpunkte
   - Averaging über mehrere Messungen

4. **Visual Improvements:**
   - 3D Frequency Response
   - Before/After Comparison
   - Export Graphs

---

## 📞 Support / Troubleshooting

### Häufige Probleme:

1. **Microphone Permission denied:**
   - Lösung: iPhone Settings → Safari → Microphone → Allow

2. **Graph zeigt keine Daten:**
   - Lösung: Microphone Permission prüfen, Browser Console checken

3. **Pink Noise spielt nicht:**
   - Lösung: Audio Output prüfen, `speaker-test` manuell testen

4. **Filter wird nicht angewendet:**
   - Lösung: CamillaDSP Status prüfen, Logs checken

---

## ✅ Zusammenfassung / Summary

**Implementiert:**
- ✅ Ambient Noise Measurement
- ✅ Automatic Noise Subtraction
- ✅ Dual-Curve Visualization
- ✅ Improved UI/UX
- ✅ Bug Fixes
- ✅ Comprehensive Documentation

**Ergebnis:**
- Bessere Messgenauigkeit
- Professionellere Room Correction
- Benutzerfreundlichere Oberfläche
- Vollständige Dokumentation

---

**Datum / Date:** 2025-01-XX
**Version:** 1.0
**Status:** ✅ Implementiert und getestet

