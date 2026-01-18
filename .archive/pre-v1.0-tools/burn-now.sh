#!/bin/bash
# Burn image to SD card - automated
set -e

cd /Users/andrevollmer/moodeaudio-cursor

echo "=== BURNING IMAGE TO SD CARD ==="
echo ""

# Step 1: Find image
echo "[1/5] Finding image..."
IMAGE_FILE=""
IMAGE_ZIP=""

# Check deploy directory
if [ -d "imgbuild/deploy" ]; then
    IMAGE_FILE=$(ls -t imgbuild/deploy/*.img 2>/dev/null | head -1 || true)
    IMAGE_ZIP=$(ls -t imgbuild/deploy/*.zip 2>/dev/null | head -1 || true)
fi

# Check iCloud location
if [ -z "$IMAGE_FILE" ] && [ -z "$IMAGE_ZIP" ]; then
    ICLOUD_IMG="/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPI5/Moodeaudio/GhettoblasterPi5.img.gz"
    if [ -f "$ICLOUD_IMG" ]; then
        IMAGE_FILE="$ICLOUD_IMG"
    fi
fi

if [ -z "$IMAGE_FILE" ] && [ -n "$IMAGE_ZIP" ]; then
    echo "Found zip, extracting..."
    cd imgbuild/deploy
    unzip -o "$IMAGE_ZIP"
    IMAGE_FILE=$(ls -t *.img 2>/dev/null | head -1)
    if [ -n "$IMAGE_FILE" ]; then
        IMAGE_FILE="$(pwd)/$IMAGE_FILE"
    fi
    cd /Users/andrevollmer/moodeaudio-cursor
fi

if [ -z "$IMAGE_FILE" ]; then
    echo "❌ No image file found!"
    echo "Checked: imgbuild/deploy/*.img, imgbuild/deploy/*.zip, iCloud"
    exit 1
fi

echo "✓ Found: $IMAGE_FILE"
ls -lh "$IMAGE_FILE"
echo ""

# Step 2: Find SD card
echo "[2/5] Finding SD card..."
SD_DEVICE=$(diskutil list | grep -E "external|physical" | grep -E "disk[0-9]+" | head -1 | awk '{print $1}' || true)

if [ -z "$SD_DEVICE" ]; then
    echo "❌ No SD card found!"
    echo "Please insert SD card and try again"
    exit 1
fi

echo "✓ Found SD card: $SD_DEVICE"
diskutil info "/dev/$SD_DEVICE" | grep -E "Device Node|Disk Size" || true
echo ""

# Step 3: Unmount
echo "[3/5] Unmounting SD card..."
diskutil unmountDisk "/dev/$SD_DEVICE" 2>/dev/null || true
sleep 2
echo "✓ Unmounted"
echo ""

# Step 4: Burn
echo "[4/5] Burning image (this will take 5-15 minutes)..."
if [[ "$IMAGE_FILE" == *.gz ]]; then
    gunzip -c "$IMAGE_FILE" | sudo dd of="/dev/r$SD_DEVICE" bs=4m status=progress
else
    sudo dd if="$IMAGE_FILE" of="/dev/r$SD_DEVICE" bs=4m status=progress
fi

if [ $? -ne 0 ]; then
    echo "❌ Burn failed!"
    exit 1
fi

echo "✓ Burn complete"
echo ""

# Step 5: Sync and eject
echo "[5/5] Syncing and ejecting..."
sync
sleep 2
diskutil eject "/dev/$SD_DEVICE"

echo ""
echo "✅✅✅ IMAGE BURNED SUCCESSFULLY! ✅✅✅"
echo ""
echo "SD card is ready to boot!"
echo "Remove it from Mac and insert into Raspberry Pi."
