# 🎵 Room Correction Wizard - Quick Access

## Where to Find It

**moOde Web UI → Audio Settings → Room Correction → "Run Wizard" Button**

**Direct Path:**
1. Open Safari: http://moode.local
2. Click **"Audio"** in the menu
3. Scroll to **"Room Correction"** section
4. Click **"Run Wizard"** button (blue button next to preset dropdown)

## Quick Start for Real Measurement

1. **Click "Run Wizard"** button
2. **Step 1:** Click "Start Measurement"
3. **Step 2:** Allow microphone access when Safari asks
4. **Step 3:** Wait 5 seconds (ambient noise measurement)
5. **Step 4:** Pink noise starts playing
   - **IMPORTANT:** Set volume to comfortable level BEFORE this step!
   - Position iPhone at listening position
   - Measurement runs continuously (2-3 seconds to stabilize)
6. **Step 5:** Click "Apply Correction" when satisfied
7. **Step 6:** Review graph, click "Generate Filter"
8. **Step 7:** Apply filter and optimize volume

## iPhone Microphone Setup (REQUIRED!)

**Before starting wizard:**
1. iPhone Settings → Safari → Microphone
2. Find: `192.168.3.8` (or your Pi's IP)
3. Set to **"Allow"**

**During wizard:**
- Safari will also ask for permission
- Click **"Allow"** when prompted

## Volume Setting (CRITICAL!)

⚠️ **Set volume BEFORE Step 3!**

- Pink noise plays at current system volume
- Set to comfortable listening level
- Don't change during measurement

## What You'll See

- **Real-time frequency response graph**
- **Before/after correction comparison**
- **Volume optimization step** (NEW!)

---

**Ready?** Go to Audio Settings → Room Correction → **Run Wizard** 🎵
