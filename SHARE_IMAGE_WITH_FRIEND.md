# Share Working moOde Image with Friend

## Quick Steps

### Option 1: Automated Upload (Recommended)

If you already have the image file, just upload it:

```bash
cd /Users/andrevollmer/moodeaudio-cursor/scripts/deployment
./UPLOAD_IMAGE_TO_GITHUB.sh
```

This script will:
- ✅ Find your image file automatically
- ✅ Create GitHub repository if needed
- ✅ Upload image as release
- ✅ Give you the shareable link

**That's it!** Share the link with your friend.

### Option 2: Create Image + Upload (All-in-One)

If you need to create the image first:

```bash
cd /Users/andrevollmer/moodeaudio-cursor/scripts/deployment
./DO_EVERYTHING_CREATE_AND_UPLOAD.sh
```

This creates the image from SD card AND uploads to GitHub.

### Option 3: Manual Upload (Web UI)

1. **Create Image:**
   ```bash
   cd /Users/andrevollmer/moodeaudio-cursor/scripts/deployment
   ./CREATE_WORKING_IMAGE_FROM_SD.sh
   ```
   This creates: `~/Downloads/moode-10.2-working-YYYYMMDD.img.zip`

2. **Create GitHub Repository:**
   - Go to: https://github.com/new
   - **Repository name:** `moode-working-image`
   - **Description:** `moOde 10.2 Working Image - Complete working configuration`
   - **Visibility:** Public
   - Click "Create repository"

3. **Upload Image as Release:**
   - Go to: https://github.com/horstpeter0815/moode-working-image
   - Click "Releases" → "Create a new release"
   - **Tag:** `v1.0-working`
   - **Title:** `moOde 10.2 Working Image - Complete Setup`
   - **Attach file:** Drag and drop `moode-10.2-working-YYYYMMDD.img.zip`
   - Click "Publish release"

### Share with Friend

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
