# moOde Volume Optimization Guide
**Date:** 2026-01-21  
**Purpose:** Step-by-step guide to optimize volume settings for your system

## Current Situation

**Problem:** Volume too loud at low settings (12% was already very loud)

**Root Causes Fixed:**
- ✅ Digital Mixer: Reduced from 80% to 50% (recommended)
- ✅ Filter Gain: Reduced from +12dB to +6dB
- ✅ Database: Updated to reflect correct settings

**Current Configuration:**
- Digital Mixer: 50% (-51.5dB) - FIXED
- Analogue Mixer: 100% (0.0dB) - FIXED  
- Filter Gain: +6dB (testing)
- MPD Volume: 1% (safe for testing)

## Optimization Strategy

### Step 1: Test Filter Gain Values

We'll test different filter gain values to find the optimal compensation:

| Filter Gain | Expected Behavior | Test Order |
|-------------|-------------------|------------|
| **+4dB** | Most conservative, may be quiet | 1st |
| **+5dB** | Moderate compensation | 2nd |
| **+6dB** | Current setting | 3rd |
| **+7dB** | More compensation | 4th |
| **+8dB** | Maximum recommended | 5th |

### Step 2: Testing Protocol

For each filter gain value:

1. **Set Configuration:**
   - Filter gain: Test value (e.g., +4dB)
   - MPD volume: 1%
   - Digital mixer: 50% (fixed)
   - Restart MPD

2. **Your Test Protocol:**
   - Volume is at 1% (almost zero)
   - Press play
   - Increase volume very gradually
   - Note where comfortable listening occurs

3. **Evaluation:**
   - **Too quiet:** Need more gain (+1dB)
   - **Good:** Optimal found!
   - **Too loud:** Need less gain (-1dB)

### Step 3: Target Volume Response

**Ideal behavior:**
- MPD 1%: Audible but very quiet (safe for testing)
- MPD 5%: Barely audible
- MPD 10%: Quiet background listening
- MPD 20%: Normal listening level
- MPD 30%: Moderate volume
- MPD 50%: Loud (maximum recommended)

## Quick Optimization Commands

### Test +4dB (Most Conservative)
```bash
ssh andre@moode.local
sudo sed -i 's/gain: [0-9]*/gain: 4/' /usr/share/camilladsp/working_config.yml
mpc volume 1
sudo systemctl restart mpd
# Test with your protocol
```

### Test +5dB
```bash
sudo sed -i 's/gain: [0-9]*/gain: 5/' /usr/share/camilladsp/working_config.yml
mpc volume 1
sudo systemctl restart mpd
# Test with your protocol
```

### Test +6dB (Current)
```bash
sudo sed -i 's/gain: [0-9]*/gain: 6/' /usr/share/camilladsp/working_config.yml
mpc volume 1
sudo systemctl restart mpd
# Test with your protocol
```

### Test +7dB
```bash
sudo sed -i 's/gain: [0-9]*/gain: 7/' /usr/share/camilladsp/working_config.yml
mpc volume 1
sudo systemctl restart mpd
# Test with your protocol
```

### Test +8dB
```bash
sudo sed -i 's/gain: [0-9]*/gain: 8/' /usr/share/camilladsp/working_config.yml
mpc volume 1
sudo systemctl restart mpd
# Test with your protocol
```

## Automated Optimization Script

**Location:** `/Users/andrevollmer/moodeaudio-cursor/scripts/optimize-volume.sh`

**Usage:**
```bash
cd /Users/andrevollmer/moodeaudio-cursor/scripts
./optimize-volume.sh
```

**What it does:**
- Tests filter gains: 3, 4, 5, 6, 7, 8, 9 dB
- Sets MPD volume to 1% for each test
- Prompts you to evaluate each setting
- Saves optimal configuration when found

## Expected Results

### With +4dB (Conservative)
- MPD 1%: Very quiet, may be inaudible
- MPD 10%: Quiet
- MPD 20%: Moderate
- **Verdict:** Likely too quiet, need +5dB or +6dB

### With +6dB (Current)
- MPD 1%: Audible but safe
- MPD 10%: Quiet background
- MPD 20%: Normal listening
- **Verdict:** Should be close to optimal

### With +8dB (Maximum)
- MPD 1%: Audible
- MPD 10%: Moderate
- MPD 20%: Loud
- **Verdict:** May be too loud, need to reduce

## Fine-Tuning

Once you find a good range (e.g., +6dB is good but +7dB is too loud):

1. Test intermediate values: +6.5dB (if possible) or stick with +6dB
2. Verify volume response across full range (1-50%)
3. Document final settings

## Final Configuration Checklist

When optimal settings are found:

- [ ] Filter gain: ___ dB (optimal value)
- [ ] Digital mixer: 50% (fixed)
- [ ] Analogue mixer: 100% (fixed)
- [ ] MPD volume: 1% (for testing)
- [ ] Volume response verified: 1-50% range
- [ ] Settings saved to database
- [ ] Configuration documented

## Troubleshooting

### Still Too Loud at Low Settings

**Possible causes:**
1. Filter gain still too high → Reduce by 1-2dB
2. Digital mixer not at 50% → Check: `amixer sget Digital`
3. Multiple gain stages compounding → Verify all settings

**Fix:**
```bash
# Reduce filter gain
sudo sed -i 's/gain: [0-9]*/gain: 4/' /usr/share/camilladsp/working_config.yml
# Verify Digital mixer
amixer sset Digital 50%
# Restart
sudo systemctl restart mpd
```

### Too Quiet Even at High Settings

**Possible causes:**
1. Filter gain too low → Increase by 1-2dB
2. Digital mixer too low → Should be 50%, not lower
3. Filter attenuation not compensated → Increase gain

**Fix:**
```bash
# Increase filter gain
sudo sed -i 's/gain: [0-9]*/gain: 8/' /usr/share/camilladsp/working_config.yml
# Verify Digital mixer
amixer sget Digital  # Should show 50%
# Restart
sudo systemctl restart mpd
```

## Best Practices

1. **Always start with MPD volume at 1%** (your safety protocol)
2. **Test gradually** - increase volume slowly
3. **Document findings** - note which gain value works best
4. **Keep Digital mixer at 50%** - never change this
5. **Keep Analogue mixer at 100%** - never change this
6. **Only adjust filter gain** - this is the optimization variable

## Next Steps

1. **Test +4dB** (currently set)
2. **Evaluate** with your protocol
3. **Report back:** too quiet / good / too loud
4. **Adjust** to next value based on feedback
5. **Repeat** until optimal found

---

**Current Test:** Filter Gain +4dB  
**Status:** Ready for your testing protocol  
**Next:** Report results, we'll adjust accordingly
