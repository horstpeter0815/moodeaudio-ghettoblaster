# 🎯 Room Correction Wizard - Action Plan

**Date:** 2025-01-20  
**Role:** Senior Project Manager - Proactive Guidance  
**Status:** Ready to Execute

---

## 📋 EXECUTIVE SUMMARY

**Current Situation:**
- ✅ moOde Audio is running with everything
- ✅ Wizard code is complete and functional
- ⚠️ Step 2 (Ambient Noise) is temporarily disabled
- 🎯 **Goal:** Deploy and test wizard on real moOde system

**What We'll Do:**
1. Fix Step 2 (re-enable ambient noise measurement)
2. Deploy wizard files to moOde system
3. Test complete wizard workflow
4. Fix any issues found

---

## 🚀 STEP-BY-STEP ACTION PLAN

### **PHASE 1: Fix Wizard Code (5 minutes)**

**Task 1.1: Re-enable Step 2 (Ambient Noise Measurement)**

**File:** `test-wizard/wizard-functions.js`  
**Line:** ~174-183

**Current Code (WRONG - skips Step 2):**
```javascript
if (wizardStep === 2) {
    wizardLog('wizardStep is 2 - skipping to Step 3', 'info');
    // TEMPORARILY DISABLED: Skip ambient noise measurement
    wizardStep = 3;
    startContinuousMeasurement();
}
```

**Fix (CORRECT - enables Step 2):**
```javascript
if (wizardStep === 2) {
    wizardLog('wizardStep is 2 - starting ambient noise measurement', 'info');
    showWizardStep(2);
    startNoiseMeasurement(); // Re-enable ambient noise measurement
}
```

**Action:** I will fix this now.

---

### **PHASE 2: Deploy to moOde System (10 minutes)**

**Task 2.1: Copy Wizard Files to SD Card**

**Files to Copy:**
1. `test-wizard/wizard-functions.js` → `/Volumes/rootfs/var/www/html/test-wizard/wizard-functions.js`
2. `moode-source/www/command/room-correction-wizard.php` → `/Volumes/rootfs/var/www/html/command/room-correction-wizard.php`
3. `moode-source/www/templates/snd-config.html` → `/Volumes/rootfs/var/www/html/templates/snd-config.html`

**Action:** I will create a deployment script.

---

**Task 2.2: Verify Python Scripts Are Installed**

**Check if these exist on SD card:**
- `/Volumes/rootfs/usr/local/bin/generate-camilladsp-eq.py`
- `/Volumes/rootfs/usr/local/bin/analyze-measurement.py`

**Action:** I will verify these exist.

---

### **PHASE 3: Test Wizard (15 minutes)**

**Task 3.1: Boot Pi and Access moOde**

1. Eject SD card safely
2. Boot Raspberry Pi
3. Wait for moOde to start
4. Access moOde web interface: `http://<PI_IP>`

**Action:** You do this step.

---

**Task 3.2: Test Wizard Steps**

**Test Sequence:**
1. **Step 1:** Click "Run Wizard" → Modal opens ✅
2. **Step 2:** Click "Start Measurement" → Ambient noise measures for 5 seconds ✅
3. **Step 3:** Continue → Pink noise plays, graph shows ✅
4. **Step 4:** Upload measurement (optional) ✅
5. **Step 5:** Generate filter ✅
6. **Step 6:** Apply filter ✅

**Action:** You test, I help troubleshoot.

---

### **PHASE 4: Fix Issues (as needed)**

**If something doesn't work:**
- I'll analyze the problem
- I'll provide fix
- We'll test again

---

## 📁 FILE LOCATIONS

### **On Your Mac (Development):**
- `test-wizard/wizard-functions.js` - Wizard JavaScript functions
- `moode-source/www/command/room-correction-wizard.php` - Backend PHP
- `moode-source/www/templates/snd-config.html` - Wizard HTML

### **On SD Card (moOde System):**
- `/Volumes/rootfs/var/www/html/test-wizard/wizard-functions.js`
- `/Volumes/rootfs/var/www/html/command/room-correction-wizard.php`
- `/Volumes/rootfs/var/www/html/templates/snd-config.html`

---

## ✅ SUCCESS CRITERIA

**Wizard is working when:**
1. ✅ Modal opens from "Run Wizard" button
2. ✅ Step 1 displays correctly
3. ✅ Step 2 measures ambient noise (5 seconds, graph shows)
4. ✅ Step 3 plays pink noise and measures (graph shows both curves)
5. ✅ Step 5 generates filter successfully
6. ✅ Step 6 applies filter and audio changes

---

## 🎯 IMMEDIATE NEXT STEPS

**I will now:**
1. ✅ Fix Step 2 code (re-enable ambient noise)
2. ✅ Create deployment script
3. ✅ Verify files are ready
4. ✅ Guide you through testing

**You will:**
1. Run deployment script (I'll tell you how)
2. Boot Pi and test wizard
3. Report any issues

---

**Let's start! I'm fixing Step 2 now...**

