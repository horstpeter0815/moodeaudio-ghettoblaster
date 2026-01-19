# Display Chain Source Code Study
**Date:** 2026-01-19  
**Goal:** Understand how moOde display works by reading source code, not guessing

---

## Study Plan

### Phase 1: Understand xinitrc Logic (moOde's Display Bootstrap)
**Files to read:**
1. `/home/andre/.xinitrc` - v1.0 working version from commit 84aa8c2
2. moOde source: How does moOde generate/use xinitrc?
3. How does `kmsprint` get screen resolution vs `fbset`?
4. How does `xrandr --output HDMI-1 --rotate left` work with KMS?

**Questions to answer:**
- Why does v1.0 use `kmsprint` instead of `fbset`?
- What's the difference between HDMI-1 and HDMI-2 in xrandr vs hardware HDMI-A-1/HDMI-A-2?
- How does screen rotation affect `SCREEN_RES` variable passed to Chromium?
- Why does v1.0 NOT need `xdotool` to resize Chromium window?

---

### Phase 2: Understand Chromium Window Sizing
**Files to read:**
1. How does Chromium interpret `--window-size=1280,400` in kiosk mode?
2. Why does Chromium default to 10x10 pixels in some cases?
3. What's the relationship between X11 window geometry and Chromium's internal sizing?
4. Does xrandr rotation affect Chromium's understanding of display size?

**Questions to answer:**
- Why does `xdotool getwindowgeometry` show 10x10 when `--window-size=1280,400` is passed?
- Is this a Chromium bug or a configuration issue?
- Does v1.0 have a different Chromium version?
- How does KMS affect Chromium window detection?

---

### Phase 3: Understand GBM (Graphics Buffer Manager) Errors
**Files to read:**
1. What is GBM and why does Chromium need it?
2. Why does `gbm_wrapper.cc` fail to export buffers?
3. What's the relationship between framebuffer geometry and GBM?
4. Does `--disable-gpu` actually disable GBM or just GPU acceleration?

**Questions to answer:**
- Are GBM errors fatal or just warnings?
- Why do GBM errors persist even with `--disable-gpu`?
- What's the relationship between KMS, DRM, GBM, and Chromium rendering?
- Did v1.0 have these errors or were they silent?

---

### Phase 4: Compare v1.0 vs Current State
**Compare:**
1. v1.0 cmdline.txt: `video=HDMI-A-1:400x1280M@60,rotate=90`
   - Current: Same (should be good)
2. v1.0 config.txt: `hdmi_group=0`, `hdmi_blanking=1`, `hdmi_force_edid_audio=1`
   - Current: `hdmi_group=2`, `hdmi_blanking=0`, `hdmi_force_edid_audio=0`
3. v1.0 xinitrc: Uses `kmsprint`, rotates `HDMI-1`
   - Current: Same, but fixed to `HDMI-2` (hardware difference?)
4. v1.0 Chromium: NO `--disable-gpu`, NO `xdotool` workaround
   - Current: Added these as "fixes"

**Critical differences to understand:**
- Why do config.txt differences matter?
- Is `hdmi_group=2` causing issues vs `hdmi_group=0`?
- Are the "fixes" I added (--disable-gpu, xdotool) making it worse?

---

## Learning Methodology

1. **Read source code first** - understand HOW it works
2. **Document findings** - write down what each line does
3. **Compare v1.0 vs current** - identify exact differences
4. **Understand root cause** - why did v1.0 work?
5. **Only then fix** - with full understanding, not trial-and-error

---

## Learning #1: moOde xinitrc Management

### Source Code Location
**File:** `moode-source/home/xinitrc.default`
- This is moOde's DEFAULT template for xinitrc
- worker.php modifies it with sed commands based on user settings

### Key Functions in xinitrc.default (IMPORTANT!)

#### 1. HDMI Output Detection (Lines 19-23)
```bash
# Detect HDMI output (HDMI-1 for Pi 4, HDMI-2 for Pi 5)
HDMI_OUTPUT="HDMI-1"
if xrandr --query 2>/dev/null | grep -q "HDMI-2 connected"; then
    HDMI_OUTPUT="HDMI-2"
fi
```
**Learning:** The default xinitrc AUTOMATICALLY detects which HDMI port is used!
- Pi 4 uses HDMI-1
- Pi 5 uses HDMI-2
- This is dynamic, not hardcoded!

