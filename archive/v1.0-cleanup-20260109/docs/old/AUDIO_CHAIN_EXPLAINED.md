# moOde Audio Chain Explained

## Overview

The audio chain in moOde shows how audio flows from music files to your speakers:

```
Music File → MPD → CamillaDSP → ALSA → Hardware
```

## Components

### 1. MPD (Music Player Daemon)
- Reads and decodes music files
- Outputs digital audio stream
- Can output via:
  - **Pipe** (to CamillaDSP process)
  - **ALSA** (directly to sound card, or routed to CamillaDSP)

### 2. CamillaDSP (Digital Signal Processing)
- Processes audio with filters/EQ
- Applies:
  - Parametric EQ (PEQ) filters (like your Bose Wave filters)
  - Convolution filters (room correction IR files)
  - Crossovers, delays, etc.
- Outputs processed audio to ALSA

### 3. ALSA (Advanced Linux Sound Architecture)
- Linux audio subsystem
- Routes audio to hardware sound card
- Manages volume, format conversion

### 4. Hardware
- Your DAC/sound card (e.g., HiFiBerry DAC)
- Speakers/headphones

## How Bose Wave Filters Work

1. **Config File**: `/usr/share/camilladsp/configs/bose_wave_filters.yml`
   - Contains 20 PEQ filter bands
   - Left and right channels processed separately

2. **Activation**:
   - Selected in moOde Web UI: **Audio Config → CamillaDSP**
   - Dropdown: **Signal processing** → Select `bose_wave_filters.yml`
   - Click **Apply**

3. **Processing**:
   - MPD sends audio to CamillaDSP
   - CamillaDSP applies all 20 filter bands to each channel
   - Processed audio sent to ALSA → Hardware

## Audio Chain Modes

### Mode 1: CamillaDSP OFF (Direct)
```
Music → MPD → ALSA → Hardware
```
- No filtering applied
- Direct audio output

### Mode 2: CamillaDSP ON (Pipe Mode)
```
Music → MPD → (pipe) → CamillaDSP → ALSA → Hardware
```
- MPD outputs via named pipe or stdout
- CamillaDSP reads from stdin
- Most common mode

### Mode 3: CamillaDSP ON (ALSA Mode)
```
Music → MPD → ALSA → CamillaDSP → ALSA → Hardware
```
- MPD outputs to ALSA device
- ALSA routes to CamillaDSP
- CamillaDSP processes and outputs back to ALSA

## Checking Your Audio Chain

### Quick Check (Web UI)
1. Go to **Audio Config** → **CamillaDSP**
2. Check **Signal processing** dropdown
3. Should show `bose_wave_filters.yml` if active

### Detailed Check (SSH)
Run the diagnostic script:
```bash
./check-audio-chain.sh
```

This will show:
- MPD status
- CamillaDSP status
- Active configuration
- Available config files
- Audio device info
- Current audio path

## Troubleshooting

### Filters Not Working?
1. **Check if CamillaDSP is enabled**
   - Web UI: Audio Config → CamillaDSP → Signal processing ≠ "Off"

2. **Check if config file exists**
   ```bash
   ls -la /usr/share/camilladsp/configs/bose_wave_filters.yml
   ```

3. **Check if CamillaDSP is running**
   ```bash
   pgrep camilladsp
   ```

4. **Check active config in database**
   ```bash
   sqlite3 /var/local/www/db/moode-sqlite3.db "SELECT value FROM cfg_system WHERE param = 'camilladsp';"
   ```

### Common Issues

- **CamillaDSP OFF**: Filters won't be applied
- **Config file missing**: Filter file not found in configs directory
- **Wrong config selected**: Different config active, not `bose_wave_filters.yml`
- **CamillaDSP not running**: Service stopped or crashed

## File Locations

- **CamillaDSP configs**: `/usr/share/camilladsp/configs/`
- **CamillaDSP coefficients**: `/usr/share/camilladsp/coeffs/`
- **MPD config**: `/var/lib/mpd/mpd.conf`
- **ALSA config**: `/etc/alsa/conf.d/`
- **moOde database**: `/var/local/www/db/moode-sqlite3.db`

## Your Bose Wave Filters

- **Config**: `bose_wave_filters.yml`
- **Location**: `/usr/share/camilladsp/configs/bose_wave_filters.yml`
- **Type**: Parametric EQ (PEQ) with 20 bands
- **Channels**: Stereo (both channels processed separately)
- **Filters**: Lowshelf, Peaking, Highshelf types
