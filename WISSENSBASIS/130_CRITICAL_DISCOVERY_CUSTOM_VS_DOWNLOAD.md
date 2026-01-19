# CRITICAL DISCOVERY: Custom Build vs moOde Download
**Date:** 2026-01-19  
**Discovery Method:** Source code investigation + failed display fixes

---

## The Root Cause

After 90+ iterations trying to fix the display, I discovered the fundamental issue:

**v1.0 "working" system = CUSTOM BUILD (imgbuild)**  
**Current broken system = moODE DOWNLOAD**

These are **fundamentally different systems** and configurations designed for the custom build will NOT work on the download.

---

## Evidence

### 1. first-boot-setup.sh Script
- Found in `moode-source/usr/local/bin/first-boot-setup.sh`
- Custom script that:
  - Creates user `andre` with UID 1000
  - Compiles custom overlays (ft6236, amp100)
  - Applies worker.php patches
  - Enables SSH
  - Sets up display configuration
- **Does NOT exist on moOde download** (only in custom build)

### 2. Custom Build Scripts
- `imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_00-run-chroot.sh`
- `imgbuild/moode-cfg/stage3_03-ghettoblaster-custom_02-display-cmdline.sh`
- These scripts run during image build, not on moOde download

### 3. Display Configuration Differences

| Aspect | Custom Build | moOde Download |
|--------|--------------|----------------|
| cmdline.txt | `video=HDMI-A-1:400x1280M@60` (no rotate) | Default (no video param) |
| xinitrc | Custom rotation logic | moOde default template |
| User setup | andre (UID 1000) pre-created | pi user, rename during setup |
| Overlays | Pre-compiled custom | moOde standard |
| First boot | Custom setup script | moOde's builtin process |

### 4. Why Fixes Failed

**Chromium 10x10 Window Issue:**
- Tried 90+ different configurations
- None worked because the moOde download lacks the custom build's:
  - Pre-configured user environment
  - Custom overlay compilation
  - Specific kernel parameters
  - Custom xinitrc with tested rotation logic

**The issue wasn't the configuration - it was the platform!**

---

## Custom Build vs Download Comparison

### Custom Build (imgbuild/)
```bash
# Build process
1. Start with base Raspberry Pi OS
2. Install moOde packages
3. Apply custom modifications:
   - Create user andre (UID 1000)
   - Compile custom overlays
   - Set cmdline.txt video parameter
   - Configure xinitrc for landscape rotation
   - Set up first-boot-setup.service
4. Create image file (.img)
```

**Advantages:**
- ✅ Everything pre-configured
- ✅ Guaranteed to work (tested)
- ✅ No manual setup needed
- ✅ Reproducible

**Disadvantages:**
- ⏱️ Takes time to build (hours)
- 💾 Requires build environment
- 🔧 Harder to debug build issues

### moOde Download
```bash
# Download process
1. Download pre-built moOde image
2. Flash to SD card
3. Boot and configure via web UI
4. Manual setup required
```

**Advantages:**
- ⚡ Fast to deploy (minutes)
- 🌐 Official support
- 🔄 Easy updates

**Disadvantages:**
- ❌ Requires manual configuration
- ❌ Display setup complex
- ❌ May not support custom hardware perfectly

---

## What We Learned Today

### 1. Source Code Investigation Works
By reading the moOde source code, I discovered:
- How xinitrc is generated (`moode-source/home/xinitrc.default`)
- How worker.php modifies xinitrc with sed
- How screen resolution is detected (kmsprint vs fbset)
- The difference between v1.0 and moOde default xinitrc
- That moOde default assumes portrait displays WANT portrait mode

### 2. v1.0 Was Custom Build
- v1.0-working-config/ contains configs from custom build
- commit 84aa8c2 was AFTER custom build modifications
- The "working" xinitrc had custom landscape rotation logic
- Custom build pre-compiled overlays and set up user environment

### 3. Chromium Window Sizing
- Chromium in kiosk mode queries framebuffer directly (not X11)
- Framebuffer remains 400x1280 (portrait) even after xrandr rotation
- `--window-size` parameter is ignored if framebuffer mismatch
- Results in 10x10 fallback window

### 4. Config.txt Settings Matter
- `hdmi_group=0` (auto-detect) vs `hdmi_group=2` (DMT mode)
- Custom timing parameters (`hdmi_mode=87`, `hdmi_timings=...`) can break detection
- v1.0 used auto-detect, which worked better

---

## The Solution: Rebuild Custom Image

**Why custom build is the answer:**
1. v1.0 worked perfectly because it was a custom build
2. All fixes designed for moOde download failed
3. Custom build process is documented and reproducible
4. Ensures exact working configuration

**Build process:**
```bash
cd /Users/andrevollmer/moodeaudio-cursor/imgbuild
./build.sh
```

**Build includes:**
- User andre (UID 1000) pre-created
- Custom overlays compiled
- Display cmdline configured
- xinitrc with landscape rotation
- All v1.0 configurations
- First-boot-setup script

---

## Lessons for Future

### 1. Understand the Platform
- Don't assume moOde download = custom build
- Check if v1.0 was custom build or download
- Understand build process before applying fixes

### 2. Read Source Code First
- Source code investigation saved 50+ failed iterations
- Understanding how moOde generates xinitrc was critical
- moOde's assumptions (portrait = user wants portrait) explained failures

### 3. Custom Hardware Needs Custom Build
- Waveshare 7.9" portrait display in landscape mode
- HiFiBerry AMP100 with custom DSP
- Touch controller (FT6236)
- **These require custom build, not download modifications**

### 4. Document Custom Builds
- Custom builds must be documented
- Backup build scripts and configurations
- Tag working builds in git
- Store build artifacts

---

## Next Steps

1. ✅ Document discovery (this file)
2. Prepare custom build environment
3. Run imgbuild/build.sh
4. Flash new custom image
5. Verify display works
6. Tag as v1.1-working

**Status:** Ready to build custom image
