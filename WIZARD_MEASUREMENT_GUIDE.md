# Room Correction Wizard - Real Measurement Guide

## Where to Find the Wizard

**Location:** moOde Web UI → **Audio Settings** → **Room Correction** section

**Button:** Click **"Run Wizard"** button (next to the Room Correction preset dropdown)

**Direct URL:** http://moode.local/index.php?section=audio

## Step-by-Step Measurement Process

### Step 1: Preparation
- Position your iPhone at the listening position
- Ensure microphone access is allowed in Safari settings
- Reduce ambient noise as much as possible

### Step 2: Ambient Noise Measurement (5 seconds)
- System measures background noise
- **Important:** Be quiet during this measurement
- This baseline is subtracted from the final measurement

### Step 3: Continuous Pink Noise Measurement
- Pink noise plays continuously
- iPhone microphone records at listening position
- Real-time frequency response graph updates
- **Volume:** Set to comfortable level BEFORE starting
- Click **"Apply Correction"** when satisfied with measurement

### Step 4: Analysis & Filter Generation
- Review frequency response graph
- Select target curve (Flat or House Curve)
- Click **"Generate Filter"** to create PEQ correction

### Step 5: Apply Filter
- Review before/after comparison
- Set preset name
- Click **"Apply Filter"** to activate

### Step 6: Volume Optimization (NEW!)
- Test filter gain compensation (4-8 dB)
- Follow safety protocol:
  1. Volume set to 1%
  2. Press play
  3. Increase gradually
  4. Report: Too Quiet / Good / Too Loud
- System finds optimal gain automatically
- Save configuration when optimal

## iPhone Microphone Setup

### Safari Settings (Required!)
1. **Settings** → **Safari** → **Microphone**
2. Find your Pi's IP address (e.g., 192.168.3.8)
3. Set to **"Allow"**

### During Measurement
- Browser will ask for microphone permission
- Click **"Allow"** when prompted
- Keep iPhone steady at listening position

## Tips for Accurate Measurement

1. **Quiet Environment:** Minimize background noise
2. **Stable Position:** Keep iPhone in same position during measurement
3. **Volume Level:** Set comfortable volume BEFORE starting (pink noise plays at current volume)
4. **Measurement Time:** Let it run for 2-3 seconds to stabilize
5. **Multiple Positions:** Can run wizard multiple times for different listening positions

## Troubleshooting

### Microphone Not Working
- Check Safari microphone permissions
- Settings → Safari → Microphone → Allow for your IP
- Try refreshing the page

### Measurement Not Starting
- Check that pink noise is playing
- Verify microphone access was granted
- Check browser console for errors (Safari → Develop → Show Web Inspector)

### Slow Response
- Restart web services on Pi:
  ```bash
  ssh andre@moode.local
  sudo systemctl restart nginx
  sudo systemctl restart php8.4-fpm
  ```

## What Gets Measured

- **Frequency Response:** 20 Hz - 20 kHz
- **Room Acoustics:** Reflections, resonances, standing waves
- **Speaker Response:** Combined speaker + room response
- **Correction Target:** Flat (0 dB) or House Curve (Harman Target)

## After Measurement

1. **Filter Applied:** PEQ correction active in CamillaDSP
2. **Preset Saved:** Can be selected from Room Correction dropdown
3. **A/B Test:** Toggle filter on/off to compare
4. **Volume Optimized:** Filter gain compensation set for proper volume

---

**Ready to measure?** Go to Audio Settings → Room Correction → **Run Wizard** 🎵
