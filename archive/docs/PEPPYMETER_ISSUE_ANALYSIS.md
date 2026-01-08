# PEPPYMETER ISSUE ANALYSIS

**Date:** 2025-12-04  
**Problem:** Only one meter showing top-left, bottom cut off, right side empty

---

## PROBLEM DESCRIPTION

- **Symptom:** Only ONE meter displayed
- **Position:** Top-left corner (not centered)
- **Issues:**
  - Bottom is cut off
  - Right side of screen is empty
  - Should show TWO meters (left and right) centered

---

## CONFIGURATION APPLIED

### **Main Config (`/opt/peppymeter/config.txt`):**
- width = 1280
- height = 400
- base.folder = /opt/peppymeter/1280x400
- current = gold

### **Meter Config (`/opt/peppymeter/1280x400/meters.txt`):**
- channels = 2 ✅
- left.origin.x = 320
- left.origin.y = 200
- right.origin.x = 960
- right.origin.y = 200
- meter.x = 0
- meter.y = 0

### **Window:**
- Size: 1280x400 ✅
- Position: 0,0 ✅

---

## POSSIBLE CAUSES

1. **Config Not Being Read:**
   - PeppyMeter might not be reading the config correctly
   - Resolution detection might be failing
   - Falling back to default/mono mode

2. **Rendering Issue:**
   - Only left meter being created despite channels=2
   - Both meters at same position (0,0)
   - Coordinate system offset

3. **X Server Connection:**
   - XIO errors in logs
   - Connection instability causing rendering issues

4. **Background Image:**
   - Background is 1280x400 (verified)
   - But content might be offset/scaled wrong

---

## FIXES APPLIED

1. ✅ Updated config.txt with explicit 1280x400
2. ✅ Updated meters.txt with channels=2 and correct positions
3. ✅ Updated wrapper script for better X connection
4. ✅ Window positioned at 0,0 with size 1280x400

---

## NEXT STEPS

1. Verify if both meters are now showing
2. Check if positioning is correct
3. If still wrong, investigate:
   - How PeppyMeter detects resolution
   - If config is actually being read
   - Coordinate system issues

---

**Status:** Configuration updated. Need to verify actual display.

