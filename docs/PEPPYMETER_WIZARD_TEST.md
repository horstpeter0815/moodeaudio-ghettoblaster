# 🧙 PeppyMeter + Wizard Test Plan

**Date:** 2025-01-12  
**Status:** ⏳ **PENDING TEST**

---

## 🎯 Test Objectives

1. Verify PeppyMeter display works during wizard measurements
2. Test PeppyMeter shows pink noise levels correctly
3. Verify PeppyMeter displays corrected audio after filter application
4. Test tap-to-switch functionality during wizard

---

## 📋 Pre-Test Checklist

### PeppyMeter Configuration
- [ ] PeppyMeter service is running
- [ ] Display shows audio meters
- [ ] Blue skin configured (if desired)
- [ ] Tap-to-switch to moOde UI works

### Wizard Access
- [ ] Web interface accessible
- [ ] Audio settings page loads
- [ ] "Run Wizard" button visible
- [ ] Microphone permissions granted (for browser)

### System Status
- [ ] Pi is running and accessible
- [ ] Audio chain is working
- [ ] CamillaDSP is active
- [ ] MPD is playing (for meter test)

---

## 🧪 Test Steps

### Test 1: PeppyMeter Status
```bash
# From Mac
bash ~/moodeaudio-cursor/scripts/wizard/TEST_PEPPYMETER_WIZARD.sh

# Or from Pi
~/moodeaudio-cursor/scripts/wizard/TEST_PEPPYMETER_WIZARD.sh
```

**Expected:**
- ✅ PeppyMeter service running
- ✅ Config file exists
- ✅ Display shows meters

### Test 2: Wizard Access
1. Open browser: `http://192.168.1.159/snd-config.php`
2. Navigate to Room Correction section
3. Click "Run Wizard"

**Expected:**
- ✅ Wizard modal opens
- ✅ Step 1 instructions visible
- ✅ PeppyMeter still showing meters

### Test 3: Ambient Noise Measurement
1. Click "Start Measurement" (Step 2)
2. Allow microphone access
3. Wait 5 seconds for ambient noise measurement

**Expected:**
- ✅ PeppyMeter shows ambient noise levels
- ✅ Measurement completes
- ✅ Step 3 becomes available

### Test 4: Pink Noise Measurement
1. Click "Start Pink Noise" (Step 3)
2. Watch PeppyMeter during measurement
3. Let measurement run (30-60 seconds recommended)

**Expected:**
- ✅ PeppyMeter shows pink noise levels
- ✅ Levels are consistent (not clipping)
- ✅ Measurement completes successfully
- ✅ Frequency response graph appears

### Test 5: Filter Application
1. Generate filter (Step 5)
2. Apply filter (Step 6)
3. Watch PeppyMeter after application

**Expected:**
- ✅ Filter applied successfully
- ✅ PeppyMeter shows corrected audio levels
- ✅ Levels match expected correction curve

### Test 6: Tap-to-Switch During Wizard
1. While wizard is running
2. Tap PeppyMeter display
3. Should switch to moOde UI
4. Tap again to return to PeppyMeter

**Expected:**
- ✅ Tap switches display correctly
- ✅ Wizard continues in background
- ✅ Can return to PeppyMeter view

---

## 🔍 Verification Commands

### Check PeppyMeter Service
```bash
ssh andre@192.168.1.159 'systemctl status peppymeter'
```

### Check PeppyMeter Config
```bash
ssh andre@192.168.1.159 'cat /etc/peppymeter/config.txt | grep -E "^meter =|^random.meter"'
```

### Check Display Status
```bash
ssh andre@192.168.1.159 'DISPLAY=:0 xrandr --query'
```

### Monitor PeppyMeter Logs
```bash
ssh andre@192.168.1.159 'journalctl -u peppymeter -f'
```

---

## ⚠️ Known Issues / Notes

### PeppyMeter Configuration
- Blue skin can be set with: `~/moodeaudio-cursor/scripts/wizard/set-peppymeter-blue.sh`
- Random meter switching can be disabled in config
- Service restart required after config changes

### Wizard Integration
- Wizard runs in browser (web interface)
- PeppyMeter runs independently (display service)
- Both should work simultaneously
- PeppyMeter shows audio levels regardless of wizard state

### Display Switching
- Tap PeppyMeter → moOde UI
- Tap moOde UI → PeppyMeter (if configured)
- Wizard continues in browser during display switch

---

## 📊 Test Results

**Date:** ___________  
**Tester:** ___________  
**Pi IP:** ___________  

### Test 1: PeppyMeter Status
- [ ] Pass
- [ ] Fail
- [ ] Notes: ___________

### Test 2: Wizard Access
- [ ] Pass
- [ ] Fail
- [ ] Notes: ___________

### Test 3: Ambient Noise
- [ ] Pass
- [ ] Fail
- [ ] Notes: ___________

### Test 4: Pink Noise
- [ ] Pass
- [ ] Fail
- [ ] Notes: ___________

### Test 5: Filter Application
- [ ] Pass
- [ ] Fail
- [ ] Notes: ___________

### Test 6: Tap-to-Switch
- [ ] Pass
- [ ] Fail
- [ ] Notes: ___________

---

## 🚀 Next Steps

After successful testing:
1. Document any issues found
2. Update wizard documentation if needed
3. Create fixes for any problems
4. Re-test after fixes

---

**Status:** ⏳ **READY FOR TESTING**  
**Last Updated:** 2025-01-12
