# Practical Room EQ Workflow - Your Ghettoblaster System

**Date**: 2026-01-19  
**System**: Raspberry Pi 5 + Bose Wave + HiFiBerry AMP100  
**Goal**: Measure room, generate filters, apply to base layer

## Quick Overview

moOde has THREE EQ options available:
1. **Parametric EQ** (eqfa12p) - 12 bands, precise control → `http://192.168.2.3/eqp-config.php`
2. **Graphic EQ** (alsaequal) - 10 bands, simple → `http://192.168.2.3/eqg-config.php`
3. **CamillaDSP** - Full DSP engine → `http://192.168.2.3/cdsp-config.php`

## Recommended Approach

### Strategy: Two-Layer Architecture

**Layer 1 (Base - Always Active):**
- Use **Parametric EQ** (eqfa12p) for speaker compensation
- Configure via moOde UI at `/eqp-config.php`
- This will be your BASE FILTERS that work with PeppyMeter

**Layer 2 (Room - When Not Using PeppyMeter):**
- Use **CamillaDSP** for room-specific corrections
- Already configured with Bose Wave filters
- Can add room measurements on top

## Complete Workflow

### Phase 1: Generate Pink Noise File

**On Pi (via SSH):**
```bash
# Generate 30 seconds of pink noise at 48kHz
sox -n -r 48000 -c 2 -b 16 /var/lib/mpd/music/RADIO/pink_noise.flac synth 30 pinknoise

# Add to MPD library
mpc update
sleep 2
mpc search filename pink_noise.flac
```

**Verify file created:**
```bash
ls -lh /var/lib/mpd/music/RADIO/pink_noise.flac
```

### Phase 2: Measurement Setup

**What You Need:**
1. **Microphone**: iPhone/Android with measurement app, or USB mic
2. **Position**: Place phone/mic at listening position
3. **Volume**: Set to normal listening level (not too loud)

**Recommended Apps:**
- **iOS**: AudioTools ($9.99) - Professional room analysis
- **Android**: Audio Spectrum Analyzer (Free) - Basic spectrum view
- **Desktop**: REW (Free) - Most powerful option

**Or Use Mac Microphone:**
- Built-in Mac mic for rough measurement
- USB audio interface for better accuracy

### Phase 3: Perform Measurement

**Step-by-step:**

1. **Start Recording on Measurement Device**
   - Open measurement app
   - Start RTA (Real-Time Analyzer) or Frequency Response mode
   - Or use Mac: `sox -d recording.wav` to record

2. **Play Pink Noise on Pi**
   ```bash
   ssh andre@192.168.2.3
   mpc clear
   mpc search filename pink_noise.flac | mpc add
   mpc volume 60  # Start at moderate volume
   mpc repeat on
   mpc play
   ```

3. **Capture Response**
   - Let pink noise play for 30-60 seconds
   - App will show frequency response graph
   - Screenshot or export the data

4. **Stop Playback**
   ```bash
   mpc stop
   ```

### Phase 4: Analyze Frequency Response

**What to Look For:**

1. **Room Modes** (20-200 Hz)
   - Large peaks = bass buildup
   - Large dips = bass cancellation
   - Typical in corners/walls

2. **Mid-Range** (200-2000 Hz)
   - Should be relatively flat
   - Peaks = boxiness, honkiness
   - Dips = lack of presence

3. **High Frequencies** (2000-20000 Hz)
   - Natural roll-off is normal
   - Sharp peaks = harshness
   - Dips = dullness

**Example Problem Frequencies:**
```
45-60 Hz:   Room mode (bass boom in corner)
120-150 Hz: Cabinet resonance
250-400 Hz: Boxiness/mud
2-4 kHz:    Harsh/sibilant
8-12 kHz:   Brightness/air
```

### Phase 5: Configure Base Filters (Parametric EQ)

**Access moOde Parametric EQ:**
```
http://192.168.2.3/eqp-config.php
```

**Configure 12-band EQ based on measurements:**

**Example Configuration (adjust to YOUR measurements):**

1. **Band 1: 50 Hz**
   - Problem: +6dB room mode peak
   - Setting: Q=2.0, Gain=-6dB (cut the peak)

2. **Band 2: 120 Hz**
   - Problem: +3dB cabinet resonance
   - Setting: Q=1.5, Gain=-3dB

3. **Band 3: 200 Hz**
   - Problem: -4dB dip
   - Setting: Q=1.0, Gain=+3dB (fill the dip)

4. **Band 4: 500 Hz**
   - Problem: +2dB boxiness
   - Setting: Q=2.0, Gain=-2dB

5. **Band 5: 1000 Hz** - Reference (0dB)

6. **Band 6: 2000 Hz**
   - Problem: -2dB dip
   - Setting: Q=1.5, Gain=+2dB

7. **Band 7: 4000 Hz**
   - Problem: +3dB harshness
   - Setting: Q=2.5, Gain=-3dB

8. **Band 8: 8000 Hz**
   - Problem: -3dB dullness
   - Setting: Q=1.5, Gain=+3dB

9. **Bands 9-12**: Leave at 0dB unless specific issues

**In moOde UI:**
- Enable the bands you need
- Set frequency, Q (bandwidth), and gain
- Click "Set" to apply
- Click "Save" to make persistent

