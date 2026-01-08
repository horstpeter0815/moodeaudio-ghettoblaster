# CamillaDSP Integration Plan - Room Correction

**Datum:** 6. Dezember 2025  
**Ziel:** Convolution Filter in CamillaDSP Pipeline einbinden

---

## 🔍 RESEARCH ERGEBNISSE

### **CamillaDSP Struktur in moOde:**

1. **Config Files:**
   - Location: `/usr/share/camilladsp/configs/`
   - Template: `/usr/share/camilladsp/__quick_convolution__.yml`
   - Working: `/usr/share/camilladsp/working_config.yml` (Symlink)

2. **Coefficients:**
   - Location: `/usr/share/camilladsp/coeffs/`
   - Format: WAV oder RAW
   - Stereo: Kann 2 Channels haben

3. **CamillaDsp Klasse:**
   - `selectConfig($configName)` - Config auswählen
   - `writeQuickConvolutionConfig()` - Quick Convolution Config schreiben
   - `setPlaybackDevice()` - Playback Device setzen
   - `updCDSPConfig()` - Config updaten

4. **Quick Convolution:**
   - Template: `__quick_convolution__.yml`
   - Parameters: `gain, irl, irr, irtype`
   - Placeholders: `__IR_GAIN__`, `__IR_LEFT__`, `__IR_RIGHT__`, etc.

---

## 💡 INTEGRATION STRATEGIE

### **Option 1: Quick Convolution Template nutzen** ⭐ **EMPFEHLUNG**

**Vorteile:**
- ✅ Bereits vorhanden in moOde
- ✅ Funktioniert mit `writeQuickConvolutionConfig()`
- ✅ Einfach zu integrieren

**Implementation:**
1. Filter wird in `/usr/share/camilladsp/coeffs/` kopiert (oder symlink)
2. Quick Convolution Config wird geschrieben
3. CamillaDSP wird auf Quick Convolution umgestellt

**Code:**
```php
// In room-correction-wizard.php apply_filter:
$filter_file = '/var/lib/camilladsp/convolution/' . $preset_name . '.wav';
$coeff_file = '/usr/share/camilladsp/coeffs/room_correction_' . $preset_name . '.wav';

// Copy filter to coeffs directory
copy($filter_file, $coeff_file);

// Setup Quick Convolution
$cdsp = new CamillaDsp($_SESSION['camilladsp'], $_SESSION['cardnum'], $_SESSION['camilladsp_quickconv']);
$cdsp->setQuickConvolutionConfig([
    'gain' => '0', // No additional gain
    'irl' => 'room_correction_' . $preset_name . '.wav',
    'irr' => 'room_correction_' . $preset_name . '.wav', // Same for stereo
    'irtype' => 'WAVE'
]);
$cdsp->selectConfig('__quick_convolution__.yml');
$cdsp->reloadConfig();
```

---

### **Option 2: Custom Config File erstellen**

**Vorteile:**
- ✅ Mehr Kontrolle
- ✅ Kann mit anderen Filters kombiniert werden

**Nachteile:**
- ⚠️ Komplexer
- ⚠️ Muss Pipeline richtig konfigurieren

---

## 🎯 IMPLEMENTATION PLAN

### **1. Filter in Coefficients kopieren:**

```php
// Copy generated filter to CamillaDSP coeffs directory
$filter_file = '/var/lib/camilladsp/convolution/' . $preset_name . '.wav';
$coeff_file = '/usr/share/camilladsp/coeffs/room_correction_' . $preset_name . '.wav';

if (!copy($filter_file, $coeff_file)) {
    // Error handling
}
```

### **2. Quick Convolution aktivieren:**

```php
// Use Quick Convolution
$cdsp = new CamillaDsp($_SESSION['camilladsp'], $_SESSION['cardnum'], $_SESSION['camilladsp_quickconv']);
$cdsp->setQuickConvolutionConfig([
    'gain' => '0',
    'irl' => 'room_correction_' . $preset_name . '.wav',
    'irr' => 'room_correction_' . $preset_name . '.wav',
    'irtype' => 'WAVE'
]);
$cdsp->selectConfig('__quick_convolution__.yml');
$cdsp->setPlaybackDevice($_SESSION['cardnum'], $_SESSION['alsa_output_mode']);
$cdsp->reloadConfig();
```

### **3. Deaktivieren:**

```php
// Disable Room Correction
if ($_SESSION['camilladsp'] != 'off') {
    // Restore previous CamillaDSP config
    $cdsp->selectConfig($_SESSION['camilladsp']);
} else {
    // Turn off CamillaDSP
    $cdsp->selectConfig('off');
}
```

---

## ⚠️ HINWEISE

1. **CamillaDSP muss aktiv sein:**
   - Room Correction benötigt CamillaDSP
   - Falls `camilladsp == 'off'`, muss es aktiviert werden

2. **Symlink statt Copy:**
   - Optional: Symlink statt Copy für weniger Storage
   - `symlink($filter_file, $coeff_file)`

3. **Stereo vs Mono:**
   - Aktuell: Gleicher Filter für L+R
   - Zukunft: Separate L/R Filter möglich

---

**Status:** ✅ Research abgeschlossen - Ready für Implementation

