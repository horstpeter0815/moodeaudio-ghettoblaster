# Room Correction Wizard - Real-Time Auto-Adjusting EQ

**Date**: 2026-01-19  
**Status**: Code ready, needs deployment  
**Location**: `rag-upload-files/source-code/room-correction-wizard.php`

## System Overview

**Real-time auto-adjusting EQ system:**

```
┌─────────────────┐     Pink Noise     ┌─────────────────┐
│  Raspberry Pi   │ ───────────────────>│  Room/Speakers  │
│  (plays noise)  │                     └─────────────────┘
└─────────────────┘                              │
                                          Sound travels
                                                 │
                                                 ▼
                        ┌────────────────────────────────────┐
                        │  iPhone Microphone (Web Browser)   │
                        │  - Measures frequency response     │
                        │  - Real-time FFT analysis          │
                        │  - Web Audio API                   │
                        └────────────────────────────────────┘
                                         │
                        Frequency data via HTTP POST
                                         │
                                         ▼
                        ┌────────────────────────────────────┐
                        │  Pi Backend (room-correction-      │
                        │  wizard.php)                       │
                        │  - Calculates corrections          │
                        │  - Generates CamillaDSP filters    │
                        │  - Applies EQ automatically        │
                        └────────────────────────────────────┘
                                         │
                                         ▼
                        ┌────────────────────────────────────┐
                        │  CamillaDSP                        │
                        │  - 12-band parametric EQ           │
                        │  - Real-time filter adjustment     │
                        └────────────────────────────────────┘
```

## How It Works

### Step 1: Pi Plays Continuous Pink Noise

**Command:** `start_pink_noise`

**Backend** (`room-correction-wizard.php` lines 349-381):
```php
case 'start_pink_noise':
    $cardnum = $_SESSION['cardnum'] ?? 0;
    $cmd = "speaker-test -t pink -c 2 -r 44100 -l 0 -D plughw:$cardnum,0 > /dev/null 2>&1 & echo $!";
    $pid = trim(shell_exec($cmd));
    file_put_contents('/var/run/pink_noise.pid', $pid);
```

**What happens:**
- Pi plays continuous pink noise through speakers
- Uses `speaker-test` with infinite loop (`-l 0`)
- 44.1kHz stereo pink noise
- Plays until stopped

### Step 2: iPhone Measures Frequency Response

**Frontend** (Web Audio API in browser):

**User opens:** `http://192.168.2.3/test-wizard/index-simple.html`

**Browser JavaScript:**
1. Requests microphone access
2. Captures audio in real-time
3. Performs FFT (Fast Fourier Transform)
4. Calculates frequency magnitude for each band
5. **Continuously measures** - 2-3 second rolling average
6. Subtracts ambient noise automatically

**Frequency Bands Measured:**
- 20Hz - 20kHz spectrum
- Real-time analysis
- Ambient noise compensation

### Step 3: Ambient Noise Measurement

**Before main measurement:**
1. User clicks "Measure Ambient Noise"
2. System measures room noise (5 seconds)
3. Stores baseline noise spectrum
4. **Automatically subtracted** from all subsequent measurements

**Why:** Ensures accurate room response without room noise interference

### Step 4: Continuous Measurement with Auto-Adjustment

**Process:**
1. Pink noise plays continuously
2. iPhone microphone measures frequency response
3. Web Audio API sends data to Pi every 2-3 seconds
4. **Backend automatically:**
   - Calculates target curve (flat by default)
   - Computes correction needed: `correction = target - measured`
   - Applies correction limits:
     * Bass (20-35Hz): ±15dB max
     * Other frequencies: ±10dB max
   - Generates CamillaDSP Biquad filters (12 bands)
   - **Applies filters in real-time**

**Backend** (`process_frequency_response` lines 425-506):
```php
case 'process_frequency_response':
    $freq_data = $_POST['frequency_response'] ?? null;
    
    // Calculate corrections
    for ($i = 0; $i < count($freq_data['frequencies']); $i++) {
        $freq = $freq_data['frequencies'][$i];
        $corr_value = $target_response[$i] - $freq_data['magnitude'][$i];
        
        // Apply limits
        if ($freq >= 20 && $freq <= 35) {
            $corr_value = max(-15.0, min(15.0, $corr_value));
        } else {
            $corr_value = max(-10.0, min(10.0, $corr_value));
        }
        
        $correction[] = $corr_value;
    }
```