### Phase 6: Test & Iterate

**Listening Test:**
```bash
# Play familiar music
mpc clear
mpc add "Your favorite track"
mpc play
```

**Re-measure with EQ Applied:**
```bash
# Play pink noise again
mpc clear
mpc search filename pink_noise.flac | mpc add
mpc play
```

**Compare Before/After:**
- Should see flatter response
- Peaks reduced, dips filled
- More balanced across spectrum

**Adjust if needed:**
- Too much bass cut? Reduce negative gain
- Still harsh? Increase cut at problem frequency
- Sounds dull? Boost high frequencies

### Phase 7: Configure CamillaDSP (Additional Room EQ)

**If you want MORE correction on top of base filters:**

1. **Access CamillaDSP config:**
   ```
   http://192.168.2.3/cdsp-config.php
   ```

2. **Edit existing Bose Wave config:**
   ```bash
   ssh andre@192.168.2.3
   sudo nano /usr/share/camilladsp/working_config.yml
   ```

3. **Add room-specific filters:**
   ```yaml
   filters:
     # Keep existing Bose Wave filters...
     
     # Add room corrections
     room_mode_50hz:
       type: Peaking
       freq: 50
       q: 3.0
       gain: -4.0  # Additional room mode cut
     
     room_reflection_3khz:
       type: Peaking
       freq: 3000
       q: 2.0
       gain: -2.0  # Reduce reflection harshness
   
   pipeline:
     - type: Filter
       channel: 0
       names:
         - bose_filter_1  # Existing
         - bose_filter_2  # Existing
         - room_mode_50hz  # New
         - room_reflection_3khz  # New
   ```

4. **Restart CamillaDSP:**
   ```bash
   sudo systemctl restart camilladsp
   ```

## Practical Tips

### Measurement Best Practices

1. **Multiple Positions**
   - Measure at 3-5 different listening positions
   - Average the results
   - Avoids over-correcting for one spot

2. **Background Noise**
   - Turn off HVAC, fans, appliances
   - Close windows
   - Quiet room = better measurements

3. **Volume Level**
   - Measure at normal listening volume
   - Speaker response can change with volume
   - Too loud = nonlinear distortion

4. **Microphone Position**
   - At ear height (seated position)
   - Point mic at speakers (or up, depending on type)
   - Avoid directly against walls

### EQ Configuration Guidelines

1. **Cut, Don't Boost**
   - Cutting peaks is safer than boosting dips
   - Boosting can cause clipping/distortion
   - Use boost only for small corrections (<3dB)

2. **Low Q for Bass, High Q for Mids/Highs**
   - Bass: Q = 0.7-1.5 (wider bandwidth)
   - Mids: Q = 1.0-2.0
   - Treble: Q = 1.5-3.0 (narrower bandwidth)

3. **Limit Total Correction**
   - Avoid extreme corrections (>6dB)
   - If you need >10dB correction, there's a bigger problem
   - Consider room treatment or speaker placement

4. **A/B Testing**
   - Enable/disable EQ to compare
   - Use familiar, well-recorded music
   - Trust your ears, not just measurements

### What Goes in Each Layer?

**Parametric EQ (Base Layer - Always Active):**
- Speaker response compensation
- Cabinet resonances
- Driver characteristics
- Major room modes
→ Applied to BOTH normal and PeppyMeter playback

**CamillaDSP (Room Layer - Normal Playback Only):**
- Fine room corrections
- Listening position optimization
- Advanced processing (compression, limiting)
- Crossover (if using multiple speakers)
→ Bypassed during PeppyMeter (acceptable tradeoff)

## Verification

**After configuration, verify:**

1. **Normal Playback**
   ```bash
   mpc play
   # Should have: Parametric EQ + CamillaDSP
   ```

2. **PeppyMeter Active**
   - Click PeppyMeter button
   - Should have: Parametric EQ only (base filters)
   - Sound should be consistent with normal playback

3. **A/B Test**
   - Disable Parametric EQ in moOde UI
   - Play music
   - Enable Parametric EQ
   - Should hear difference: flatter, more balanced

## Tools Summary

**Installed on Your Pi:**
- ✅ SoX (pink noise generation)
- ✅ MPD (playback)
- ✅ Parametric EQ (eqfa12p - 12 bands)
- ✅ Graphic EQ (alsaequal - 10 bands)
- ✅ CamillaDSP (advanced DSP)

**Needed for Measurement:**
- Microphone (phone/USB/Mac built-in)
- Measurement app (AudioTools/REW/spectrum analyzer)

**moOde UI Access:**
- Parametric EQ: `http://192.168.2.3/eqp-config.php`
- Graphic EQ: `http://192.168.2.3/eqg-config.php`
- CamillaDSP: `http://192.168.2.3/cdsp-config.php`

## Next Steps

**Ready to proceed:**
1. Generate pink noise file on Pi
2. Set up measurement device (phone/Mac)
3. Play pink noise and record response
4. Analyze frequency graph
5. Configure Parametric EQ in moOde
6. Test and iterate
7. Optionally add CamillaDSP room corrections

**Then implement base filter architecture from WISSENSBASIS/134** to make Parametric EQ always active (even with PeppyMeter).
