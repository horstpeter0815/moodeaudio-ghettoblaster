# Create Image from Working System

**Date:** 2026-01-18  
**Status:** Ready to create image

## Working System Configuration

All working configurations are saved in `v1.0-config-export/`:

1. **Touch:** `99-calibration.conf.working` - TransformationMatrix "0 -1 1 1 0 0 0 0 1"
2. **Boot:** `config.txt.working`, `cmdline.txt.working`
3. **Audio:** `_audioout.conf.working`, `_peppyout.conf.working`
4. **Display:** `.xinitrc.working`
5. **PeppyMeter:** `peppymeter-config.txt.working`

## Create Image Steps

### Option 1: Read from Current SD Card
```bash
# Use save-image.sh to read from SD card
./tools/save-image.sh from-sd /dev/diskX
```

### Option 2: Use Raspberry Pi Imager
1. Insert SD card into Mac
2. Use Raspberry Pi Imager "Use custom image"
3. Select the working image file
4. Burn to SD card

### Option 3: Build New Image with Working Configs
The working configs in `v1.0-config-export/` should be integrated into the build process.

## Current Working System

- ✅ Audio: HiFiBerry AMP100 (card 0)
- ✅ Display: 1280x400 landscape (rotated)
- ✅ Touch: Working with TransformationMatrix
- ✅ Web UI: http://192.168.2.3
- ✅ All services running

**System is ready for image creation.**
