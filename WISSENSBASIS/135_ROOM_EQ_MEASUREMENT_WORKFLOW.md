# Room EQ Measurement Workflow - Pink Noise Analysis

**Date**: 2026-01-19  
**Goal**: Measure room acoustics and generate corrective filters  
**Method**: Pink noise measurement → frequency response analysis → CamillaDSP filters

## Overview

**Room EQ Workflow:**
```
1. Generate Pink Noise → 2. Play through speakers → 3. Record with microphone
                                                              ↓
6. Apply to CamillaDSP ← 5. Generate filters ← 4. Analyze frequency response
```

## What You Need

### Hardware
1. **Measurement Microphone**
   - USB measurement mic (e.g., miniDSP UMIK-1, Dayton iMM-6)
   - Or: Calibrated microphone with audio interface
   - Position at listening position

2. **Your Ghettoblaster System**
   - Playing pink noise through Bose Wave speakers
   - At normal listening volume (70-80 dB SPL)

### Software
1. **REW (Room EQ Wizard)** - Free, industry standard
   - Runs on Mac/Windows/Linux
   - Generates pink noise
   - Analyzes frequency response
   - Can export filters for CamillaDSP

2. **Alternative: CamillaDSP's built-in tools**
   - Can use command-line measurement tools
   - More manual but integrated

## Method 1: REW (Recommended)

### Step 1: Install REW on Your Mac

**Download:** https://www.roomeqwizard.com/

**Requirements:**
- Java Runtime Environment (JRE)
- USB audio interface or measurement mic

### Step 2: Configure REW

**Audio Device Setup:**
1. **Output**: Select how to send signal to Pi
   - Option A: Mac → Network → Pi (via SSH + aplay)
   - Option B: Mac audio output → cable → Pi audio input → loopback
   - Option C: Generate pink noise file → copy to Pi → play with MPD

2. **Input**: USB measurement microphone on Mac

**Calibration:**
- Load microphone calibration file (if available)
- UMIK-1 mics include calibration file
- Improves measurement accuracy

### Step 3: Measurement Process

**Position Microphone:**
- At listening position (where your head normally is)
- Pointing at speakers (or up, depending on mic)
- Away from walls/reflections if possible

**REW Measurement Steps:**
1. **Generate Pink Noise Test Signal**
   - File → Generator → Pink Noise
   - Duration: 30 seconds (longer = more accurate)
   - Level: -20 dBFS (safe starting point)

2. **Play Through Pi**
   - Export WAV file
   - Copy to Pi: `scp pink_noise.wav andre@192.168.2.3:/tmp/`
   - Play: `ssh andre@192.168.2.3 "mpc clear; mpc add /tmp/pink_noise.wav; mpc play"`

3. **Record Response**
   - REW → Measure button
   - Start recording on Mac while Pi plays pink noise
   - Keep room quiet during measurement

4. **Analyze Results**
   - REW shows frequency response graph
   - Identifies peaks/dips in response
   - Shows room modes, reflections

### Step 4: Generate Corrective Filters

**REW's EQ Feature:**
1. **Select Target Curve**
   - Flat response (most neutral)
   - Or: Harman curve (slight bass boost)
   - Or: Custom target

2. **Auto-EQ**
   - REW → EQ → Auto EQ
   - Select parametric filters (for CamillaDSP)
   - Choose number of filters (8-12 recommended)
   - REW calculates optimal filter parameters

3. **Export for CamillaDSP**
   - REW → File → Export Filter Settings
   - Format: Text file with frequencies, Q, gain
   - You'll manually enter these into CamillaDSP config

### Step 5: Apply to CamillaDSP

**CamillaDSP Configuration:**

Example filter output from REW:
```
Band 1: 45 Hz, Q=2.5, Gain=-6 dB (cut room mode)
Band 2: 120 Hz, Q=1.8, Gain=-3 dB (reduce boom)
Band 3: 250 Hz, Q=3.0, Gain=+2 dB (fill dip)
... etc
```

