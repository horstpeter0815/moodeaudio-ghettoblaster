#!/bin/bash
# Device Tree Parameter Test Script
# Purpose: Test specific device tree parameters and document behavior
# Usage: ./test-parameter.sh <overlay> <parameter> [value]

set -e

OVERLAY=$1
PARAMETER=$2
VALUE=$3

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

if [ -z "$OVERLAY" ] || [ -z "$PARAMETER" ]; then
    echo "Usage: $0 <overlay> <parameter> [value]"
    echo ""
    echo "Examples:"
    echo "  $0 hifiberry-dacplus 24db_digital_gain"
    echo "  $0 hifiberry-dacplus auto_mute"
    echo "  $0 vc4-kms-v3d-pi5 noaudio"
    echo "  $0 hifiberry-amp100-pi5 mute_ext_ctl 4"
    exit 1
fi

echo -e "${BLUE}================================${NC}"
echo -e "${BLUE}Device Tree Parameter Test${NC}"
echo -e "${BLUE}================================${NC}"
echo ""
echo "Overlay:   $OVERLAY"
echo "Parameter: $PARAMETER"
if [ -n "$VALUE" ]; then
    echo "Value:     $VALUE"
fi
echo ""

# Step 1: Backup current config
echo -e "${YELLOW}Step 1: Backing up config.txt...${NC}"
sudo cp /boot/firmware/config.txt /boot/firmware/config.txt.param-test-backup
echo -e "${GREEN}✓ Backup created${NC}"
echo ""

# Step 2: Check if overlay exists
echo -e "${YELLOW}Step 2: Checking if overlay file exists...${NC}"
if [ -f "/boot/firmware/overlays/${OVERLAY}.dtbo" ]; then
    echo -e "${GREEN}✓ Overlay file found: /boot/firmware/overlays/${OVERLAY}.dtbo${NC}"
else
    echo -e "${RED}✗ Overlay file not found: /boot/firmware/overlays/${OVERLAY}.dtbo${NC}"
    echo "Available overlays:"
    ls /boot/firmware/overlays/*.dtbo | head -10
    exit 1
fi
echo ""

# Step 3: Check current state
echo -e "${YELLOW}Step 3: Checking current configuration...${NC}"
CURRENT_CONFIG=$(grep "dtoverlay=$OVERLAY" /boot/firmware/config.txt | head -1)
if [ -n "$CURRENT_CONFIG" ]; then
    echo "Current: $CURRENT_CONFIG"
else
    echo "Overlay not currently loaded"
fi
echo ""

# Step 4: Add parameter to config
echo -e "${YELLOW}Step 4: Adding parameter to config.txt...${NC}"
# Remove existing overlay line
sudo sed -i "/dtoverlay=$OVERLAY/d" /boot/firmware/config.txt

# Add new overlay line with parameter
if [ -n "$VALUE" ]; then
    NEW_LINE="dtoverlay=$OVERLAY,$PARAMETER=$VALUE"
else
    NEW_LINE="dtoverlay=$OVERLAY,$PARAMETER"
fi

echo "$NEW_LINE" | sudo tee -a /boot/firmware/config.txt > /dev/null
echo -e "${GREEN}✓ Added: $NEW_LINE${NC}"
echo ""

# Step 5: Prompt for reboot
echo -e "${YELLOW}Step 5: Reboot required${NC}"
echo ""
echo "The system needs to reboot to apply the parameter."
echo "After reboot, run: $0 verify $OVERLAY $PARAMETER"
echo ""
read -p "Reboot now? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "Rebooting..."
    sudo reboot
else
    echo "Skipping reboot. Remember to reboot manually!"
fi
