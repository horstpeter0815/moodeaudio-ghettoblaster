#!/bin/bash
# Cleanup Old Build Images
# Removes old/non-working build images to free up storage space

set -e

PROJECT_DIR="$HOME/moodeaudio-cursor"
BUILD_DIR="$PROJECT_DIR/imgbuild/deploy"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  🧹 CLEANUP OLD BUILD IMAGES                                 ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

if [ ! -d "$BUILD_DIR" ]; then
    echo "❌ Build directory not found: $BUILD_DIR"
    exit 1
fi

# List all images
echo "=== Current Build Images ==="
echo ""
IMAGES=($(ls -t "$BUILD_DIR"/*.img 2>/dev/null))
TOTAL_SIZE=0

if [ ${#IMAGES[@]} -eq 0 ]; then
    echo "No build images found."
    exit 0
fi

# Show images with sizes
for i in "${!IMAGES[@]}"; do
    IMG="${IMAGES[$i]}"
    SIZE=$(du -h "$IMG" | cut -f1)
    SIZE_BYTES=$(du -b "$IMG" | cut -f1)
    TOTAL_SIZE=$((TOTAL_SIZE + SIZE_BYTES))
    DATE=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$IMG" 2>/dev/null || stat -c "%y" "$IMG" 2>/dev/null | cut -d' ' -f1,2 | cut -d'.' -f1)
    echo "$((i+1)). $(basename "$IMG")"
    echo "   Size: $SIZE | Date: $DATE"
    echo ""
done

TOTAL_SIZE_GB=$(echo "scale=2; $TOTAL_SIZE / 1024 / 1024 / 1024" | bc)
echo "Total: ${#IMAGES[@]} images, ~${TOTAL_SIZE_GB} GB"
echo ""

# Ask which to keep
echo "Which images do you want to KEEP?"
echo "  (Enter numbers separated by spaces, or 'all' to keep all)"
echo ""
read -p "Keep images: " KEEP_INPUT

if [ "$KEEP_INPUT" = "all" ]; then
    echo ""
    echo "✅ Keeping all images"
    exit 0
fi

# Parse keep list
KEEP_LIST=()
for num in $KEEP_INPUT; do
    if [[ "$num" =~ ^[0-9]+$ ]] && [ "$num" -ge 1 ] && [ "$num" -le ${#IMAGES[@]} ]; then
        KEEP_LIST+=("${IMAGES[$((num-1))]}")
    fi
done

if [ ${#KEEP_LIST[@]} -eq 0 ]; then
    echo "❌ No valid images selected to keep"
    exit 1
fi

# Find images to delete
DELETE_LIST=()
for IMG in "${IMAGES[@]}"; do
    KEEP_THIS=false
    for KEEP in "${KEEP_LIST[@]}"; do
        if [ "$IMG" = "$KEEP" ]; then
            KEEP_THIS=true
            break
        fi
    done
    if [ "$KEEP_THIS" = false ]; then
        DELETE_LIST+=("$IMG")
    fi
done

if [ ${#DELETE_LIST[@]} -eq 0 ]; then
    echo ""
    echo "✅ No images to delete"
    exit 0
fi

# Show what will be deleted
echo ""
echo "=== Images to DELETE ==="
DELETE_SIZE=0
for IMG in "${DELETE_LIST[@]}"; do
    SIZE=$(du -h "$IMG" | cut -f1)
    SIZE_BYTES=$(du -b "$IMG" | cut -f1)
    DELETE_SIZE=$((DELETE_SIZE + SIZE_BYTES))
    echo "  - $(basename "$IMG") ($SIZE)"
done

DELETE_SIZE_GB=$(echo "scale=2; $DELETE_SIZE / 1024 / 1024 / 1024" | bc)
echo ""
echo "Total to delete: ${#DELETE_LIST[@]} images, ~${DELETE_SIZE_GB} GB"
echo ""

# Confirm
read -p "Delete these images? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Cancelled."
    exit 0
fi

# Delete images
echo ""
echo "Deleting images..."
DELETED=0
for IMG in "${DELETE_LIST[@]}"; do
    if rm "$IMG" 2>/dev/null; then
        echo "✅ Deleted: $(basename "$IMG")"
        DELETED=$((DELETED + 1))
    else
        echo "❌ Failed to delete: $(basename "$IMG")"
    fi
done

echo ""
echo "✅✅✅ CLEANUP COMPLETE ✅✅✅"
echo ""
echo "Deleted: $DELETED images"
echo "Freed: ~${DELETE_SIZE_GB} GB"
echo ""

