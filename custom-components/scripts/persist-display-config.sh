#!/bin/bash
# Persist display configuration
# Ensures display settings persist across reboots

BOOT_CONFIG="/boot/firmware/config.txt"
BOOT_CMDLINE="/boot/firmware/cmdline.txt"

# Ensure display_rotate=1
if [ -f "$BOOT_CONFIG" ]; then
    if ! grep -q "^display_rotate=1" "$BOOT_CONFIG"; then
        echo "display_rotate=1" >> "$BOOT_CONFIG"
    fi
fi

# Ensure fbcon=rotate:1
if [ -f "$BOOT_CMDLINE" ]; then
    if ! grep -q "fbcon=rotate:1" "$BOOT_CMDLINE"; then
        sed -i 's/$/ fbcon=rotate:1/' "$BOOT_CMDLINE"
    fi
fi
