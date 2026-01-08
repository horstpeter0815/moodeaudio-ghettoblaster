#!/bin/bash
# Verify Build After Completion
# Actually checks the built image to see if everything is included

set -e

PROJECT_DIR="$HOME/moodeaudio-cursor"
BUILD_DIR="$PROJECT_DIR/imgbuild/deploy"

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║  ✅ VERIFY BUILD AFTER COMPLETION                           ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

# Find latest image
LATEST_IMAGE=$(ls -t "$BUILD_DIR"/*.img 2>/dev/null | head -1)

if [ -z "$LATEST_IMAGE" ]; then
    echo "❌ ERROR: No build image found in $BUILD_DIR"
    echo ""
    echo "Build may not have completed yet."
    exit 1
fi

echo "✅ Found build image:"
echo "   $(basename "$LATEST_IMAGE")"
echo "   Size: $(du -h "$LATEST_IMAGE" | cut -f1)"
echo ""

# Check if we can mount the image
echo "=== MOUNTING IMAGE FOR VERIFICATION ==="
echo ""

# Try to mount (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    echo "Mounting image on macOS..."
    
    # Create mount points
    MOUNT_ROOT="/tmp/moode-build-verify"
    ROOTFS_MOUNT="$MOUNT_ROOT/rootfs"
    BOOTFS_MOUNT="$MOUNT_ROOT/bootfs"
    
    mkdir -p "$ROOTFS_MOUNT" "$BOOTFS_MOUNT"
    
    # Get image info
    IMG_INFO=$(hdiutil attach -imagekey diskimage-class=CRawDiskImage "$LATEST_IMAGE" 2>&1)
    
    if [ $? -eq 0 ]; then
        echo "✅ Image mounted successfully"
        echo ""
        
        # Find mounted partitions - try multiple methods
        BOOT_DEV=$(echo "$IMG_INFO" | grep -E "Apple_HFS|FAT|MS-DOS" | head -1 | awk '{print $1}')
        ROOT_DEV=$(echo "$IMG_INFO" | grep -E "Linux|ext4" | head -1 | awk '{print $1}')
        
        # Alternative: Get device from hdiutil output
        if [ -z "$BOOT_DEV" ] || [ -z "$ROOT_DEV" ]; then
            # Try to get all devices from the image
            ATTACHED_DEV=$(echo "$IMG_INFO" | grep "/dev/disk" | head -1 | awk '{print $1}')
            if [ -n "$ATTACHED_DEV" ]; then
                # Get partition devices
                BASE_DEV=$(echo "$ATTACHED_DEV" | sed 's/s[0-9]*$//')
                BOOT_DEV="${BASE_DEV}s1"
                ROOT_DEV="${BASE_DEV}s2"
                
                # Verify devices exist
                if [ ! -e "$BOOT_DEV" ]; then
                    BOOT_DEV=""
                fi
                if [ ! -e "$ROOT_DEV" ]; then
                    ROOT_DEV=""
                fi
            fi
        fi
        
        if [ -n "$BOOT_DEV" ] && [ -n "$ROOT_DEV" ]; then
            echo "Boot partition: $BOOT_DEV"
            echo "Root partition: $ROOT_DEV"
            echo ""
            
            # Mount partitions
            echo "Mounting boot partition ($BOOT_DEV)..."
            sudo mount -t msdos "$BOOT_DEV" "$BOOTFS_MOUNT" 2>&1 || {
                # Try FAT32
                sudo mount -t msdosfs "$BOOT_DEV" "$BOOTFS_MOUNT" 2>&1 || {
                    # Try auto-detect
                    sudo mount "$BOOT_DEV" "$BOOTFS_MOUNT" 2>&1 || true
                }
            }
            
            echo "Mounting root partition ($ROOT_DEV)..."
            # macOS doesn't natively support ext4, but we can try
            # For verification, we'll check if we can read the device directly
            if command -v ext4fuse >/dev/null 2>&1; then
                sudo ext4fuse "$ROOT_DEV" "$ROOTFS_MOUNT" -o allow_other 2>&1 || true
            else
                # Try using diskutil mount (macOS native)
                sudo diskutil mount "$ROOT_DEV" 2>&1 || true
                # Check if mounted via diskutil
                MOUNTED_PATH=$(diskutil info "$ROOT_DEV" 2>/dev/null | grep "Mount Point" | awk '{print $3}')
                if [ -n "$MOUNTED_PATH" ]; then
                    ROOTFS_MOUNT="$MOUNTED_PATH"
                    echo "  Root partition mounted at: $ROOTFS_MOUNT"
                fi
            fi
            
            if [ -d "$ROOTFS_MOUNT/lib" ] && [ -d "$BOOTFS_MOUNT" ]; then
                echo "✅ Partitions mounted"
                echo ""
                
                # Verify critical services
                echo "=== VERIFYING CRITICAL SERVICES ==="
                echo ""
                
                SERVICES_FOUND=0
                SERVICES_MISSING=0
                
                for service in 01-ssh-enable.service fix-user-id.service 02-eth0-configure.service 00-boot-network-ssh.service; do
                    if [ -f "$ROOTFS_MOUNT/lib/systemd/system/$service" ]; then
                        echo "  ✅ $service"
                        SERVICES_FOUND=$((SERVICES_FOUND + 1))
                    else
                        echo "  ❌ $service MISSING"
                        SERVICES_MISSING=$((SERVICES_MISSING + 1))
                    fi
                done
                
                echo ""
                echo "Services: $SERVICES_FOUND found, $SERVICES_MISSING missing"
                echo ""
                
                # Verify SSH flag
                echo "=== VERIFYING SSH CONFIGURATION ==="
                echo ""
                if [ -f "$BOOTFS_MOUNT/ssh" ] || [ -f "$BOOTFS_MOUNT/firmware/ssh" ]; then
                    echo "  ✅ SSH flag found"
                else
                    echo "  ⚠️  SSH flag not found (will be created by service)"
                fi
                echo ""
                
                # Verify boot config
                echo "=== VERIFYING BOOT CONFIGURATION ==="
                echo ""
                if [ -f "$BOOTFS_MOUNT/config.txt" ] || [ -f "$BOOTFS_MOUNT/firmware/config.txt" ]; then
                    echo "  ✅ config.txt found"
                    CONFIG_FILE="$BOOTFS_MOUNT/config.txt"
                    [ -f "$BOOTFS_MOUNT/firmware/config.txt" ] && CONFIG_FILE="$BOOTFS_MOUNT/firmware/config.txt"
                    
                    if grep -q "dtparam=i2c_arm=on" "$CONFIG_FILE" 2>/dev/null; then
                        echo "  ✅ I2C enabled"
                    fi
                else
                    echo "  ⚠️  config.txt not found"
                fi
                echo ""
                
                # Summary
                echo "=== VERIFICATION SUMMARY ==="
                echo ""
                if [ $SERVICES_MISSING -eq 0 ]; then
                    echo "✅✅✅ BUILD VERIFICATION PASSED ✅✅✅"
                    echo ""
                    echo "All critical services are included:"
                    echo "  ✅ SSH enable service"
                    echo "  ✅ User fix service (andre, UID 1000)"
                    echo "  ✅ Network fix service (eth0 static IP)"
                    echo "  ✅ Early boot service"
                    echo ""
                    echo "Build is ready for deployment!"
                else
                    echo "⚠️  BUILD VERIFICATION: Some services missing"
                    echo ""
                    echo "Missing services need to be added to the build."
                fi
                
                # Unmount
                echo ""
                echo "Unmounting image..."
                sudo umount "$ROOTFS_MOUNT" 2>/dev/null || true
                sudo umount "$BOOTFS_MOUNT" 2>/dev/null || true
                hdiutil detach "$BOOT_DEV" 2>/dev/null || true
                hdiutil detach "$ROOT_DEV" 2>/dev/null || true
                rmdir "$ROOTFS_MOUNT" "$BOOTFS_MOUNT" 2>/dev/null || true
                
            else
                echo "❌ Failed to mount partitions"
                hdiutil detach "$BOOT_DEV" 2>/dev/null || true
                hdiutil detach "$ROOT_DEV" 2>/dev/null || true
            fi
        else
            echo "❌ Could not find partitions in image"
            echo ""
            echo "Debug info:"
            echo "  Image info output:"
            echo "$IMG_INFO" | head -10
            echo ""
            echo "  Trying alternative method..."
            
            # Alternative: Use diskutil to list partitions
            ATTACHED_DEV=$(echo "$IMG_INFO" | grep "/dev/disk" | head -1 | awk '{print $1}')
            if [ -n "$ATTACHED_DEV" ]; then
                BASE_DEV=$(echo "$ATTACHED_DEV" | sed 's/s[0-9]*$//')
                echo "  Base device: $BASE_DEV"
                diskutil list "$BASE_DEV" 2>/dev/null || true
            fi
            
            # Cleanup
            hdiutil detach "$ATTACHED_DEV" 2>/dev/null || true
        fi
    else
        echo "❌ Failed to mount image"
        echo "$IMG_INFO"
    fi
else
    echo "⚠️  Image verification on Linux not yet implemented"
    echo "   Image location: $LATEST_IMAGE"
fi

echo ""
echo "=== VERIFICATION COMPLETE ==="
echo ""

