# Share Working moOde Image with Friend

## Quick Steps

### 1. Create Image from Your Working SD Card

Run this script:
```bash
cd /Users/andrevollmer/moodeaudio-cursor/scripts/deployment
./CREATE_WORKING_IMAGE_FROM_SD.sh
```

This will create: `~/Downloads/moode-10.2-working-YYYYMMDD.img.zip`

### 2. Create GitHub Repository

Go to: https://github.com/new

- **Repository name:** `moode-working-image`
- **Description:** `moOde 10.2 Working Image - Complete working configuration`
- **Visibility:** Public
- **Initialize:** Add a README

Click "Create repository"

### 3. Upload Image as Release

1. Go to your new repository: https://github.com/horstpeter0815/moode-working-image
2. Click "Releases" → "Create a new release"
3. **Tag:** `v1.0-working`
4. **Title:** `moOde 10.2 Working Image - Complete Setup`
5. **Description:**
   ```
   Complete working moOde 10.2 image ready to burn!
   
   Includes:
   - Display: 1280x400 landscape, touch calibrated
   - Audio: HiFiBerry AMP100, volume optimized
   - Network: WiFi configured
   - Filters: CamillaDSP ready
   - Radio: 6 stations
   ```
6. **Attach file:** Drag and drop `moode-10.2-working-YYYYMMDD.img.zip`
7. Click "Publish release"

### 4. Share with Friend

Send them this link:
```
https://github.com/horstpeter0815/moode-working-image/releases/latest
```

They can:
1. Download the `.img.zip` file
2. Extract it
3. Burn to SD card using Balena Etcher or dd
4. Boot and use!

## Alternative: Use Git LFS for Large Files

If the image is too large for GitHub Releases (max 2GB for free accounts):

1. Enable Git LFS in your repository
2. Use the script: `scripts/deployment/upload-image-with-lfs.sh`

## What's in the Image

✅ Complete moOde 10.2 installation
✅ All working configurations
✅ Display, touch, audio, network
✅ Volume optimized settings
✅ Ready to use!

---

**Your friend just needs to download and burn!** 🎵
