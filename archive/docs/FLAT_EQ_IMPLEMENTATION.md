# Flat EQ Preset - Implementierungs-Plan

**Datum:** 6. Dezember 2025  
**Ziel:** Flat EQ Preset für Ghetto Crew System implementieren

---

## 🎯 ZUSAMMENFASSUNG

**User-Anforderung:**
- Flat EQ Preset: Gerade Linie für alle Treiber
- Basierend auf Frequency Response Charakteristiken
- Factory Settings (Default: Flat)
- Ein/Aus-Schalter im Web-UI
- Nutzung moOde's bestehender Preset-Templates

---

## 📊 FREQUENCY RESPONSE DATEN

### **Bose 901 Series 6 (Bass - 8x Treiber):**

**Frequency Response (aus Recherche):**
- **130-250 Hz:** +5-6 dB Anhebung
- **6000 Hz:** -7 dB Abfall
- **10.000-15.000 Hz:** Wiederanstieg auf Referenzniveau

**Bose 901 Original EQ-Parameter:**
- **Mid-Bass:** ±6 dB bei 225 Hz
- **Mid-Treble:** ±6 dB bei 3000 Hz

**Impedanz (aus BOSE_901_MEASUREMENTS.md):**
- **Minimum:** ~0.8 Ohm (400-500 Hz)
- **Resonanz:** ~4.3 Ohm (90-100 Hz)
- **Nenn:** 8 Ohm

**Kompensation für Flat Response:**
```
130-250 Hz: -5 bis -6 dB (Anhebung ausgleichen)
6000 Hz: +7 dB (Abfall ausgleichen)
225 Hz: -5 dB (Mid-Bass Kompensation)
3000 Hz: 0 dB (Mid-Treble - wird angepasst)
```

### **Fostex T90A Super Tweeter (Hochton):**

**Spezifikationen:**
- **Frequenzbereich:** 5 kHz - 35 kHz
- **Empfindlichkeit:** 106 dB/W(1m)
- **Crossover:** 7 kHz empfohlen

**Frequency Response:** (Wird noch recherchiert - geschätzt relativ flach im Bereich 5-20 kHz)

**Kompensation:**
- (Wird basierend auf Frequency Response Daten berechnet)

### **Fostex Mitteltön:**

**Details:** (Wird noch recherchiert)
- **Frequency Response:** (Wird recherchiert)

**Kompensation:**
- (Wird basierend auf Frequency Response Daten berechnet)

---

## 🔧 MOODE AUDIO INTEGRATION

### **Bestehende Systeme:**

1. **CamillaDSP:**
   - Erweiterte DSP-Funktionen
   - Preset-System vorhanden
   - Web-UI Integration über `snd-config.php`

2. **EQ Preset System (`eqp.php`):**
   - Preset-Verwaltung
   - Speicherung in Datenbank
   - Integration in Web-UI

3. **Audio Config (`snd-config.php`):**
   - Haupt-Interface für Audio-Einstellungen
   - Preset-Auswahl
   - Toggle-Funktionen

### **Implementierungs-Optionen:**

**Option 1: CamillaDSP Preset**
- Vorteil: Sehr flexibel, professionell
- Nachteil: Benötigt CamillaDSP Konfiguration

**Option 2: ALSA EQ Plugin**
- Vorteil: Einfacher, direkt verfügbar
- Nachteil: Weniger Bands, weniger flexibel

**Option 3: moOde EQ Preset System**
- Vorteil: Bestehende Integration, einfach
- Nachteil: Abhängig von moOde's EQ-System

**Empfehlung:** Option 3 (moOde EQ Preset) für Einfachheit

---

## 💻 IMPLEMENTIERUNG

### **1. Preset-Datei erstellen:**

**Datei:** `/var/www/html/command/ghettoblaster-flat-eq.json`

```json
{
  "name": "Ghetto Crew Flat EQ",
  "description": "Factory Flat EQ für Ghetto Crew System (Bose 901 + Fostex)",
  "type": "equalizer",
  "bands": [
    { "freq": 20, "gain": 0.0 },
    { "freq": 100, "gain": 0.0 },
    { "freq": 130, "gain": -5.0 },
    { "freq": 225, "gain": -5.0 },
    { "freq": 250, "gain": -5.0 },
    { "freq": 500, "gain": 0.0 },
    { "freq": 1000, "gain": 0.0 },
    { "freq": 3000, "gain": 0.0 },
    { "freq": 6000, "gain": 7.0 },
    { "freq": 10000, "gain": 0.0 },
    { "freq": 20000, "gain": 0.0 }
  ],
  "enabled": false
}
```

### **2. PHP Handler:**

**Datei:** `moode-source/www/command/ghettoblaster-flat-eq.php`

```php
<?php
require_once __DIR__ . '/../inc/common.php';
require_once __DIR__ . '/../inc/session.php';
require_once __DIR__ . '/../inc/sql.php';

phpSession('open');
$dbh = sqlConnect();

$cmd = $_POST['cmd'] ?? '';
$response = ['status' => 'error', 'message' => 'Invalid command'];

switch ($cmd) {
    case 'toggle':
        $enabled = $_POST['enabled'] ?? 'false';
        // Load preset and apply EQ
        // Save state to database
        sqlUpdate('cfg_system', $dbh, 'ghettoblaster_flat_eq', $enabled);
        $response = ['status' => 'ok', 'enabled' => $enabled];
        break;
    
    case 'status':
        $enabled = sqlQuery('cfg_system', $dbh, 'ghettoblaster_flat_eq', 'false');
        $response = ['status' => 'ok', 'enabled' => $enabled];
        break;
}

header('Content-Type: application/json');
echo json_encode($response);
phpSession('close');
?>
```

### **3. Web-UI Integration:**

**Datei:** `moode-source/www/templates/snd-config.html`

```html
<!-- Ghetto Crew Flat EQ -->
<div class="control-group">
    <label class="control-label" for="ghettoblaster-flat-eq">Flat EQ (Factory Settings)</label>
    <div class="controls">
        <label class="checkbox">
            <input type="checkbox" id="ghettoblaster-flat-eq" 
                   onchange="toggleGhettoBlasterFlatEQ(this.checked);">
            Enable Flat EQ (Kompensiert Frequency Response für gerade Linie)
        </label>
        <span class="help-block">
            Aktiviert/Deaktiviert den Flat EQ Preset für Ghetto Crew System.
            Kompensiert Frequency Response Schwankungen für eine gerade Linie.
        </span>
    </div>
</div>
```

**JavaScript:**
```javascript
function toggleGhettoBlasterFlatEQ(enabled) {
    $.post('/command/ghettoblaster-flat-eq.php', {
        cmd: 'toggle',
        enabled: enabled ? 'true' : 'false'
    }, function(data) {
        if (data.status === 'ok') {
            // Reload audio config or show notification
            showNotification('Flat EQ ' + (enabled ? 'aktiviert' : 'deaktiviert'));
        }
    });
}
```

---

## 📋 NÄCHSTE SCHRITTE

1. ✅ Frequency Response Daten sammeln (alle Treiber)
2. ⏳ Preset-Werte finalisieren (basierend auf allen Daten)
3. ⏳ PHP Handler implementieren
4. ⏳ Web-UI Integration
5. ⏳ Testen mit echtem System

---

**Status:** Planung abgeschlossen - Implementierung kann starten nach Frequency Response Daten

