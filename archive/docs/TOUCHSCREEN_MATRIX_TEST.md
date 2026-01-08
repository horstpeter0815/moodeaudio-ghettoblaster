# TOUCHSCREEN MATRIX TEST

**Date:** 2025-12-04  
**Issue:** Touchscreen hardware works, but touch input not working in X

---

## 🔍 PROBLEM ANALYSIS

1. **Hardware:** ✅ Working (raw events confirmed)
2. **Device:** ✅ Detected (ID=6)
3. **Send Events:** ✅ Enabled
4. **X Input:** ❓ Events might not reach X or matrix is wrong

---

## 🎯 POSSIBLE CAUSES

### **1. Matrix Mismatch:**
- Display: `display_rotate=1` (90° clockwise)
- Current Matrix: `0 -1 1 1 0 0 0 0 1` (270° counter-clockwise)
- **Mismatch possible!**

### **2. Matrix Options to Test:**

| Matrix | Rotation | Description |
|--------|----------|-------------|
| `0 1 0 -1 0 1 0 0 1` | 90° CCW | For display_rotate=1 |
| `0 -1 1 1 0 0 0 0 1` | 270° CCW | moOde default (current) |
| `-1 0 1 0 -1 1 0 0 1` | 180° | Both axes inverted |
| `1 0 0 0 1 0 0 0 1` | 0° | Identity (no rotation) |

---

## 📋 TEST PROCEDURE

1. Test each matrix
2. Touch screen after each change
3. Check if cursor moves correctly
4. Identify working matrix
5. Save to `.xinitrc`

---

**Status: Testing different matrices to find correct calibration!**

