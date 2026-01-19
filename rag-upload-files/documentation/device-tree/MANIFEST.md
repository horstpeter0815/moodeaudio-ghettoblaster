# Device Tree Documentation Manifest

## Overview

This directory contains comprehensive documentation for all device tree overlays used in the Ghettoblaster system.

**Study Completed:** 2026-01-18
**Phase Completed:** Phase 1 (Inventory) + Phase 2 (Deep Analysis)

## Documentation Files

### 1. DEVICE_TREE_OVERVIEW.md
**Purpose:** High-level introduction to device tree concepts

**Contents:**
- What is device tree?
- Device tree vs software layers (ALSA, MPD, X11)
- Layer architecture
- How overlays work
- Common mistakes overview
- Best practices

**Who should read:** Anyone new to device tree or troubleshooting hardware issues

### 2. HIFIBERRY_AMP100_DTO.md
**Purpose:** Detailed analysis of HiFiBerry AMP100 overlay

**Contents:**
- Hardware components (PCM5122 DAC)
- Fragment-by-fragment analysis
- Available parameters (24db_digital_gain, slave, leds_off)
- Custom parameters (auto_mute, mute_ext_ctl)
- Pi 5 compatibility
- Comparison: upstream vs custom overlays
- Verification commands

**Who should read:** Anyone configuring audio, troubleshooting DAC issues

### 3. VC4_KMS_DTO.md
**Purpose:** Display overlay analysis

**Contents:**
- What is KMS (Kernel Mode Setting)?
- Hardware components enabled
- Parameters (audio, noaudio, composite, nohdmi)
- Pi 5 vs Pi 4 differences
- What this overlay does NOT do (rotation, resolution)
- Common display issues

**Who should read:** Anyone troubleshooting display issues, understanding boot screen vs runtime

### 4. COMMON_MISTAKES.md
**Purpose:** Catalog of common device tree mistakes

**Contents:**
- 10 common mistakes with explanations
- Why each mistake is wrong
- Correct approach for each
- Layer identification guide
- Quick reference: What layer fixes what problem

**Who should read:** EVERYONE - prevents repeating past mistakes

### 5. PARAMETERS_REFERENCE.md
**Purpose:** Quick reference for all available parameters

**Contents:**
- All HiFiBerry parameters
- All vc4-kms parameters
- dtparam built-in parameters
- Parameter types (boolean vs value)
- Common combinations
- Parameters that do NOT exist
- How to find available parameters

**Who should read:** When modifying config.txt, when parameters aren't working

### 6. VISUAL_DIAGRAMS.md
**Purpose:** Visual representations of system architecture

**Contents:**
- Hardware layer diagram (complete component layout)
- Layer separation diagram (what each layer controls)
- Audio signal flow (source to speakers)
- Display signal flow (boot to runtime)
- Boot sequence diagram (power-on to UI ready)
- I2C bus architecture (device addressing)
- Device tree loading process (overlay application)
- Parameter resolution flow (how dtoverlay parameters work)

**Who should read:** Visual learners, presentations, teaching, troubleshooting signal paths

### 7. AI_TRAINING_PROMPTS.md
**Purpose:** Training questions and answers for AI assistants

**Contents:**
- 20 test questions across 7 categories
- Basic understanding, parameter knowledge, layer separation
- Troubleshooting scenarios, best practices, advanced concepts
- Common mistakes with correct/incorrect responses
- Success metrics for AI training

**Who should read:** When training AI assistants, RAG system setup, validating AI knowledge

## Key Learnings Summary

### Critical Concept: Layer Separation

```
Hardware Layer (Device Tree):
- Initializes I2C, I2S, GPIO
- Creates device nodes
- Enables hardware

Software Layer (ALSA/MPD/X11):
- Audio routing (IEC958)
- Volume control
- Display rotation
- Application configuration
```

**Most mistakes = Trying to fix software problems with hardware configuration**

### What Device Tree Controls

✅ I2C device initialization (PCM5122, FT6236)
✅ I2S interface enabling  
✅ GPIO pin functions
✅ Clock sources
✅ Power supply connections

### What Device Tree Does NOT Control

❌ ALSA routing (IEC958/SPDIF)
❌ Display rotation (cmdline.txt + xrandr)
❌ Volume levels (ALSA/MPD)
❌ Audio formats (ALSA/MPD)
❌ Application settings (moOde database)

## Overlays in v1.0 Working Config

From `v1.0-config-export/config.txt.working`:

```ini
dtoverlay=vc4-kms-v3d-pi5,noaudio    # Display with HDMI audio disabled
dtoverlay=hifiberry-amp100            # Audio HAT
```

**Analysis:**
- Uses stock upstream overlays (not custom)
- No touch overlay in config.txt (touch works through other means)
- No custom parameters (no auto_mute)
- Proves stock overlays are sufficient for basic operation

## Parameters That Actually Exist

### HiFiBerry (Upstream)
- `24db_digital_gain` - Enable 24dB digital gain
- `slave` - Switch to clock producer mode
- `leds_off` - Disable LEDs

### HiFiBerry (Custom Pi 5 Variants)
- `auto_mute` - Auto-mute on silence
- `mute_ext_ctl` - GPIO for external mute