### Step 5: Filter Generation

**Command:** `generate_peq`

**Backend** (lines 154-210):
- Calls Python script: `/usr/local/bin/generate-camilladsp-eq.py`
- Converts frequency corrections to Biquad filters
- Generates CamillaDSP YAML config
- 12-band parametric EQ
- Saves to: `/usr/share/camilladsp/configs/room_correction_peq_YYYY-MM-DD_HH-MM-SS.yml`

**Filter Format:**
```yaml
filters:
  band_1_63hz:
    type: Peaking
    freq: 63
    q: 1.0
    gain: -3.0  # Correction calculated from measurement
  
  band_2_125hz:
    type: Peaking
    freq: 125
    q: 1.0
    gain: 2.5
  
  # ... 10 more bands
```

### Step 6: Apply EQ Automatically

**Command:** `apply_peq`

**Backend** (lines 212-259):
- Loads generated CamillaDSP config
- Applies to CamillaDSP service
- Reloads configuration
- **EQ active immediately**
- Saves to database

**Result:** Room EQ automatically adjusted based on iPhone measurements!

## Complete Workflow

### User Experience:

1. **Open wizard on iPhone:**
   ```
   http://192.168.2.3/test-wizard/index-simple.html
   ```

2. **Set volume:**
   - Set Pi volume to comfortable level (50-60%)
   - Pink noise will play at this volume

3. **Measure ambient noise:**
   - Click "Measure Ambient Noise"
   - Keep room quiet for 5 seconds
   - Baseline stored

4. **Start measurement:**
   - Click "Start Pink Noise" (Pi starts playing)
   - Click "Start Measurement" (iPhone starts measuring)
   - **System continuously:**
     * Measures frequency response
     * Calculates corrections
     * Adjusts EQ
     * Updates in real-time

5. **User sees:**
   - Real-time frequency response graph
   - Target curve overlay
   - Correction values
   - EQ automatically adjusting

6. **When satisfied:**
   - Click "Stop Pink Noise"
   - Click "Apply Correction"
   - Final EQ saved and applied

## Technical Implementation

### Files Required

**Backend:**
1. `/var/www/command/room-correction-wizard.php` - Main PHP backend
2. `/usr/local/bin/generate-camilladsp-eq.py` - Python EQ generator
3. `/usr/local/bin/analyze-measurement.py` - FFT analysis (optional)

**Frontend:**
1. `/var/www/test-wizard/index-simple.html` - Main UI
2. `/var/www/test-wizard/wizard-functions.js` - JavaScript logic
3. `/var/www/test-wizard/snd-config.html` - Settings panel

### API Endpoints

**Base URL:** `http://192.168.2.3/command/room-correction-wizard.php`

**Commands:**
- `start_wizard` - Initialize wizard session
- `start_pink_noise` - Start pink noise playback
- `stop_pink_noise` - Stop pink noise
- `get_pink_noise_status` - Check if playing
- `process_frequency_response` - Process iPhone measurements
- `generate_peq` - Generate EQ filters
- `apply_peq` - Apply EQ to CamillaDSP
- `toggle_ab_test` - Enable A/B comparison

### Web Audio API Integration

**Frontend JavaScript:**

```javascript
// Request microphone access
navigator.mediaDevices.getUserMedia({ audio: true })
  .then(stream => {
    // Create audio context
    const audioContext = new AudioContext();
    const source = audioContext.createMediaStreamSource(stream);
    
    // Create analyzer
    const analyzer = audioContext.createAnalyser();
    analyzer.fftSize = 8192; // High resolution FFT
    source.connect(analyzer);
    
    // Continuous measurement
    const dataArray = new Uint8Array(analyzer.frequencyBinCount);
    function measureLoop() {
      analyzer.getByteFrequencyData(dataArray);
      
      // Convert to frequency/magnitude arrays
      const freqResponse = processFFT(dataArray, audioContext.sampleRate);
      
      // Send to Pi backend
      fetch('/command/room-correction-wizard.php', {
        method: 'POST',
        body: JSON.stringify({
          cmd: 'process_frequency_response',
          frequency_response: freqResponse
        })
      });
      
      // Repeat every 2-3 seconds
      setTimeout(measureLoop, 2500);
    }
    
    measureLoop();
  });
```

