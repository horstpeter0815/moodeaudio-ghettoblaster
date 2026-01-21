#!/bin/bash
#########################################################################
# Complete Image Fix Pipeline - Mount, Fix, Unmount, Copy
# Usage: ./fix-image-complete.sh <source-image> <output-image>
# Example: ./fix-image-complete.sh moode.img moode-FIXED.img
#########################################################################

set -e

SOURCE_IMAGE="${1}"
OUTPUT_IMAGE="${2}"
CONTAINER_NAME="pigen_work"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

if [ -z "$SOURCE_IMAGE" ] || [ -z "$OUTPUT_IMAGE" ]; then
    echo "Usage: $0 <source-image> <output-image>"
    echo "Example: $0 /path/to/moode.img /path/to/moode-FIXED.img"
    exit 1
fi

if [ ! -f "$SOURCE_IMAGE" ]; then
    echo "❌ Error: Source image not found: $SOURCE_IMAGE"
    exit 1
fi

echo "========================================="
echo "COMPLETE IMAGE FIX PIPELINE"
echo "========================================="
echo "Source: $SOURCE_IMAGE"
echo "Output: $OUTPUT_IMAGE"
echo ""

# Step 1: Mount
echo "Step 1/4: Mounting image..."
"$SCRIPT_DIR/mount-image.sh" "$SOURCE_IMAGE" "$CONTAINER_NAME"

# Step 2: Apply fixes
echo ""
echo "Step 2/4: Applying fixes..."
"$SCRIPT_DIR/apply-fixes.sh" "$CONTAINER_NAME"

# Step 3: Unmount
echo ""
echo "Step 3/4: Unmounting image..."
"$SCRIPT_DIR/unmount-image.sh" "$CONTAINER_NAME"

# Step 4: Copy fixed image to output
echo ""
echo "Step 4/4: Copying fixed image to host..."
docker cp "$CONTAINER_NAME":/tmp/moode.img "$OUTPUT_IMAGE"

echo ""
echo "========================================="
echo "✅ COMPLETE! Fixed image ready:"
echo "$OUTPUT_IMAGE"
echo "========================================="
echo ""
echo "Next: Use burn-to-sd.sh to burn to SD card"
