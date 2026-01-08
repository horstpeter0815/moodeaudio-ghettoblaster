# 📥 moOde Download Guide

## Overview

Official moOde Audio downloads are used for:
- Quick testing and comparison
- Reference for new features
- Quick fixes when needed
- Backup/testing option

---

## Download Location

**Directory:** `downloads/`

**Structure:**
```
downloads/
├── moode-r1001-arm64-lite.zip    # Downloaded images
└── extracted/                     # Extracted images
```

---

## Quick Start

### 1. Download moOde
```bash
# Download from moOde website
# https://moodeaudio.org/

# Save to downloads/
mv ~/Downloads/moode-r1001-arm64-lite.zip downloads/
```

### 2. Extract Image
```bash
# Extract ZIP
unzip downloads/moode-r1001-arm64-lite.zip -d downloads/extracted/
```

### 3. Apply Fixes
```bash
# Flash to SD card first, then:
./INSTALL_FIXES_AFTER_FLASH.sh
```

---

## Fix Installation

### After Flashing moOde Image

**Script:** `INSTALL_FIXES_AFTER_FLASH.sh`

**What it installs:**
1. SSH fix (`ssh-guaranteed.service`)
2. User fix (`fix-user-id.service`)
3. Ethernet fix (`eth0-direct-static.service`)
4. Display fix (`.xinitrc`)

**Usage:**
```bash
# Mount SD card (rootfs and bootfs)
# Then run:
sudo ./INSTALL_FIXES_AFTER_FLASH.sh
```

---

## Workflow: Quick Fix

### 1. Flash moOde Image
```bash
# Use Raspberry Pi Imager or dd
# Flash moode-r1001-arm64-lite.img to SD card
```

### 2. Mount SD Card
```bash
# macOS
diskutil list
sudo diskutil mount diskXs1  # bootfs
sudo diskutil mount diskXs2  # rootfs
```

### 3. Apply Fixes
```bash
# Install fixes
sudo ./INSTALL_FIXES_AFTER_FLASH.sh
```

### 4. Eject and Boot
```bash
# Eject SD card
diskutil eject /Volumes/bootfs
diskutil eject /Volumes/rootfs

# Boot Pi
```

---

## Comparison with Custom Builds

| Feature | moOde Download | Custom Build |
|---------|---------------|--------------|
| **Setup Time** | ⚠️ Flash + Fixes | ✅ Build once |
| **Control** | ⚠️ Limited | ✅ Full |
| **Customization** | ⚠️ After flash | ✅ From start |
| **Updates** | ⚠️ Re-flash | ✅ Build new |
| **Testing** | ⚠️ Manual | ✅ Docker suite |

---

## When to Use moOde Downloads

### ✅ Use Downloads When:
- Quick testing needed
- Comparing with custom builds
- Reference for new features
- Backup/testing option
- Quick fixes needed

### ✅ Use Custom Builds When:
- Full customization needed
- Faster development cycles
- Integrated testing
- Long-term development
- Production deployment

---

## Fixes Applied

### SSH Fix
- `ssh-guaranteed.service` - Ensures SSH is always enabled
- Creates `/boot/firmware/ssh` flag

### User Fix
- `fix-user-id.service` - Creates user `andre` (UID 1000)
- Sets password: `0815`
- Configures sudo (NOPASSWD)

### Ethernet Fix
- `eth0-direct-static.service` - Configures static IP (192.168.10.2)
- Disables WiFi to prevent conflicts

### Display Fix
- `.xinitrc` - Configures display rotation
- Sets `SCREEN_RES="1280,400"`
- Configures Chromium launch

---

## Documentation

- **`INSTALL_WORKING_MOODE.md`** - Installation guide
- **`INSTALL_FIXES_AFTER_FLASH.sh`** - Fix installation script
- **`RESTORE_MOODE_FROM_IMAGE.sh`** - Restore from image

---

**moOde downloads are useful for quick testing and reference! 📥**