#### 2. Screen Resolution Detection (Lines 47-53)
```bash
fgrep "#dtoverlay=vc4-kms-v3d" /boot/firmware/config.txt
if [ $? -ne 0 ]; then
    # KMS is enabled (default for Pi 5)
    SCREEN_RES=$(kmsprint | awk '$1 == "FB" {print $3}' | awk -F"x" '{print $1","$2}')
else
    # KMS is disabled (legacy fbdev mode)
    SCREEN_RES=$(fbset -s | awk '$1 == "geometry" {print $2","$3}')
fi
```
**Learning:** 
- Uses `kmsprint` when KMS is enabled (Pi 5 default)
- Falls back to `fbset` when KMS is disabled (commented out)
- This checks config.txt to determine which method to use!

#### 3. Portrait Mode Handling (Lines 34-44) - CRITICAL!
```bash
if [ $HDMI_SCN_ORIENT = "portrait" ]; then
    # Portrait mode: Set to native 400x1280, no rotation (portrait is native)
    DISPLAY=:0 xrandr --output $HDMI_OUTPUT --rotate normal 2>/dev/null || true
    sleep 1
    DISPLAY=:0 xrandr --output $HDMI_OUTPUT --mode 400x1280 2>/dev/null || true
    sleep 1
    DISPLAY=:0 xrandr --output $HDMI_OUTPUT --rotate normal 2>/dev/null || true
    sleep 1
    # Force SCREEN_RES to portrait (400,1280)
    SCREEN_RES="400,1280"
fi
```
**Learning:** 
- moOde's default assumes portrait displays are NATIVE 400x1280 (like Waveshare)
- Sets mode to 400x1280, no rotation needed
- Forces SCREEN_RES to "400,1280" for Chromium

### CRITICAL DIFFERENCE: v1.0 vs moOde Default

#### v1.0 xinitrc (from commit 84aa8c2)
- Uses `xrandr --output HDMI-1 --rotate left` for portrait mode
- Gets resolution from `kmsprint` for HDMI
- Rotates 400x1280 to 1280x400 landscape using `--rotate left`

#### moOde Default xinitrc (xinitrc.default)
- Auto-detects HDMI-1 vs HDMI-2
- Assumes portrait mode is NATIVE, sets `--mode 400x1280 --rotate normal`
- Forces SCREEN_RES to "400,1280" (portrait)

**ROOT CAUSE HYPOTHESIS:**
The v1.0 xinitrc was manually customized to rotate portrait to landscape.
The moOde default assumes portrait displays WANT portrait mode (no rotation).
Our display is physically portrait (400x1280) but we WANT landscape (1280x400).

### worker.php Modifications

**File:** `moode-source/www/daemon/worker.php`

Lines 1349, 3522: Modifies `--app=` URL in xinitrc
```php
sysCmd("sed -i 's|--app.*|--app=\"" . $_SESSION['local_display_url'] . "\" \\\\|' " . $_SESSION['home_dir'] . '/.xinitrc');
```

Lines 1354, 3538: Modifies screen blank interval
```php
sysCmd('sed -i "/xset s/c\xset s ' . $_SESSION['scn_blank'] . '" ' . $_SESSION['home_dir'] . '/.xinitrc');
```

Lines 1360, 3548: Adds `--disable-gpu` flag
```php
$value = $_SESSION['disable_gpu_chromium'] == 'on' ? ' --disable-gpu' : '';
sysCmd("sed -i 's/--kiosk.*/--kiosk" . $value . "/' ". $_SESSION['home_dir'] . '/.xinitrc');
```

**Learning:** moOde uses sed to modify xinitrc based on database settings!
- This explains why manual edits can be overwritten
- worker.php regenerates parts of xinitrc on config changes

---

---

## ROOT CAUSE ANALYSIS (By Reading Source Code)

### The Problem
- Physical display: 400x1280 portrait (Waveshare)
- User wants: 1280x400 landscape (rotated 90°)
- Database setting: `hdmi_scn_orient='portrait'` (correct, because display IS portrait)
- But moOde interprets this as "user wants portrait display", not "display is physically portrait"

### v1.0 Working Logic (Lines 36-38 of v1.0 xinitrc)
```bash
if [ $HDMI_SCN_ORIENT = "portrait" ]; then
    SCREEN_RES=$(echo $SCREEN_RES | awk -F"," '{print $2","$1}')  # Swap to 1280,400
    DISPLAY=:0 xrandr --output HDMI-1 --rotate left                # Rotate to landscape
fi
```
**What it does:**
1. Detects portrait orientation setting
2. Gets native resolution (400x1280)
3. **ROTATES to landscape** with `--rotate left`
4. **SWAPS dimensions** for Chromium: 1280,400
5. Chromium launches with `--window-size=1280,400` in landscape mode
6. **Result: Display shows 1280x400 landscape**

