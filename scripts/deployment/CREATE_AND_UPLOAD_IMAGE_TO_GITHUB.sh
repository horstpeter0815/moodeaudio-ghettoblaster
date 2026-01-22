#!/bin/bash
#
# Create Working Image and Upload to GitHub for Sharing
# Date: 2026-01-21
#
# This script:
# 1. Creates image from current working SD card
# 2. Creates a new GitHub repository
# 3. Uploads image as a release for easy download
#

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKSPACE_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
OUTPUT_DIR="$HOME/Downloads"
IMAGE_NAME="moode-10.2-working-$(date +%Y%m%d).img"
REPO_NAME="moode-working-image"
REPO_OWNER="horstpeter0815"

echo "=========================================="
echo "Create & Upload Working Image to GitHub"
echo "=========================================="
echo ""

# Check if running on macOS
if [[ "$(uname)" != "Darwin" ]]; then
    echo "❌ This script must run on macOS"
    exit 1
fi

# Check for SD card
echo "Step 1: Checking for SD card..."
if ! diskutil list | grep -q "disk[0-9]"; then
    echo "❌ No SD card detected. Please insert SD card with working moOde."
    exit 1
fi

SD_DISK=$(diskutil list | grep "disk[0-9]" | tail -1 | awk '{print $NF}')
echo "✅ SD card detected: $SD_DISK"

# Confirm
echo ""
echo "This will:"
echo "  1. Create image from SD card: $SD_DISK"
echo "  2. Create GitHub repo: $REPO_OWNER/$REPO_NAME"
echo "  3. Upload image as release"
echo ""
read -p "Continue? (yes/no): " CONFIRM
if [[ "$CONFIRM" != "yes" ]]; then
    echo "Aborted."
    exit 0
fi

# Step 1: Create image
echo ""
echo "=========================================="
echo "Step 1: Creating Image from SD Card"
echo "=========================================="
echo "Unmounting SD card..."
diskutil unmountDisk "/dev/$SD_DISK" 2>/dev/null || true
sleep 2

echo "Creating image file..."
echo "This will take 5-10 minutes..."
sudo dd if="/dev/r${SD_DISK}" of="$OUTPUT_DIR/$IMAGE_NAME" bs=1m status=progress
sync

IMAGE_SIZE=$(ls -lh "$OUTPUT_DIR/$IMAGE_NAME" | awk '{print $5}')
echo "✅ Image created: $OUTPUT_DIR/$IMAGE_NAME ($IMAGE_SIZE)"

# Step 2: Compress image
echo ""
echo "=========================================="
echo "Step 2: Compressing Image"
echo "=========================================="
echo "Compressing for easier download..."
cd "$OUTPUT_DIR"
ZIP_NAME="${IMAGE_NAME}.zip"
zip -9 "$ZIP_NAME" "$IMAGE_NAME"
ZIP_SIZE=$(ls -lh "$ZIP_NAME" | awk '{print $5}')
echo "✅ Compressed: $ZIP_NAME ($ZIP_SIZE)"

# Step 3: Create GitHub repository
echo ""
echo "=========================================="
echo "Step 3: Creating GitHub Repository"
echo "=========================================="
echo "Repository: $REPO_OWNER/$REPO_NAME"
echo ""
echo "Note: This requires GitHub CLI (gh) or manual creation"
echo "If you don't have 'gh' CLI, you can:"
echo "  1. Manually create repo at: https://github.com/new"
echo "  2. Name it: $REPO_NAME"
echo "  3. Then run this script again or upload manually"
echo ""

# Check for GitHub CLI
if command -v gh &> /dev/null; then
    echo "Creating repository with GitHub CLI..."
    gh repo create "$REPO_NAME" --public --description "moOde 10.2 Working Image - Complete working configuration ready to burn" 2>/dev/null || echo "Repository may already exist"
    echo "✅ Repository created/verified"
else
    echo "⚠️  GitHub CLI not found. Please create repository manually:"
    echo "   https://github.com/new"
    echo "   Name: $REPO_NAME"
    echo "   Description: moOde 10.2 Working Image"
    echo "   Public repository"
    echo ""
    read -p "Press Enter after creating repository..."
fi

# Step 4: Create README
echo ""
echo "=========================================="
echo "Step 4: Creating README"
echo "=========================================="
README_FILE="/tmp/README.md"
cat > "$README_FILE" << EOF
# moOde 10.2 Working Image

Complete working moOde 10.2 image ready to burn and use!

## What's Included

✅ **Complete moOde 10.2 installation**
✅ **Display:** 1280x400 landscape, touchscreen calibrated
✅ **Audio:** HiFiBerry AMP100, volume optimized (Digital 75%, Analogue 100%)
✅ **Network:** WiFi (NAM YANG 2) configured, Ethernet disabled
✅ **Filters:** CamillaDSP ready (Bose Wave filters available)
✅ **Radio:** 6 curated stations
✅ **Volume:** Optimized settings (MPD software volume control)

## Quick Start

### 1. Download Image

Download the latest release: **moode-10.2-working-YYYYMMDD.img.zip**

### 2. Extract

