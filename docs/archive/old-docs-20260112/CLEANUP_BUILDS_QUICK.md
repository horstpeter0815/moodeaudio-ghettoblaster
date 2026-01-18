# 🧹 Cleanup Old Build Images

## Quick Cleanup

```bash
~/moodeaudio-cursor/CLEANUP_OLD_BUILDS.sh
```

**What it does:**
- Lists all build images with sizes
- Asks which ones to keep
- Deletes the rest
- Shows how much space was freed

---

## Current Build Images

Check what you have:
```bash
ls -lh ~/moodeaudio-cursor/imgbuild/deploy/*.img
```

---

## Manual Cleanup

If you want to delete specific images manually:

```bash
# List images
ls -lh ~/moodeaudio-cursor/imgbuild/deploy/*.img

# Delete specific image
rm ~/moodeaudio-cursor/imgbuild/deploy/moode-r1001-arm64-build-XX-*.img

# Or delete all except latest
cd ~/moodeaudio-cursor/imgbuild/deploy
ls -t *.img | tail -n +2 | xargs rm
```

---

## Recommended: Keep Only Latest

**Keep:**
- Latest working build (Build 35 or Build 36 when done)

**Delete:**
- All older builds
- Failed builds
- Test builds

**This can free up 10-20 GB!**

---

**Run the cleanup script to free up space! 🧹**