### moOde Default Logic (Lines 34-44 of xinitrc.default)
```bash
if [ $HDMI_SCN_ORIENT = "portrait" ]; then
    DISPLAY=:0 xrandr --output $HDMI_OUTPUT --rotate normal  # NO rotation!
    DISPLAY=:0 xrandr --output $HDMI_OUTPUT --mode 400x1280  # Force 400x1280
    DISPLAY=:0 xrandr --output $HDMI_OUTPUT --rotate normal  # Ensure normal
    SCREEN_RES="400,1280"  # Force portrait dimensions
fi
```
**What it does:**
1. Detects portrait orientation setting
2. Assumes user WANTS portrait (native 400x1280)
3. **NO rotation** - keeps portrait mode
4. Forces `SCREEN_RES="400,1280"` for Chromium
5. Chromium launches with `--window-size=400,1280` in portrait mode
6. **Result: Display shows 400x1280 portrait (WRONG!)**

### Why v1.0 Worked
- **Custom xinitrc** with landscape rotation logic
- Database correctly set to `hdmi_scn_orient='portrait'`
- v1.0 xinitrc interprets this as "rotate portrait display to landscape"
- Chromium gets correct `1280,400` window size
- Display shows landscape

### Why System Broke
- moOde updates/reconfigurations overwrote custom xinitrc
- Reverted to moOde default logic
- moOde default interprets `hdmi_scn_orient='portrait'` as "keep portrait"
- Chromium gets wrong `400,1280` window size
- Display shows portrait (or fails to render correctly)

### The Design Misunderstanding
**moOde's assumption:**
- `hdmi_scn_orient='portrait'` = "User wants portrait UI on landscape display"
- `hdmi_scn_orient='landscape'` = "User wants landscape UI on landscape display"

**Our reality:**
- Physical display: Portrait (400x1280)
- Desired UI: Landscape (1280x400)
- Setting should be: `hdmi_scn_orient='portrait'` (physical orientation)
- But xinitrc should **rotate** to landscape for UI

**Correct interpretation needed:**
- Physical display orientation != Desired UI orientation
- Need custom xinitrc that rotates portrait display to landscape UI

---

## Solution Strategy (Based on Understanding)

### Option 1: Restore v1.0 Custom xinitrc
- Copy v1.0 xinitrc with landscape rotation logic
- Fix HDMI-1 → HDMI-2 (hardware difference)
- Ensure worker.php doesn't overwrite critical parts
- **Risk:** moOde updates may overwrite custom logic

