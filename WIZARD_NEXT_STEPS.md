# 🎯 Wizard Deployment - Next Steps

**Status:** ✅ **Deployment Complete!**

---

## ✅ WHAT'S DONE

1. ✅ Step 2 fixed (ambient noise re-enabled)
2. ✅ Files deployed to SD card:
   - `/var/www/html/test-wizard/wizard-functions.js`
   - `/var/www/html/command/room-correction-wizard.php`
   - Python scripts (if they exist)

---

## 🚀 NEXT STEPS

### **Step 1: Eject SD Card** (30 seconds)

**Run this command:**
```bash
diskutil eject /dev/disk4
```

**Or:**
- Open Finder
- Right-click on SD card
- Click "Eject"

---

### **Step 2: Boot Raspberry Pi** (2-3 minutes)

1. Insert SD card into Raspberry Pi
2. Power on Raspberry Pi
3. Wait for moOde to start
   - LED will blink during boot
   - LED stops blinking when ready
4. Find IP address:
   - Check router admin page
   - Or check screen if connected
   - Or use: `arp -a | grep raspberry`

---

### **Step 3: Access moOde Web Interface** (1 minute)

1. Open browser
2. Go to: `http://<PI_IP>`
   - Example: `http://10.10.11.39`
   - Or: `http://moode.local` (if mDNS works)

---

### **Step 4: Test Wizard** (5-10 minutes)

1. **Navigate to Audio page:**
   - Click "Audio" in moOde menu
   - Scroll down to "Room Correction" section

2. **Click "Run Wizard" button:**
   - Modal should open
   - Step 1 should be visible with instructions

3. **Test Step 1:**
   - ✅ Modal opens
   - ✅ Step 1 displays
   - ✅ "Start Measurement" button visible

4. **Test Step 2 (Ambient Noise):**
   - Click "Start Measurement"
   - Grant microphone permission if asked
   - Wait 5 seconds (stay quiet)
   - Graph should show ambient noise
   - Should auto-advance to Step 3

5. **Test Step 3 (Pink Noise):**
   - Pink noise should start playing
   - Grant microphone permission if asked
   - Graph should show:
     - Orange dashed line: Ambient noise
     - Blue solid line: Corrected response
   - Let it run for 10-15 seconds

6. **Test Step 4 (Upload - Optional):**
   - Can skip or upload measurement file

7. **Test Step 5 (Generate Filter):**
   - Click "Generate Filter"
   - Should process and generate PEQ

8. **Test Step 6 (Apply Filter):**
   - Filter should be applied
   - Pink noise should sound different (flatter response)

---

## ❓ IF SOMETHING DOESN'T WORK

### **Problem: Modal doesn't open**
- **Check:** Browser console (F12) for errors
- **Check:** Are you on the Audio page?
- **Tell me:** What error message you see

### **Problem: Step 2 doesn't work**
- **Check:** Microphone permissions in browser
- **Check:** Are you in a quiet environment?
- **Tell me:** What happens when you click "Start Measurement"

### **Problem: Pink noise doesn't play**
- **Check:** Audio output is connected
- **Check:** moOde audio settings
- **Tell me:** Does the graph show anything?

### **Problem: Filter doesn't generate**
- **Check:** Browser console (F12) for errors
- **Check:** PHP backend logs (if you can SSH)
- **Tell me:** What error message appears

---

## 📋 TESTING CHECKLIST

After booting, test these:

- [ ] moOde web interface loads
- [ ] Audio page accessible
- [ ] "Run Wizard" button visible
- [ ] Modal opens when clicking button
- [ ] Step 1 displays correctly
- [ ] Step 2 measures ambient noise (5 seconds)
- [ ] Step 3 plays pink noise
- [ ] Graph displays correctly
- [ ] Filter generates successfully
- [ ] Filter applies successfully

---

## 🎯 SUMMARY

**What's done:**
- ✅ Wizard code fixed
- ✅ Files deployed to SD card

**What you do now:**
1. Eject SD card
2. Boot Raspberry Pi
3. Test wizard

**After testing:**
- Tell me what works
- Tell me what doesn't work
- I'll help fix any issues

---

**Ready to test! Let me know how it goes!** 🚀

