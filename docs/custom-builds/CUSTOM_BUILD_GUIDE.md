# 🔨 Custom Build Guide

## Overview

Custom builds use **pi-gen-64** to create fully customized moOde Audio images with all customizations integrated from the start.

---

## Quick Start

```bash
# Start build
./tools/build.sh --build

# Monitor build progress
./tools/build.sh --monitor

# Validate build
./tools/build.sh --validate

# Deploy to SD card
./tools/build.sh --deploy
```

---

## Build System

**Location:** `imgbuild/pi-gen-64/`

**Components:**
- `imgbuild/custom-components/` - Custom components
- `imgbuild/moode-cfg/` - moOde configuration
- `imgbuild/deploy/` - Built images

---

## Custom Features

### 1. User Configuration
- User: `andre` (UID 1000, GID 1000)
- Password: `0815`
- Sudo: NOPASSWD

### 2. Services (12 Services)
- `enable-ssh-early.service`
- `fix-ssh-sudoers.service`
- `fix-user-id.service`
- `localdisplay.service`
- `disable-console.service`
- `xserver-ready.service`
- `ft6236-delay.service`
- `i2c-monitor.service`
- `i2c-stabilize.service`
- `audio-optimize.service`
- `peppymeter.service`
- `peppymeter-extended-displays.service`

### 3. Scripts (10 Scripts)
- `start-chromium-clean.sh`
- `xserver-ready.sh`
- `worker-php-patch.sh`
- `i2c-stabilize.sh`
- `i2c-monitor.sh`
- `audio-optimize.sh`
- `pcm5122-oversampling.sh`
- `peppymeter-extended-displays.py`
- `generate-fir-filter.py`
- `analyze-measurement.py`

### 4. Hardware Support
- FT6236 touchscreen overlay
- HiFiBerry AMP100 overlay
- Display configuration (Waveshare 7.9")
- Network configuration

---

## Build Process

### 1. Pre-Build
```bash
# Verify Docker is running
docker info

# Check build system
ls -la imgbuild/pi-gen-64/
```

### 2. Build
```bash
# Start build
./tools/build.sh --build

# Or manually
cd imgbuild/pi-gen-64/
./build.sh
```

### 3. Post-Build
```bash
# Validate image
./tools/build.sh --validate

# Test in Docker
./tools/test.sh --image

# Deploy to SD card
./tools/build.sh --deploy
```

---

## Testing

### Docker Test Suite
```bash
# Run complete test suite
./complete_test_suite.sh

# Run Docker simulation
./tools/test.sh --docker

# Test image in container
./tools/test.sh --image
```

### What Gets Tested
- ✅ User configuration
- ✅ All 12 services
- ✅ All 10 scripts
- ✅ Boot configuration
- ✅ Display simulation
- ✅ Audio simulation

---

## Build History

### Build 35 (Latest)
- **Image:** `moode-r1001-arm64-build-35-20251209_234258.img`
- **Status:** ✅ Deployed
- **Features:**
  - Custom user (andre, UID 1000)
  - All 12 services integrated
  - All 10 scripts integrated
  - Display configuration
  - Network configuration

### Build 36 (Planned)
- **Status:** 🔄 Planning
- **Improvements:**
  - TBD based on Build 35 testing

---

## Troubleshooting

### Build Fails
```bash
# Check Docker
docker info

# Check logs
tail -f imgbuild/deploy/build-*.log

# Clean and rebuild
cd imgbuild/pi-gen-64/
./build.sh clean
./build.sh
```

### Image Validation Fails
```bash
# Check image size
ls -lh imgbuild/deploy/*.img

# Verify image format
file imgbuild/deploy/*.img
```

---

## Documentation

- **`CUSTOM_BUILD_NEXT_STEPS.md`** - Next steps guide
- **`BUILD_36_TEST_SUITE_FINDINGS.md`** - Test findings
- **`TEST_SUITE_DOCKER_SUMMARY.md`** - Docker test suite

---

**Custom builds provide full control and faster development cycles! 🚀**

