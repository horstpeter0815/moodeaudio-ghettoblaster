# 🎯 Restore moOde - Step by Step

## Current Situation
- ✅ moOde image found: `2025-12-07-moode-r1001-arm64-lite.img`
- ✅ Image extracted
- ❌ SD card has NO moOde (only wizard files)
- ❌ Need to copy moOde from image to SD card

## Steps to Fix

### 1. Mount the Image (if not mounted)
```bash
cd ~/moodeaudio-cursor
hdiutil attach -imagekey diskimage-class=CRawDiskImage 2025-12-07-moode-r1001-arm64-lite.img
```

### 2. Copy moOde Files
```bash
sudo ./COPY_MOODE_FROM_IMAGE.sh
```

This copies:
- `/var/www/html/` (moOde web interface)
- `/var/local/www/` (moOde configuration)

### 3. Install Our Fixes
```bash
sudo ./INSTALL_FIXES_AFTER_FLASH.sh
```

This installs:
- SSH fix (always enabled)
- User fix (andre with UID 1000)
- Ethernet fix (192.168.10.2)

### 4. Eject and Boot
```bash
# Eject SD card
diskutil eject /Volumes/rootfs
diskutil eject /Volumes/bootfs

# Boot Pi
```

---

**Run these commands now!**

