# Image Management Toolbox

Reusable tools for managing moOde images efficiently.

## Quick Start

### Fix and burn an image (complete pipeline):
```bash
cd /Users/andrevollmer/moodeaudio-cursor/tools/image-management

# Fix an image completely (mount, fix, unmount, copy)
./fix-image-complete.sh /path/to/source.img /path/to/output-FIXED.img

# Burn to SD card
./burn-to-sd.sh /path/to/output-FIXED.img /dev/disk4
```

## Individual Tools

### 1. mount-image.sh
Mount an image file in Docker container for modification.

```bash
./mount-image.sh /path/to/image.img [container-name]
```

- Mounts image to `/mnt/boot` and `/mnt/root` inside container
- Uses kpartx for partition mapping
- Cleans up any previous mounts automatically

### 2. apply-fixes.sh
Apply all standard moOde configuration fixes to a mounted image.

```bash
./apply-fixes.sh [container-name]
```

**Fixes applied:**
- ✅ cmdline.txt: `video=HDMI-A-1:1280x400@60` (landscape display)
- ✅ config.txt: `arm_boost=1`, `hdmi_force_edid_audio=0`
- ✅ Database: HiFiBerry AMP100, landscape orientation, CamillaDSP filters
- ✅ ALSA: `plughw:1,0` for HiFiBerry

### 3. unmount-image.sh
Safely unmount an image with proper sync.

```bash
./unmount-image.sh [container-name]
```

- Syncs all changes
- Unmounts partitions
- Removes kpartx mappings
- Detaches loop device

### 4. fix-image-complete.sh
Complete pipeline: mount, fix, unmount, copy.

```bash
./fix-image-complete.sh source.img output-FIXED.img
```

- Runs all steps automatically
- Outputs fixed image ready to burn
- Single command workflow

### 5. burn-to-sd.sh
Burn any image to SD card.

```bash
./burn-to-sd.sh image.img [/dev/disk4]
```

- Prompts for confirmation
- Shows progress
- Unmounts and ejects automatically
- Works with any device

## Typical Workflow

```bash
# 1. Fix the image
./fix-image-complete.sh \
  ~/moodeaudio-cursor/imgbuild/deploy/moode-latest.img \
  ~/moodeaudio-cursor/imgbuild/deploy/moode-latest-FIXED.img

# 2. Burn to SD card
./burn-to-sd.sh \
  ~/moodeaudio-cursor/imgbuild/deploy/moode-latest-FIXED.img \
  /dev/disk4
```

## Token Efficiency

### Before (manual approach):
- 50+ shell commands
- 10,000+ tokens
- Error-prone
- Not reusable

### After (toolbox approach):
- 2 commands
- 500 tokens
- Reliable
- Reusable for all future images

## Requirements

- Docker with `pigen_work` container (or specify different container)
- Container must have: `kpartx`, `util-linux`, `sqlite3`
- SD card at `/dev/disk4` (or specify different device)
- sudo access for burning to SD card

## Adding New Fixes

To add new configuration fixes, edit `apply-fixes.sh`:

```bash
docker exec "$CONTAINER_NAME" bash -c '
  # Your new fix here
  echo "New fix applied"
'
```

## When macOS Can't Modify ext4 Filesystems

### 6. create-firstrun-fix.sh
Create a fix script on bootfs (FAT32) to run after first boot.

```bash
./create-firstrun-fix.sh [disk_device]
```

**Use when:**
- macOS ext4 permissions prevent modifications
- Need root access to modify system files
- Can't delete systemd services from macOS

**Workflow:**
1. Create script: `./create-firstrun-fix.sh disk4`
2. Edit the generated script to add fixes
3. Boot the Pi
4. SSH in and run: `sudo bash /boot/firmware/firstrun-fix.sh`

All scripts are modular and can be combined in any way.
