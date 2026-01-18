#!/bin/bash
################################################################################
#
# Monitor Build and Auto-Flash to SD Card
#
# Checks build status every 2 minutes and flashes when complete
#
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$PROJECT_ROOT"

SD_CARD="/dev/disk4"
CHECK_INTERVAL=120  # 2 minutes

echo "=== BUILD MONITOR & AUTO-FLASH ==="
echo ""
echo "SD Card: $SD_CARD"
echo "Check interval: $CHECK_INTERVAL seconds"
echo ""

while true; do
    # Check if build container is still running
    BUILD_CONTAINER=$(docker ps | grep moode-builder | awk '{print $1}' | head -1)
    
    if [ -z "$BUILD_CONTAINER" ]; then
        # Build container stopped - check for new image
        echo "[$(date +%H:%M:%S)] Build container stopped, checking for image..."
        
        # Find newest image
        NEWEST_IMAGE=$(ls -t imgbuild/deploy/*.img 2>/dev/null | head -1)
        
        if [ -n "$NEWEST_IMAGE" ]; then
            # Check if it's newer than 5 minutes (likely the new build)
            if [ -f "$NEWEST_IMAGE" ]; then
                IMAGE_AGE=$(( $(date +%s) - $(stat -f %m "$NEWEST_IMAGE" 2>/dev/null || stat -c %Y "$NEWEST_IMAGE" 2>/dev/null) ))
                
                if [ "$IMAGE_AGE" -lt 600 ]; then  # Less than 10 minutes old
                    echo ""
                    echo "🎉 BUILD COMPLETE!"
                    echo "Image: $NEWEST_IMAGE"
                    echo "Size: $(du -h "$NEWEST_IMAGE" | cut -f1)"
                    echo ""
                    echo "Flashing to SD card: $SD_CARD"
                    echo "⚠️  This will take 5-10 minutes..."
                    echo ""
                    
                    # Unmount SD card
                    diskutil unmountDisk "$SD_CARD" 2>/dev/null || true
                    sleep 2
                    
                    # Flash image
                    echo "Starting flash at $(date)..."
                    sudo dd if="$NEWEST_IMAGE" of="$SD_CARD" bs=1m status=progress
                    
                    if [ $? -eq 0 ]; then
                        echo ""
                        echo "✅ FLASH COMPLETE!"
                        echo "SD card is ready to boot!"
                        echo ""
                        # Eject SD card
                        diskutil eject "$SD_CARD"
                        echo "✅ SD card ejected - safe to remove"
                        exit 0
                    else
                        echo "❌ Flash failed!"
                        exit 1
                    fi
                fi
            fi
        fi
        
        echo "[$(date +%H:%M:%S)] No new image found yet, waiting..."
    else
        # Build still running
        STAGE=$(docker logs "$BUILD_CONTAINER" 2>&1 | grep -E "Begin.*stage" | tail -1 | sed 's/.*Begin //' | cut -d'/' -f4-5)
        echo "[$(date +%H:%M:%S)] Build running: $STAGE"
    fi
    
    sleep "$CHECK_INTERVAL"
done
