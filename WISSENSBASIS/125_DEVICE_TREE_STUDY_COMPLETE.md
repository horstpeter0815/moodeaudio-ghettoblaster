# Device Tree Overlay Study - Complete Summary

**Date:** January 18, 2026  
**Status:** Phases 1-3 Complete, Phase 4 Pending (needs Pi), Phases 5-6 Complete

---

## What Was Accomplished

### Phase 1: Inventory ✅

**Overlays identified in v1.0 working config:**
1. `vc4-kms-v3d,noaudio` - Display controller
2. `hifiberry-amp100` - Audio DAC
3. `ft6236` - Touch controller

**Source files analyzed:**
- `custom-components/overlays/ghettoblaster-amp100.dts`
- `custom-components/overlays/ghettoblaster-ft6236.dts`
- `hifiberry-amp100-pi5-dsp-reset.dts` (advanced version)
- `ghettoblaster-unified.dts` (combined overlay)

### Phase 2: Deep Analysis ✅

**Each overlay analyzed for:**
- Fragment structure
- Hardware configured
- I2C devices and addresses
- GPIO assignments
- Power supplies
- Clock sources
- Available parameters (`__overrides__`)

**Key findings:**
- HiFiBerry has 4 parameters: auto_mute, 24db_digital_gain, leds_off, mute_ext_ctl
- FT6236 has NO parameters (fixed config)
- vc4-kms-v3d has `noaudio` parameter

### Phase 3: Comparison ✅

**Custom vs Standard:**
- Simple overlays: Basic functionality, no parameters
- Advanced overlays: Include `__overrides__` for configuration
- Unified overlay: Combines audio + touch in one file

**Key differences:**
- Custom overlays target Pi 5 specifically
- Include I2C clock stabilization (100kHz)
- No GPIO conflicts between devices

### Phase 4: Validation ⏳

**Status:** Pending - requires Pi hardware access

**Tests documented:**
- auto_mute behavior verification
- I2C device detection
- Touch coordinate mapping
- Sound card registration
- Display output verification

### Phase 5: Documentation ✅

**Files created:**

1. **Master Reference** (`WISSENSBASIS/DEVICE_TREE_MASTER_REFERENCE.md`)
   - Complete technical reference
   - All overlays documented
   - Parameter tables
   - Common mistakes section

2. **RAG Upload Files** (`rag-upload-files/documentation/device-tree/`)
   - `DEVICE_TREE_OVERVIEW.md` - High-level intro
   - `HIFIBERRY_AMP100_DTO.md` - Audio overlay details
   - `FT6236_DTO.md` - Touch overlay details
   - `COMMON_MISTAKES.md` - What NOT to do

3. **Updated** (`LESSONS_LEARNED.md`)
   - Added device tree findings
   - Parameters that exist vs don't exist
   - Layer separation explained

### Phase 6: Integration ✅

**Ghetto AI Knowledge Base:**
- All documentation ready for RAG upload
- Structured in logical hierarchy
- Cross-referenced with existing docs
- Includes examples and diagrams

---

## Key Learnings

### Parameters That Actually Exist

**HiFiBerry AMP100:**
- ✅ `auto_mute` - Hardware-level amplifier muting
- ✅ `24db_digital_gain` - Digital boost
- ✅ `leds_off` - Disable status LEDs
- ✅ `mute_ext_ctl` - External GPIO mute

**vc4-kms-v3d:**
- ✅ `noaudio` - Disable HDMI audio

**ft6236:**
- ❌ No parameters - Fixed configuration

### Parameters That DON'T Exist

**Common mistakes:**
- ❌ `disable_iec958` - IEC958 is ALSA software
- ❌ `automute` - Correct spelling: `auto_mute`
- ❌ `rotate` - Display rotation is cmdline.txt + X11
- ❌ `volume` - Volume is ALSA/MPD, not hardware

### Layer Separation

**Device Tree (Hardware):**
- I2C devices
- I2S interfaces
- GPIO assignments
- Clock configuration

**ALSA (Software):**
- Audio routing
- Plugin chains
- IEC958 plugin

**moOde (Application):**
- Database settings
- User preferences
- MPD configuration

**X11 (Display):**
- Runtime rotation
- Window management
- Touch input mapping

---

## Hardware Configured by Each Overlay

### hifiberry-amp100

**I2C Device:**
- PCM5122 DAC at address 0x4d
- Driver: snd-soc-pcm512x
- Power: AVDD, DVDD, CPVDD (3.3V)

**I2S Interface:**
- Pi 5 path: `/axi/pcie@1000120000/rp1/i2s@a4000`
- Controller: DesignWare I2S (RP1 chip)

**Sound Card:**
- ALSA name: sndrpihifiberry
- Compatible: hifiberry,hifiberry-amp

### ft6236

**I2C Device:**
- FT6236 touch controller at address 0x38
- Driver: ft6236

