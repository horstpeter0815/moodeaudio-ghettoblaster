# moOde Audio Ghettoblaster

**Custom Raspberry Pi 5 Audio System with Bose Wave Drivers**

---

## 🎵 System Overview

High-quality audio streaming system built on Raspberry Pi 5, featuring:
- **moOde Audio Player** r1001 (Debian 13 Trixie)
- **Bose Wave True Stereo** audio processing with L/R channel separation
- **HiFiBerry AMP100** professional audio HAT
- **1280x400 landscape touchscreen** display
- **11 streaming services** (AirPlay, Spotify, Bluetooth, UPnP/DLNA, etc.)
- **Room EQ Wizard integration** for acoustic optimization
- **PeppyMeter** VU visualization

---

## 🎯 Quick Start

### Build Custom Image

```bash
cd imgbuild
sudo ./build-macos.sh 2>&1 | tee "build-$(date +%Y%m%d_%H%M%S).log"
```

**Build time:** 1-2 hours  
**Output:** `imgbuild/pi-gen-64/deploy/image_moode-*.zip`

### Flash to SD Card

```bash
cd scripts/deployment
sudo ./burn-ghettoblaster-to-sd.sh
```

### First Boot

1. Insert SD card into Raspberry Pi 5
2. Connect display (HDMI), touchscreen (USB), audio HAT (GPIO)
3. Power on
4. System auto-configures on first boot
5. Access moOde UI: `http://moode.local` or touchscreen

**Default credentials:**
- User: `andre`
- Password: `0815`
- SSH: Enabled

---

## 🔧 Hardware Configuration

### Required Components

```
Raspberry Pi 5 (8GB)                    ~$80
HiFiBerry AMP100 HAT                    ~$60
1280x400 IPS Display (HDMI)             ~$40
WaveShare USB Touchscreen               ~$20
Bose Wave Drivers (salvaged)            ~$0
MicroSD Card (32GB minimum)             ~$10
Power Supply (5V 5A USB-C)              ~$15
────────────────────────────────────────────
Total:                                  ~$225
```

### Connections

```
Raspberry Pi 5
├── GPIO Header → HiFiBerry AMP100 HAT
│   ├── I2C: PCM5122 control (0x4d)
│   ├── I2S: Audio data
│   └── DSP: Optional DSP add-on board
├── HDMI → 1280x400 Display (landscape)
├── USB #1 → WaveShare Touch (HID)
└── USB #2 → Available for DAB+ or IR receiver
```

---

## 🎛️ Audio System

### Bose Wave True Stereo Configuration

**300 Hz Linkwitz-Riley crossover** splits audio:
- **Left Channel (Bass):** 40-300 Hz with waveguide compensation
- **Right Channel (Mids/Highs):** 300-12000 Hz direct driver

**Features:**
- ✅ Sub-bass boost (+10dB @ 40Hz)
- ✅ Bass body (+4dB @ 80Hz)
- ✅ Presence boost (+2dB @ 2.5kHz)
- ✅ Brilliance (+4dB @ 5kHz)
- ✅ Air enhancement (+2.5dB @ 12kHz)
- ✅ Resonance fixes (8 notch filters)

### Supported Services (11)

1. **MPD** - Music Player Daemon (local playback)
2. **AirPlay** - Apple device streaming (fixed!)
3. **Spotify** - Spotify Connect + librespot
4. **Bluetooth** - Bluetooth audio input
5. **Squeezelite** - Logitech Media Server client
6. **Snapcast** - Multi-room audio
7. **UPnP/DLNA** - upmpdcli (+ Qobuz, Tidal)
8. **NQPTP** - Network time for AirPlay
9. **MPRIS** - Media control interface

---

## 📖 Documentation

### Build System
- `imgbuild/BUILD_PLAN.md` - Build process overview
- `imgbuild/COMPONENTS_CHECKLIST.md` - Component verification
- `WISSENSBASIS/140_FINAL_BUILD_SUMMARY.md` - Complete build summary

### Configuration
- `WISSENSBASIS/138_AUDIO_CONFIGURATION_SUMMARY.md` - Audio details
- `WISSENSBASIS/137_SERVICES_REPOSITORIES_SUMMARY.md` - Service info
- `WISSENSBASIS/141_IR_REMOTE_DAB_INTEGRATION_PLAN.md` - Future features