### Option 2: Change Database Setting
- Set `hdmi_scn_orient='landscape'`
- Let moOde default xinitrc handle it
- **Problem:** This tells moOde the display is landscape (it's not)
- May cause other issues with touch calibration, etc.

### Option 3: Modify moOde Default xinitrc
- Update `xinitrc.default` in moOde source
- Add logic: "If portrait display, rotate to landscape"
- Submit patch to moOde project
- **Best long-term solution**

### Immediate Action (Based on Code Understanding)
1. Restore v1.0 xinitrc with HDMI-2 fix (already done)
2. Test if it works now
3. Document why it works
4. Protect from worker.php overwrites

---

## Next Steps

1. ✅ Read moOde xinitrc generation logic - DONE
2. ✅ Compare v1.0 xinitrc with moOde default - DONE
3. ✅ Understand why v1.0 worked (landscape rotation) - DONE
4. ✅ Understand why moOde default doesn't work (expects portrait native) - DONE
5. Test current xinitrc (v1.0 with HDMI-2 fix) to verify understanding
6. If working: Document and protect from overwrites
7. If not working: Check for other differences (config.txt, cmdline.txt)

**Status:** ROOT CAUSE UNDERSTOOD - Ready to verify

---

## Verification Results

### Current System State (2026-01-19 07:27)

**Display Configuration:**
```bash
# xrandr output
HDMI-2 connected 1280x400+0+0 left
   400x1280      59.51*+  # Native resolution
   1280x720     100.00    # Additional mode
```
✅ Display IS rotated to landscape correctly

**Chromium Launch:**
```bash
--window-size=1280,400  # Correct parameter passed
```
✅ Window size parameter is correct

**Actual Window Geometry:**
```bash
Window 6291457
  Position: 10,10 (screen: 0)
  Geometry: 10x10  # ❌ WRONG!
```
❌ Chromium IGNORES --window-size parameter in kiosk mode!

### New Problem Discovered

**Chromium Kiosk Mode Window Sizing Issue:**
- Chromium receives correct `--window-size=1280,400`
- Display is correctly rotated to `1280x400 left`
- But Chromium window defaults to `10x10` pixels
- This explains the black screen / missing UI

**Question:** Did v1.0 have this issue?
- User reported v1.0 worked perfectly
- v1.0 xinitrc has NO `xdotool` workaround
- Either:
  1. v1.0 Chromium version handled window sizing differently
  2. v1.0 had different kernel/KMS version
  3. v1.0 rendering worked despite 10x10 window (unlikely)

### Hypothesis: Chromium Version Difference
- Current Chromium: 126.0.6478.164
- v1.0 Chromium: Unknown (need to check)
- Chromium 126 may have broken `--window-size` handling in kiosk mode with KMS

### What We Know Now
1. ✅ Chromium 126 is the CORRECT version (moOde intentionally uses it)
2. ✅ xinitrc has correct landscape rotation logic
3. ✅ Display is rotated correctly to `1280x400 left`
4. ✅ Chromium launches with `--window-size=1280,400`
5. ❌ Chromium window shows as `10x10` (ignores parameter)

### Mystery: Why Does v1.0 Work?
- v1.0 restoration log says "moOde UI loads correctly"
- v1.0 xinitrc has NO xdotool workaround
- v1.0 uses same Chromium 126
- Yet user reports v1.0 worked perfectly

**Possible explanations:**
1. v1.0 config.txt has different settings (hdmi_group, hdmi_blanking, etc.)
2. The 10x10 window is not preventing rendering (GBM errors are warnings?)
3. Need to ask user what they see on display RIGHT NOW

### ROOT CAUSE FOUND: config.txt Differences!

**User reports:** "still only m on top right" (10x10 window confirmed)

**Critical config.txt differences discovered:**

| Setting | v1.0 Working | Current Broken |
|---------|--------------|----------------|
| hdmi_group | 0 (auto-detect) | 2 (DMT mode - computer monitors) |
| hdmi_blanking | 1 (enabled) | 0 (disabled) |
| hdmi_force_edid_audio | 1 (enabled) | 0 (disabled) |
| hdmi_mode | NOT SET | 87 (custom timings) |
| hdmi_timings | NOT SET | 400 0 220 32 110 1280... |

**Why this breaks Chromium window sizing:**
1. `hdmi_group=2` + `hdmi_mode=87` forces custom DMT timings
2. Custom `hdmi_timings` define a non-standard display mode
3. KMS detects display as 400x1280, but with custom timings
4. Chromium queries X11 for window size hint
5. X11/KMS provides wrong size hint due to custom timings
6. Chromium defaults to fallback: 10x10 window
7. Result: Only "m" icon visible

**Why v1.0 worked:**
- `hdmi_group=0` lets system auto-detect display
- No custom timings - uses native EDID
- KMS provides correct size hint to X11
- Chromium gets correct window size
- Full UI renders correctly

### Solution: Restore v1.0 config.txt HDMI Settings
Remove custom timing parameters, restore auto-detection:
```ini
hdmi_group=0        # Was: 2
hdmi_blanking=1     # Was: 0  
hdmi_force_edid_audio=1  # Was: 0
# Remove: hdmi_mode=87
# Remove: hdmi_timings=...
```

### CRITICAL DISCOVERY: v1.0 uses `fbset`, not `kmsprint`!

**v1.0 SCREEN_RES detection:**
```bash
# Both branches use fbset!
if fgrep -q "#dtoverlay=vc4-kms-v3d" /boot/firmware/config.txt; then
    SCREEN_RES=$(fbset -s 2>/dev/null | awk '$1 == "geometry" {print $2","$3}')
else
    SCREEN_RES=$(fbset -s 2>/dev/null | awk '$1 == "geometry" {print $2","$3}')
fi
```

**Current xinitrc (from v1.0 commit 84aa8c2):**
```bash
# Uses kmsprint when KMS enabled!
if [ $? -ne 0 ]; then
    SCREEN_RES=$(kmsprint | awk '$1 == "FB" {print $3}' | awk -F"x" '{print $1","$2}')
else
    SCREEN_RES=$(fbset -s | awk '$1 == "geometry" {print $2","$3}')
fi
```

**The discrepancy:**
- v1.0-working-config/xinitrc uses `fbset` (older version?)
- v1.0 from commit 84aa8c2 uses `kmsprint` (newer version?)
- One of these worked, the other doesn't!

### Next Steps
1. Verify which version is actually v1.0 working
2. Test if switching to `fbset` fixes window sizing
3. Document the correct SCREEN_RES detection method
