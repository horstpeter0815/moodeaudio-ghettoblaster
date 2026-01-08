#!/bin/bash

# SD Card Setup Script for Pi 5 HDMI Configuration
# Based on STABLE_HDMI_SOLUTION_PLAN.md

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CONFIG_DIR="$SCRIPT_DIR"

echo "=========================================="
echo "SD Card Setup for Pi 5 HDMI Configuration"
echo "=========================================="
echo ""

# Find SD card mount point
echo "Step 1: Finding SD card..."
SD_CARD_MOUNT=""

# Check common mount points
for mount in /Volumes/boot /Volumes/firmware /Volumes/*; do
    if [ -d "$mount" ] && [ -f "$mount/config.txt" ] || [ -f "$mount/cmdline.txt" ]; then
        SD_CARD_MOUNT="$mount"
        echo "✓ Found SD card at: $SD_CARD_MOUNT"
        break
    fi
done

# If not found, try to detect by looking for Raspberry Pi firmware files
if [ -z "$SD_CARD_MOUNT" ]; then
    for mount in /Volumes/*; do
        if [ -d "$mount" ] && ([ -f "$mount/config.txt" ] || [ -f "$mount/start4.elf" ] || [ -f "$mount/start.elf" ]); then
            SD_CARD_MOUNT="$mount"
            echo "✓ Found SD card at: $SD_CARD_MOUNT"
            break
        fi
    done
fi

if [ -z "$SD_CARD_MOUNT" ]; then
    echo "❌ ERROR: Could not find SD card!"
    echo ""
    echo "Please ensure:"
    echo "  1. SD card is inserted"
    echo "  2. SD card is mounted (check /Volumes/)"
    echo ""
    echo "Mounted volumes:"
    ls -la /Volumes/ | grep -v "^d" | tail -n +4
    exit 1
fi

# Determine boot partition path (Pi 5 uses /boot/firmware, older Pis use /boot)
BOOT_DIR=""
if [ -d "$SD_CARD_MOUNT/firmware" ]; then
    BOOT_DIR="$SD_CARD_MOUNT/firmware"
elif [ -f "$SD_CARD_MOUNT/config.txt" ]; then
    BOOT_DIR="$SD_CARD_MOUNT"
else
    echo "❌ ERROR: Could not find boot directory on SD card!"
    exit 1
fi

echo "✓ Boot directory: $BOOT_DIR"
echo ""

# Create backup directory
BACKUP_DIR="$CONFIG_DIR/backups/$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"
echo "Step 2: Creating backups in $BACKUP_DIR..."

# Backup existing files
if [ -f "$BOOT_DIR/config.txt" ]; then
    cp "$BOOT_DIR/config.txt" "$BACKUP_DIR/config.txt.backup"
    echo "✓ Backed up config.txt"
fi

if [ -f "$BOOT_DIR/cmdline.txt" ]; then
    cp "$BOOT_DIR/cmdline.txt" "$BACKUP_DIR/cmdline.txt.backup"
    echo "✓ Backed up cmdline.txt"
    
    # Extract PARTUUID from existing cmdline.txt
    PARTUUID=$(grep -o 'root=PARTUUID=[^ ]*' "$BOOT_DIR/cmdline.txt" | sed 's/root=PARTUUID=//' || echo "")
    if [ -n "$PARTUUID" ]; then
        echo "✓ Found PARTUUID: $PARTUUID"
    fi
else
    PARTUUID=""
    echo "⚠️  No existing cmdline.txt found"
fi

echo ""

# Apply new config.txt
echo "Step 3: Applying new config.txt..."
if [ -f "$CONFIG_DIR/config.txt" ]; then
    cp "$CONFIG_DIR/config.txt" "$BOOT_DIR/config.txt"
    echo "✓ Applied new config.txt"
else
    echo "❌ ERROR: $CONFIG_DIR/config.txt not found!"
    exit 1
fi

# Apply new cmdline.txt (preserving PARTUUID)
echo "Step 4: Applying new cmdline.txt..."
if [ -f "$CONFIG_DIR/cmdline.txt" ]; then
    if [ -n "$PARTUUID" ]; then
        # Replace CHANGE_ME with actual PARTUUID
        sed "s/PARTUUID=CHANGE_ME/PARTUUID=$PARTUUID/g" "$CONFIG_DIR/cmdline.txt" > "$BOOT_DIR/cmdline.txt"
        echo "✓ Applied new cmdline.txt (preserved PARTUUID: $PARTUUID)"
    else
        cp "$CONFIG_DIR/cmdline.txt" "$BOOT_DIR/cmdline.txt"
        echo "✓ Applied new cmdline.txt (no PARTUUID found - you may need to update manually)"
        echo "⚠️  WARNING: Please check cmdline.txt and update PARTUUID if needed!"
    fi
else
    echo "❌ ERROR: $CONFIG_DIR/cmdline.txt not found!"
    exit 1
fi

echo ""
echo "=========================================="
echo "✓ Setup Complete!"
echo "=========================================="
echo ""
echo "Applied configurations:"
echo "  - config.txt: Clean HDMI configuration (1280x400 landscape)"
echo "  - cmdline.txt: No video parameter (clean boot)"
echo ""
echo "Backups saved to: $BACKUP_DIR"
echo ""
echo "Next steps:"
echo "  1. Eject SD card safely"
echo "  2. Insert into Pi 5"
echo "  3. Boot and test display"
echo "  4. If issues, restore from: $BACKUP_DIR"
echo ""