### Reference
- `WISSENSBASIS/000_INDEX.md` - Complete documentation index
- `scripts/README.md` - Production scripts
- `tools/README.md` - Development tools

---

## 🚀 Features

### Current (v1.1)
- ✅ Custom Raspberry Pi OS image with moOde
- ✅ Bose Wave True Stereo audio processing
- ✅ 1280x400 landscape touchscreen UI
- ✅ 100+ radio stations pre-loaded
- ✅ Room EQ Wizard integration
- ✅ PeppyMeter VU visualization
- ✅ CamillaDSP with Bose filters (enabled by default)
- ✅ 11 streaming services
- ✅ Clean boot (no splash screens)
- ✅ Auto-configuration on first boot

### Planned (v1.2)
- 🔄 IR receiver for Bose Wave remote control
- 🔄 DAB+ digital radio integration
- 🔄 Multi-room audio expansion
- 🔄 Voice control (Alexa/Google Assistant)

---

## 🛠️ Development

### Directory Structure

```
moodeaudio-cursor/
├── imgbuild/           # Build system (pi-gen based)
│   ├── moode-cfg/     # Custom build configuration
│   └── deploy/        # Build output (images)
├── moode-source/      # Custom components
│   ├── boot/          # Boot configs (config.txt, cmdline.txt)
│   ├── usr/           # System files and scripts
│   └── lib/           # Systemd services
├── scripts/           # Production scripts
│   ├── deployment/    # SD card burning
│   ├── audio/         # Audio setup
│   ├── display/       # Display config
│   └── system/        # System maintenance
├── tools/             # Development tools
│   ├── build/         # Build helpers
│   ├── debug/         # Debugging tools
│   └── config/        # Configuration tools
├── WISSENSBASIS/      # Knowledge base (157 docs)
└── docs/              # Official documentation
```

### Build Environment

**Host:** macOS (Apple Silicon or Intel)  
**Build:** Docker-based (Linux container)  
**Base:** Raspberry Pi OS Trixie (Debian 13)  
**Target:** Raspberry Pi 5 (64-bit ARM)

### Key Technologies
- **pi-gen** - Raspberry Pi image builder
- **moOde** - Audiophile music player
- **CamillaDSP** - Real-time audio processing
- **ALSA** - Linux audio subsystem
- **X11** - Display server
- **Chromium** - WebUI renderer (kiosk mode)

---

## 📝 Changelog

### v1.1 (2026-01-19)
- ✅ Major cleanup: Production-ready workspace
- ✅ Bose Wave True Stereo as default (L/R separation)
- ✅ Fixed syntax errors in build scripts
- ✅ Organized scripts/ and tools/ directories
- ✅ Consolidated documentation (WISSENSBASIS index)
- ✅ Removed 43 duplicate config files
- ✅ Added IR/DAB+ integration plan
- ✅ GitHub maintenance and tagging

### v1.0 (2026-01-08)
- ✅ Initial working system
- ✅ Landscape display 1280x400
- ✅ Basic Bose Wave filters
- ✅ moOde r1001 integration

---

## 🤝 Contributing

This is a personal project, but feel free to:
- Report issues
- Suggest improvements
- Fork for your own builds

### Development Workflow

1. Make changes in workspace
2. Test on hardware
3. Document in WISSENSBASIS
4. Update build scripts
5. Test full build
6. Commit and tag

---

## 📜 License

This project combines multiple open-source components:
- **moOde Audio Player:** GPLv3
- **pi-gen:** BSD 3-Clause
- **CamillaDSP:** GPLv3
- **Custom scripts:** GPLv3

See individual component licenses for details.

---

## 🔗 Links

- **moOde Audio:** https://moodeaudio.org/
- **HiFiBerry:** https://www.hifiberry.com/
- **CamillaDSP:** https://github.com/HEnquist/camilladsp
- **Room EQ Wizard:** https://www.roomeqwizard.com/
- **pi-gen:** https://github.com/RPi-Distro/pi-gen

---

## 📞 Support

For questions or issues:
1. Check `WISSENSBASIS/000_INDEX.md` for documentation
2. Review build logs in `imgbuild/*.log`
3. Use debug tools in `tools/debug/`

---

**Status:** Production-ready v1.1  
**Build:** In progress (Bose Wave True Stereo + all fixes)  
**Last Updated:** 2026-01-19

🎵 **Enjoy the music!** 🎵
