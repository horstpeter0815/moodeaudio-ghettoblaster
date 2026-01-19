# Room Correction Wizard - DEPLOYED and Ready to Use!

**Date**: 2026-01-19  
**Status**: ✅ FULLY DEPLOYED  
**Pi IP**: 192.168.2.3

## ✅ What's Deployed

**Backend:**
- ✅ `/var/www/command/room-correction-wizard.php` - PHP backend
- ✅ `/usr/local/bin/generate-camilladsp-eq.py` - EQ generator
- ✅ `/usr/local/bin/analyze-measurement.py` - Analyzer
- ✅ Python dependencies installed (scipy, soundfile, numpy)

**Frontend:**
- ✅ `/var/www/wizard-test.html` - Mobile-friendly web interface

## 🎯 How to Use (Step-by-Step)

### On Your Pi:

1. **Set Volume First (Important!)**
   ```bash
   ssh andre@192.168.2.3
   mpc volume 50  # Set to comfortable listening level
   ```

### On Your iPhone:

2. **Open the Wizard:**
   ```
   http://192.168.2.3/wizard-test.html
   ```

3. **Follow the On-Screen Instructions:**
   - Grant microphone access when prompted
   - Position iPhone at listening position
   - Click "Start Pink Noise on Pi"
   - Click "Start Measurement (iPhone Mic)"
   - **Watch the magic happen!**

4. **Real-Time Auto-Adjustment:**
   - System measures frequency response every 2.5 seconds
   - Automatically calculates corrections
   - Shows frequency spectrum in real-time
   - Displays dB values for each band

5. **When Satisfied:**
   - Click "Apply Correction"
   - EQ filters generated and applied automatically!
   - Click "Stop Everything" when done

## 🔧 What Happens Behind the Scenes

### Continuous Loop:

```
1. Pink Noise plays from Pi speakers
        ↓
2. iPhone microphone captures sound
        ↓
3. Web Audio API performs FFT analysis
        ↓
4. JavaScript extracts 9 frequency bands:
   - 63Hz, 125Hz, 250Hz, 500Hz, 1kHz
   - 2kHz, 4kHz, 8kHz, 16kHz
        ↓
5. Sends data to Pi backend (every 2.5s)
        ↓
6. PHP processes frequency response
        ↓
7. Calculates corrections (target - measured)
        ↓
8. When you click "Apply":
   - Python generates 12-band Biquad filters
   - CamillaDSP config created
   - EQ applied automatically
```

### Frequency Bands Measured:

| Band | Frequency | Purpose |
|------|-----------|---------|
| 1 | 63 Hz | Sub-bass |
| 2 | 125 Hz | Bass |
| 3 | 250 Hz | Low-mids |
| 4 | 500 Hz | Mids |
| 5 | 1 kHz | Upper-mids |
| 6 | 2 kHz | Presence |
| 7 | 4 kHz | Clarity |
| 8 | 8 kHz | Brilliance |
| 9 | 16 kHz | Air |

## 📊 Visual Feedback

**On iPhone Screen:**
1. **Status Bar** - Current operation status
2. **Spectrum Visualizer** - Real-time frequency spectrum (colorful bars)
3. **Frequency Display** - 9 bands with dB values
4. **Control Buttons** - Start/Stop/Apply

**Example Display:**
```
63 Hz        125 Hz       250 Hz
-3.2 dB      -1.8 dB      +2.1 dB

500 Hz       1 kHz        2 kHz
+0.5 dB      -0.2 dB      +1.3 dB

4 kHz        8 kHz        16 kHz
-2.4 dB      +3.1 dB      +1.8 dB
```

## 🎛️ Correction Limits

**Built-in Safety:**
- **Bass (20-35Hz):** Max ±15dB
- **Other frequencies:** Max ±10dB
- **Purpose:** Prevents clipping and speaker damage

## 🔄 Integration with Base Filters

**This wizard creates the ROOM LAYER:**

```
MPD → _audioout → BASE FILTERS → CamillaDSP (Wizard) → HiFiBerry
                  (manual)       (auto-measured)
```

**Complete workflow:**
1. Set base filters manually (speaker compensation)
2. Run wizard for room-specific EQ
3. Result: Base + Room correction!

## 🧪 Testing Commands

