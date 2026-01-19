# WISSENSBASIS - Knowledge Base Index

**Project:** moOde Audio Ghettoblaster  
**System:** Raspberry Pi 5 + HiFiBerry AMP100 + Bose Wave Drivers  
**Version:** v1.1  
**Last Updated:** 2026-01-19

---

## 🎯 ACTIVE DOCUMENTATION (Current System)

### Build & Configuration
- `131_BUILD_READY_CHECKLIST.md` - Pre-build verification
- `132_BOOT_CONFIGURATION_CLEAN.md` - Boot parameters
- `133_CRITICAL_CONFIG_DIFFERENCES.md` - v1.0 vs current
- `134_COMPREHENSIVE_BUILD_REVIEW.md` - Full build review
- `140_FINAL_BUILD_SUMMARY.md` - Build summary v1.1

### Audio System
- `137_SERVICES_REPOSITORIES_SUMMARY.md` - All 11 audio services
- `138_AUDIO_CONFIGURATION_SUMMARY.md` - Audio chain details
- `139_IEC958_CONFIGURATION.md` - S/PDIF configuration

### Display System
- `129_DISPLAY_CHAIN_SOURCE_CODE_STUDY.md` - Display architecture
- `135_DEVICE_TREE_OVERLAYS.md` - Device tree config
- `136_USB_TOUCH_NO_I2C.md` - USB touchscreen details

### Future Features
- `141_IR_REMOTE_DAB_INTEGRATION_PLAN.md` - IR receiver + DAB+ radio plan

---

## 📚 REFERENCE DOCUMENTATION (Background Info)

### moOde UI Architecture
- `128_MOODE_UI_ARCHITECTURE_BUTTON_HANDLERS.md` - UI event system

### Audio Chain Analysis
- `132_AUDIO_CHAIN_ANALYSIS.md` - Audio routing details
- `133_BASE_FILTER_ARCHITECTURE_ANALYSIS.md` - Filter architecture
- `134_BASE_FILTER_IMPLEMENTATION_PLAN.md` - Filter implementation

### Room EQ System
- `135_ROOM_EQ_MEASUREMENT_WORKFLOW.md` - REW measurement process
- `136_PRACTICAL_ROOM_EQ_WORKFLOW.md` - Practical REW usage

---

## 🗄️ ARCHIVED DOCUMENTATION (Historical)

*Moved to `.archive/` - kept for reference but not actively maintained*

### Old Troubleshooting Guides
- Display orientation fixes (multiple attempts) → SOLVED in v1.0
- Network configuration issues → SOLVED
- Audio chain debugging → SOLVED with Bose Wave True Stereo

### Build Iterations
- Multiple build attempts documentation → Consolidated into v1.1
- Trial-and-error fixes → Replaced with working config

---

## 📋 DOCUMENT STATUS LEGEND

- **[ACTIVE]** - Current system documentation, keep updated
- **[REFERENCE]** - Background info, useful but not critical
- **[ARCHIVED]** - Historical, moved to `.archive/`
- **[PLANNED]** - Future features, not yet implemented

---

## 🎵 System Overview

### Hardware Configuration
```
Raspberry Pi 5 (8GB)
├── GPIO Header
│   ├── HiFiBerry AMP100 HAT (I2C + I2S)
│   │   └── PCM5122 DAC (0x4d)
│   └── [Future: IR Receiver on GPIO 18]
├── HDMI → 1280x400 Display (landscape)
├── USB #1 → WaveShare Touch (HID)
└── USB #2 → [Future: DAB+ receiver]
```

### Audio Chain
```
MPD (Music Player Daemon)
  ↓
CamillaDSP (Bose Wave True Stereo - 300 Hz crossover)
  ├─ Left Channel → Bass driver (40-300 Hz)
  └─ Right Channel → Mids/Highs driver (300-12000 Hz)
  ↓
ALSA (plughw:1,0)
  ↓
HiFiBerry AMP100 (I2S)
  ↓
Bose Wave Drivers
```

### Software Stack
- **OS:** Raspberry Pi OS Trixie (Debian 13) 64-bit
- **Audio Player:** moOde Audio r1001
- **DSP:** CamillaDSP 2.0.3
- **Services:** 11 streaming services (MPD, AirPlay, Spotify, etc.)
- **UI:** Chromium kiosk mode (1280x400 landscape)
- **Visualization:** PeppyMeter (VU meters)

---

## 📂 Related Documentation

### Root Directory
- `README.md` - Project overview
- `CLEANUP_PLAN.md` - Workspace organization
- `PROJECT_STATUS_V1.0.md` - v1.0 status (reference)

### Build Directory
- `imgbuild/BUILD_PLAN.md` - Build process
- `imgbuild/COMPONENTS_CHECKLIST.md` - Component verification
- `imgbuild/KICK_OFF_BUILD.sh` - Build starter script

### Scripts & Tools
- `scripts/README.md` - Production scripts index
- `tools/README.md` - Development tools index

---

## 🔄 Maintenance Schedule

### After Each Build
- [ ] Update build status in `140_FINAL_BUILD_SUMMARY.md`
- [ ] Tag git commit: `v1.x-working`
- [ ] Test all components
- [ ] Update COMPONENTS_CHECKLIST.md

### Monthly
- [ ] Review and archive old docs
- [ ] Update service versions (137_SERVICES_REPOSITORIES_SUMMARY.md)
- [ ] Check for moOde updates

### As Needed
- [ ] Add new features to WISSENSBASIS
- [ ] Update integration plans (IR/DAB+)
- [ ] Document any configuration changes

---

## 🎯 Quick Links

**Most Used Docs:**
1. Build Summary → `140_FINAL_BUILD_SUMMARY.md`
2. Audio Config → `138_AUDIO_CONFIGURATION_SUMMARY.md`
3. Build Checklist → `131_BUILD_READY_CHECKLIST.md`
4. IR/DAB+ Plan → `141_IR_REMOTE_DAB_INTEGRATION_PLAN.md`

**Troubleshooting:**
1. Audio Chain → `132_AUDIO_CHAIN_ANALYSIS.md`
2. Display Issues → `129_DISPLAY_CHAIN_SOURCE_CODE_STUDY.md`
3. Device Tree → `135_DEVICE_TREE_OVERLAYS.md`

---

**Total Documents:** 157 (15 active, 20 reference, 122 archived)  
**System Status:** Production-ready v1.1  
**Build:** In progress (Bose Wave True Stereo + all fixes)
