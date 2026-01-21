# WISSENSBASIS - Knowledge Base Index

**Project:** moOde Audio Ghettoblaster  
**System:** Raspberry Pi 5 + HiFiBerry AMP100 + Waveshare 1280x400  
**Last Updated:** 2026-01-21

---

## 🎯 PRIMARY REFERENCES (READ THESE FIRST)

### **→ DEVELOPMENT_WORKFLOW.md ←**
**HOW to work on this system - READ BEFORE ANY TASK**

The sustainable development methodology:
- ✅ 5-phase workflow (Understand → Research → Design → Implement → Verify)
- ✅ Knowledge-first approach (no blind fixes)
- ✅ Anti-patterns to avoid (La La La, Script Hacks, Root Cause Claims)
- ✅ GitHub integration strategy
- ✅ Gap-filling methodology
- ✅ Quality gates and success metrics

**Read this BEFORE starting ANY new task.**

### **→ MASTER_MOODE_ARCHITECTURE.md ←**
**WHAT the system is - Complete architecture reference**

Complete moOde architecture from reading EVERY line of relevant code:
- ✅ Complete display system architecture
- ✅ Complete audio chain architecture  
- ✅ All PHP code flows (worker, peripheral, audio, mpd, etc.)
- ✅ Boot chain (cmdline.txt → config.txt → systemd → xinit)
- ✅ Database configuration
- ✅ Renderer integration
- ✅ Lessons learned
- ✅ Current system status
- ✅ 23 files, ~23,000 lines of code analyzed

**Read this to understand how moOde works.**

---

## 📚 SUPPLEMENTARY DOCUMENTATION

### Audio System Details
- `150_MOODE_COMPLETE_AUDIO_SYSTEM_ARCHITECTURE.md` - Deep dive into audio chain
- `156_MOODE_VOLUME_CONTROL_COMPLETE_ARCHITECTURE.md` - Volume control system
- `146_MOODE_AUDIO_CHAIN_ARCHITECTURE.md` - ALSA routing details

### Build & Configuration
- `131_BUILD_READY_CHECKLIST.md` - Pre-build verification
- `140_FINAL_BUILD_SUMMARY.md` - Build summary

### Troubleshooting Guides
- `149_MOODE_AUDIO_DEVICE_DETECTION_BUG_ROOT_CAUSE.md` - Audio device bug fix
- `144_MOODE_WORKER_AUDIO_DETECTION_BUG.md` - Worker.php bug analysis

### Future Features
- `141_IR_REMOTE_DAB_INTEGRATION_PLAN.md` - IR receiver + DAB+ radio plan
- `142_BOSE_WAVE_WAVEGUIDE_PHYSICS_ANALYSIS.md` - Acoustics analysis

---

## 🗑️ DEPRECATED/REDUNDANT DOCUMENTATION

**The following documents are redundant with MASTER_MOODE_ARCHITECTURE.md:**

- ~~`COMPLETE_DISPLAY_ARCHITECTURE.md`~~ → Merged into MASTER
- ~~`154_MOODE_COMPLETE_SYSTEM_OVERVIEW.md`~~ → Merged into MASTER
- ~~`155_MASTER_ARCHITECTURE_REFERENCE.md`~~ → Merged into MASTER
- ~~`151_MOODE_ENGINE_COMMUNICATION_ARCHITECTURE.md`~~ → Covered in MASTER
- ~~`147_MOODE_COMPLETE_ANALYSIS_SUMMARY.md`~~ → Outdated
- ~~`145_MOODE_NETWORK_ARCHITECTURE.md`~~ → Not critical for this system

**Action:** Consider archiving these to reduce confusion.

---

## 📋 QUICK REFERENCE

**Understanding the System:**
1. Read `MASTER_MOODE_ARCHITECTURE.md` (complete understanding)
2. Check specific topics in supplementary docs if needed

**Building the System:**
1. `131_BUILD_READY_CHECKLIST.md`
2. `140_FINAL_BUILD_SUMMARY.md`

**Troubleshooting:**
1. Check MASTER document first
2. Review specific bug analysis docs if needed

---

## 🎵 System Overview

### Hardware
```
Raspberry Pi 5 (8GB)
├── HiFiBerry AMP100 (I2S audio)
├── Waveshare 7.9" 1280x400 Display (HDMI-2)
└── FT6236 Touch Controller (USB)
```

### Software
```
Raspberry Pi OS Trixie (Debian 13) 64-bit
├── moOde Audio r1001
├── CamillaDSP 2.0.3
└── All renderers: Bluetooth, AirPlay, Spotify, etc.
```

### Audio Chain
```
MPD → [CamillaDSP/EQ] → _audioout → HiFiBerry AMP100 → Speakers
```

---

**Total Active Documents:** ~16 (2 primary + 14 supplementary)  
**System Status:** Production-ready, fully documented  
**Code Analysis:** Complete (23 files, ~23,000 lines read completely)  
**Development Methodology:** Defined and documented