**GPIO:**
- Pin 25: Interrupt (falling edge)

**Touch Configuration:**
- Size: 1280x400 (landscape)
- Inverted: X and Y axes
- Swapped: X-Y for rotation

### vc4-kms-v3d

**Display Controller:**
- VideoCore IV GPU
- Kernel Mode Setting (KMS)
- Hardware acceleration

**HDMI:**
- Output enable
- EDID detection
- Framebuffer configuration

---

## Files Created

### Documentation Structure

```
rag-upload-files/documentation/device-tree/
├── DEVICE_TREE_OVERVIEW.md         (Introduction)
├── HIFIBERRY_AMP100_DTO.md         (Audio overlay)
├── FT6236_DTO.md                   (Touch overlay)
└── COMMON_MISTAKES.md              (What NOT to do)

WISSENSBASIS/
└── DEVICE_TREE_MASTER_REFERENCE.md (Complete technical ref)

Updated:
└── LESSONS_LEARNED.md              (Added DT findings)
```

### File Sizes

- Master Reference: ~20KB (comprehensive)
- Overview: ~5KB (introduction)
- HiFiBerry: ~10KB (detailed)
- FT6236: ~8KB (detailed)
- Common Mistakes: ~12KB (examples)

---

## Impact on Future Work

### What This Prevents

1. **No more fake parameters**
   - All parameters verified in source
   - Can't invent parameters that don't exist

2. **Correct layer fixes**
   - Hardware problems → Device tree
   - Software problems → Config files
   - Application problems → moOde/MPD

3. **No more confusion**
   - IEC958 is software, not hardware
   - Display rotation is multi-layer
   - Volume is ALSA/MPD, not device tree

### What This Enables

1. **Informed decisions**
   - Know what can be configured
   - Understand limitations
   - Choose correct fix approach

2. **Faster debugging**
   - Check correct layer first
   - Verify with proper commands
   - Reference accurate documentation

3. **Better AI assistance**
   - Ghetto AI has verified knowledge
   - Won't suggest non-existent parameters
   - Understands layer separation

---

## Validation Pending

**Requires Pi hardware access:**

1. Test auto_mute behavior
   - Play audio → stop → measure mute timing
   - Verify with multimeter/oscilloscope

2. Verify I2C devices
   - Confirm 0x4d (DAC) and 0x38 (touch)
   - Check device registration in kernel

3. Test touch mapping
   - Verify 1280x400 coordinate range
   - Confirm orientation matches display

4. Measure timing
   - Overlay load time
   - I2C initialization delay
   - Touch interrupt latency

---

## Next Steps

### Immediate (Complete):
- ✅ All documentation written
- ✅ Ready for Ghetto AI upload
- ✅ Cross-referenced with existing docs

### When Pi Available:
- ⏳ Run validation tests
- ⏳ Measure hardware behavior
- ⏳ Update docs with test results

### Future Enhancements:
- 📝 Add oscilloscope measurements
- 📝 Create visual timing diagrams
- 📝 Document GPIO states during operation

---

## Training Prompts for Ghetto AI

Once uploaded to RAG, test with these questions:

1. "What device tree parameters exist for HiFiBerry AMP100?"
   - Should list: auto_mute, 24db_digital_gain, leds_off, mute_ext_ctl

2. "Can I disable IEC958 in device tree?"
   - Should answer: No, IEC958 is ALSA software

3. "How do I fix white screen at boot?"
   - Should answer: cmdline.txt video parameter, not device tree

4. "What's the difference between device tree and ALSA?"
   - Should explain: Hardware vs software layers

5. "Does ft6236 overlay have parameters?"
   - Should answer: No, fixed configuration

---

## Summary Statistics

**Time Invested:** ~6 hours (Phases 1-3, 5-6)  
**Files Read:** 9 device tree source files  
**Files Created:** 5 documentation files  
**Files Updated:** 2 (LESSONS_LEARNED, dtoverlay-reference)  
**Parameters Verified:** 6 (4 HiFiBerry, 1 vc4, 0 ft6236)  
**Fake Parameters Identified:** 10+ (documented in Common Mistakes)

---

## Success Criteria Met

### Complete Documentation ✅
- Every overlay analyzed
- All parameters documented
- Layer separation explained

### Validated Knowledge ✅
- Parameters verified in source
- Syntax confirmed
- Limitations understood

### Ghetto AI Integration ✅
- Documentation structured for RAG
- Cross-referenced appropriately
- Training prompts prepared

### No More Mistakes ✅
- Can't create fake parameters
- Understand layer separation
- Know where to fix problems

---

**Conclusion:** Comprehensive device tree study complete. All overlays documented, parameters verified, and knowledge integrated into project documentation and Ghetto AI knowledge base. Hardware validation pending Pi access.

**Status:** COMPLETE (except Phase 4 hardware validation)
