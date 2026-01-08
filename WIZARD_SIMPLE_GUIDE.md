# 🧙 Room Correction Wizard - Simple Guide

**For: Non-Technical User**  
**Status: Ready to Deploy**

---

## ✅ WHAT I JUST DID

1. ✅ **Fixed Step 2** - Re-enabled ambient noise measurement
2. ✅ **Created deployment script** - `deploy-wizard-to-sd.sh`
3. ✅ **Created action plan** - `WIZARD_ACTION_PLAN.md`

---

## 🚀 WHAT YOU NEED TO DO NOW

### **Step 1: Deploy Wizard to SD Card** (2 minutes)

**Run this command:**
```bash
sudo ./deploy-wizard-to-sd.sh
```

**What it does:**
- Copies wizard files to SD card
- Sets correct permissions
- Shows you what was copied

**You'll see:**
```
=== Room Correction Wizard Deployment ===
✅ SD card rootfs found at: /Volumes/rootfs
📁 Creating directories...
📋 Copying wizard files...
  → Copying wizard-functions.js...
  ✅ wizard-functions.js copied
  ...
=== Deployment Complete ===
```

---

### **Step 2: Eject SD Card** (30 seconds)

**Run this command:**
```bash
diskutil eject /dev/disk4
```

**Or:**
- Open Finder
- Right-click on SD card
- Click "Eject"

---

### **Step 3: Boot Raspberry Pi** (2 minutes)

1. Insert SD card into Raspberry Pi
2. Power on Raspberry Pi
3. Wait for moOde to start (LED will stop blinking)
4. Note the IP address (shown on screen or check router)

---

### **Step 4: Test Wizard** (5 minutes)

1. **Open moOde web interface:**
   - Open browser
   - Go to: `http://<PI_IP>`
   - Example: `http://10.10.11.39`

2. **Navigate to Audio page:**
   - Click "Audio" in menu
   - Scroll to "Room Correction" section

3. **Click "Run Wizard" button:**
   - Modal should open
   - Step 1 should be visible

4. **Test each step:**
   - **Step 1:** Click "Start Measurement"
   - **Step 2:** Wait 5 seconds (ambient noise measurement)
   - **Step 3:** Pink noise plays, graph shows
   - **Step 4:** (Optional) Upload measurement
   - **Step 5:** Generate filter
   - **Step 6:** Apply filter

---

## ❓ IF SOMETHING DOESN'T WORK

**Problem: Modal doesn't open**
- Check browser console (F12) for errors
- Make sure you're on Audio page

**Problem: Step 2 doesn't work**
- Check microphone permissions in browser
- Make sure you're in quiet environment

**Problem: Pink noise doesn't play**
- Check audio output is connected
- Check moOde audio settings

**Problem: Filter doesn't generate**
- Check browser console for errors
- Check PHP backend logs

**Just tell me what happened and I'll help fix it!**

---

## 📋 SUMMARY

**What I did:**
- ✅ Fixed Step 2 (ambient noise)
- ✅ Created deployment script

**What you do:**
1. Run: `sudo ./deploy-wizard-to-sd.sh`
2. Eject SD card
3. Boot Pi
4. Test wizard

**That's it! Simple!**

---

**Ready? Run the deployment script now!**