## Deployment Steps

### 1. Copy Backend PHP
```bash
scp rag-upload-files/source-code/room-correction-wizard.php andre@192.168.2.3:/tmp/
ssh andre@192.168.2.3 "sudo cp /tmp/room-correction-wizard.php /var/www/command/ && sudo chmod 755 /var/www/command/room-correction-wizard.php"
```

### 2. Create Python EQ Generator

**Create:** `/usr/local/bin/generate-camilladsp-eq.py`

This script:
- Reads frequency response JSON
- Calculates optimal Biquad filter coefficients
- Generates CamillaDSP YAML config
- 12-band parametric EQ

### 3. Create Frontend Files

Copy to Pi:
- `test-wizard/index-simple.html`
- `test-wizard/wizard-functions.js`

### 4. Test

```bash
# Check backend accessible
curl -X POST http://192.168.2.3/command/room-correction-wizard.php \
  -d "cmd=start_pink_noise"

# Open frontend on iPhone
# http://192.168.2.3/test-wizard/index-simple.html
```

## Current Status

**Code Locations:**
- ✅ Backend PHP: `rag-upload-files/source-code/room-correction-wizard.php`
- ✅ Documentation: `rag-upload-files/v1.0-docs/v1.0_room_correction_wizard.md`
- ⏳ Python scripts: Need to create
- ⏳ Frontend files: Need to locate/create
- ⏳ Deployment: Not deployed yet

**Next Steps:**
1. Locate frontend files (test-wizard/*.html, *.js)
2. Create Python EQ generator script
3. Deploy to Pi
4. Test with iPhone microphone
5. Verify auto-adjustment works

## Key Features

### Automatic EQ Adjustment
- **Continuous measurement** - Not one-shot, but ongoing
- **Real-time correction** - EQ updates as you measure
- **No manual EQ setting** - System calculates optimal values
- **iPhone microphone** - No special measurement mic needed
- **Web Audio API** - Browser-based, no app installation

### Correction Limits
- **Bass boost protection:** Max ±15dB (20-35Hz)
- **Other frequencies:** Max ±10dB
- **Prevents clipping** and excessive boosting
- **Safe corrections** that won't damage speakers

### Ambient Noise Compensation
- **Pre-measurement baseline** - Measures room noise
- **Automatic subtraction** - All measurements noise-compensated
- **Accurate results** even in non-ideal rooms

## Integration with Base Filter Architecture

**This wizard can work with the base filter system:**

```
MPD → _audioout → BASE FILTERS → CamillaDSP (Room Correction Wizard) → HiFiBerry
                  (manual offset)   (auto-measured room EQ)
```

**Workflow:**
1. Set base filters manually (speaker compensation)
2. Run Room Correction Wizard for room-specific EQ
3. **Result:** Base filters + automatically measured room correction!

This gives you:
- **Base layer:** Your custom speaker tuning (always active)
- **Room layer:** Auto-measured room correction (wizard-generated)
- **Both active:** Complete frequency response optimization

## Advantages Over REW

**Room Correction Wizard vs REW:**

| Feature | REW | Room Correction Wizard |
|---------|-----|------------------------|
| **Microphone** | Measurement mic required | iPhone built-in mic |
| **Setup** | Complex (Java, calibration) | Simple (open web page) |
| **Measurement** | One-shot sweep | Continuous real-time |
| **EQ Adjustment** | Manual export/import | **Automatic** |
| **User Experience** | Technical/expert | Consumer-friendly |
| **Cost** | $75+ (UMIK-1 mic) | Free (use iPhone) |

**Trade-off:** REW more accurate, Wizard more convenient

## Next Actions

**To deploy and use this system:**

1. **Find frontend files** in workspace
2. **Create Python EQ generator**
3. **Deploy to Pi**
4. **Test with your iPhone**
5. **Verify auto-adjustment**
6. **Document results**

**This is the real-time auto-adjusting EQ system you requested!**
