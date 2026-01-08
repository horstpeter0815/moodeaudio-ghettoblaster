# TOUCH ROTATION BUTTON

**Date:** 2025-12-04  
**Important:** WaveShare Display has hardware "Touch Rotation" button on the back!

---

## 🔘 HARDWARE BUTTON

**Location:** Back of the WaveShare 7.9" display  
**Function:** Changes touchscreen rotation at hardware level  
**Effect:** Touch coordinates are rotated before reaching software

---

## ⚠️ IMPORTANT

**When the button is pressed:**
- Hardware touchscreen rotation changes
- Software calibration matrix must match the new rotation
- Different button presses = different rotations
- Need to find correct matrix for current rotation

---

## 🔄 ROTATION CYCLES

The button typically cycles through rotations:
1. **0°** (normal)
2. **90°** (clockwise)
3. **180°** (upside down)
4. **270°** (counter-clockwise)

Each press changes to the next rotation.

---

## 🎯 SOLUTION

**Need to test different matrices:**
- `1 0 0 0 1 0 0 0 1` - 0° (identity)
- `0 1 0 -1 0 1 0 0 1` - 90° counter-clockwise
- `-1 0 1 0 -1 1 0 0 1` - 180°
- `0 -1 1 1 0 0 0 0 1` - 270° counter-clockwise

**Test each one until touch works correctly!**

---

## 📋 PROCEDURE

1. Press "Touch Rotation" button on display back
2. Test touchscreen
3. If wrong, try different calibration matrix
4. Repeat until correct
5. Save working matrix to `.xinitrc`

---

**Status: Testing matrices to match hardware rotation button setting!**