**Test backend directly:**
```bash
# Start wizard
curl -X POST http://192.168.2.3/command/room-correction-wizard.php -d 'cmd=start_wizard'

# Start pink noise
curl -X POST http://192.168.2.3/command/room-correction-wizard.php -d 'cmd=start_pink_noise'

# Check if playing
curl -X POST http://192.168.2.3/command/room-correction-wizard.php -d 'cmd=get_pink_noise_status'

# Stop pink noise
curl -X POST http://192.168.2.3/command/room-correction-wizard.php -d 'cmd=stop_pink_noise'
```

**Expected responses:**
```json
{"status":"ok","step":1,"message":"Wizard started"}
{"status":"ok","message":"Pink noise started","pid":"12345"}
{"status":"ok","playing":true,"pid":"12345"}
{"status":"ok","message":"Pink noise stopped"}
```

## 🐛 Troubleshooting

### Pink Noise Won't Start
```bash
# Check if speaker-test is available
ssh andre@192.168.2.3 "which speaker-test"

# Check audio device
ssh andre@192.168.2.3 "aplay -l"

# Kill any stuck processes
ssh andre@192.168.2.3 "sudo pkill -f speaker-test"
```

### iPhone Can't Access Website
```bash
# Check if Pi is reachable
ping 192.168.2.3

# Check if web server is running
curl -I http://192.168.2.3/

# Check if wizard file exists
ssh andre@192.168.2.3 "ls -la /var/www/wizard-test.html"
```

### Microphone Access Denied
- iPhone Settings → Safari → Microphone → Allow
- Or use Chrome/Firefox mobile browser

### EQ Not Applying
```bash
# Check CamillaDSP is running
ssh andre@192.168.2.3 "systemctl status camilladsp"

# Check generated configs
ssh andre@192.168.2.3 "ls -la /usr/share/camilladsp/configs/"

# Check Python scripts
ssh andre@192.168.2.3 "ls -la /usr/local/bin/generate-camilladsp-eq.py"
```

## 📝 Tips for Best Results

1. **Volume:**
   - Set to comfortable listening level BEFORE starting
   - Not too loud (risk hearing damage)
   - Not too quiet (poor signal-to-noise ratio)

2. **Microphone Position:**
   - At your normal listening position
   - Same height as your ears when seated
   - Away from walls (at least 1 meter)

3. **Room Conditions:**
   - Close windows/doors
   - Turn off noisy appliances
   - Quiet environment (no talking/TV)

4. **Measurement Duration:**
   - Let it measure for 30-60 seconds
   - More measurements = better averaging
   - Watch frequency display stabilize

5. **Verification:**
   - After applying EQ, test with music
   - Compare before/after
   - Re-measure if needed

## 🎉 Success Indicators

**You know it's working when:**
- ✅ Pi plays continuous pink noise
- ✅ iPhone shows spectrum moving/changing
- ✅ Frequency values update every 2-3 seconds
- ✅ "Apply Correction" button is enabled
- ✅ No error messages in status bar

**After applying:**
- ✅ CamillaDSP config created with timestamp
- ✅ EQ active in moOde Audio Settings
- ✅ Music sounds more balanced/flat

## 🔗 Quick Links

**Access Points:**
- **Wizard:** http://192.168.2.3/wizard-test.html
- **moOde UI:** http://192.168.2.3/
- **CamillaDSP Configs:** http://192.168.2.3/cdsp-config.php

**SSH Access:**
```bash
ssh andre@192.168.2.3  # Password: 0815
```

## 📚 Related Documentation

- **WISSENSBASIS/137** - Complete technical implementation details
- **WISSENSBASIS/136** - Manual room EQ workflow (REW alternative)
- **WISSENSBASIS/134** - Base filter architecture
- **WISSENSBASIS/132** - Audio chain analysis

## 🚀 Next Steps

**After wizard works:**
1. Run measurement in your room
2. Apply generated EQ
3. Test with various music genres
4. Fine-tune if needed (run wizard again)
5. Save working configuration

**For permanent setup:**
- Create named presets in moOde
- Document your room-specific settings
- Back up CamillaDSP configs

## 🎯 Current Implementation Status

| Component | Status | Notes |
|-----------|--------|-------|
| Backend PHP | ✅ Deployed | /var/www/command/room-correction-wizard.php |
| Python Scripts | ✅ Deployed | generate-camilladsp-eq.py, analyze-measurement.py |
| Dependencies | ✅ Installed | scipy, soundfile, numpy |
| Frontend | ✅ Deployed | /var/www/wizard-test.html |
| Pink Noise | ✅ Tested | speaker-test working |
| Web Access | ✅ Ready | http://192.168.2.3/wizard-test.html |

**Ready to use! Open on your iPhone now! 🎵**