### vc4-kms-v3d-pi5
- `noaudio` - Disable HDMI audio (most important for Ghettoblaster)
- `audio`, `audio1` - Enable HDMI audio per port
- `composite` - Enable composite video
- `nohdmi`, `nohdmi0`, `nohdmi1` - Disable HDMI ports

## Parameters That Do NOT Exist

These were attempted in past fixes but **do not exist**:

❌ `disable_iec958` - IEC958 is ALSA software
❌ `rotation` - Rotation is cmdline.txt + xrandr  
❌ `volume` - Volume is ALSA/MPD
❌ `automute` - Typo, should be auto_mute
❌ `gain` - Wrong name, should be 24db_digital_gain

## Files Organization

```
rag-upload-files/documentation/device-tree/
├── DEVICE_TREE_OVERVIEW.md       # Start here - concepts and basics
├── HIFIBERRY_AMP100_DTO.md       # Audio overlay deep dive
├── VC4_KMS_DTO.md                # Display overlay analysis
├── COMMON_MISTAKES.md            # What NOT to do (critical!)
├── PARAMETERS_REFERENCE.md       # Quick parameter lookup
├── VISUAL_DIAGRAMS.md            # Mermaid diagrams (8 diagrams)
├── AI_TRAINING_PROMPTS.md        # AI training Q&A (20 questions)
└── MANIFEST.md                   # This file

device-tree-study/
├── PHASE_1_2_COMPLETE.md         # Initial study completion summary
├── OVERLAY_COMPARISON_DETAILED.md # Custom vs upstream comparison
└── upstream-overlays/             # Downloaded upstream sources
    ├── hifiberry-dacplus-overlay.dts
    ├── vc4-kms-v3d-overlay.dts
    └── vc4-kms-v3d-pi5-overlay.dts

WISSENSBASIS/
└── 125_DEVICE_TREE_STUDY_COMPLETE.md  # Complete master reference
```

## Completed Phases (2026-01-18)

### ✅ Phase 1: Inventory All Overlays (Complete)
- Identified all overlays in v1.0 working config
- Located 9 local .dts source files
- Downloaded upstream overlays for comparison

### ✅ Phase 2: Deep Analysis (Complete)
- Fragment-by-fragment overlay analysis
- Parameter discovery and documentation
- Pi 5 compatibility analysis
- Created master reference document (5,300+ lines)

### ✅ Phase 3: Compare with Stock Overlays (Complete)
- Detailed line-by-line diff analysis
- Custom vs upstream comparison document (4,000+ lines)
- Migration paths documented (custom ↔ upstream)
- Recommendations for each use case

### ✅ Phase 5: Documentation Output (Complete)
- Created 8 comprehensive visual diagrams (mermaid)
- Hardware architecture, signal flows, boot sequence
- Layer separation and device tree process diagrams
- Ready for presentations and teaching

### ✅ Phase 6: AI Integration Preparation (Complete)
- 20 training questions across 7 categories
- Test scenarios with correct/incorrect responses
- Success metrics for AI validation
- Ready for RAG upload

## Remaining Work (Optional)

### Phase 4: Validation on Pi Hardware (2-4 hours)
- Test each parameter on actual Pi
- Document observable behavior
- Verify auto_mute functionality
- Measure GPIO states
- Create automated test scripts

**When needed:** Before recommending parameter changes, validating custom overlays

## Verification Checklist

After reading these docs, you should be able to:

- ✅ Explain what device tree controls vs ALSA vs X11
- ✅ Find available parameters for any overlay
- ✅ Verify overlay loading with i2cdetect and aplay
- ✅ Identify which layer a problem belongs to
- ✅ Fix problems at the correct layer
- ✅ Avoid making up non-existent parameters

## Success Metrics

This documentation achieves:

1. ✅ Complete inventory of all overlays in use
2. ✅ Deep analysis of each overlay (fragments, parameters)
3. ✅ Comparison with upstream overlays
4. ✅ Clear layer separation explained
5. ✅ Common mistakes cataloged with corrections
6. ✅ Quick reference for all parameters
7. ✅ Ready for RAG upload (when needed)

## Questions This Documentation Answers

- **"What device tree parameters exist for HiFiBerry AMP100?"** → HIFIBERRY_AMP100_DTO.md
- **"Can I disable IEC958 in device tree?"** → COMMON_MISTAKES.md (No, it's ALSA)
- **"How do I fix white screen at boot?"** → VC4_KMS_DTO.md (cmdline.txt, not device tree)
- **"What's the difference between device tree and ALSA?"** → DEVICE_TREE_OVERVIEW.md
- **"Why isn't my parameter working?"** → PARAMETERS_REFERENCE.md (check if it exists)

## References

- Upstream overlays: https://github.com/raspberrypi/linux/tree/rpi-6.6.y/arch/arm/boot/dts/overlays
- Device tree spec: https://www.devicetree.org/
- Raspberry Pi overlay README: /boot/firmware/overlays/README
- PCM5122 datasheet: https://www.ti.com/product/PCM5122

---

**Status:** Phase 1 & 2 Complete | Phase 3-5 Available for Future Work
