# 📋 Commands That Work From Home Directory

## ✅ All Commands Use Full Paths

**No need to `cd` first - all commands work from anywhere!**

---

## 🚀 Quick Start

### Build 36 (Requires sudo)
```bash
# Option 1: Full path with sudo (recommended)
sudo ~/moodeaudio-cursor/START_BUILD_36.sh

# Option 2: One-liner (cd + sudo)
cd ~/moodeaudio-cursor && sudo ./START_BUILD_36.sh

# Option 3: Via toolbox (requires sudo)
cd ~/moodeaudio-cursor && sudo ./tools/build.sh --build
```

---

## 🔨 Build Commands

```bash
# Start build
~/moodeaudio-cursor/START_BUILD_36.sh

# Or via toolbox
~/moodeaudio-cursor/tools/build.sh --build

# Monitor build
~/moodeaudio-cursor/tools/build.sh --monitor

# Validate build
~/moodeaudio-cursor/tools/build.sh --validate

# Deploy to SD card
~/moodeaudio-cursor/tools/build.sh --deploy

# Build status
~/moodeaudio-cursor/tools/build.sh --status
```

---

## 🧪 Test Commands

```bash
# Docker simulation
~/moodeaudio-cursor/tools/test.sh --docker

# Test image in Docker
~/moodeaudio-cursor/tools/test.sh --image

# Complete test suite
~/moodeaudio-cursor/complete_test_suite.sh
```

---

## 🛠️ Toolbox

```bash
# Interactive menu
~/moodeaudio-cursor/tools/toolbox.sh
```

---

## ⚡ Quick Start Script

**New!** Use `QUICK_START.sh` for easy access:

```bash
# Build
~/moodeaudio-cursor/QUICK_START.sh build

# Monitor
~/moodeaudio-cursor/QUICK_START.sh monitor

# Validate
~/moodeaudio-cursor/QUICK_START.sh validate

# Deploy
~/moodeaudio-cursor/QUICK_START.sh deploy

# Test
~/moodeaudio-cursor/QUICK_START.sh test

# Toolbox
~/moodeaudio-cursor/QUICK_START.sh toolbox
```

---

## 📝 Notes

- **All commands work from home directory** ✅
- **No `cd` needed** - full paths provided
- **Copy-paste ready** - just paste and run
- **Quick start script** - even easier access

---

**All future commands will work from anywhere! ✅**

