# 🧪 Room Correction Wizard Test Guide

This guide helps you test the Room Correction Wizard that you've created for sound adjustment.

## 📋 Prerequisites

1. **moOde Audio System Running**: Ensure your Raspberry Pi with moOde is running and accessible
2. **iPhone Connected**: Your iPhone should be connected (certificate installed as you mentioned)
3. **Network Access**: Access to the moOde web interface
4. **Audio Setup**: Speakers/headphones connected and working

## 🔍 Pre-Test Verification

Before testing, verify these components are in place:

### 1. Access the Audio Configuration Page

1. Open moOde web interface in your browser
2. Navigate to **Audio** page (usually accessible via menu or direct URL: `http://<pi-ip>/snd-config.php`)
3. Look for the **Room Correction** section
4. You should see a **"Run Wizard"** button

### 2. Verify Required Scripts

The wizard requires these Python scripts to be installed:
- `/usr/local/bin/generate-camilladsp-eq.py` - Generates CamillaDSP EQ config
- `/usr/local/bin/analyze-measurement.py` - Analyzes measurement files (if using file upload)
- `/usr/local/bin/import-roon-eq-filter.py` - Imports Room EQ filters

You can verify these exist by SSH'ing into the Pi:
```bash
ls -la /usr/local/bin/*.py | grep -E "(generate-camilladsp-eq|analyze-measurement|import-roon-eq-filter)"
```

## 🧪 Test Steps

### Test 1: Access Wizard Modal

1. **Navigate to Audio Config Page**
   - Go to `http://<pi-ip>/snd-config.php`
   - Scroll to "Room Correction" section

2. **Click "Run Wizard" Button**
   - Expected: Modal dialog opens with "Room Correction Wizard" title
   - Should show Step 1: Vorbereitung (Preparation)

3. **Verify Step 1 Content**
   - Should display instructions in German/English
   - Should have a "Start Measurement" button

**✅ Pass Criteria**: Modal opens, Step 1 is visible, button is clickable

---

### Test 2: Ambient Noise Measurement

1. **Click "Start Measurement" Button**
   - Expected: Wizard advances to Step 2
   - Should show "Requesting microphone access for ambient noise measurement..."

2. **Grant Microphone Access**
   - Browser should request microphone permission (if first time)
   - Click "Allow" to grant access

3. **Measure Ambient Noise**
   - UI should show: "✅ Measuring ambient noise..."
   - Canvas graph should appear showing ambient noise level
   - Graph should update in real-time
   - Timer should count down from 5 seconds
   - **Important**: Stay quiet during this measurement - no music or test tones should be playing

4. **Verify Noise Measurement**
   - Graph should show the ambient noise curve (orange dashed line)
   - Measurement should complete automatically after 5 seconds
   - "Continue to Pink Noise Measurement" button should appear

**✅ Pass Criteria**: Microphone access granted, ambient noise measured, graph displays correctly

---

### Test 3: Start Pink Noise Playback

1. **Continue to Pink Noise Measurement**
   - Click "Continue to Pink Noise Measurement" button (or wait for auto-advance)
   - Expected: Wizard advances to Step 3
   - Should show "Starting pink noise playback..." message

2. **Verify Pink Noise Starts**
   - Listen: You should hear pink noise from speakers
   - Check UI: Status should change to "Pink noise started. Requesting microphone access..."

3. **Check Backend**
   - SSH into Pi: `ps aux | grep speaker-test`
   - Should see a `speaker-test -t pink` process running

**✅ Pass Criteria**: Pink noise plays, UI updates, process is running

---

### Test 4: iPhone Microphone Access (with Pink Noise)

1. **Browser Requests Microphone**
   - Expected: Browser shows permission dialog (if first time)
   - Click "Allow" to grant microphone access

2. **Measurement Starts**
   - UI should show: "✅ Measurement active"
   - Canvas graph should appear showing frequency response
   - Graph should update in real-time (every 100ms)

3. **Verify Continuous Measurement**
   - Graph should show frequency response curves
   - **Two curves should be visible:**
     - Orange dashed line: Ambient noise (measured in Step 2)
     - Blue solid line: Corrected response (pink noise minus ambient noise)
   - Data should update continuously (rolling 2-3 second average)
   - X-axis: Frequency (20 Hz - 20 kHz, logarithmic)
   - Y-axis: Amplitude in dB
   - Legend should show both curves

4. **Verify Noise Subtraction**
   - The blue curve should show the frequency response with ambient noise already subtracted
   - This gives a cleaner measurement by removing background noise

**✅ Pass Criteria**: Microphone access granted, graph appears with both curves, measurements visible, noise properly subtracted

---

### Test 5: Apply Correction

1. **Wait for Measurement to Stabilize**
   - Let measurement run for 10-15 seconds
   - Graph should show a stable frequency response

2. **Click "Apply Correction" Button**
   - Expected: Status changes to "Processing frequency response..."
   - Backend processes the measurement data

