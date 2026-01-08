# Ghetto Scratch - DSP & REST API Plan

**Datum:** 6. Dezember 2025  
**Ziel:** DSP-basierte Frequency Response Kompensation mit REST API für Pi Zero 2W

---

## 🎯 HARDWARE: RASPBERRY PI ZERO 2W

### **Spezifikationen:**
- **CPU:** Quad-core ARM Cortex-A53 @ 1.0 GHz
- **RAM:** 512 MB
- **Audio HAT:** HiFiBerry DAC+ ADC Pro
- **Audio Processing:** Real-time DSP möglich

### **Hardware-Ressourcen für DSP:**
- **CPU:** Ausreichend für einfache EQ/DSP
- **RAM:** 512 MB (kritisch für große DSP-Konfigurationen)
- **Audio:** HiFiBerry ADC Pro (Eingang von Turntable)

---

## 🔧 DSP-OPTIONEN FÜR PI ZERO 2W

### **Option 1: CamillaDSP**
- **Vorteil:** Sehr flexibel, professionell
- **Nachteil:** Höhere CPU/RAM Nutzung
- **Fazit:** Möglich, aber ressourcen-intensiv

### **Option 2: ALSA EQ Plugin**
- **Vorteil:** Einfach, niedrige Ressourcen
- **Nachteil:** Weniger Bands, weniger flexibel
- **Fazit:** Besser für Pi Zero 2W

### **Option 3: Custom Python DSP**
- **Vorteil:** Leichtgewicht, speziell angepasst
- **Nachteil:** Mehr Entwicklungsaufwand
- **Fazit:** Optimal für Pi Zero 2W

**Empfehlung:** Option 2 (ALSA EQ) oder Option 3 (Custom Python)

---

## 🌐 REST API KONZEPT

### **Base URL:**
```
http://ghetto-scratch.local/api/v1
```

### **Endpoints:**

#### **1. Cartridge Management:**
```
GET    /cartridges           # Liste aller Cartridges
GET    /cartridges/{id}      # Cartridge Details
GET    /cartridges/{id}/curve # Frequency Response Curve
```

#### **2. Preset Management:**
```
GET    /presets              # Verfügbare Presets
GET    /presets/current      # Aktuell angewendetes Preset
POST   /presets/apply        # Preset anwenden
DELETE /presets/current      # Preset entfernen (Flat)
```

#### **3. DSP Control:**
```
GET    /dsp/status           # DSP Status
POST   /dsp/enable           # DSP aktivieren
POST   /dsp/disable          # DSP deaktivieren
POST   /dsp/curve            # Custom Curve anwenden
```

#### **4. System Info:**
```
GET    /system/info          # System-Informationen
GET    /system/resources     # CPU/RAM Nutzung
```

---

## 📋 API-REQUESTS EXAMPLES

### **Cartridge auswählen:**
```bash
POST /api/v1/presets/apply
Content-Type: application/json

{
  "cartridge_id": "ortofon-2m-red",
  "type": "MM",
  "loading": {
    "impedance": 47000,
    "capacitance": 200
  }
}
```

### **Response:**
```json
{
  "status": "ok",
  "preset_applied": "ortofon-2m-red",
  "compensation_curve": [
    { "freq": 20, "gain": 0.0 },
    { "freq": 50, "gain": 2.0 },
    { "freq": 10000, "gain": -2.0 }
  ],
  "dsp_enabled": true
}
```

### **Aktuelles Preset abfragen:**
```bash
GET /api/v1/presets/current
```

### **Response:**
```json
{
  "status": "ok",
  "cartridge": {
    "id": "ortofon-2m-red",
    "name": "Ortofon 2M Red",
    "type": "MM"
  },
  "compensation_active": true
}
```

---

## 💻 IMPLEMENTIERUNG

### **1. Python Flask/FastAPI Backend:**
```python
from flask import Flask, jsonify, request
import alsa_eq  # Custom ALSA EQ Wrapper

app = Flask(__name__)

@app.route('/api/v1/presets/apply', methods=['POST'])
def apply_preset():
    data = request.json
    cartridge_id = data['cartridge_id']
    
    # Load preset
    preset = load_preset(cartridge_id)
    
    # Apply DSP compensation
    alsa_eq.apply_curve(preset['compensation_curve'])
    
    return jsonify({
        'status': 'ok',
        'preset_applied': cartridge_id
    })
```

### **2. ALSA EQ Wrapper:**
```python
import subprocess
import json

class ALSAEQ:
    def apply_curve(self, curve):
        # Convert curve to ALSA EQ format
        # Apply via ALSA EQ plugin
        pass
```

### **3. Preset-Loader:**
```python
def load_preset(cartridge_id):
    with open(f'/var/www/phono-presets/{cartridge_id}.json') as f:
        return json.load(f)
```

---

## 📊 RESSOURCEN-OPTIMIERUNG

### **Pi Zero 2W Limits:**
- **RAM:** 512 MB (kritisch)
- **CPU:** 1.0 GHz Quad-core (OK für einfache DSP)

### **Optimierungen:**
1. **ALSA EQ statt CamillaDSP:** Weniger RAM
2. **Limitierte Bands:** 10-12 Bands statt 30+
3. **Pre-compiled Curves:** Keine Runtime-Berechnung
4. **Streaming:** Minimale Buffer-Größe

---

## 🎯 NÄCHSTE SCHRITTE

1. ⏳ MM/MC Cartridges recherchieren (50-100 häufigste)
2. ⏳ Frequency Response Curves sammeln
3. ⏳ Preset-Datenbank erstellen
4. ⏳ REST API implementieren (Flask/FastAPI)
5. ⏳ ALSA EQ Wrapper entwickeln
6. ⏳ Web-UI Integration

---

**Status:** Konzept erstellt - Ready für Implementation!