**Translate to CamillaDSP YAML:**

File: `/usr/share/camilladsp/room_eq_measured.yml`

```yaml
devices:
  samplerate: 48000
  chunksize: 2048
  capture:
    type: File
    channels: 2
    filename: "/dev/stdin"
    format: S32LE
  playback:
    type: Alsa
    channels: 2
    device: "_peppyout"
    format: S32LE

filters:
  # Room mode at 45Hz
  room_mode_45hz:
    type: Peaking
    freq: 45
    q: 2.5
    gain: -6.0
  
  # Room boom at 120Hz
  room_boom_120hz:
    type: Peaking
    freq: 120
    q: 1.8
    gain: -3.0
  
  # Dip correction at 250Hz
  dip_250hz:
    type: Peaking
    freq: 250
    q: 3.0
    gain: 2.0
  
  # Add all other bands here...

pipeline:
  - type: Filter
    channel: 0
    names:
      - room_mode_45hz
      - room_boom_120hz
      - dip_250hz
  - type: Filter
    channel: 1
    names:
      - room_mode_45hz
      - room_boom_120hz
      - dip_250hz
```

**Activate New Config:**
```bash
sudo ln -sf /usr/share/camilladsp/room_eq_measured.yml /usr/share/camilladsp/working_config.yml
sudo systemctl restart camilladsp
```

## Method 2: Command-Line (Advanced)

### Generate Pink Noise on Pi

**Using SoX:**
```bash
# Generate 30 seconds of pink noise
sox -n -r 48000 -c 2 pink_noise.wav synth 30 pinknoise

# Play through MPD
mpc clear
mpc add /tmp/pink_noise.wav
mpc volume 50  # Start at safe volume
mpc play
```

**Using Python:**
```python
import numpy as np
import soundfile as sf

# Generate pink noise (1/f spectrum)
duration = 30  # seconds
sample_rate = 48000
samples = int(duration * sample_rate)

# Pink noise generation algorithm
white_noise = np.random.randn(samples)
# Apply pink noise filter (simplified)
pink_noise = np.cumsum(white_noise)
pink_noise = pink_noise / np.max(np.abs(pink_noise))

# Stereo
pink_stereo = np.column_stack([pink_noise, pink_noise])

# Save
sf.write('/tmp/pink_noise.wav', pink_stereo, sample_rate)
```

### Capture Frequency Response

**Option A: Use USB Mic on Pi**
```bash
# Record while playing
arecord -D hw:2,0 -f S32_LE -r 48000 -c 1 -d 30 /tmp/recording.wav
```

**Option B: Use Phone App**
- Android: Audio Spectrum Analyzer
- iOS: AudioTools
- Export measurement data

### Analyze FFT

**Using SoX:**
```bash
sox /tmp/recording.wav -n spectrogram -o /tmp/spectrum.png
```

**Using Python:**
```python
import numpy as np
import matplotlib.pyplot as plt
from scipy.io import wavfile
from scipy.signal import welch

# Read recording
rate, data = wavfile.read('/tmp/recording.wav')

# Calculate power spectral density
freqs, psd = welch(data, rate, nperseg=8192)

# Plot
plt.semilogx(freqs, 10 * np.log10(psd))
plt.xlabel('Frequency (Hz)')
plt.ylabel('Power (dB)')
plt.grid(True)
plt.savefig('/tmp/frequency_response.png')
```

## Method 3: moOde's Built-in Room Correction Wizard

**moOde has a Room Correction Wizard!**

From your project files, I see references to:
- `documentation/v1.0_room_correction_wizard.md`
- `source-code/room-correction-wizard.php`

**To access:**
1. Open moOde web UI
2. Menu → Configure → Audio Options
3. Look for "Room Correction" or "Parametric EQ" section
4. There might be a wizard or manual EQ interface

**Let me check what moOde provides:**