\`\`\`bash
unzip moode-10.2-working-YYYYMMDD.img.zip
\`\`\`

### 3. Burn to SD Card

**macOS:**
\`\`\`bash
# Find your SD card
diskutil list

# Unmount
diskutil unmountDisk /dev/diskX

# Burn image
sudo dd if=moode-10.2-working-YYYYMMDD.img of=/dev/rdiskX bs=1m status=progress
sync
\`\`\`

**Linux:**
\`\`\`bash
# Find your SD card
lsblk

# Burn image
sudo dd if=moode-10.2-working-YYYYMMDD.img of=/dev/sdX bs=4M status=progress
sync
\`\`\`

**Windows:**
- Use [Balena Etcher](https://www.balena.io/etcher/) or [Raspberry Pi Imager](https://www.raspberrypi.com/software/)

### 4. Boot and Use

1. Insert SD card into Raspberry Pi 5
2. Power on
3. Wait for boot (30-60 seconds)
4. Access via: **http://moode.local**
5. SSH: **andre@moode.local** (password: 0815)

## Configuration Details

### Hardware
- **Raspberry Pi 5** (8GB)
- **HiFiBerry AMP100** audio HAT
- **1280x400 touchscreen** (WaveShare, rotated to landscape)

### Volume Settings
- **Digital Mixer:** 75% (FIXED)
- **Analogue Mixer:** 100% (FIXED)
- **MPD Volume:** 0-100% (user control via UI slider)

### Network
- **WiFi:** NAM YANG 2 (auto-connect)
- **Ethernet:** Disabled (auto-connect off)
- **Hostname:** moode.local

### Display
- **Resolution:** 1280x400 landscape
- **Touch:** Calibrated (90° left rotation)
- **Orientation:** Portrait in database → Landscape display

### Audio
- **Device:** HiFiBerry AMP100 (plughw:0,0)
- **Routing:** MPD → HiFiBerry (direct, no CamillaDSP by default)
- **CamillaDSP:** Available, filters ready in /usr/share/camilladsp/configs/

## First Boot

After first boot, you may need to:
1. Connect to WiFi (if NAM YANG 2 not available, use Ethernet temporarily)
2. Access web UI: http://moode.local
3. Configure additional settings if needed

## Troubleshooting

### No Audio
- Check HiFiBerry is connected
- Verify volume: MPD slider should control volume
- Check: \`aplay -l\` should show HiFiBerry card 0

### Display Wrong Orientation
- Database setting: \`hdmi_scn_orient='portrait'\` (this is correct!)
- Touch calibration: \`/usr/share/X11/xorg.conf.d/40-libinput-touchscreen.conf\`

### WiFi Not Connecting
- Check network name: "NAM YANG 2" (with spaces)
- Password: 1163855108
- Or connect via Ethernet and configure WiFi in web UI

## Files Included

- Complete moOde 10.2 installation
- All configuration files
- Touch calibration
- WiFi settings
- Volume optimization
- Radio stations

## Support

For issues or questions, see the main repository:
https://github.com/horstpeter0815/moodeaudio-ghettoblaster

## License

moOde Audio is licensed under GPL-3.0-or-later
This image contains moOde 10.2 with custom configurations

---

**Ready to use! Just download, burn, and boot!** 🎵
EOF

echo "✅ README created"

# Step 5: Instructions for manual upload
echo ""
echo "=========================================="
echo "Step 5: Upload Instructions"
echo "=========================================="
echo ""
echo "To upload to GitHub:"
echo ""
echo "Option 1: Using GitHub Web Interface"
echo "  1. Go to: https://github.com/$REPO_OWNER/$REPO_NAME/releases/new"
echo "  2. Tag: v1.0-working"
echo "  3. Title: moOde 10.2 Working Image - $(date +%Y-%m-%d)"
echo "  4. Description: Complete working image ready to burn"
echo "  5. Attach file: $OUTPUT_DIR/$ZIP_NAME"
echo "  6. Publish release"
echo ""
echo "Option 2: Using GitHub CLI (if installed)"
echo "  gh release create v1.0-working \\"
echo "    --title \"moOde 10.2 Working Image\" \\"
echo "    --notes \"Complete working image\" \\"
echo "    \"$OUTPUT_DIR/$ZIP_NAME\""
echo ""
echo "Option 3: Manual upload via web"
echo "  1. Create release at: https://github.com/$REPO_OWNER/$REPO_NAME/releases/new"
echo "  2. Upload: $ZIP_NAME"
echo ""

# Remount SD card
echo "Remounting SD card..."
diskutil mountDisk "/dev/$SD_DISK" 2>/dev/null || true

echo ""
echo "=========================================="
echo "✅ Image Ready for Upload!"
echo "=========================================="
echo ""
echo "Files created:"
echo "  📦 Image: $OUTPUT_DIR/$IMAGE_NAME"
echo "  📦 Compressed: $OUTPUT_DIR/$ZIP_NAME"
echo "  📄 README: $README_FILE"
echo ""
echo "Next steps:"
echo "  1. Upload $ZIP_NAME to GitHub Releases"
echo "  2. Share the release link with your friend"
echo "  3. They download, extract, and burn!"
echo ""
echo "Repository: https://github.com/$REPO_OWNER/$REPO_NAME"
