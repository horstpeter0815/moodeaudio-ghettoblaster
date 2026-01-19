# CRITICAL Configuration Differences: v1.0 vs Current Build

**Date:** 2026-01-19  
**Status:** 🚨 MUST FIX BEFORE BUILD

---

## Summary

Found **3 critical differences** between v1.0 working configuration (from GitHub commit 9cb5210) and current `config.txt.overwrite` that will cause issues.

---

## Differences Found

### 1. ❌ arm_boost Setting

| Config | v1.0 Working | Current Build | Status |
|--------|-------------|---------------|--------|
| arm_boost | **0** | **1** | ❌ WRONG |

**Why this matters:**
- v1.0 used `arm_boost=0` (disabled)
- Current has `arm_boost=1` (enabled)
- This affects CPU frequency and could impact display timing/stability

**Fix:** Change to `arm_boost=0` to match v1.0

---

### 2. ❌ HiFiBerry AMP100 automute

| Config | v1.0 Working | Current Build | Status |
|--------|-------------|---------------|--------|
| dtoverlay | `hifiberry-amp100` | `hifiberry-amp100,automute` | ❌ WRONG |

**Why this matters:**
- v1.0 did NOT use automute parameter
- Current has automute enabled
- automute can cause audio dropouts or silence issues
- User reported AirPlay crashes - automute might be related

**Fix:** Remove `,automute` parameter to match v1.0

---

### 3. ❌ ft6236 Touchscreen Overlay

| Config | v1.0 Working | Current Build | Status |
|--------|-------------|---------------|--------|
| dtoverlay | `dtoverlay=ft6236` | `# dtoverlay=ft6236` (commented) | ❌ DIFFERENT |

**Why this matters:**
- v1.0 loaded ft6236 directly in config.txt
- Current has it commented, relies on ft6236-delay.service
- Service-based loading might cause timing issues
- User mentioned I2C init problems with touchscreen/display timing

**Note:** The service-based approach might actually be BETTER for timing issues, but it's different from v1.0. Need to verify which approach user prefers.

---

## Additional Differences (Minor)

### 4. hdmi_drive Setting

| Config | v1.0 Working | Current Build | Status |
|--------|-------------|---------------|--------|
| hdmi_drive | **2** | removed (commented) | ⚠️ DIFFERENT |

**Why this matters:**
- v1.0 forced HDMI to DVI mode (`hdmi_drive=2`)
- Current lets EDID auto-detect
- This might be OK, but it's different from v1.0

---

## Recommended Fixes

### Priority 1: MUST FIX (Breaking Changes)

1. **arm_boost:** Change from 1 to 0
2. **hifiberry-amp100:** Remove `,automute` parameter

### Priority 2: VERIFY (Functional Differences)

3. **ft6236:** Verify if service-based loading works better than direct overlay
   - If user has I2C timing issues → keep service approach
   - If user wants exact v1.0 match → uncomment in config.txt

4. **hdmi_drive:** Verify if EDID auto-detect works
   - If display issues → add back `hdmi_drive=2`
   - If working → keep current approach

---

## Git Comparison Commands

```bash
# Compare full v1.0 config.txt with current
git show 9cb5210:v1.0-working-config/config.txt > /tmp/v1.0-config.txt
diff -u /tmp/v1.0-config.txt moode-source/boot/firmware/config.txt.overwrite

# Key lines to check:
grep arm_boost /tmp/v1.0-config.txt  # Should show: arm_boost=0
grep hifiberry-amp100 /tmp/v1.0-config.txt  # Should show: dtoverlay=hifiberry-amp100 (no automute)
grep ft6236 /tmp/v1.0-config.txt  # Should show: dtoverlay=ft6236
```

---

## Impact Assessment

### If NOT Fixed

**arm_boost=1 (wrong):**
- Potential: Display timing issues, instability
- Risk: Medium
- Severity: Unknown (needs testing)

**hifiberry-amp100,automute (wrong):**
- Potential: Audio dropouts, silence after playback stops
- Risk: High
- Severity: User reported audio issues and AirPlay crashes
- **This might be the root cause of AirPlay crashes!**

**ft6236 service vs direct (different):**
- Potential: Touch not working, I2C conflicts
- Risk: Medium
- Severity: User mentioned I2C timing issues
- Service-based loading might actually be better for timing

---

## Decision

**Recommendation:** Match v1.0 EXACTLY for first build
- Set `arm_boost=0`
- Remove `automute` from hifiberry-amp100
- Uncomment `dtoverlay=ft6236` (direct loading)

**After first boot:** Test if everything works
- If touch has I2C issues → switch back to service-based ft6236 loading
- If audio has automute issues → keep without automute
- If display unstable → verify arm_boost setting

**Goal:** Build should match v1.0 configuration byte-for-byte to ensure same behavior.
