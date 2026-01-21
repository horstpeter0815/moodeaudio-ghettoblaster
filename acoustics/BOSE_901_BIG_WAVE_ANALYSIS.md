# Bose 901 Drivers for Big Wave System - Analysis

**Date:** 2026-01-19  
**Purpose:** Evaluate Bose 901 4.5" drivers for scaled-up Big Wave horn system  
**Source:** Measured T-S parameters + frequency response

---

## 📊 BOSE 901 DRIVER SPECIFICATIONS

### Physical & Electrical:
```
Driver Size:        4.5" (11.4 cm)
Nominal Impedance:  8 Ω
CRITICAL: Min impedance: 0.8 Ω @ 400-500 Hz ⚠️
Type:               Full-range with Helical Voice Coil
Quantity:           9 drivers per 901 cabinet
```

### Measured Parameters (from LMS data):

**Impedance Curve:**
```
20 Hz:     1.5 Ω
90-100 Hz: 4.3 Ω  ← Resonance peak (Fs ≈ 95 Hz)
400-500 Hz: 0.8 Ω  ← CRITICAL: Minimum!
20 kHz:    8.5 Ω
```

**Frequency Response:**
```
20 Hz:  80 dBSPL
50 Hz:  75 dBSPL  ← Dip (below resonance)
100 Hz: 92 dBSPL  ← Peak (at resonance!)
200 Hz-5 kHz: 85-95 dBSPL (stable)
20 kHz: 88 dBSPL
```

**Inferred Thiele-Small Parameters:**

From impedance curve, we can estimate:
```
Fs (Resonance frequency):  ~95 Hz
Qts (Total Q):            ~1.2-1.5 (moderate damping)
Re (DC resistance):       ~6-7 Ω
```

---

## 🔬 BIG WAVE HORN SUITABILITY ANALYSIS

### 1. Driver Size Comparison

