#!/bin/bash
# Execute burn - finds image and SD card automatically

cd /Users/andrevollmer/moodeaudio-cursor

# Try the existing burn script first (uses iCloud image and disk4)
if [ -f "scripts/deployment/burn-v1.0-safe.sh" ]; then
    echo "Using existing burn script..."
    bash scripts/deployment/burn-v1.0-safe.sh
    exit $?
fi

# Fallback: manual burn
echo "Finding image and SD card..."

# Find image
IMAGE=""
if [ -f "/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPI5/Moodeaudio/GhettoblasterPi5.img.gz" ]; then
    IMAGE="/Users/andrevollmer/Library/Mobile Documents/com~apple~CloudDocs/Ablage/Roon filters/Bose Wave/OS/RPI5/Moodeaudio/GhettoblasterPi5.img.gz"
elif [ -d "imgbuild/deploy" ]; then
    IMAGE=$(ls -t imgbuild/deploy/*.img 2>/dev/null | head -1 || ls -t imgbuild/deploy/*.zip 2>/dev/null | head -1)
fi

# Find SD card
SD=$(diskutil list | grep -E "external|physical" | grep -E "disk[0-9]+" | head -1 | awk '{print $1}')

if [ -z "$IMAGE" ] || [ -z "$SD" ]; then
    echo "Image or SD card not found"
    echo "Image: $IMAGE"
    echo "SD: $SD"
    exit 1
fi

echo "Burning $IMAGE to $SD..."
diskutil unmountDisk "/dev/$SD" 2>/dev/null || true
sleep 2

if [[ "$IMAGE" == *.gz ]]; then
    gunzip -c "$IMAGE" | sudo dd of="/dev/r$SD" bs=4m status=progress
else
    sudo dd if="$IMAGE" of="/dev/r$SD" bs=4m status=progress
fi

sync
diskutil eject "/dev/$SD"
echo "Done!"