3. **PEQ Generation**
   - Wizard generates parametric EQ configuration
   - Creates a CamillaDSP config file

4. **Filter Applied**
   - Success message: "Room correction applied successfully!"
   - Pink noise continues playing (you should hear the difference)

5. **Verify Filter Applied**
   - Check CamillaDSP status (if available in UI)
   - Listen: Pink noise should sound different (flatter response)

**✅ Pass Criteria**: Correction applied, success message shown, audio changes audible

---

### Test 6: Stop Measurement

1. **Click "Stop Measurement" Button**
   - Expected: Pink noise stops playing
   - UI should show: "Measurement stopped"
   - Microphone access should be released

2. **Verify Process Stopped**
   - SSH: `ps aux | grep speaker-test` should show no pink noise process
   - Browser console: No errors

**✅ Pass Criteria**: Noise stops, processes cleaned up, no errors

---

### Test 7: Close Wizard

1. **Click "Close" Button or X**
   - Expected: Modal closes
   - All resources cleaned up (pink noise stops, microphone released)

2. **Re-open Wizard**
   - Click "Run Wizard" again
   - Should start fresh at Step 1

**✅ Pass Criteria**: Modal closes cleanly, can reopen without issues

---

## 🐛 Troubleshooting

### Issue: Modal doesn't open
- **Check**: Browser console for JavaScript errors
- **Fix**: Ensure jQuery and Bootstrap are loaded
- **Verify**: Modal HTML exists in page source

### Issue: Pink noise doesn't play
- **Check**: Audio output is configured correctly
- **Verify**: `speaker-test` command works manually: `speaker-test -t pink -c 2 -r 44100`
- **Check**: Audio device permissions

### Issue: Microphone access denied
- **Check**: Browser permissions (Safari/Chrome settings)
- **Note**: Requires HTTPS or localhost for microphone access
- **Fix**: Grant microphone permission in browser settings

### Issue: Graph doesn't show data
- **Check**: Browser console for Web Audio API errors
- **Verify**: Microphone is actually recording (check system sound settings)
- **Note**: iPhone microphone should work in Safari/Chrome

### Issue: "Apply Correction" fails
- **Check**: Backend logs: `tail -f /var/log/moode.log`
- **Verify**: Python scripts are executable: `chmod +x /usr/local/bin/*.py`
- **Check**: Required Python packages: `numpy`, `scipy`, `soundfile`

### Issue: Filter doesn't apply
- **Check**: CamillaDSP is enabled and running
- **Verify**: Config file was created: `ls -la /usr/share/camilladsp/configs/room_correction_*.yml`
- **Check**: CamillaDSP logs for errors

---

## 📊 Expected Behavior Summary

| Step | Action | Expected Result |
|------|--------|----------------|
| 1 | Click "Run Wizard" | Modal opens, Step 1 visible |
| 2 | Click "Start Measurement" | Step 2 shows (ambient noise) |
| 3 | Grant microphone access | Ambient noise graph appears |
| 4 | Wait 5 seconds (be quiet) | Ambient noise measured, auto-advances |
| 5 | Continue to Step 3 | Pink noise starts, Step 3 shows |
| 6 | Grant microphone access again | Graph appears with both curves |
| 7 | Wait 10-15 seconds | Graph stabilizes (noise subtracted) |
| 8 | Click "Apply Correction" | Processing message, then success |
| 9 | Listen | Pink noise should sound different (flatter) |
| 10 | Click "Stop Measurement" | Noise stops, cleanup |
| 11 | Close modal | Everything cleaned up |

---

## ✅ Success Criteria

The wizard test is successful if:
1. ✅ Modal opens and closes properly
2. ✅ Ambient noise can be measured (Step 2) - no pink noise playing
3. ✅ Ambient noise graph displays correctly
4. ✅ Pink noise plays when main measurement starts (Step 3)
5. ✅ iPhone microphone access works for both measurements
6. ✅ Real-time frequency response graph displays both curves (noise and corrected)
7. ✅ Ambient noise is properly subtracted from the measurement
8. ✅ Correction can be applied successfully
9. ✅ Audio changes are audible after applying correction
10. ✅ All processes clean up properly when stopped/closed
11. ✅ No errors in browser console or system logs

---

## 📝 Notes

- **iPhone Certificate**: Since you mentioned the certificate is installed, ensure you're accessing via HTTPS if needed for microphone access
- **Browser Compatibility**: Tested on Safari (iPhone) and Chrome/Edge (desktop)
- **Performance**: Real-time measurement uses rolling average for stability
- **Measurement Duration**: 
  - Ambient noise: 5 seconds (automatic)
  - Pink noise measurement: Let run for at least 10-15 seconds for best results
- **Ambient Noise**: Important to stay quiet during ambient noise measurement. This measurement is automatically subtracted from the pink noise measurement to give cleaner results.

---

**Ready to test? Start with Test 1 and work through each step!**