**Current Bose Wave:**
- Driver: 10 cm (4")
- Path: 3.98 m
- Cutoff: 21.5 Hz
- Resonance: 80 Hz

**Bose 901 Drivers:**
- Driver: 11.4 cm (4.5")
- Bigger than Bose Wave! ✓
- Should work for similar application

**Verdict:** ✅ Size is good! Slightly larger = better bass potential

---

### 2. Resonance Frequency (Fs) Analysis

**Bose 901 Fs:** ~95 Hz (from impedance peak)

**Horn theory:** Optimal when `Fs ≈ f_resonance` (horn resonance)

**For Big Wave (scaled 2×):**
```
Desired resonance: ~40-50 Hz (lower than Bose Wave's 80 Hz)
Driver Fs: 95 Hz

Problem: Driver Fs is HIGHER than desired horn resonance!
```

**Impact:**
- Below Fs (< 95 Hz): Driver has high mechanical impedance
- Horn below driver Fs: Less efficient, needs more excursion
- Not ideal for deep bass extension

**Verdict:** ⚠️ Fs is too high for deep bass horn (40-60 Hz range)

---

### 3. Impedance Issues - CRITICAL!

**Measured minimum:** **0.8 Ω @ 400-500 Hz**

**This is EXTREMELY LOW!**

**For horn system using multiple drivers:**
```
Series connection (4 drivers):
Total Z = 4 × 0.8 Ω = 3.2 Ω @ 400 Hz (still very low!)

Parallel connection (not recommended):
Total Z = 0.8 Ω / 4 = 0.2 Ω (IMPOSSIBLE for most amps!)
```

**Amplifier requirements:**
- Must handle 0.8 Ω minimum
- Requires high-current amplifier
- Risk of amp overheating/protection

**Comparison with current system:**
```
Bose Wave drivers: 3.5 Ω (already below HiFiBerry minimum!)
Bose 901 drivers:  0.8 Ω (MUCH WORSE!)
```

**Verdict:** ❌ MAJOR PROBLEM - Impedance too low for most amps!

---

### 4. Frequency Response for Horn Use

**Measured response shows:**
```
50 Hz:  75 dBSPL ← Dip (driver struggles below Fs)
100 Hz: 92 dBSPL ← Peak (driver happy at Fs!)
```

**For back-loaded horn:**
- Horn boost: +6 to +9 dB
- But only above cutoff frequency!

**If using 5m path (scaled 2× from Bose Wave):**
```
Cutoff: f_c = 343 / (4 × 5) = 17.2 Hz
Peak efficiency: ~68 Hz (4× cutoff)

Problem: Driver Fs = 95 Hz > 68 Hz
Driver is still "stiff" at horn's peak efficiency!
```

**Verdict:** ⚠️ Fs mismatch limits deep bass performance

---

### 5. Power Handling

**Bose 901 specifications:**
```
Recommended power: 10-450W RMS
8 drivers rear in 901: Share power
```

**Each driver capacity:** ~50W continuous (estimate)

**For Big Wave:**
```
Using 4 drivers in series: 4 × 50W = 200W handling
Using 2 drivers: 2 × 50W = 100W handling
```

**Verdict:** ✅ Power handling is EXCELLENT!

---

## 🎯 OVERALL SUITABILITY ASSESSMENT

### ✅ PROS:
1. **Power handling:** Excellent (50W+ per driver)
2. **Size:** Good (11.4 cm, bigger than current)
3. **Build quality:** Helical voice coil, proven design
4. **Availability:** You already have them!
5. **Full-range capable:** Works up to 20 kHz

### ❌ CONS:
1. **Impedance:** 0.8 Ω minimum is VERY problematic
2. **Fs too high:** 95 Hz is too high for deep bass horn
3. **Below-Fs rolloff:** Driver struggles below 50 Hz
4. **Amplifier stress:** Requires special high-current amp

---

## 📐 HORN CALCULATIONS WITH BOSE 901

### Scenario: 4× Drivers in Back-Loaded Horn

**Optimal horn parameters for Fs = 95 Hz:**

**Path length:**
```
For f_c = Fs/4 = 24 Hz (quarter-wave)
L = c / (4 × f_c) = 343 / (4 × 24) = 3.57 m

For peak @ Fs = 95 Hz:
L = c / (4 × Fs/4) = 343 / (4 × 24) ≈ 3.6 m
```

**Entry area:**
```
Driver area: π × (5.7 cm)² = 102 cm² per driver
4 drivers: 4 × 102 = 408 cm²
Entry port: ~20 × 20 cm (optimize for impedance matching)
```

**Expansion ratio:**
```
For good horn loading: 8:1 to 12:1
Entry: 400 cm²
Exit: 3200-4800 cm² (56-69 cm × 56-69 cm)
```

**Resonance prediction:**
```
f_res ≈ 4 × f_c = 4 × 24 = 96 Hz (matches Fs! ✓)
```

**Expected response:**
- Below 50 Hz: Poor (driver Fs too high)
- 50-95 Hz: Building efficiency
- 95 Hz: PEAK (+9 dB boost from resonance!)
- 100-300 Hz: Excellent (horn + driver alignment)
- Above 300 Hz: Phase issues (folded path)

---

## 💡 RECOMMENDATIONS

### Option 1: Use for Mid-Bass (50-300 Hz) - BEST!

**Why:** Fs = 95 Hz is PERFECT for mid-bass horn!

**Configuration:**
```
Frequency range: 50-300 Hz (mid-bass)
Crossover: 50 Hz highpass, 300 Hz lowpass
Horn path: 3.5-4 m (optimized for 95 Hz resonance)
Drivers: 4× in series = 3.2 Ω @ 400 Hz (marginal but workable)
DSP: +9 dB boost @ 95 Hz (exploit resonance!)
```

**Add subwoofer for deep bass:**
```
< 50 Hz: Separate subwoofer (dedicated bass driver with lower Fs)
50-300 Hz: Bose 901 horn system
> 300 Hz: Direct radiator (tweeter)
```

**Verdict:** ⭐⭐⭐⭐ EXCELLENT for mid-bass horn!

---

### Option 2: Use for Upper Bass/Midrange (100-500 Hz)

**Configuration:**
```
Frequency range: 100-500 Hz
Crossover: 100 Hz highpass, 500 Hz lowpass
Horn path: 2.5-3 m
Drivers: 2-4× in series
```

**Advantages:**
- Away from impedance minimum (400-500 Hz is at END of range)
- Driver is comfortable in this range
- Less amplifier stress

**Disadvantages:**
- Not exploiting deep bass capability
- Need separate woofer for < 100 Hz

**Verdict:** ⭐⭐⭐ GOOD but underutilizes horn potential

---

### Option 3: Use WITHOUT Horn (Direct Radiator)

**Configuration:**
```
Frequency range: 100 Hz - 20 kHz (full-range)
No horn, direct radiation
Array configuration (line source)
```

**Advantages:**
- No horn complexity
- Simpler to build
- 901 design already optimized for direct use

**Disadvantages:**
- Not using horn loading (less efficiency)
- Not the "Big Wave" concept you want

**Verdict:** ⭐⭐ OK but defeats the purpose

---

## 🚨 CRITICAL IMPEDANCE SOLUTION

### Problem: 0.8 Ω minimum is too low!

### Solution 1: Series Resistor (Recommended)

**Add 2-3 Ω resistor in series:**
```
Total Z_min = 0.8 + 2.5 = 3.3 Ω (safer for amp!)
Power loss: ~40% @ 400 Hz (but driver isn't main contributor here anyway)
```

### Solution 2: Use Professional Amplifier

**Requirements:**
```
Must handle: 0.8-1.0 Ω loads
Examples:
- Crown XLS DriveCore series
- QSC RMX series
- Lab Gruppen
- Powersoft
```

**Cost:** $300-1000+ per channel

### Solution 3: Fewer Drivers

**Use 2 drivers instead of 4:**
```
Z_min = 2 × 0.8 = 1.6 Ω (better, but still low)
Power handling: 2 × 50W = 100W (still good)
```

---

## 🎯 FINAL VERDICT

### For "Big Wave" Back-Loaded Horn System:

**Rating:** ⭐⭐⭐ GOOD with caveats

**Best use:** **Mid-bass horn (50-300 Hz)**

**Why:**
- ✅ Fs = 95 Hz PERFECT for mid-bass resonance
- ✅ Power handling excellent
- ✅ Size appropriate
- ⚠️ Impedance requires special handling
- ❌ NOT suitable for deep bass (< 50 Hz)

**Recommended system:**

```
Frequency Range | Component | Configuration
----------------|-----------|---------------
20-50 Hz        | Subwoofer | Separate (low Fs driver)
50-300 Hz       | Bose 901  | 4× in 3.5m horn + series R
300 Hz-20 kHz   | Tweeter   | Direct radiation
```

**Expected performance:**
- Deep bass (20-50 Hz): From subwoofer ⭐⭐⭐⭐
- Mid-bass (50-300 Hz): From 901 horn ⭐⭐⭐⭐⭐
- Mids/Highs (300 Hz+): From tweeter ⭐⭐⭐⭐

**Overall:** ⭐⭐⭐⭐ VERY GOOD with proper system design!

---

## 📋 NEXT STEPS

### 1. Test Single Driver
```bash
# Measure actual Fs and impedance
# Verify measurements match LMS data
# Test power handling at different frequencies
```

### 2. Design Horn for Fs = 95 Hz
```
Target cutoff: 24 Hz (Fs/4)
Path length: 3.5-4 m
Entry: 400 cm² (4 drivers)
Exit: 3200 cm² (60×60 cm)
Expansion: 8:1 ratio
```

### 3. Amplifier Selection
```
Must handle: 3.3 Ω minimum (with series R)
Power: 200W+ RMS
Consider: Crown XLS, QSC RMX
Budget: $300-500
```

### 4. Crossover Design
```
Highpass: 50 Hz (protect below Fs)
Lowpass: 300 Hz (avoid phase issues)
Type: Linkwitz-Riley 4th order
DSP: CamillaDSP (perfect for this!)
```

---

## 🏆 CONCLUSION

**Question:** Are Bose 901 drivers good for Big Wave?

**Answer:** **YES, but with modifications!**

**Best application:** **Mid-bass horn (50-300 Hz)** with:
1. 3.5m path optimized for 95 Hz resonance
2. Series resistor (2.5-3 Ω) for impedance safety
3. Separate subwoofer for deep bass (< 50 Hz)
4. CamillaDSP with +9 dB boost @ 95 Hz

**Expected result:** **EXCELLENT mid-bass performance!**

The 901 drivers are NOT ideal for deep bass (Fs too high), but they're PERFECT for a mid-bass horn system. Combined with a proper subwoofer, you'd have an incredible 3-way system!

**Do you want me to design the complete Big Wave system with these drivers?** 🎵
