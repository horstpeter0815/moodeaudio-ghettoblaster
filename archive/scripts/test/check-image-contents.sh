#!/bin/bash
# check-image-contents.sh
# Checks if SSH services and scripts are actually in the Raspberry Pi image

set -e

IMAGE_FILE="${1:-/img.img}"

if [ ! -f "$IMAGE_FILE" ]; then
    echo "❌ Image file not found: $IMAGE_FILE"
    exit 1
fi

echo "=== CHECKING IMAGE: $(basename "$IMAGE_FILE") ==="
echo ""

# Get image size
IMAGE_SIZE=$(stat -c%s "$IMAGE_FILE" 2>/dev/null || stat -f%z "$IMAGE_FILE" 2>/dev/null || echo "0")
IMAGE_SIZE_GB=$(echo "scale=2; $IMAGE_SIZE / 1024 / 1024 / 1024" | bc 2>/dev/null || echo "0")
echo "Image size: ${IMAGE_SIZE_GB} GB"
echo ""

# Create loop device
echo "=== CREATING LOOP DEVICE ==="
LOOP_DEV=$(losetup -f --show "$IMAGE_FILE")
echo "✅ Loop device created: $LOOP_DEV"
echo ""

# Use kpartx to create partition devices
echo "=== CREATING PARTITION DEVICES ==="
kpartx -a "$LOOP_DEV" 2>/dev/null || true
sleep 1

# Get partition devices
PART1_DEV=$(ls /dev/mapper/loop*p1 2>/dev/null | head -1)
PART2_DEV=$(ls /dev/mapper/loop*p2 2>/dev/null | head -1)

# Get partition table
echo "=== PARTITION TABLE ==="
fdisk -l "$LOOP_DEV" 2>/dev/null | grep -E "^/|Device|Start|End" | head -10
echo ""

if [ -n "$PART1_DEV" ] && [ -e "$PART1_DEV" ]; then
    echo "✅ Partition 1 (boot) device: $PART1_DEV"
    
    # Try to mount boot partition
    mkdir -p /mnt/boot
    if mount "$PART1_DEV" /mnt/boot 2>/dev/null; then
        echo "✅ Boot partition mounted"
        
        # Check for SSH flag
        if [ -f /mnt/boot/ssh ] || [ -f /mnt/boot/firmware/ssh ]; then
            echo "✅ SSH flag file found in boot partition"
        else
            echo "❌ SSH flag file NOT found in boot partition"
        fi
        
        # Check for userconf.txt
        if [ -f /mnt/boot/userconf.txt ] || [ -f /mnt/boot/firmware/userconf.txt ]; then
            echo "✅ userconf.txt found in boot partition"
        else
            echo "⚠️  userconf.txt NOT found in boot partition"
        fi
        
        umount /mnt/boot 2>/dev/null || true
    else
        echo "⚠️  Could not mount boot partition"
    fi
else
    echo "⚠️  Partition 1 device not found"
fi

if [ -n "$PART2_DEV" ] && [ -e "$PART2_DEV" ]; then
    echo "✅ Partition 2 (rootfs) device: $PART2_DEV"
    
    # Try to mount rootfs partition (ext4, read-only)
    mkdir -p /mnt/rootfs
    if mount -o ro "$PART2_DEV" /mnt/rootfs 2>/dev/null || mount -t ext4 -o ro "$PART2_DEV" /mnt/rootfs 2>/dev/null; then
        echo "✅ Rootfs partition mounted"
        echo ""
        
        echo "=== CHECKING SSH SERVICES ==="
        # Check for SSH services
        SSH_SERVICES=(
            "ssh-ultra-early.service"
            "ssh-guaranteed.service"
            "enable-ssh-early.service"
            "ssh-watchdog.service"
            "first-boot-setup.service"
        )
        
        for service in "${SSH_SERVICES[@]}"; do
            if [ -f "/mnt/rootfs/lib/systemd/system/$service" ]; then
                echo "✅ $service FOUND in image"
            else
                echo "❌ $service NOT FOUND in image"
            fi
        done
        
        echo ""
        echo "=== CHECKING SCRIPTS ==="
        # Check for scripts
        SCRIPTS=(
            "force-ssh-on.sh"
            "first-boot-setup.sh"
        )
        
        for script in "${SCRIPTS[@]}"; do
            if [ -f "/mnt/rootfs/usr/local/bin/$script" ]; then
                echo "✅ $script FOUND in image"
                if [ -x "/mnt/rootfs/usr/local/bin/$script" ]; then
                    echo "   ✅ $script is executable"
                else
                    echo "   ⚠️  $script is NOT executable"
                fi
            else
                echo "❌ $script NOT FOUND in image"
            fi
        done
        
        echo ""
        echo "=== CHECKING SSH CONFIG ==="
        # Check for SSH config
        if [ -f "/mnt/rootfs/etc/ssh/sshd_config" ]; then
            echo "✅ sshd_config found"
        else
            echo "⚠️  sshd_config NOT found"
        fi
        
        if [ -d "/mnt/rootfs/etc/ssh" ]; then
            SSH_KEYS=$(ls /mnt/rootfs/etc/ssh/ssh_host_*_key 2>/dev/null | wc -l)
            echo "   SSH keys found: $SSH_KEYS"
        fi
        
        echo ""
        echo "=== CHECKING SYSTEMD LINKS ==="
        # Check if services are enabled (have symlinks)
        if [ -L "/mnt/rootfs/etc/systemd/system/multi-user.target.wants/ssh-ultra-early.service" ]; then
            echo "✅ ssh-ultra-early.service is ENABLED (symlink exists)"
        else
            echo "⚠️  ssh-ultra-early.service is NOT enabled (no symlink)"
        fi
        
        if [ -L "/mnt/rootfs/etc/systemd/system/multi-user.target.wants/first-boot-setup.service" ]; then
            echo "✅ first-boot-setup.service is ENABLED (symlink exists)"
        else
            echo "⚠️  first-boot-setup.service is NOT enabled (no symlink)"
        fi
        
        umount /mnt/rootfs 2>/dev/null || true
    else
        echo "⚠️  Could not mount rootfs partition"
    fi
fi

# Cleanup
kpartx -d "$LOOP_DEV" 2>/dev/null || true
losetup -d "$LOOP_DEV" 2>/dev/null || true

echo ""
echo "=== IMAGE CHECK COMPLETE ==="

