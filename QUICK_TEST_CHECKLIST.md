# 🧪 Quick Test Checklist - Room Correction Wizard

## ✅ Pre-Test Setup

- [ ] moOde system is running and accessible
- [ ] iPhone is connected (certificate installed)
- [ ] Browser with microphone permissions ready
- [ ] Audio output connected (speakers/headphones)
- [ ] Open browser console (F12 or Cmd+Option+I) to see any errors

---

## 🧪 Test Flow

### Step 1: Access Wizard
1. [ ] Navigate to: `http://<pi-ip>/snd-config.php`
2. [ ] Find "Room Correction" section
3. [ ] Click **"Run Wizard"** button
4. [ ] ✅ Modal should open
5. [ ] ✅ Step 1 should be visible (Vorbereitung/Preparation)

### Step 2: Ambient Noise Measurement
1. [ ] Click **"Start Measurement"** button
2. [ ] ✅ Should advance to Step 2
3. [ ] ✅ Browser should request microphone permission (if first time)
4. [ ] Grant microphone access: **"Allow"**
5. [ ] ✅ Should show "Measuring ambient noise..."
6. [ ] ✅ Graph should appear with orange curve
7. [ ] ✅ Timer should countdown from 5 seconds
8. [ ] **Stay quiet** during this measurement (no music/test tones)
9. [ ] ✅ After 5 seconds, should auto-advance to Step 3

### Step 3: Pink Noise Measurement
1. [ ] ✅ Should advance to Step 3 automatically
2. [ ] ✅ Should show "Starting pink noise playback..."
3. [ ] ✅ Should hear pink noise from speakers
4. [ ] ✅ Should request microphone access again
5. [ ] Grant microphone access: **"Allow"**
6. [ ] ✅ Graph should appear with TWO curves:
   - Orange dashed line (ambient noise)
   - Blue solid line (corrected response)
7. [ ] ✅ Graph should update in real-time
8. [ ] ✅ Legend should show both curves

### Step 4: Apply Correction
1. [ ] Wait 10-15 seconds for measurement to stabilize
2. [ ] ✅ Graph should show stable frequency response
3. [ ] Click **"Apply Correction"** button
4. [ ] ✅ Should show "Processing frequency response..."
5. [ ] ✅ Should show success message: "Room correction applied successfully!"
6. [ ] ✅ Pink noise should continue playing
7. [ ] ✅ You should hear the difference (flatter response)

### Step 5: Stop & Cleanup
1. [ ] Click **"Stop Measurement"** button
2. [ ] ✅ Pink noise should stop
3. [ ] ✅ Should show "Measurement stopped"
4. [ ] Click **"Close"** button or X
5. [ ] ✅ Modal should close
6. [ ] ✅ All resources cleaned up

---

## 🐛 Common Issues Checklist

### Modal doesn't open
- [ ] Check browser console for JavaScript errors
- [ ] Verify jQuery/Bootstrap are loaded
- [ ] Try refreshing the page

### Microphone access denied
- [ ] Check browser permissions (Settings → Privacy → Microphone)
- [ ] Try HTTPS instead of HTTP (if certificate installed)
- [ ] Safari: Preferences → Websites → Microphone → Allow
- [ ] Chrome: Settings → Privacy → Site Settings → Microphone

### Pink noise doesn't play
- [ ] Check audio output is configured
- [ ] SSH into Pi: `ps aux | grep speaker-test` should show process
- [ ] Try manually: `speaker-test -t pink -c 2 -r 44100 -D plughw:0,0`

### Graph doesn't show data
- [ ] Check browser console for Web Audio API errors
- [ ] Verify microphone is actually recording (check system settings)
- [ ] Try refreshing the page and starting again

### "Apply Correction" fails
- [ ] Check browser console for errors
- [ ] SSH into Pi: `tail -f /var/log/moode.log` for backend errors
- [ ] Verify Python scripts exist: `ls -la /usr/local/bin/*.py`
- [ ] Check Python packages: `python3 -c "import numpy, scipy, soundfile"`

### Filter doesn't apply
- [ ] Check CamillaDSP is enabled in moOde settings
- [ ] SSH: `ls -la /usr/share/camilladsp/configs/room_correction_*.yml`
- [ ] Check CamillaDSP logs: `journalctl -u camilladsp -f`

---

## 📊 Expected Console Output (Browser)

When working correctly, you should see in browser console:
```
✅ No errors
✅ "Ambient noise measured: {...}" log message
✅ No Web Audio API errors
✅ AJAX requests succeed (status 200)
```

---

## 📊 Expected Console Output (SSH)

SSH into Pi and check logs:
```bash
# Check if pink noise process is running (during Step 3)
ps aux | grep speaker-test

# Check moOde worker log for wizard messages
tail -f /var/log/moode.log | grep -i "wizard\|room correction"

# Check for any errors
journalctl -xe | grep -i "error\|wizard"
```

---

## ✅ Success Criteria

The test is successful if:
- [x] Modal opens and closes properly
- [x] Ambient noise is measured (Step 2)
- [x] Pink noise plays (Step 3)
- [x] Graph shows both curves (noise + corrected)
- [x] Correction can be applied
- [x] Audio changes are audible
- [x] All processes clean up
- [x] No errors in console/logs

---

## 🚨 If Issues Found

1. **Document the issue**: What step failed? What error message?
2. **Check console/logs**: Copy any error messages
3. **Try again**: Sometimes a refresh helps
4. **Check prerequisites**: Verify all scripts and permissions

---

**Ready to test! Start with Step 1 and work through each step systematically.**

