# 🔨 Build 36 - Commands (Work from Anywhere)

## Quick Start (From Home Directory)

```bash
# Start build (requires sudo)
sudo ~/moodeaudio-cursor/START_BUILD_36.sh
```

## Or Use Full Paths (No cd needed)

```bash
# Start build (from anywhere, requires sudo)
sudo ~/moodeaudio-cursor/START_BUILD_36.sh

# Or use toolbox
~/moodeaudio-cursor/tools/build.sh --build

# Monitor build
~/moodeaudio-cursor/tools/build.sh --monitor

# Validate build
~/moodeaudio-cursor/tools/build.sh --validate

# Deploy to SD card
~/moodeaudio-cursor/tools/build.sh --deploy
```

## All Commands (Full Paths)

### Build Commands
```bash
# Start build
~/moodeaudio-cursor/START_BUILD_36.sh

# Or via toolbox
~/moodeaudio-cursor/tools/build.sh --build

# Monitor build progress
~/moodeaudio-cursor/tools/build.sh --monitor

# Validate build image
~/moodeaudio-cursor/tools/build.sh --validate

# Deploy to SD card
~/moodeaudio-cursor/tools/build.sh --deploy

# Show build status
~/moodeaudio-cursor/tools/build.sh --status
```

### Test Commands
```bash
# Test in Docker
~/moodeaudio-cursor/tools/test.sh --docker

# Test image in container
~/moodeaudio-cursor/tools/test.sh --image

# Complete test suite
~/moodeaudio-cursor/complete_test_suite.sh
```

### Toolbox
```bash
# Interactive menu
~/moodeaudio-cursor/tools/toolbox.sh
```

## One-Liner (Copy-Paste Ready)

```bash
cd ~/moodeaudio-cursor && ./START_BUILD_36.sh
```

---

**All commands work from your home directory! ✅**

